<?php

namespace App\Modules\Order\Services;

use App\Models\User;
use App\Modules\Inventory\Models\Product;
use App\Modules\Order\Models\Order;
use App\Modules\Order\Models\OrderItem;
use App\Modules\Order\Models\OrderStatusHistory;
use App\Modules\Notification\Events\OrderCreatedEvent;
use App\Modules\Order\Repositories\OrderRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;

class OrderService
{
    public function __construct(
        private readonly OrderRepository $repository,
    ) {}

    public function list(
        ?int $outletId = null,
        ?string $status = null,
        ?string $source = null,
        int $perPage = 15,
    ): LengthAwarePaginator {
        return $this->repository->paginate($outletId, $status, $source, $perPage);
    }

    public function findByUuid(string $uuid): Order
    {
        $order = $this->repository->findByUuid($uuid);

        if (! $order) {
            abort(404, 'Pesanan tidak ditemukan.');
        }

        return $order;
    }

    public function create(array $data, ?User $user = null): Order
    {
        return DB::transaction(function () use ($data, $user) {
            $items = $this->buildItems($data['items']);
            $subtotal = collect($items)->sum('subtotal');

            $count = $this->repository->countToday();
            $order = $this->repository->create([
                'tenant_id' => tenant('id'),
                'order_number' => 'ORD-'.now()->format('Ymd').'-'.str_pad((string) ($count + 1), 4, '0', STR_PAD_LEFT),
                'outlet_id' => $data['outlet_id'],
                'table_id' => $data['table_id'] ?? null,
                'member_id' => $data['member_id'] ?? null,
                'source' => $data['source'] ?? 'pos',
                'order_type' => $data['order_type'] ?? 'dine_in',
                'status' => 'pending',
                'subtotal' => $subtotal,
                'notes' => $data['notes'] ?? null,
            ]);

            foreach ($items as $item) {
                OrderItem::query()->create([
                    'tenant_id' => tenant('id'),
                    'order_id' => $order->id,
                    ...$item,
                ]);
            }

            $this->recordStatus($order, null, 'pending', $user?->id, 'Pesanan dibuat');

            if ($order->table_id) {
                \App\Modules\Order\Models\Table::query()
                    ->where('id', $order->table_id)
                    ->update(['status' => 'occupied']);
            }

            $created = $this->repository->findByUuid($order->uuid);
            Event::dispatch(new OrderCreatedEvent($created));

            return $created;
        });
    }

    public function updateStatus(Order $order, string $status, ?User $user = null, ?string $notes = null): Order
    {
        $allowed = ['pending', 'cooking', 'ready', 'served', 'completed', 'cancelled'];

        if (! in_array($status, $allowed, true)) {
            abort(422, 'Status tidak valid.');
        }

        $from = $order->status;
        $this->repository->update($order, ['status' => $status]);
        $this->recordStatus($order, $from, $status, $user?->id, $notes);

        if (in_array($status, ['completed', 'cancelled'], true) && $order->table_id) {
            \App\Modules\Order\Models\Table::query()
                ->where('id', $order->table_id)
                ->update(['status' => 'available']);
        }

        return $this->repository->findByUuid($order->uuid);
    }

    public function bump(Order $order, ?User $user = null): Order
    {
        $next = match ($order->status) {
            'pending' => 'cooking',
            'cooking' => 'ready',
            'ready' => 'served',
            default => abort(422, 'Pesanan tidak dapat di-bump.'),
        };

        return $this->updateStatus($order, $next, $user, 'KDS bump');
    }

    protected function buildItems(array $rawItems): array
    {
        if ($rawItems === []) {
            abort(422, 'Minimal satu item diperlukan.');
        }

        $built = [];

        foreach ($rawItems as $raw) {
            $product = Product::query()
                ->where('id', $raw['product_id'])
                ->where('is_active', true)
                ->first();

            if (! $product) {
                abort(422, 'Produk tidak ditemukan.');
            }

            $qty = (float) ($raw['quantity'] ?? 1);
            $unitPrice = (float) $product->base_price;

            $built[] = [
                'product_id' => $product->id,
                'product_name' => $product->name,
                'quantity' => $qty,
                'unit_price' => $unitPrice,
                'subtotal' => round($unitPrice * $qty, 2),
                'notes' => $raw['notes'] ?? null,
                'status' => 'pending',
            ];
        }

        return $built;
    }

    protected function recordStatus(
        Order $order,
        ?string $from,
        string $to,
        ?int $userId,
        ?string $notes,
    ): void {
        OrderStatusHistory::query()->create([
            'order_id' => $order->id,
            'from_status' => $from,
            'to_status' => $to,
            'changed_by' => $userId,
            'notes' => $notes,
            'created_at' => now(),
        ]);
    }
}