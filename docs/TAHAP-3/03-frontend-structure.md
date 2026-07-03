# TAHAP 3 — Frontend Structure (Next.js 15)

## Project Root

```
frontend/
├── app/                              # Next.js App Router
├── components/                       # React components
├── lib/                              # Utilities, API client, hooks
├── stores/                           # Zustand stores
├── types/                            # TypeScript types
├── public/                           # Static assets
├── styles/                           # Global styles
├── middleware.ts                     # Auth & tenant middleware
├── next.config.ts
├── tailwind.config.ts
├── tsconfig.json
└── package.json
```

---

## App Router Structure

```
app/
├── layout.tsx                        # Root layout (providers)
├── page.tsx                          # Landing page
├── globals.css
│
├── (auth)/                           # Auth group (no sidebar)
│   ├── layout.tsx
│   ├── login/
│   │   └── page.tsx
│   ├── register/
│   │   └── page.tsx
│   ├── forgot-password/
│   │   └── page.tsx
│   ├── reset-password/
│   │   └── [token]/page.tsx
│   ├── verify-email/
│   │   └── page.tsx
│   └── two-factor/
│       └── page.tsx
│
├── (dashboard)/                      # Main dashboard (sidebar layout)
│   ├── layout.tsx                    # Sidebar + header
│   ├── dashboard/
│   │   └── page.tsx                  # KPI dashboard
│   ├── inventory/
│   │   ├── page.tsx                  # Product list
│   │   ├── products/
│   │   │   ├── page.tsx
│   │   │   ├── create/page.tsx
│   │   │   └── [id]/
│   │   │       ├── page.tsx          # Edit product
│   │   │       └── variants/page.tsx
│   │   ├── categories/page.tsx
│   │   ├── stock/
│   │   │   ├── page.tsx
│   │   │   ├── transfer/page.tsx
│   │   │   ├── adjustment/page.tsx
│   │   │   └── opname/page.tsx
│   │   ├── suppliers/page.tsx
│   │   └── purchase-orders/
│   │       ├── page.tsx
│   │       └── [id]/page.tsx
│   ├── members/
│   │   ├── page.tsx
│   │   ├── [id]/page.tsx
│   │   ├── tiers/page.tsx
│   │   └── rewards/page.tsx
│   ├── reservations/
│   │   ├── page.tsx
│   │   └── calendar/page.tsx
│   ├── delivery/
│   │   ├── page.tsx
│   │   ├── [id]/page.tsx
│   │   ├── drivers/page.tsx
│   │   └── zones/page.tsx
│   ├── crm/
│   │   ├── tickets/
│   │   │   ├── page.tsx
│   │   │   └── [id]/page.tsx
│   │   └── knowledge-base/page.tsx
│   ├── reports/
│   │   ├── page.tsx
│   │   ├── sales/page.tsx
│   │   ├── inventory/page.tsx
│   │   ├── profit-loss/page.tsx
│   │   └── cash-flow/page.tsx
│   └── settings/
│       ├── page.tsx
│       ├── outlets/page.tsx
│       ├── users/page.tsx
│       ├── roles/page.tsx
│       ├── payments/page.tsx
│       ├── printers/page.tsx
│       ├── integrations/page.tsx
│       └── receipt/page.tsx
│
├── (pos)/                            # POS fullscreen layout
│   ├── layout.tsx                    # Minimal chrome, touch-optimized
│   └── pos/
│       ├── page.tsx                  # Main POS screen
│       ├── shifts/
│       │   ├── open/page.tsx
│       │   └── close/page.tsx
│       ├── held/page.tsx             # Held transactions
│       └── history/page.tsx          # Transaction history
│
├── (kitchen)/                        # Kitchen Display fullscreen
│   ├── layout.tsx
│   └── kitchen/
│       └── page.tsx                  # KDS screen
│
├── (menu)/                           # Public QR Digital Menu
│   ├── layout.tsx                    # Tenant-branded, no auth required
│   └── [tenantSlug]/
│       └── [outletSlug]/
│           ├── page.tsx              # Menu browse
│           ├── table/
│           │   └── [tableToken]/
│           │       ├── page.tsx      # Table menu
│           │       ├── cart/page.tsx
│           │       └── track/page.tsx
│           └── checkout/page.tsx
│
├── (platform)/                       # Super Admin panel
│   ├── layout.tsx
│   └── platform/
│       ├── page.tsx                  # Platform dashboard
│       ├── tenants/
│       │   ├── page.tsx
│       │   └── [id]/page.tsx
│       ├── packages/page.tsx
│       ├── subscriptions/page.tsx
│       └── billing/page.tsx
│
├── (setup)/                          # Onboarding wizard
│   ├── layout.tsx
│   └── setup/
│       ├── page.tsx                  # Step 1: Profile
│       ├── outlet/page.tsx           # Step 2: Outlet
│       ├── products/page.tsx         # Step 3: Products
│       └── complete/page.tsx         # Step 4: Done
│
└── api/                              # Next.js API routes (BFF proxy, optional)
    └── auth/
        └── [...nextauth]/route.ts
```

---

## Components Structure

```
components/
├── ui/                               # ShadCN UI primitives
│   ├── button.tsx
│   ├── input.tsx
│   ├── dialog.tsx
│   ├── table.tsx
│   ├── card.tsx
│   ├── badge.tsx
│   ├── dropdown-menu.tsx
│   ├── select.tsx
│   ├── tabs.tsx
│   ├── toast.tsx
│   ├── calendar.tsx
│   ├── chart.tsx
│   └── ...
│
├── layout/
│   ├── sidebar.tsx
│   ├── header.tsx
│   ├── breadcrumb.tsx
│   ├── tenant-switcher.tsx
│   ├── outlet-selector.tsx
│   └── notification-bell.tsx
│
├── dashboard/
│   ├── kpi-card.tsx
│   ├── sales-chart.tsx
│   ├── revenue-trend.tsx
│   ├── outlet-performance.tsx
│   ├── stock-alerts.tsx
│   ├── recent-transactions.tsx
│   └── live-feed.tsx
│
├── pos/
│   ├── product-grid.tsx
│   ├── cart-panel.tsx
│   ├── payment-modal.tsx
│   ├── discount-modal.tsx
│   ├── member-scanner.tsx
│   ├── barcode-scanner.tsx
│   ├── numpad.tsx
│   ├── receipt-preview.tsx
│   ├── split-bill-dialog.tsx
│   ├── held-transactions.tsx
│   └── shift-summary.tsx
│
├── inventory/
│   ├── product-form.tsx
│   ├── variant-manager.tsx
│   ├── stock-table.tsx
│   ├── barcode-generator.tsx
│   ├── po-form.tsx
│   └── opname-checklist.tsx
│
├── kitchen/
│   ├── order-card.tsx
│   ├── order-queue.tsx
│   ├── station-filter.tsx
│   ├── order-timer.tsx
│   └── bump-button.tsx
│
├── menu/                             # QR Digital Menu components
│   ├── menu-header.tsx
│   ├── category-tabs.tsx
│   ├── product-card.tsx
│   ├── cart-drawer.tsx
│   ├── order-tracker.tsx
│   └── call-waiter-button.tsx
│
├── members/
│   ├── member-form.tsx
│   ├── member-card.tsx
│   ├── point-history.tsx
│   └── tier-badge.tsx
│
├── delivery/
│   ├── delivery-map.tsx
│   ├── driver-card.tsx
│   ├── tracking-timeline.tsx
│   └── zone-editor.tsx
│
├── crm/
│   ├── ticket-list.tsx
│   ├── ticket-detail.tsx
│   ├── message-thread.tsx
│   ├── sla-timer.tsx
│   └── csat-rating.tsx
│
├── reports/
│   ├── report-filters.tsx
│   ├── export-button.tsx
│   └── report-table.tsx
│
└── shared/
    ├── data-table.tsx                # Reusable data table
    ├── search-input.tsx
    ├── date-range-picker.tsx
    ├── confirm-dialog.tsx
    ├── loading-spinner.tsx
    ├── empty-state.tsx
    ├── error-boundary.tsx
    ├── permission-gate.tsx
    └── feature-gate.tsx
```

---

## Lib / Utilities

```
lib/
├── api/
│   ├── client.ts                     # Axios instance + interceptors
│   ├── auth.ts                       # Auth API calls
│   ├── products.ts
│   ├── transactions.ts
│   ├── members.ts
│   ├── orders.ts
│   ├── reports.ts
│   └── index.ts                      # Barrel export
│
├── hooks/
│   ├── use-auth.ts
│   ├── use-tenant.ts
│   ├── use-permissions.ts
│   ├── use-outlet.ts
│   ├── use-websocket.ts
│   ├── use-debounce.ts
│   ├── use-barcode-scanner.ts
│   └── use-media-query.ts
│
├── utils/
│   ├── cn.ts                         # Tailwind class merge
│   ├── format.ts                     # Currency, date formatting
│   ├── validation.ts
│   └── permissions.ts
│
├── websocket/
│   ├── echo.ts                       # Laravel Echo setup
│   └── channels.ts                   # Channel subscriptions
│
└── constants/
    ├── routes.ts
    ├── permissions.ts
    └── config.ts
```

---

## Zustand Stores

```
stores/
├── auth-store.ts                     # User, token, permissions
├── tenant-store.ts                   # Current tenant, settings
├── outlet-store.ts                   # Selected outlet
├── pos-store.ts                      # Cart, held transactions
├── cart-store.ts                     # QR menu cart
├── ui-store.ts                       # Sidebar, theme, modals
└── notification-store.ts             # In-app notifications
```

### Example: POS Store

```typescript
interface POSState {
  cart: CartItem[];
  member: Member | null;
  discounts: Discount[];
  table: Table | null;
  addItem: (product: Product, qty: number) => void;
  removeItem: (itemId: string) => void;
  applyDiscount: (discount: Discount) => void;
  clearCart: () => void;
  holdTransaction: (name: string) => void;
}
```

---

## TypeScript Types

```
types/
├── api.ts                            # API response wrappers
├── auth.ts                           # User, Role, Permission
├── tenant.ts                         # Tenant, Outlet, Settings
├── product.ts                        # Product, Variant, Category
├── transaction.ts                    # SaleTransaction, Payment
├── member.ts                         # Member, Points, Tier
├── order.ts                          # Order, OrderItem, KDS
├── reservation.ts
├── delivery.ts
├── ticket.ts                         # CRM Ticket
├── report.ts
└── common.ts                         # Pagination, Filter, Sort
```

---

## Middleware (Next.js)

```typescript
// middleware.ts
export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Public routes (no auth)
  if (pathname.startsWith('/login') || pathname.startsWith('/register')
      || pathname.startsWith('/menu/')) {
    return NextResponse.next();
  }

  // Check auth token
  const token = request.cookies.get('auth_token');
  if (!token) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  // Platform routes require super admin
  if (pathname.startsWith('/platform/')) {
    // Check super admin role
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|api).*)'],
};
```

---

## Key Dependencies

```json
{
  "dependencies": {
    "next": "^15.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "typescript": "^5.0.0",
    "@tanstack/react-query": "^5.0.0",
    "zustand": "^5.0.0",
    "axios": "^1.7.0",
    "laravel-echo": "^1.16.0",
    "pusher-js": "^8.0.0",
    "recharts": "^2.0.0",
    "date-fns": "^4.0.0",
    "zod": "^3.0.0",
    "react-hook-form": "^7.0.0",
    "@hookform/resolvers": "^3.0.0",
    "lucide-react": "^0.400.0",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.0.0",
    "tailwind-merge": "^2.0.0",
    "sonner": "^1.0.0",
    "next-pwa": "^5.6.0"
  },
  "devDependencies": {
    "tailwindcss": "^4.0.0",
    "@types/react": "^19.0.0",
    "eslint": "^9.0.0",
    "prettier": "^3.0.0"
  }
}
```

---

## Layout Strategy

| Layout Group | Chrome | Target Device |
|-------------|--------|---------------|
| `(auth)` | Minimal (logo + form) | Desktop, mobile |
| `(dashboard)` | Sidebar + header | Desktop, tablet |
| `(pos)` | Top bar only, fullscreen | Tablet (touch) |
| `(kitchen)` | None, fullscreen | Large display/TV |
| `(menu)` | Tenant-branded header | Mobile (customer) |
| `(platform)` | Admin sidebar | Desktop |

---

## PWA Configuration

```typescript
// next.config.ts
const withPWA = require('next-pwa')({
  dest: 'public',
  register: true,
  skipWaiting: true,
  runtimeCaching: [
    { urlPattern: /\/api\/v1\/public\//, handler: 'NetworkFirst' },
    { urlPattern: /\/_next\/static\//, handler: 'CacheFirst' },
  ],
});
```