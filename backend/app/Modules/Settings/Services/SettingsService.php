<?php

namespace App\Modules\Settings\Services;

use App\Models\User;
use App\Modules\Billing\Services\BillingService;
use App\Shared\Services\PackageLimitService;
use App\Shared\Support\PaymentMethodCatalog;
use App\Modules\Notification\Services\MailConfigService;
use App\Modules\Settings\Models\EmailConfig;
use App\Modules\Settings\Models\WhatsappConfig;
use App\Modules\Platform\Models\Tenant;
use App\Modules\Inventory\Models\Product;
use App\Modules\POS\Models\PaymentMethod;
use App\Modules\Tenant\Models\Outlet;
use App\Modules\Tenant\Models\TenantSetting;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class SettingsService
{
    public function __construct(
        private readonly BillingService $billingService,
        private readonly PackageLimitService $packageLimits,
    ) {}

    public function getTenantSettings(): array
    {
        $tenant = Tenant::query()->find(tenant('id'));
        $settings = TenantSetting::query()
            ->where('tenant_id', tenant('id'))
            ->first();

        return [
            'business_name' => $settings?->business_name ?? $tenant?->name,
            'business_type' => $settings?->business_type,
            'phone' => $tenant?->phone,
            'address' => $tenant?->address,
            'email' => $tenant?->email,
            'logo_url' => $settings?->logo_url ?? $tenant?->logo_url,
            'primary_color' => $settings?->primary_color ?? '#2563EB',
            'service_charge_rate' => (float) ($settings?->service_charge_rate ?? 0),
            'tax_rate' => (float) ($settings?->tax_rate ?? 11),
            'timezone' => $settings?->timezone ?? 'Asia/Jakarta',
            'currency' => $settings?->currency ?? 'IDR',
            'setup_completed' => (bool) ($settings?->setup_completed ?? false),
            'feature_reservations' => (bool) ($settings?->feature_reservations ?? true),
            'feature_delivery' => (bool) ($settings?->feature_delivery ?? true),
            'feature_qr_menu' => (bool) ($settings?->feature_qr_menu ?? true),
            'enabled_payment_methods' => $settings?->enabled_payment_methods ?? [],
            'onboarding_progress' => $settings?->onboarding_progress ?? [],
            'wifi_ssid' => $settings?->wifi_ssid,
            'wifi_password' => $settings?->wifi_password,
            'receipt_show_wifi' => (bool) ($settings?->receipt_show_wifi ?? false),
        ];
    }

    public function updateTenantSettings(array $data): array
    {
        $tenant = Tenant::query()->findOrFail(tenant('id'));

        $tenantFields = array_intersect_key($data, array_flip(['phone', 'address', 'email']));
        if ($tenantFields !== []) {
            $tenant->update($tenantFields);
        }

        $settings = TenantSetting::query()->firstOrCreate(
            ['tenant_id' => tenant('id')],
            ['business_name' => $tenant->name],
        );

        $settings->update(array_intersect_key($data, array_flip([
            'business_name', 'business_type', 'logo_url', 'primary_color',
            'service_charge_rate', 'tax_rate', 'timezone', 'currency', 'setup_completed',
            'onboarding_progress', 'enabled_payment_methods',
            'feature_reservations', 'feature_delivery', 'feature_qr_menu',
            'wifi_ssid', 'wifi_password', 'receipt_show_wifi',
        ])));

        return $this->getTenantSettings();
    }

    public function listOutlets(): Collection
    {
        return Outlet::query()
            ->orderBy('name')
            ->get(['id', 'uuid', 'name', 'code', 'address', 'phone', 'is_active', 'is_default']);
    }

    public function createOutlet(array $data): Outlet
    {
        $this->packageLimits->assertCanCreateOutlet();

        if (! empty($data['is_default'])) {
            Outlet::query()->update(['is_default' => false]);
        }

        return Outlet::query()->create($data);
    }

    public function updateOutlet(Outlet $outlet, array $data): Outlet
    {
        if (! empty($data['is_default'])) {
            Outlet::query()->where('id', '!=', $outlet->id)->update(['is_default' => false]);
        }

        $outlet->update($data);

        return $outlet->fresh();
    }

    public function listUsers(int $perPage = 15): LengthAwarePaginator
    {
        return User::query()
            ->where('tenant_id', tenant('id'))
            ->where('is_super_admin', false)
            ->orderBy('name')
            ->paginate($perPage, ['id', 'uuid', 'name', 'email', 'phone', 'status', 'outlet_id', 'last_login_at']);
    }

    public function getSubscription(): ?array
    {
        return $this->billingService->getSubscription();
    }

    public function listIntegrations(): array
    {
        $waConfig = WhatsappConfig::query()->first();
        $emailConfig = EmailConfig::query()->first();

        return [
            [
                'provider' => 'email',
                'is_active' => (bool) ($emailConfig?->is_active ?? false),
                'config' => [
                    'mailer' => $emailConfig?->mailer ?? 'smtp',
                    'host' => $emailConfig?->host,
                    'port' => $emailConfig?->port ?? 587,
                    'encryption' => $emailConfig?->encryption,
                    'username' => $emailConfig?->username,
                    'password' => $emailConfig?->password ? '••••••••' : '',
                    'from_address' => $emailConfig?->from_address,
                    'from_name' => $emailConfig?->from_name,
                    'send_welcome_email' => (bool) ($emailConfig?->send_welcome_email ?? true),
                ],
            ],
            [
                'provider' => 'whatsapp',
                'is_active' => (bool) ($waConfig?->is_active ?? false),
                'config' => [
                    'gateway' => $waConfig?->provider ?? 'fonnte',
                    'api_url' => $waConfig?->api_url,
                    'phone' => $waConfig?->phone_number,
                    'phone_number_id' => $waConfig?->phone_number,
                    'access_token' => $waConfig?->api_token ? '••••••••' : '',
                    'webhook_verify_token' => $waConfig?->webhook_secret,
                ],
            ],
            [
                'provider' => 'midtrans',
                'is_active' => filled(config('creativepos.payment.midtrans.server_key')),
                'config' => [
                    'methods' => 'VA BCA/BNI/BRI, QRIS, GoPay, OVO, DANA',
                    'scope' => 'saas_billing',
                ],
            ],
            [
                'provider' => 'xendit',
                'is_active' => filled(config('creativepos.payment.xendit.secret_key')),
                'config' => [
                    'methods' => 'Kartu Kredit, Recurring Subscription',
                    'scope' => 'saas_billing',
                ],
            ],
        ];
    }

    public function getEmailConfig(): array
    {
        $config = EmailConfig::query()->first();

        return [
            'mailer' => $config?->mailer ?? 'smtp',
            'host' => $config?->host,
            'port' => $config?->port ?? 587,
            'encryption' => $config?->encryption,
            'username' => $config?->username,
            'from_address' => $config?->from_address,
            'from_name' => $config?->from_name,
            'is_active' => (bool) ($config?->is_active ?? false),
            'send_welcome_email' => (bool) ($config?->send_welcome_email ?? true),
            'has_password' => filled($config?->password),
        ];
    }

    public function updateEmailConfig(array $data): array
    {
        $config = EmailConfig::query()->firstOrCreate(
            ['tenant_id' => tenant('id')],
            [
                'mailer' => 'smtp',
                'port' => 587,
                'is_active' => false,
                'send_welcome_email' => true,
            ],
        );

        $mapped = [];

        if (array_key_exists('config', $data) && is_array($data['config'])) {
            $nested = $data['config'];
            foreach (['mailer', 'host', 'port', 'encryption', 'username', 'from_address', 'from_name'] as $field) {
                if (array_key_exists($field, $nested)) {
                    $mapped[$field] = $nested[$field];
                }
            }
            if (
                ! empty($nested['password'])
                && ! str_contains((string) $nested['password'], '•')
                && ! str_contains((string) $nested['password'], '*')
            ) {
                $mapped['password'] = $nested['password'];
            }
            if (array_key_exists('send_welcome_email', $nested)) {
                $mapped['send_welcome_email'] = (bool) $nested['send_welcome_email'];
            }
        }

        foreach (['mailer', 'host', 'port', 'encryption', 'username', 'from_address', 'from_name'] as $field) {
            if (array_key_exists($field, $data)) {
                $mapped[$field] = $data[$field];
            }
        }

        if (
            array_key_exists('password', $data)
            && filled($data['password'])
            && ! str_contains((string) $data['password'], '•')
            && ! str_contains((string) $data['password'], '*')
        ) {
            $mapped['password'] = $data['password'];
        }

        if (array_key_exists('is_active', $data)) {
            $mapped['is_active'] = (bool) $data['is_active'];
        }

        if (array_key_exists('send_welcome_email', $data)) {
            $mapped['send_welcome_email'] = (bool) $data['send_welcome_email'];
        }

        if (isset($mapped['from_address']) && filled($mapped['from_address'])) {
            $mapped['from_address'] = strtolower((string) $mapped['from_address']);
        }

        if ($mapped !== []) {
            $config->update($mapped);
        }

        return collect($this->listIntegrations())->firstWhere('provider', 'email');
    }

    /**
     * @param  array<string, mixed>|null  $overrides
     * @return array{success: bool, mode: string, message: string}
     */
    public function testEmailIntegration(
        string $recipient,
        ?array $overrides = null,
        bool $persistConfig = false,
    ): array {
        if ($persistConfig && $overrides !== null) {
            $this->updateEmailConfig([
                'config' => $overrides,
                'is_active' => $overrides['is_active'] ?? true,
            ]);
        }

        return app(MailConfigService::class)->sendTestEmail(
            $recipient,
            tenant('id'),
            $overrides,
        );
    }

    public function getWhatsappConfig(): array
    {
        $config = WhatsappConfig::query()->first();

        return [
            'provider' => $config?->provider ?? 'fonnte',
            'api_url' => $config?->api_url,
            'phone_number' => $config?->phone_number,
            'is_active' => (bool) ($config?->is_active ?? false),
            'has_token' => filled($config?->api_token),
        ];
    }

    public function updateWhatsappConfig(array $data): array
    {
        $config = WhatsappConfig::query()->firstOrCreate(
            ['tenant_id' => tenant('id')],
            ['provider' => 'fonnte', 'is_active' => false, 'phone_number' => ''],
        );

        $mapped = [];
        if (array_key_exists('phone_number', $data)) {
            $mapped['phone_number'] = $data['phone_number'];
        }
        if (array_key_exists('phone', $data)) {
            $mapped['phone_number'] = $data['phone'];
        }
        if (array_key_exists('config', $data) && is_array($data['config'])) {
            if (isset($data['config']['phone'])) {
                $mapped['phone_number'] = $data['config']['phone'];
            }
            if (
                ! empty($data['config']['access_token'])
                && ! str_contains((string) $data['config']['access_token'], '•')
                && ! str_contains((string) $data['config']['access_token'], '*')
            ) {
                $mapped['api_token'] = $data['config']['access_token'];
            }
            if (isset($data['config']['webhook_verify_token'])) {
                $mapped['webhook_secret'] = $data['config']['webhook_verify_token'];
            }
            if (isset($data['config']['gateway'])) {
                $mapped['provider'] = $data['config']['gateway'];
            }
            if (isset($data['config']['api_url'])) {
                $mapped['api_url'] = $data['config']['api_url'];
            }
        }
        if (array_key_exists('provider', $data)) {
            $mapped['provider'] = $data['provider'];
        }
        if (array_key_exists('api_url', $data)) {
            $mapped['api_url'] = $data['api_url'];
        }
        if (
            array_key_exists('api_token', $data)
            && filled($data['api_token'])
            && ! str_contains((string) $data['api_token'], '•')
            && ! str_contains((string) $data['api_token'], '*')
        ) {
            $mapped['api_token'] = $data['api_token'];
        }
        if (array_key_exists('is_active', $data)) {
            $mapped['is_active'] = (bool) $data['is_active'];
        }
        if (array_key_exists('is_enabled', $data)) {
            $mapped['is_active'] = (bool) $data['is_enabled'];
        }

        if ($mapped !== []) {
            $config->update($mapped);
        }

        return collect($this->listIntegrations())->firstWhere('provider', 'whatsapp');
    }

    /**
     * @return array{success: bool, mode: string, message: string, response?: mixed}
     */
    public function testWhatsappIntegration(
        string $phone,
        ?string $message = null,
        ?array $overrides = null,
        bool $persistConfig = false,
    ): array {
        $message ??= 'Ini pesan uji coba dari CreativePOS. Integrasi WhatsApp berhasil dikonfigurasi.';

        if ($persistConfig && $overrides !== null) {
            $this->updateWhatsappConfig([
                'config' => [
                    'phone' => $overrides['phone'] ?? null,
                    'access_token' => $overrides['api_token'] ?? $overrides['access_token'] ?? null,
                    'gateway' => $overrides['gateway'] ?? $overrides['provider'] ?? null,
                    'api_url' => $overrides['api_url'] ?? null,
                ],
                'is_active' => $overrides['is_active'] ?? true,
            ]);
        }

        $result = app(\App\Modules\Notification\Services\WhatsappService::class)->send(
            $phone,
            $message,
            tenant('id'),
            $overrides,
        );

        $isDevMode = ($result['response']['mode'] ?? null) === 'dev';

        if ($result['success']) {
            return [
                'success' => true,
                'mode' => $isDevMode ? 'dev' : 'live',
                'message' => $isDevMode
                    ? 'Mode dev: pesan dicatat di log server (token/API belum aktif).'
                    : 'Pesan uji coba berhasil dikirim ke WhatsApp.',
                'response' => $result['response'] ?? null,
            ];
        }

        return [
            'success' => false,
            'mode' => 'live',
            'message' => $result['error'] ?? 'Gagal mengirim pesan uji coba WhatsApp.',
            'response' => $result['response'] ?? null,
        ];
    }

    public function getOnboardingChecklist(): array
    {
        $status = $this->getOnboardingStatus();

        $items = [
            [
                'id' => 'outlet',
                'label' => 'Siapkan outlet',
                'description' => 'Tambahkan lokasi toko atau cabang pertama',
                'done' => $status['has_outlet'],
                'href' => '/settings',
                'priority' => 1,
            ],
            [
                'id' => 'product',
                'label' => 'Tambah produk',
                'description' => 'Buat menu atau barang yang akan dijual',
                'done' => $status['has_product'],
                'href' => '/inventory',
                'priority' => 2,
            ],
            [
                'id' => 'payment',
                'label' => 'Atur pembayaran',
                'description' => 'Pilih metode pembayaran yang diterima',
                'done' => $status['has_payment_methods'],
                'href' => '/settings',
                'priority' => 3,
            ],
            [
                'id' => 'staff',
                'label' => 'Undang staff',
                'description' => 'Ajak kasir atau manager bergabung',
                'done' => $status['has_staff_invite'],
                'href' => '/settings',
                'priority' => 4,
            ],
            [
                'id' => 'pos',
                'label' => 'Coba transaksi POS',
                'description' => 'Buka shift dan lakukan penjualan pertama',
                'done' => in_array('pos_sale', $status['completed_steps'] ?? [], true),
                'href' => '/pos',
                'priority' => 5,
            ],
        ];

        $doneCount = collect($items)->where('done', true)->count();
        $totalCount = count($items);

        return [
            'setup_completed' => $status['setup_completed'],
            'items' => $items,
            'completed_count' => $doneCount,
            'total_count' => $totalCount,
            'progress_percent' => $totalCount > 0
                ? (int) round(($doneCount / $totalCount) * 100)
                : 0,
            'quota' => $this->packageLimits->getQuotaSummary(),
        ];
    }

    public function getOnboardingStatus(): array
    {
        $settings = TenantSetting::query()->where('tenant_id', tenant('id'))->first();
        $progress = $settings?->onboarding_progress ?? [];

        $completedSteps = $this->resolveCompletedSteps($settings, $progress);
        $skippedSteps = $progress['skipped_steps'] ?? [];

        return [
            'setup_completed' => (bool) ($settings?->setup_completed ?? false),
            'completed_steps' => $completedSteps,
            'skipped_steps' => $skippedSteps,
            'current_step' => (int) ($progress['current_step'] ?? $this->suggestCurrentStep($completedSteps, $skippedSteps)),
            'has_outlet' => Outlet::query()->where('is_active', true)->exists(),
            'has_product' => Product::query()->where('is_active', true)->exists(),
            'has_payment_methods' => filled($settings?->enabled_payment_methods),
            'has_staff_invite' => (bool) ($progress['staff_invited'] ?? false),
        ];
    }

    public function updateOnboardingProgress(array $progress): array
    {
        $settings = TenantSetting::query()->firstOrCreate(
            ['tenant_id' => tenant('id')],
            ['business_name' => tenant()?->name],
        );

        $merged = array_merge($settings->onboarding_progress ?? [], $progress);
        $settings->update(['onboarding_progress' => $merged]);

        return $this->getOnboardingStatus();
    }

    public function syncPaymentMethods(array $codes): array
    {
        $catalog = PaymentMethodCatalog::definitions();

        PaymentMethodCatalog::syncToDatabase();

        foreach ($catalog as $method) {
            PaymentMethod::query()->updateOrCreate(
                ['code' => $method['code']],
                [
                    'name' => $method['name'],
                    'type' => $method['type'],
                    'is_active' => true,
                ],
            );
        }

        $validCodes = collect($catalog)->pluck('code')->all();
        $selected = array_values(array_intersect($codes, $validCodes));

        if ($selected === []) {
            abort(422, 'Pilih minimal satu metode pembayaran.');
        }

        $settings = TenantSetting::query()->firstOrCreate(
            ['tenant_id' => tenant('id')],
            ['business_name' => tenant()?->name],
        );

        $settings->update(['enabled_payment_methods' => $selected]);

        $methods = PaymentMethod::query()
            ->whereIn('code', $selected)
            ->orderBy('name')
            ->get(['id', 'code', 'name', 'type']);

        return [
            'enabled_codes' => $selected,
            'methods' => $methods,
        ];
    }

    protected function resolveCompletedSteps(?TenantSetting $settings, array $progress): array
    {
        $completed = $progress['completed_steps'] ?? [];

        if ($settings?->business_name && $settings?->business_type) {
            $completed[] = 'profile';
        }

        if (Outlet::query()->where('is_active', true)->exists()) {
            $completed[] = 'outlet';
        }

        if (Product::query()->where('is_active', true)->exists()) {
            $completed[] = 'product';
        }

        if (filled($settings?->enabled_payment_methods)) {
            $completed[] = 'payment';
        }

        if (! empty($progress['staff_invited'])) {
            $completed[] = 'staff';
        }

        return array_values(array_unique($completed));
    }

    protected function suggestCurrentStep(array $completed, array $skipped): int
    {
        $steps = ['profile', 'outlet', 'product', 'payment', 'staff'];

        foreach ($steps as $index => $step) {
            if (! in_array($step, $completed, true) && ! in_array($step, $skipped, true)) {
                return $index + 1;
            }
        }

        return 5;
    }
}