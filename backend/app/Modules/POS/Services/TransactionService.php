<?php

namespace App\Modules\POS\Services;

use App\Models\User;
use App\Modules\Inventory\Models\Product;
use App\Modules\Inventory\Models\ProductModifier;
use App\Modules\Inventory\Repositories\StockRepository;
use App\Modules\Inventory\Services\RecipeService;
use App\Modules\Loyalty\Models\Member;
use App\Modules\Loyalty\Services\MemberService;
use App\Modules\Loyalty\Services\PointService;
use App\Modules\POS\Models\PaymentMethod;
use App\Modules\POS\Models\SalePayment;
use App\Modules\POS\Models\SaleTransaction;
use App\Modules\POS\Models\SaleTransactionItem;
use App\Modules\POS\Models\Shift;
use App\Modules\Tenant\Models\TenantSetting;
use App\Modules\Notification\Services\StockAlertService;
use App\Modules\Loyalty\Models\PointTransaction;
use App\Modules\POS\Repositories\TransactionRepository;
use App\Modules\Tenant\Models\TenantSetting;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class TransactionService
{
    public function __construct(
        private readonly TransactionRepository $repository,
        private readonly ShiftService $shiftService,
        private readonly StockRepository $stockRepository,
        private readonly MemberService $memberService,
        private readonly PointService $pointService,
        private readonly StockAlertService $stockAlertService,
        private readonly RecipeService $recipeService,
    ) {}

    public function list(
        ?int $outletId = null,
        ?string $status = null,
        ?string $search = null,
        int $perPage = 15,
    ): LengthAwarePaginator {
        return $this->repository->paginate($outletId, $status, $search, $perPage);
    }

    public function findByUuid(string $uuid): SaleTransaction
    {
        $transaction = $this->repository->findByUuid($uuid);

        if (! $transaction) {
            abort(404, 'Transaksi tidak ditemukan.');
        }

        return $transaction;
    }

    public function create(array $data, User $cashier): SaleTransaction
    {
        return DB::transaction(function () use ($data, $cashier) {
            $shift = $this->resolveShift($cashier, $data['outlet_id'], $data['shift_id'] ?? null);

            $items = $this->buildItems($data['items']);
            $subtotal = collect($items)->sum('subtotal');
            $discounts = $data['discounts'] ?? [];

            if (! empty($data['points_redeem'])) {
                if (empty($data['member_id'])) {
                    abort(422, 'Member wajib dipilih untuk redeem poin.');
                }

                $member = Member::query()->find($data['member_id']);

                if ($member === null) {
                    abort(422, 'Member tidak ditemukan.');
                }

                $redeemPreview = $this->pointService->previewRedeem($member, (int) $data['points_redeem']);
                $discounts[] = [
                    'type' => 'nominal',
                    'value' => $redeemPreview['discount_value'],
                    'name' => 'Redeem Poin',
                ];
            }

            $discountTotal = $this->calculateDiscount($subtotal, $discounts);
            $taxableBase = max(0, $subtotal - $discountTotal);
            $tenantSettings = TenantSetting::query()->where('tenant_id', tenant('id'))->first();
            $taxRate = (float) ($tenantSettings?->tax_rate ?? 0);
            $serviceRate = (float) ($tenantSettings?->service_charge_rate ?? 0);
            $taxTotal = round($taxableBase * $taxRate / 100, 2);
            $serviceCharge = round($taxableBase * $serviceRate / 100, 2);
            $grandTotal = max(0, $taxableBase + $taxTotal + $serviceCharge);

            $payments = $this->validatePayments($data['payments'], $grandTotal);

            $txCount = $this->repository->countTodayTransactions();
            $transaction = $this->repository->create([
                'tenant_id' => tenant('id'),
                'transaction_number' => 'TRX-'.now()->format('Ymd').'-'.str_pad((string) ($txCount + 1), 4, '0', STR_PAD_LEFT),
                'outlet_id' => $data['outlet_id'],
                'cashier_id' => $cashier->id,
                'shift_id' => $shift?->id,
                'member_id' => $data['member_id'] ?? null,
                'order_type' => $data['order_type'] ?? 'quick_sale',
                'status' => 'completed',
                'subtotal' => $subtotal,
                'discount_total' => $discountTotal,
                'tax_total' => $taxTotal,
                'service_charge' => $serviceCharge,
                'grand_total' => $grandTotal,
                'notes' => $data['notes'] ?? null,
                'completed_at' => now(),
            ]);

            foreach ($items as $item) {
                SaleTransactionItem::query()->create([
                    'tenant_id' => tenant('id'),
                    'transaction_id' => $transaction->id,
                    ...$item,
                ]);

                $this->deductStock($item['product_id'], (float) $item['quantity'], $transaction->id, $cashier->id);
                $this->recipeService->consumeForSale($item['product_id'], (float) $item['quantity']);
            }

            foreach ($payments as $payment) {
                SalePayment::query()->create([
                    'tenant_id' => tenant('id'),
                    'transaction_id' => $transaction->id,
                    ...$payment,
                    'status' => 'completed',
                    'paid_at' => now(),
                ]);
            }

            if ($shift) {
                $this->shiftService->incrementTotals($shift, $grandTotal);
            }

            if (! empty($data['member_id'])) {
                $member = Member::query()->with('tier')->find($data['member_id']);

                if ($member === null) {
                    abort(422, 'Member tidak ditemukan.');
                }

                if ($member->status !== 'active') {
                    abort(422, 'Member tidak aktif.');
                }

                if (! empty($data['points_redeem'])) {
                    $this->pointService->redeem(
                        $member,
                        (int) $data['points_redeem'],
                        "Redeem poin — {$transaction->transaction_number}",
                    );
                }

                $this->memberService->recordVisit($member, $grandTotal);
                $this->pointService->earnFromPurchase($member, $grandTotal, $transaction->id);
            }

            return $this->repository->findByUuid($transaction->uuid);
        });
    }

    public function void(SaleTransaction $transaction, User $user, ?string $reason = null): SaleTransaction
    {
        if ($transaction->status !== 'completed') {
            abort(422, 'Hanya transaksi selesai yang dapat dibatalkan.');
        }

        return DB::transaction(function () use ($transaction, $user, $reason) {
            foreach ($transaction->items as $item) {
                $this->restoreStock($item->product_id, (float) $item->quantity, $transaction->id, $user->id);
                $this->recipeService->restoreForVoid($item->product_id, (float) $item->quantity);
            }

            $this->repository->update($transaction, [
                'status' => 'voided',
                'notes' => trim(($transaction->notes ?? '').' [VOID: '.($reason ?? 'Tanpa alasan').']'),
            ]);

            if ($transaction->member_id) {
                $this->reverseMemberEffects($transaction);
            }

            return $this->repository->findByUuid($transaction->uuid);
        });
    }

    public function getReceipt(SaleTransaction $transaction): array
    {
        $transaction->load([
            'outlet:id,name,code,address',
            'cashier:id,name',
            'items',
            'payments.paymentMethod:id,name,code',
        ]);

        $tenantSettings = TenantSetting::query()
            ->where('tenant_id', $transaction->tenant_id)
            ->first();

        $receiptWifi = null;
        if (
            $tenantSettings?->receipt_show_wifi
            && filled($tenantSettings->wifi_ssid)
            && filled($tenantSettings->wifi_password)
        ) {
            $receiptWifi = [
                'ssid' => $tenantSettings->wifi_ssid,
                'password' => $tenantSettings->wifi_password,
            ];
        }

        return [
            'transaction_number' => $transaction->transaction_number,
            'outlet' => $transaction->outlet,
            'cashier' => $transaction->cashier,
            'order_type' => $transaction->order_type,
            'status' => $transaction->status,
            'items' => $transaction->items->map(fn ($item) => [
                'product_name' => $item->product_name,
                'sku' => $item->sku,
                'quantity' => (float) $item->quantity,
                'unit_price' => (float) $item->unit_price,
                'modifiers' => $item->modifiers ?? [],
                'modifier_price_adjustment' => (float) ($item->modifier_price_adjustment ?? 0),
                'subtotal' => (float) $item->subtotal,
            ]),
            'payments' => $transaction->payments,
            'subtotal' => (float) $transaction->subtotal,
            'discount_total' => (float) $transaction->discount_total,
            'tax_total' => (float) $transaction->tax_total,
            'service_charge' => (float) $transaction->service_charge,
            'grand_total' => (float) $transaction->grand_total,
            'completed_at' => $transaction->completed_at?->toIso8601String(),
            'wifi' => $receiptWifi,
        ];
    }

    protected function resolveShift(User $cashier, int $outletId, ?int $shiftId): Shift
    {
        if ($shiftId) {
            $shift = Shift::query()->find($shiftId);

            if (! $shift || $shift->status !== 'open') {
                abort(422, 'Shift tidak valid atau sudah ditutup.');
            }

            if ($shift->outlet_id !== $outletId) {
                abort(422, 'Shift tidak sesuai dengan outlet transaksi.');
            }

            if ($shift->cashier_id !== $cashier->id && ! $cashier->is_super_admin) {
                abort(403, 'Shift bukan milik kasir ini.');
            }

            return $shift;
        }

        $shift = $this->shiftService->getCurrent($cashier, $outletId);

        if ($shift === null) {
            abort(422, 'Tidak ada shift aktif. Buka shift terlebih dahulu.');
        }

        return $shift;
    }

    protected function buildItems(array $rawItems): array
    {
        if ($rawItems === []) {
            abort(422, 'Minimal satu item diperlukan.');
        }

        $built = [];

        foreach ($rawItems as $raw) {
            $product = Product::query()
                ->with([
                    'modifierGroups' => fn ($q) => $q->orderBy('sort_order'),
                    'modifierGroups.modifiers' => fn ($q) => $q->where('is_active', true)->orderBy('sort_order'),
                ])
                ->where('id', $raw['product_id'])
                ->where('is_active', true)
                ->where('show_in_pos', true)
                ->first();

            if (! $product) {
                abort(422, 'Produk tidak ditemukan atau tidak tersedia di POS.');
            }

            $qty = (float) ($raw['quantity'] ?? 1);
            if ($qty <= 0) {
                abort(422, 'Jumlah item harus lebih dari 0.');
            }

            [$modifierSnapshot, $modifierAdjustment] = $this->resolveModifiers(
                $product,
                $raw['modifiers'] ?? [],
            );

            $unitPrice = round((float) $product->base_price + $modifierAdjustment, 2);
            $built[] = [
                'product_id' => $product->id,
                'product_name' => $product->name,
                'sku' => $product->sku,
                'quantity' => $qty,
                'unit_price' => $unitPrice,
                'modifiers' => $modifierSnapshot,
                'modifier_price_adjustment' => $modifierAdjustment,
                'subtotal' => round($unitPrice * $qty, 2),
            ];
        }

        return $built;
    }

    protected function resolveModifiers(Product $product, array $selectedModifierIds): array
    {
        $groups = $product->modifierGroups;
        $selectedIds = collect($selectedModifierIds)
            ->map(fn ($id) => (int) $id)
            ->unique()
            ->values();

        if ($groups->isEmpty()) {
            if ($selectedIds->isNotEmpty()) {
                abort(422, "Produk {$product->name} tidak memiliki modifier.");
            }

            return [[], 0.0];
        }

        $modifiersById = $groups
            ->flatMap(fn ($group) => $group->modifiers)
            ->keyBy('id');

        $selectedModifiers = collect();

        foreach ($selectedIds as $modifierId) {
            $modifier = $modifiersById->get($modifierId);

            if (! $modifier) {
                abort(422, "Modifier tidak valid untuk produk {$product->name}.");
            }

            $selectedModifiers->push($modifier);
        }

        foreach ($groups as $group) {
            $groupSelectionCount = $selectedModifiers
                ->where('group_id', $group->id)
                ->count();

            if ($group->is_required && $groupSelectionCount < max(1, $group->min_select)) {
                abort(422, "Pilihan {$group->name} wajib dipilih untuk {$product->name}.");
            }

            if ($groupSelectionCount < $group->min_select) {
                abort(422, "Minimal {$group->min_select} pilihan untuk {$group->name}.");
            }

            if ($groupSelectionCount > $group->max_select) {
                abort(422, "Maksimal {$group->max_select} pilihan untuk {$group->name}.");
            }
        }

        $groupNames = $groups->keyBy('id');

        $snapshot = $selectedModifiers
            ->sortBy(fn (ProductModifier $modifier) => $modifier->group_id.'-'.$modifier->sort_order)
            ->map(fn (ProductModifier $modifier) => [
                'modifier_id' => $modifier->id,
                'group_id' => $modifier->group_id,
                'group_name' => $groupNames[$modifier->group_id]->name,
                'name' => $modifier->name,
                'price_adjustment' => (float) $modifier->price_adjustment,
            ])
            ->values()
            ->all();

        $adjustment = round(
            collect($snapshot)->sum(fn (array $item) => $item['price_adjustment']),
            2,
        );

        return [$snapshot, $adjustment];
    }

    protected function calculateDiscount(float $subtotal, array $discounts): float
    {
        $total = 0;

        foreach ($discounts as $discount) {
            $type = $discount['type'] ?? 'nominal';
            $value = (float) ($discount['value'] ?? 0);

            if ($type === 'percentage') {
                $total += $subtotal * ($value / 100);
            } else {
                $total += $value;
            }
        }

        return min($total, $subtotal);
    }

    protected function validatePayments(array $payments, float $grandTotal): array
    {
        if ($payments === []) {
            abort(422, 'Minimal satu metode pembayaran diperlukan.');
        }

        $validated = [];
        $totalPaid = 0;

        foreach ($payments as $payment) {
            $method = PaymentMethod::query()
                ->where('id', $payment['payment_method_id'])
                ->where('is_active', true)
                ->first();

            if (! $method) {
                abort(422, 'Metode pembayaran tidak valid.');
            }

            if (! in_array($method->code, $this->enabledPaymentCodes(), true)) {
                abort(422, "Metode pembayaran {$method->name} tidak diaktifkan untuk bisnis ini.");
            }

            $amount = (float) $payment['amount'];
            if ($amount <= 0) {
                abort(422, 'Jumlah pembayaran harus lebih dari 0.');
            }

            $validated[] = [
                'payment_method_id' => $method->id,
                'amount' => $amount,
                'reference_number' => $payment['reference_number'] ?? null,
            ];

            $totalPaid += $amount;
        }

        if (abs($totalPaid - $grandTotal) > 0.01) {
            abort(422, 'Total pembayaran harus sama dengan grand total.');
        }

        return $validated;
    }

    protected function enabledPaymentCodes(): array
    {
        $settings = TenantSetting::query()->where('tenant_id', tenant('id'))->first();

        if ($settings && filled($settings->enabled_payment_methods)) {
            return $settings->enabled_payment_methods;
        }

        return ['cash'];
    }

    protected function reverseMemberEffects(SaleTransaction $transaction): void
    {
        $member = Member::query()->find($transaction->member_id);

        if (! $member) {
            return;
        }

        $earned = (int) PointTransaction::query()
            ->where('member_id', $member->id)
            ->where('reference_type', 'sale_transactions')
            ->where('reference_id', $transaction->id)
            ->where('type', 'earn')
            ->sum('points');

        if ($earned > 0) {
            $this->pointService->adjust(
                $member,
                -$earned,
                "Pembalikan poin — void transaksi {$transaction->transaction_number}",
            );
        }

        $member->decrement('visit_count');
        $member->decrement('total_spend', min((float) $member->total_spend, (float) $transaction->grand_total));
    }

    protected function deductStock(int $productId, float $quantity, int $transactionId, int $userId): void
    {
        $product = Product::query()->find($productId);

        if (! $product?->track_stock) {
            return;
        }

        $warehouse = $this->stockRepository->defaultWarehouse();

        if (! $warehouse) {
            abort(422, 'Gudang default tidak ditemukan. Konfigurasi gudang terlebih dahulu.');
        }

        $stock = $this->stockRepository->findOrCreateStock($productId, $warehouse->id);
        $before = (float) $stock->quantity;

        if ($quantity > $before) {
            abort(422, "Stok {$product->name} tidak mencukupi.");
        }

        $after = $before - $quantity;
        $this->stockRepository->updateStockQuantity($stock, $after);
        $this->stockRepository->recordMovement([
            'tenant_id' => tenant('id'),
            'product_id' => $productId,
            'warehouse_id' => $warehouse->id,
            'type' => 'sale',
            'quantity' => $quantity,
            'before_quantity' => $before,
            'after_quantity' => $after,
            'reference_type' => 'sale_transactions',
            'reference_id' => $transactionId,
            'created_by' => $userId,
            'created_at' => now(),
        ]);

        $this->stockAlertService->checkProductStock($productId, $warehouse->id);
    }

    protected function restoreStock(int $productId, float $quantity, int $transactionId, int $userId): void
    {
        $product = Product::query()->find($productId);

        if (! $product?->track_stock) {
            return;
        }

        $warehouse = $this->stockRepository->defaultWarehouse();

        if (! $warehouse) {
            return;
        }

        $stock = $this->stockRepository->findOrCreateStock($productId, $warehouse->id);
        $before = (float) $stock->quantity;
        $after = $before + $quantity;

        $this->stockRepository->updateStockQuantity($stock, $after);
        $this->stockRepository->recordMovement([
            'tenant_id' => tenant('id'),
            'product_id' => $productId,
            'warehouse_id' => $warehouse->id,
            'type' => 'return',
            'quantity' => $quantity,
            'before_quantity' => $before,
            'after_quantity' => $after,
            'reference_type' => 'sale_transactions',
            'reference_id' => $transactionId,
            'notes' => 'Void transaction',
            'created_by' => $userId,
            'created_at' => now(),
        ]);
    }
}