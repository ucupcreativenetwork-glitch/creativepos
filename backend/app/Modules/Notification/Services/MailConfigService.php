<?php

namespace App\Modules\Notification\Services;

use App\Modules\Settings\Models\EmailConfig;
use App\Shared\Support\FrontendUrl;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class MailConfigService
{
    public function applyForTenant(?int $tenantId): bool
    {
        if ($tenantId === null) {
            $this->applyGlobalConfig();

            return config('mail.default') !== 'log';
        }

        $config = EmailConfig::query()
            ->withoutGlobalScopes()
            ->where('tenant_id', $tenantId)
            ->first();

        if ($config === null || ! $config->is_active) {
            $this->applyGlobalConfig();

            return config('mail.default') !== 'log';
        }

        $this->applyConfig($config);

        return true;
    }

    public function applyGlobalConfig(): void
    {
        $mailer = (string) config('mail.default', 'log');

        Config::set('mail.default', $mailer);
        $this->purgeMailers();
    }

    public function applyConfig(EmailConfig $config): void
    {
        $mailer = $config->mailer ?: 'smtp';

        Config::set('mail.default', $mailer);

        if ($mailer === 'smtp') {
            Config::set('mail.mailers.smtp', [
                'transport' => 'smtp',
                'host' => $config->host,
                'port' => (int) ($config->port ?: 587),
                'username' => $config->username,
                'password' => $config->password,
                'timeout' => null,
                'local_domain' => env('MAIL_EHLO_DOMAIN', 'smtp.mailersend.net'),
            ]);
        }

        if (filled($config->from_address)) {
            Config::set('mail.from.address', strtolower((string) $config->from_address));
        }

        if (filled($config->from_name)) {
            Config::set('mail.from.name', $config->from_name);
        }

        $this->purgeMailers();
    }

    protected function purgeMailers(): void
    {
        Mail::purge(config('mail.default'));
        Mail::purge('smtp');
        Mail::purge('log');
    }

    /**
     * @param  array<string, mixed>|null  $overrides
     * @return array{success: bool, mode: string, message: string}
     */
    public function sendTestEmail(string $recipient, ?int $tenantId = null, ?array $overrides = null): array
    {
        $config = $this->resolveConfig($tenantId, $overrides);

        if ($config === null || ! $config->is_active || ! $this->hasDeliverableSmtpConfig($config)) {
            if (config('mail.default') === 'log') {
                try {
                    Mail::raw(
                        'Ini pesan uji coba email dari CreativePOS. Gateway email berjalan (mode log).',
                        fn ($message) => $message->to($recipient)->subject('Uji Email CreativePOS')
                    );

                    return [
                        'success' => true,
                        'mode' => 'log',
                        'message' => 'Mode log: email dicatat di storage/logs/laravel.log',
                    ];
                } catch (\Throwable $e) {
                    return [
                        'success' => false,
                        'mode' => 'log',
                        'message' => 'Gagal mencatat email uji: '.$e->getMessage(),
                    ];
                }
            }

            return [
                'success' => false,
                'mode' => 'disabled',
                'message' => 'Gateway email belum diaktifkan. Aktifkan di Pengaturan → Integrasi.',
            ];
        }

        $this->applyConfig($config);

        try {
            $from = $config->from_address ?: config('mail.from.address');
            $tenant = $tenantId ? \App\Modules\Platform\Models\Tenant::query()->find($tenantId) : null;

            Mail::send(
                'emails.smtp-test',
                [
                    'sentAt' => now()->timezone(config('app.timezone', 'Asia/Jakarta'))->format('d M Y H:i T'),
                    'businessName' => $tenant?->name,
                ],
                function ($message) use ($recipient, $from, $config): void {
                    $message->to($recipient)->subject('Uji Email CreativePOS');
                    if (filled($from)) {
                        $message->from($from, $config->from_name ?: config('mail.from.name'));
                    }
                }
            );

            return [
                'success' => true,
                'mode' => 'smtp',
                'message' => 'Email uji berhasil dikirim ke '.$recipient,
            ];
        } catch (\Throwable $e) {
            Log::error('Email test failed', [
                'tenant_id' => $tenantId,
                'error' => $e->getMessage(),
            ]);

            return [
                'success' => false,
                'mode' => 'smtp',
                'message' => 'Gagal mengirim email: '.$e->getMessage(),
            ];
        }
    }

    public function sendWelcomeEmail(object $user, object $tenant): bool
    {
        $config = EmailConfig::query()
            ->withoutGlobalScopes()
            ->where('tenant_id', $tenant->id)
            ->first();

        if ($config !== null && ! $config->send_welcome_email) {
            return false;
        }

        $this->applyForTenant($tenant->id);

        try {
            $businessName = $tenant->name ?? 'CreativePOS';

            Mail::send(
                'emails.welcome-registration',
                [
                    'userName' => $user->name,
                    'businessName' => $businessName,
                    'loginUrl' => FrontendUrl::login(),
                ],
                function ($message) use ($user, $tenant, $config): void {
                    $message->to($user->email)
                        ->subject('Selamat datang di CreativePOS — '.$tenant->name);

                    if ($config && filled($config->from_address)) {
                        $message->from($config->from_address, $config->from_name ?: $tenant->name);
                    }
                }
            );

            return true;
        } catch (\Throwable $e) {
            Log::warning('Welcome registration email failed', [
                'tenant_id' => $tenant->id,
                'email' => $user->email,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }

    /**
     * @param  array<string, mixed>|null  $overrides
     */
    protected function resolveConfig(?int $tenantId, ?array $overrides = null): ?EmailConfig
    {
        if ($overrides !== null) {
            return $this->configFromOverrides($overrides, $tenantId);
        }

        if ($tenantId === null) {
            return null;
        }

        return EmailConfig::query()
            ->withoutGlobalScopes()
            ->where('tenant_id', $tenantId)
            ->first();
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    protected function configFromOverrides(array $overrides, ?int $tenantId): EmailConfig
    {
        $stored = $tenantId
            ? EmailConfig::query()->withoutGlobalScopes()->where('tenant_id', $tenantId)->first()
            : null;

        $password = $overrides['password'] ?? null;
        if ($this->isMaskedSecret($password)) {
            $password = $stored?->password;
        }

        $config = new EmailConfig([
            'tenant_id' => $tenantId,
            'mailer' => $overrides['mailer'] ?? $stored?->mailer ?? 'smtp',
            'host' => $overrides['host'] ?? $stored?->host,
            'port' => (int) ($overrides['port'] ?? $stored?->port ?? 587),
            'encryption' => $overrides['encryption'] ?? $stored?->encryption,
            'username' => $overrides['username'] ?? $stored?->username,
            'from_address' => $overrides['from_address'] ?? $stored?->from_address,
            'from_name' => $overrides['from_name'] ?? $stored?->from_name,
            'is_active' => array_key_exists('is_active', $overrides)
                ? (bool) $overrides['is_active']
                : (bool) ($stored?->is_active ?? true),
            'send_welcome_email' => array_key_exists('send_welcome_email', $overrides)
                ? (bool) $overrides['send_welcome_email']
                : (bool) ($stored?->send_welcome_email ?? true),
        ]);
        $config->password = $password ?? $stored?->password;

        return $config;
    }

    protected function isMaskedSecret(?string $value): bool
    {
        if (blank($value)) {
            return true;
        }

        return str_contains($value, '•') || str_contains($value, '*');
    }

    protected function hasDeliverableSmtpConfig(EmailConfig $config): bool
    {
        if (($config->mailer ?: 'smtp') === 'log') {
            return true;
        }

        return filled($config->host);
    }
}