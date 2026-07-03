<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <title>{{ $title ?? 'Laporan' }} — CreativePOS</title>
    <style>
        body { font-family: DejaVu Sans, sans-serif; font-size: 11px; color: #111; }
        h1 { font-size: 18px; margin-bottom: 4px; }
        .meta { color: #555; margin-bottom: 16px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ccc; padding: 6px 8px; text-align: left; }
        th { background: #f1f5f9; font-weight: bold; }
        .text-right { text-align: right; }
        .total-row { font-weight: bold; background: #f8fafc; }
    </style>
</head>
<body>
    <h1>{{ $title ?? 'Laporan' }}</h1>
    <div class="meta">
        Periode: {{ $date_from ?? '-' }} s/d {{ $date_to ?? '-' }}<br>
        Dicetak: {{ now()->format('d M Y H:i') }}
    </div>
    @yield('content')
</body>
</html>