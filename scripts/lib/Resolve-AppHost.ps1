# CreativePOS — Resolve APP_HOST / APP_URL dari argumen, file konfigurasi, atau auto-detect.
#
# Usage:
#   . .\scripts\lib\Resolve-AppHost.ps1
#   $r = Resolve-AppHost -Root $Root -CliHost $AppHost -CliPort $AppPort
#
# Returns hashtable: AppHost, Port, Scheme, Url, Source

function Test-PlaceholderHost {
    param([string]$HostName)
    if ([string]::IsNullOrWhiteSpace($HostName)) { return $true }
    $h = $HostName.ToLowerInvariant() -replace '^https?://', '' -replace '/.*$', '' -replace ':.*$', ''
    $placeholders = @('', 'localhost', '127.0.0.1', '0.0.0.0', '192.168.1.50', 'example.com', 'pos.example.com')
    return $placeholders -contains $h
}

function Read-EnvValue {
    param([string]$File, [string]$Key)
    if (-not (Test-Path $File)) { return $null }
    $line = Get-Content $File -ErrorAction SilentlyContinue |
        Where-Object { $_ -match "^\s*$([regex]::Escape($Key))=" } |
        Select-Object -First 1
    if (-not $line) { return $null }
    return ($line -split '=', 2)[1].Trim().Trim('"')
}

function Parse-AppUrl {
    param([string]$Url)
    if ($Url -match '^(https?)://([^/:]+)(?::(\d+))?') {
        $port = if ($Matches[3]) { [int]$Matches[3] } elseif ($Matches[1] -eq 'https') { 443 } else { 80 }
        return @{
            Scheme = $Matches[1]
            Host   = $Matches[2]
            Port   = $port
        }
    }
    return $null
}

function Build-AppUrl {
    param([string]$Scheme, [string]$AppHostName, [int]$Port)
    if ($Scheme -eq 'https' -and $Port -eq 443) { return "https://$AppHostName" }
    if ($Scheme -eq 'http' -and $Port -eq 80) { return "http://$AppHostName" }
    return "${Scheme}://${AppHostName}:$Port"
}

function Get-DefaultRouteLanIp {
    $route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
        Where-Object { $_.NextHop -ne '0.0.0.0' } |
        Sort-Object RouteMetric, InterfaceMetric |
        Select-Object -First 1

    if ($route) {
        $ip = Get-NetIPAddress -InterfaceIndex $route.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object {
                $_.IPAddress -notlike '127.*' -and
                $_.IPAddress -notlike '169.254.*'
            } |
            Select-Object -First 1 -ExpandProperty IPAddress
        if ($ip) { return $ip }
    }

    $ip = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -notlike '127.*' -and
            $_.IPAddress -notlike '169.254.*' -and
            $_.InterfaceAlias -notmatch 'vEthernet|Docker|Loopback|Virtual|Tailscale|WSL'
        } |
        Select-Object -First 1 -ExpandProperty IPAddress
    return $ip
}

function Get-SystemFqdn {
    try {
        $fqdn = [System.Net.Dns]::GetHostEntry('localhost').HostName
        if ($fqdn -and $fqdn -ne 'localhost' -and -not (Test-PlaceholderHost $fqdn)) {
            return $fqdn
        }
    } catch { }
    return $null
}

function Resolve-AppHost {
    param(
        [Parameter(Mandatory)][string]$Root,
        [string]$CliHost = '',
        [int]$CliPort = 80
    )

    $dockerEnv = Join-Path $Root 'docker\.env'
    $backendEnv = Join-Path $Root 'backend\.env'

    $result = @{
        AppHost = ''
        Port    = $CliPort
        Scheme  = 'http'
        Url     = ''
        Source  = ''
    }

    # 1) Argumen CLI
    if (-not [string]::IsNullOrWhiteSpace($CliHost)) {
        $result.AppHost = $CliHost.Trim()
        $result.Port = $CliPort
        $result.Scheme = 'http'
        $result.Source = 'argumen CLI'
        $result.Url = Build-AppUrl $result.Scheme $result.AppHost $result.Port
        return $result
    }

    $dockerHost = Read-EnvValue $dockerEnv 'APP_HOST'
    $dockerPort = Read-EnvValue $dockerEnv 'APP_PORT'
    if ($dockerPort -match '^\d+$') { $result.Port = [int]$dockerPort }

    # 2) docker/.env
    if ($dockerHost -and -not (Test-PlaceholderHost $dockerHost)) {
        $result.AppHost = $dockerHost
        $result.Scheme = 'http'
        $result.Source = 'docker/.env (APP_HOST)'
        $result.Url = Build-AppUrl $result.Scheme $result.AppHost $result.Port
        return $result
    }

    # 3) backend/.env APP_URL / FRONTEND_URL
    foreach ($key in @('APP_URL', 'FRONTEND_URL')) {
        $url = Read-EnvValue $backendEnv $key
        if (-not $url) { continue }
        $parsed = Parse-AppUrl $url
        if (-not $parsed) { continue }
        if (Test-PlaceholderHost $parsed.Host) { continue }
        $result.AppHost = $parsed.Host
        $result.Scheme = $parsed.Scheme
        if ($CliPort -ne 80) {
            $result.Port = $CliPort
        } elseif ($dockerPort -match '^\d+$') {
            $result.Port = [int]$dockerPort
        } elseif ($parsed.Port -in 8000, 3000, 8080) {
            $result.Port = 80
        } else {
            $result.Port = $parsed.Port
        }
        $result.Source = "backend/.env ($key)"
        $result.Url = Build-AppUrl $result.Scheme $result.AppHost $result.Port
        return $result
    }

    # 4) Auto-detect LAN IP
    $detected = Get-DefaultRouteLanIp
    if ($detected) {
        $result.AppHost = $detected
        $result.Scheme = 'http'
        $result.Source = 'auto-detect IP LAN'
        $result.Url = Build-AppUrl $result.Scheme $result.AppHost $result.Port
        return $result
    }

    # 5) FQDN
    $fqdn = Get-SystemFqdn
    if ($fqdn) {
        $result.AppHost = $fqdn
        $result.Scheme = 'http'
        $result.Source = 'hostname (FQDN)'
        $result.Url = Build-AppUrl $result.Scheme $result.AppHost $result.Port
        return $result
    }

    # 6) Prompt manual
    if ($env:CREATIVEPOS_NO_PROMPT -ne '1') {
        $result.AppHost = Read-Host 'Masukkan IP/hostname server'
        $result.Scheme = 'http'
        $result.Source = 'input manual'
        $result.Url = Build-AppUrl $result.Scheme $result.AppHost $result.Port
        return $result
    }

    throw 'Gagal mendeteksi APP_HOST. Set manual: install.ps1 -AppHost IP_SERVER'
}