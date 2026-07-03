<?php

namespace App\Providers;

use App\Modules\Dashboard\Repositories\DashboardRepository;
use App\Modules\Dashboard\Services\DashboardService;
use App\Modules\Inventory\Repositories\CategoryRepository;
use App\Modules\Inventory\Repositories\ProductRepository;
use App\Modules\Inventory\Repositories\RawMaterialRepository;
use App\Modules\Inventory\Repositories\StockRepository;
use App\Modules\Inventory\Services\CategoryService;
use App\Modules\Inventory\Services\ProductService;
use App\Modules\Inventory\Services\RawMaterialService;
use App\Modules\Inventory\Services\RecipeService;
use App\Modules\Inventory\Services\StockService;
use App\Modules\POS\Repositories\ShiftRepository;
use App\Modules\POS\Repositories\TransactionRepository;
use App\Modules\POS\Services\ShiftService;
use App\Modules\POS\Services\TransactionService;
use App\Modules\Loyalty\Repositories\MemberRepository;
use App\Modules\Loyalty\Repositories\PointRepository;
use App\Modules\Loyalty\Repositories\WalletRepository;
use App\Modules\Loyalty\Services\MemberService;
use App\Modules\Loyalty\Services\PointService;
use App\Modules\Loyalty\Services\WalletService;
use App\Modules\Delivery\Repositories\DeliveryDriverRepository;
use App\Modules\Delivery\Repositories\DeliveryOrderRepository;
use App\Modules\Delivery\Repositories\DeliveryZoneRepository;
use App\Modules\Delivery\Services\DeliveryFeeService;
use App\Modules\Delivery\Services\DeliveryService;
use App\Modules\Report\Repositories\ReportRepository;
use App\Modules\Report\Services\ReportExportGenerator;
use App\Modules\Report\Services\ReportService;
use App\Modules\Billing\Services\BillingService;
use App\Modules\Billing\Services\Gateways\MidtransGateway;
use App\Modules\Billing\Services\Gateways\XenditGateway;
use App\Modules\Billing\Services\PaymentService;
use App\Modules\Settings\Services\SettingsService;
use App\Modules\Notification\Console\NotifyDueInvoicesCommand;
use App\Modules\Notification\Services\FirebaseService;
use App\Modules\Notification\Services\NotificationLogService;
use App\Modules\Notification\Services\NotificationPreferenceService;
use App\Modules\Notification\Services\NotificationService;
use App\Modules\Notification\Services\RecipientResolver;
use App\Modules\Notification\Services\StockAlertService;
use App\Modules\Notification\Services\WhatsappService;
use App\Modules\Platform\Services\PlatformBillingService;
use App\Modules\Platform\Services\PlatformDashboardService;
use App\Modules\Platform\Services\PlatformTenantService;
use App\Modules\Order\Repositories\OrderRepository;
use App\Modules\Order\Services\OrderService;
use App\Modules\Order\Services\PublicMenuService;
use App\Modules\Reservation\Repositories\ReservationRepository;
use App\Modules\Reservation\Services\ReservationService;
use App\Modules\CRM\Repositories\KnowledgeBaseRepository;
use App\Modules\CRM\Repositories\TicketRepository;
use App\Modules\CRM\Services\KnowledgeBaseService;
use App\Modules\CRM\Services\TicketService;
use App\Modules\Auth\Repositories\LoginHistoryRepository;
use App\Modules\Auth\Repositories\OtpVerificationRepository;
use App\Modules\Auth\Repositories\UserDeviceRepository;
use App\Modules\Auth\Repositories\UserRepository;
use App\Modules\Auth\Services\AuthService;
use App\Modules\Auth\Services\OtpService;
use App\Modules\Auth\Services\TwoFactorService;
use Illuminate\Support\ServiceProvider;

class ModuleServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->registerAuthModule();
        $this->registerDashboardModule();
        $this->registerInventoryModule();
        $this->registerPosModule();
        $this->registerLoyaltyModule();
        $this->registerOrderModule();
        $this->registerReservationModule();
        $this->registerDeliveryModule();
        $this->registerCrmModule();
        $this->registerReportModule();
        $this->registerBillingModule();
        $this->registerNotificationModule();
        $this->registerSettingsModule();
        $this->registerPlatformModule();
    }

    public function boot(): void
    {
        $this->commands([
            NotifyDueInvoicesCommand::class,
        ]);
    }

    protected function registerAuthModule(): void
    {
        $this->app->singleton(UserRepository::class);
        $this->app->singleton(OtpVerificationRepository::class);
        $this->app->singleton(LoginHistoryRepository::class);
        $this->app->singleton(UserDeviceRepository::class);

        $this->app->singleton(OtpService::class);
        $this->app->singleton(TwoFactorService::class);
        $this->app->singleton(AuthService::class);
    }

    protected function registerDashboardModule(): void
    {
        $this->app->singleton(DashboardRepository::class);
        $this->app->singleton(DashboardService::class);
    }

    protected function registerInventoryModule(): void
    {
        $this->app->singleton(CategoryRepository::class);
        $this->app->singleton(ProductRepository::class);
        $this->app->singleton(StockRepository::class);
        $this->app->singleton(RawMaterialRepository::class);
        $this->app->singleton(CategoryService::class);
        $this->app->singleton(ProductService::class);
        $this->app->singleton(StockService::class);
        $this->app->singleton(RawMaterialService::class);
        $this->app->singleton(RecipeService::class);
    }

    protected function registerPosModule(): void
    {
        $this->app->singleton(ShiftRepository::class);
        $this->app->singleton(TransactionRepository::class);
        $this->app->singleton(ShiftService::class);
        $this->app->singleton(TransactionService::class);
    }

    protected function registerLoyaltyModule(): void
    {
        $this->app->singleton(MemberRepository::class);
        $this->app->singleton(PointRepository::class);
        $this->app->singleton(WalletRepository::class);
        $this->app->singleton(MemberService::class);
        $this->app->singleton(PointService::class);
        $this->app->singleton(WalletService::class);
    }

    protected function registerOrderModule(): void
    {
        $this->app->singleton(OrderRepository::class);
        $this->app->singleton(OrderService::class);
        $this->app->singleton(PublicMenuService::class);
    }

    protected function registerReservationModule(): void
    {
        $this->app->singleton(ReservationRepository::class);
        $this->app->singleton(ReservationService::class);
    }

    protected function registerDeliveryModule(): void
    {
        $this->app->singleton(DeliveryOrderRepository::class);
        $this->app->singleton(DeliveryDriverRepository::class);
        $this->app->singleton(DeliveryZoneRepository::class);
        $this->app->singleton(DeliveryFeeService::class);
        $this->app->singleton(DeliveryService::class);
    }

    protected function registerCrmModule(): void
    {
        $this->app->singleton(TicketRepository::class);
        $this->app->singleton(KnowledgeBaseRepository::class);
        $this->app->singleton(TicketService::class);
        $this->app->singleton(KnowledgeBaseService::class);
    }

    protected function registerReportModule(): void
    {
        $this->app->singleton(ReportRepository::class);
        $this->app->singleton(ReportService::class);
        $this->app->singleton(ReportExportGenerator::class);
    }

    protected function registerBillingModule(): void
    {
        $this->app->singleton(BillingService::class);
        $this->app->singleton(MidtransGateway::class);
        $this->app->singleton(XenditGateway::class);
        $this->app->singleton(PaymentService::class);
    }

    protected function registerNotificationModule(): void
    {
        $this->app->singleton(WhatsappService::class);
        $this->app->singleton(FirebaseService::class);
        $this->app->singleton(NotificationLogService::class);
        $this->app->singleton(NotificationPreferenceService::class);
        $this->app->singleton(RecipientResolver::class);
        $this->app->singleton(StockAlertService::class);
        $this->app->singleton(NotificationService::class);
    }

    protected function registerSettingsModule(): void
    {
        $this->app->singleton(SettingsService::class);
    }

    protected function registerPlatformModule(): void
    {
        $this->app->singleton(PlatformDashboardService::class);
        $this->app->singleton(PlatformTenantService::class);
        $this->app->singleton(PlatformBillingService::class);
    }
}