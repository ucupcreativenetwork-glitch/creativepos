abstract final class ApiPaths {
  static const health = '/health';

  // Mobile app update
  static const mobileVersion = '/mobile/version';

  // Auth
  static const login = '/auth/login';
  static const login2fa = '/auth/login/2fa';
  static const logout = '/auth/logout';
  static const me = '/auth/me';
  static const otpEmail = '/auth/otp/email';
  static const otpWhatsapp = '/auth/otp/whatsapp';
  static const otpVerify = '/auth/otp/verify';

  // Dashboard
  static const dashboardKpi = '/dashboard/kpi';
  static const dashboardSalesChart = '/dashboard/charts/sales';
  static const dashboardProducts = '/dashboard/charts/products';
  static const dashboardLiveFeed = '/dashboard/live-feed';
  static const dashboardOutlets = '/dashboard/outlets';

  // POS
  static const posCatalogProducts = '/pos/catalog/products';
  static const posCatalogCategories = '/pos/catalog/categories';
  static const posPaymentMethods = '/pos/catalog/payment-methods';
  static const posShiftCurrent = '/pos/shifts/current';
  static const posShiftOpen = '/pos/shifts/open';
  static const posShiftClose = '/pos/shifts';
  static const posTransactions = '/pos/transactions';
  static const posHeld = '/pos/held';

  // Inventory
  static const inventoryProducts = '/inventory/products';
  static const inventoryProductBarcode = '/inventory/products/barcode';
  static const inventoryStocks = '/inventory/stocks';
  static const inventoryStockAlerts = '/inventory/stocks/alerts';
  static const inventoryWarehouses = '/inventory/stocks/warehouses';
  static const inventoryStockIn = '/inventory/stocks/in';
  static const inventoryStockOut = '/inventory/stocks/out';
  static const inventoryStockAdjustment = '/inventory/stocks/adjustment';
  static const inventoryCategories = '/inventory/categories';

  static String inventoryGenerateBarcode(String productIdOrUuid) =>
      '/inventory/products/$productIdOrUuid/generate-barcode';

  // Members
  static const members = '/members';
  static const membersTiers = '/members/tiers';

  // Wallet
  static const wallet = '/wallet';

  // Reservations
  static const reservations = '/reservations';
  static const reservationSlots = '/reservations/slots';

  // Table service (QR staff)
  static const tableServiceRequests = '/table-service-requests';

  static String tableServiceRequestAcknowledge(String uuid) =>
      '/table-service-requests/$uuid/acknowledge';

  // Loyalty tiers
  static String loyaltyTier(int id) => '/loyalty/tiers/$id';

  // Public QR Menu
  static const publicOrders = '/public/orders';

  static String publicMenu(String tenantSlug, String outletSlug) =>
      '/public/menu/$tenantSlug/$outletSlug';

  static String publicMenuTable(
    String tenantSlug,
    String outletSlug,
    String token,
  ) =>
      '/public/menu/$tenantSlug/$outletSlug/table/$token';

  static String publicOrderTrack(String uuid) => '/public/orders/$uuid/track';
  static const publicCallWaiter = '/public/call-waiter';
  static const publicRequestBill = '/public/request-bill';

  // Delivery
  static const deliveryOrders = '/delivery/orders';
  static const deliveryDrivers = '/delivery/drivers';

  static String deliveryAssign(String orderUuid) =>
      '/delivery/orders/$orderUuid/assign';

  // CRM
  static const crmTickets = '/crm/tickets';
  static const crmFaqs = '/crm/faqs';

  // Notifications
  static const notifications = '/notifications';
  static const notificationsUnread = '/notifications/unread-count';
  static const notificationsReadAll = '/notifications/read-all';
  static const fcmToken = '/devices/fcm-token';

  // Settings
  static const settingsTenant = '/settings/tenant';
  static const settingsOutlets = '/settings/outlets';
  static const settingsSubscription = '/settings/subscription';

  // Wallet
  static String walletMember(String memberUuid) => '/wallet/$memberUuid';
  static String walletTransactions(String memberUuid) =>
      '/wallet/$memberUuid/transactions';
}