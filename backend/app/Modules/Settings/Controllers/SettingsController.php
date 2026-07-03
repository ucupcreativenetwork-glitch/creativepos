<?php

namespace App\Modules\Settings\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Settings\Services\SettingsService;
use App\Modules\Tenant\Models\Outlet;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SettingsController extends Controller
{
    public function __construct(
        private readonly SettingsService $settingsService,
    ) {}

    public function getTenant(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.view');

        $settings = $this->settingsService->getTenantSettings();

        return ApiResponse::success($settings);
    }

    public function updateTenant(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.update');

        $validated = $request->validate([
            'business_name' => 'sometimes|string|max:255',
            'business_type' => 'sometimes|nullable|string|max:100',
            'phone' => 'sometimes|nullable|string|max:20',
            'address' => 'sometimes|nullable|string|max:500',
            'email' => 'sometimes|nullable|email|max:255',
            'logo_url' => [
                'sometimes',
                'nullable',
                'string',
                'max:500',
                function (string $attribute, mixed $value, \Closure $fail): void {
                    if (is_string($value) && str_starts_with($value, 'data:')) {
                        $fail('Logo harus diunggah sebagai file, bukan data base64.');
                    }
                },
            ],
            'primary_color' => 'sometimes|string|max:7',
            'service_charge_rate' => 'sometimes|numeric|min:0|max:100',
            'tax_rate' => 'sometimes|numeric|min:0|max:100',
            'timezone' => 'sometimes|string|max:50',
            'currency' => 'sometimes|string|size:3',
            'setup_completed' => 'sometimes|boolean',
            'onboarding_progress' => 'sometimes|array',
            'enabled_payment_methods' => 'sometimes|array',
            'feature_reservations' => 'sometimes|boolean',
            'feature_delivery' => 'sometimes|boolean',
            'feature_qr_menu' => 'sometimes|boolean',
        ]);

        $settings = $this->settingsService->updateTenantSettings($validated);

        return ApiResponse::success($settings);
    }

    public function onboardingStatus(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.view');

        return ApiResponse::success($this->settingsService->getOnboardingStatus());
    }

    public function onboardingChecklist(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.view');

        return ApiResponse::success($this->settingsService->getOnboardingChecklist());
    }

    public function updateOnboardingProgress(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.update');

        if ($request->has('current_step')) {
            $request->merge([
                'current_step' => min(5, max(1, $request->integer('current_step'))),
            ]);
        }

        $validated = $request->validate([
            'current_step' => 'sometimes|integer|min:1|max:5',
            'completed_steps' => 'sometimes|array',
            'skipped_steps' => 'sometimes|array',
            'staff_invited' => 'sometimes|boolean',
        ]);

        return ApiResponse::success(
            $this->settingsService->updateOnboardingProgress($validated),
        );
    }

    public function syncPaymentMethods(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.update');

        $validated = $request->validate([
            'codes' => 'required|array|min:1',
            'codes.*' => 'string|max:50',
        ]);

        $result = $this->settingsService->syncPaymentMethods($validated['codes']);

        $this->settingsService->updateOnboardingProgress([
            'completed_steps' => array_values(array_unique(array_merge(
                $this->settingsService->getOnboardingStatus()['completed_steps'] ?? [],
                ['payment'],
            ))),
        ]);

        return ApiResponse::success($result);
    }

    public function outlets(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.view');

        return ApiResponse::success($this->settingsService->listOutlets());
    }

    public function storeOutlet(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.outlets.manage');

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:20',
            'address' => 'nullable|string',
            'phone' => 'nullable|string|max:20',
            'is_active' => 'sometimes|boolean',
            'is_default' => 'sometimes|boolean',
        ]);

        $outlet = $this->settingsService->createOutlet($validated);

        return ApiResponse::created($outlet);
    }

    public function updateOutlet(Request $request, Outlet $outlet): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.outlets.manage');

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'code' => 'sometimes|string|max:20',
            'address' => 'nullable|string',
            'phone' => 'nullable|string|max:20',
            'is_active' => 'sometimes|boolean',
            'is_default' => 'sometimes|boolean',
        ]);

        $outlet = $this->settingsService->updateOutlet($outlet, $validated);

        return ApiResponse::success($outlet);
    }

    public function users(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.users.view');

        $paginator = $this->settingsService->listUsers($request->integer('per_page', 15));

        return ApiResponse::success(
            $paginator->items(),
            'Operation successful',
            200,
            [
                'current_page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
            ],
        );
    }

    public function subscription(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.view');

        return ApiResponse::success($this->settingsService->getSubscription());
    }

    public function integrations(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.view');

        return ApiResponse::success($this->settingsService->listIntegrations());
    }

    public function getWhatsapp(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.view');

        return ApiResponse::success($this->settingsService->getWhatsappConfig());
    }

    public function updateWhatsapp(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.update');

        $validated = $request->validate([
            'config' => 'sometimes|array',
            'config.phone' => 'sometimes|nullable|string|max:20',
            'config.access_token' => 'sometimes|nullable|string|max:500',
            'config.webhook_verify_token' => 'sometimes|nullable|string|max:100',
            'config.gateway' => 'sometimes|nullable|string|in:fonnte,wablas,meta',
            'config.api_url' => 'sometimes|nullable|string|max:255',
            'is_active' => 'sometimes|boolean',
            'phone_number' => 'sometimes|nullable|string|max:20',
            'api_token' => 'sometimes|nullable|string|max:500',
            'provider' => 'sometimes|nullable|string|in:fonnte,wablas,meta',
            'api_url' => 'sometimes|nullable|string|max:255',
        ]);

        $result = $this->settingsService->updateWhatsappConfig($validated);

        return ApiResponse::success($result);
    }

    public function testWhatsapp(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.update');

        $validated = $request->validate([
            'phone' => ['required', 'string', 'max:20', 'regex:/^08\d{8,12}$/'],
            'message' => ['sometimes', 'nullable', 'string', 'max:500'],
            'gateway' => ['sometimes', 'nullable', 'string', 'in:fonnte,wablas,meta'],
            'provider' => ['sometimes', 'nullable', 'string', 'in:fonnte,wablas,meta'],
            'api_token' => ['sometimes', 'nullable', 'string', 'max:500'],
            'access_token' => ['sometimes', 'nullable', 'string', 'max:500'],
            'api_url' => ['sometimes', 'nullable', 'string', 'max:255'],
            'sender_phone' => ['sometimes', 'nullable', 'string', 'max:20'],
            'is_active' => ['sometimes', 'boolean'],
            'save_config' => ['sometimes', 'boolean'],
        ]);

        $overrides = array_filter([
            'gateway' => $validated['gateway'] ?? $validated['provider'] ?? null,
            'api_token' => $validated['api_token'] ?? $validated['access_token'] ?? null,
            'api_url' => $validated['api_url'] ?? null,
            'phone' => $validated['sender_phone'] ?? null,
            'is_active' => $validated['is_active'] ?? true,
        ], fn ($value) => $value !== null);

        $result = $this->settingsService->testWhatsappIntegration(
            $validated['phone'],
            $validated['message'] ?? null,
            $overrides !== [] ? $overrides : null,
            (bool) ($validated['save_config'] ?? false),
        );

        if (! $result['success']) {
            return ApiResponse::error($result['message'], 422, [
                'mode' => $result['mode'],
                'response' => $result['response'] ?? null,
            ]);
        }

        return ApiResponse::success($result, $result['message']);
    }

    public function getEmail(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.view');

        return ApiResponse::success($this->settingsService->getEmailConfig());
    }

    public function updateEmail(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.update');

        $validated = $request->validate([
            'config' => 'sometimes|array',
            'config.mailer' => 'sometimes|string|in:smtp,log',
            'config.host' => 'sometimes|nullable|string|max:255',
            'config.port' => 'sometimes|nullable|integer|min:1|max:65535',
            'config.encryption' => 'sometimes|nullable|string|in:tls,ssl,none',
            'config.username' => 'sometimes|nullable|string|max:255',
            'config.password' => 'sometimes|nullable|string|max:500',
            'config.from_address' => 'sometimes|nullable|email|max:255',
            'config.from_name' => 'sometimes|nullable|string|max:255',
            'config.send_welcome_email' => 'sometimes|boolean',
            'is_active' => 'sometimes|boolean',
            'send_welcome_email' => 'sometimes|boolean',
        ]);

        $result = $this->settingsService->updateEmailConfig($validated);

        return ApiResponse::success($result);
    }

    public function testEmail(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.update');

        $validated = $request->validate([
            'email' => ['required', 'email', 'max:255'],
            'mailer' => ['sometimes', 'string', 'in:smtp,log'],
            'host' => ['sometimes', 'nullable', 'string', 'max:255'],
            'port' => ['sometimes', 'nullable', 'integer', 'min:1', 'max:65535'],
            'encryption' => ['sometimes', 'nullable', 'string', 'in:tls,ssl,none'],
            'username' => ['sometimes', 'nullable', 'string', 'max:255'],
            'password' => ['sometimes', 'nullable', 'string', 'max:500'],
            'from_address' => ['sometimes', 'nullable', 'email', 'max:255'],
            'from_name' => ['sometimes', 'nullable', 'string', 'max:255'],
            'is_active' => ['sometimes', 'boolean'],
            'send_welcome_email' => ['sometimes', 'boolean'],
            'save_config' => ['sometimes', 'boolean'],
        ]);

        $overrides = array_filter([
            'mailer' => $validated['mailer'] ?? null,
            'host' => $validated['host'] ?? null,
            'port' => $validated['port'] ?? null,
            'encryption' => ($validated['encryption'] ?? null) === 'none' ? null : ($validated['encryption'] ?? null),
            'username' => $validated['username'] ?? null,
            'password' => $validated['password'] ?? null,
            'from_address' => $validated['from_address'] ?? null,
            'from_name' => $validated['from_name'] ?? null,
            'is_active' => array_key_exists('is_active', $validated) ? $validated['is_active'] : null,
            'send_welcome_email' => array_key_exists('send_welcome_email', $validated)
                ? $validated['send_welcome_email']
                : null,
        ], fn ($value) => $value !== null);

        $result = $this->settingsService->testEmailIntegration(
            $validated['email'],
            $overrides !== [] ? $overrides : null,
            (bool) ($validated['save_config'] ?? false),
        );

        if (! $result['success']) {
            return ApiResponse::error($result['message'], 422, [
                'mode' => $result['mode'],
            ]);
        }

        return ApiResponse::success($result, $result['message']);
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses pengaturan.');
        }
    }
}