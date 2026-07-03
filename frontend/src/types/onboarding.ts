export type OnboardingStepId =
  | "profile"
  | "outlet"
  | "product"
  | "payment"
  | "staff";

export type StaffRole = "cashier" | "manager";

export type BusinessType = "restoran" | "kafe" | "retail" | "lainnya";

export interface OnboardingStatus {
  setup_completed: boolean;
  completed_steps: OnboardingStepId[];
  skipped_steps: OnboardingStepId[];
  current_step: number;
  has_outlet: boolean;
  has_product: boolean;
  has_payment_methods: boolean;
  has_staff_invite: boolean;
}

export interface OnboardingLocalProgress {
  currentStep: number;
  profile: ProfileStepData;
  outlet: OutletStepData;
  product: ProductStepData;
  payment: PaymentStepData;
  staff: StaffStepData;
  skippedSteps: OnboardingStepId[];
}

export interface ProfileStepData {
  business_name: string;
  business_type: BusinessType | "";
  logo_url: string;
  address: string;
  phone: string;
}

export interface OutletStepData {
  outlet_id: number | null;
  outlet_uuid: string | null;
  name: string;
  code: string;
  timezone: string;
  feature_reservations: boolean;
  feature_delivery: boolean;
  feature_qr_menu: boolean;
}

export interface ProductStepData {
  name: string;
  base_price: string;
  category_name: string;
  image_url: string;
}

export interface PaymentStepData {
  selected: string[];
}

export interface StaffStepData {
  email: string;
  name: string;
  role: StaffRole;
}

export const ONBOARDING_STEPS: { id: OnboardingStepId; label: string }[] = [
  { id: "profile", label: "Profil Bisnis" },
  { id: "outlet", label: "Outlet Pertama" },
  { id: "product", label: "Produk Pertama" },
  { id: "payment", label: "Metode Pembayaran" },
  { id: "staff", label: "Undang Staff" },
];

export const PAYMENT_METHOD_OPTIONS = [
  { code: "cash", label: "Cash" },
  { code: "transfer_bca", label: "Transfer BCA" },
  { code: "transfer_bni", label: "Transfer BNI" },
  { code: "transfer_bri", label: "Transfer BRI" },
  { code: "gopay", label: "GoPay" },
  { code: "ovo", label: "OVO" },
  { code: "qris", label: "QRIS" },
] as const;

export const TIMEZONE_OPTIONS = [
  { value: "Asia/Jakarta", label: "WIB — Asia/Jakarta" },
  { value: "Asia/Makassar", label: "WITA — Asia/Makassar" },
  { value: "Asia/Jayapura", label: "WIT — Asia/Jayapura" },
] as const;

export const BUSINESS_TYPE_OPTIONS = [
  { value: "restoran", label: "Restoran" },
  { value: "kafe", label: "Kafe" },
  { value: "retail", label: "Retail" },
  { value: "lainnya", label: "Lainnya" },
] as const;