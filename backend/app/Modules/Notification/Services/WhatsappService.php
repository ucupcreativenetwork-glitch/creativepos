<?php

namespace App\Modules\Notification\Services;

use App\Modules\Notification\Enums\WhatsappProvider;
use App\Modules\Settings\Models\WhatsappConfig;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class WhatsappService
{
    /**
     * @param  array<string, mixed>|null  $overrides
     * @return array{success: bool, response?: mixed, error?: string}
     */
    public function send(
        string $phone,
        string $message,
        ?int $tenantId = null,
        ?array $overrides = null,
    ): array {
        $config = $this->resolveConfig($tenantId, $overrides);

        if ($config === null || ! $config->is_active || blank($config->api_token)) {
            Log::info('WhatsApp notification (dev mode)', [
                'phone' => $phone,
                'message' => $message,
                'tenant_id' => $tenantId,
            ]);

            return ['success' => true, 'response' => ['mode' => 'dev']];
        }

        $normalizedPhone = $this->normalizePhone($phone);
        $provider = WhatsappProvider::tryFrom($config->provider ?? 'fonnte') ?? WhatsappProvider::Fonnte;

        if ($this->isSameAsSenderDevice($config, $normalizedPhone)) {
            Log::warning('WhatsApp target sama dengan nomor device Fonnte — notifikasi masuk ke chat "Pesan ke diri sendiri", tanpa push notification', [
                'target' => $normalizedPhone,
                'sender_device' => $config->phone_number,
                'tenant_id' => $tenantId,
            ]);
        }

        return match ($provider) {
            WhatsappProvider::Fonnte => $this->sendViaFonnte($config, $normalizedPhone, $message),
            WhatsappProvider::Wablas => $this->sendViaWablas($config, $normalizedPhone, $message),
            WhatsappProvider::Meta => $this->sendViaMeta($config, $normalizedPhone, $message),
        };
    }

    /**
     * @param  array<string, mixed>|null  $overrides
     */
    protected function resolveConfig(?int $tenantId, ?array $overrides = null): ?WhatsappConfig
    {
        if ($overrides !== null) {
            return $this->configFromOverrides($overrides, $tenantId);
        }

        if ($tenantId !== null) {
            return WhatsappConfig::query()
                ->withoutGlobalScopes()
                ->where('tenant_id', $tenantId)
                ->first();
        }

        return WhatsappConfig::query()->first();
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    protected function configFromOverrides(array $overrides, ?int $tenantId): WhatsappConfig
    {
        $stored = null;
        if ($tenantId !== null) {
            $stored = WhatsappConfig::query()
                ->withoutGlobalScopes()
                ->where('tenant_id', $tenantId)
                ->first();
        }

        $token = $overrides['api_token'] ?? $overrides['access_token'] ?? null;
        if ($this->isMaskedToken($token)) {
            $token = $stored?->api_token;
        }

        $config = new WhatsappConfig([
            'tenant_id' => $tenantId,
            'provider' => $overrides['gateway'] ?? $overrides['provider'] ?? $stored?->provider ?? 'fonnte',
            'api_url' => $overrides['api_url'] ?? $stored?->api_url,
            'phone_number' => $overrides['phone'] ?? $overrides['phone_number'] ?? $stored?->phone_number ?? '',
            'is_active' => array_key_exists('is_active', $overrides)
                ? (bool) $overrides['is_active']
                : (bool) ($stored?->is_active ?? true),
        ]);
        $config->api_token = $token ?? $stored?->api_token;

        return $config;
    }

    protected function isMaskedToken(?string $token): bool
    {
        if (blank($token)) {
            return true;
        }

        return str_contains($token, '•') || str_contains($token, '*');
    }

    /**
     * @return array{success: bool, response?: mixed, error?: string}
     */
    protected function sendViaFonnte(WhatsappConfig $config, string $phone, string $message): array
    {
        $url = $config->api_url ?: WhatsappProvider::Fonnte->defaultApiUrl();
        $target = $this->formatFonnteTarget($phone);

        try {
            $response = $this->httpClient()
                ->withHeaders(['Authorization' => $config->api_token])
                ->asForm()
                ->post($url, [
                    'target' => $target,
                    'message' => $message,
                    'countryCode' => '62',
                ]);
        } catch (ConnectionException $e) {
            return $this->connectionError($e);
        }

        $payload = $response->json();

        if (! $this->gatewaySucceeded($response->successful(), $payload)) {
            return [
                'success' => false,
                'error' => $this->extractGatewayError($payload, $response->body()),
                'response' => $payload,
            ];
        }

        return ['success' => true, 'response' => $payload];
    }

    /**
     * @return array{success: bool, response?: mixed, error?: string}
     */
    protected function sendViaWablas(WhatsappConfig $config, string $phone, string $message): array
    {
        $url = $config->api_url;

        if (blank($url)) {
            return ['success' => false, 'error' => 'Wablas API URL belum dikonfigurasi.'];
        }

        try {
            $response = $this->httpClient()
                ->withHeaders(['Authorization' => $config->api_token])
                ->post(rtrim($url, '/').'/api/send-message', [
                    'phone' => $phone,
                    'message' => $message,
                ]);
        } catch (ConnectionException $e) {
            return $this->connectionError($e);
        }

        $payload = $response->json();

        if (! $this->gatewaySucceeded($response->successful(), $payload)) {
            return [
                'success' => false,
                'error' => $this->extractGatewayError($payload, $response->body()),
                'response' => $payload,
            ];
        }

        return ['success' => true, 'response' => $payload];
    }

    /**
     * @return array{success: bool, response?: mixed, error?: string}
     */
    protected function sendViaMeta(WhatsappConfig $config, string $phone, string $message): array
    {
        $url = $config->api_url ?: config('creativepos.whatsapp.api_url');

        if (blank($url) || blank($config->api_token)) {
            return ['success' => false, 'error' => 'WhatsApp Business API belum dikonfigurasi.'];
        }

        try {
            $response = $this->httpClient()
                ->withToken($config->api_token)
                ->post($url, [
                    'messaging_product' => 'whatsapp',
                    'to' => $phone,
                    'type' => 'text',
                    'text' => ['body' => $message],
                ]);
        } catch (ConnectionException $e) {
            return $this->connectionError($e);
        }

        $payload = $response->json();

        if (! $response->successful()) {
            return [
                'success' => false,
                'error' => $payload['error']['message'] ?? $response->body(),
                'response' => $payload,
            ];
        }

        return ['success' => true, 'response' => $payload];
    }

    protected function gatewaySucceeded(bool $httpOk, mixed $payload): bool
    {
        if (! $httpOk || ! is_array($payload)) {
            return $httpOk;
        }

        $status = $payload['status'] ?? $payload['Status'] ?? true;

        return $status !== false && $status !== 'false';
    }

    protected function extractGatewayError(mixed $payload, string $fallback): string
    {
        if (! is_array($payload)) {
            return $fallback ?: 'Gateway WhatsApp menolak permintaan.';
        }

        $reason = $payload['reason'] ?? $payload['message'] ?? $payload['detail'] ?? null;

        if (is_string($reason) && $reason !== '') {
            return match (strtolower($reason)) {
                'invalid token', 'token invalid' => 'Token Fonnte tidak valid. Salin ulang token dari dashboard Fonnte → Device → Token.',
                'target invalid' => 'Nomor WhatsApp tujuan tidak valid. Gunakan format 08xxxxxxxxxx.',
                'insufficient quota' => 'Kuota pesan Fonnte habis. Top up atau upgrade paket Fonnte.',
                default => $reason,
            };
        }

        return $fallback ?: 'Gateway WhatsApp menolak permintaan.';
    }

    protected function formatFonnteTarget(string $phone): string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?? $phone;

        if (str_starts_with($digits, '62')) {
            return '0'.substr($digits, 2);
        }

        if (str_starts_with($digits, '0')) {
            return $digits;
        }

        return '0'.$digits;
    }

    protected function httpClient(): PendingRequest
    {
        $client = Http::timeout(30);

        if (app()->environment('local')) {
            $client = $client->withoutVerifying();
        }

        return $client;
    }

    /**
     * @return array{success: false, error: string}
     */
    protected function connectionError(ConnectionException $e): array
    {
        Log::error('WhatsApp gateway connection failed', [
            'message' => $e->getMessage(),
        ]);

        return [
            'success' => false,
            'error' => 'Koneksi ke gateway WhatsApp gagal. Periksa internet, token API, dan URL gateway.',
        ];
    }

    protected function isSameAsSenderDevice(WhatsappConfig $config, string $normalizedPhone): bool
    {
        if (blank($config->phone_number)) {
            return false;
        }

        return $normalizedPhone === $this->normalizePhone($config->phone_number);
    }

    protected function normalizePhone(string $phone): string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?? $phone;

        if (str_starts_with($digits, '0')) {
            return '62'.substr($digits, 1);
        }

        if (! str_starts_with($digits, '62')) {
            return '62'.$digits;
        }

        return $digits;
    }
}