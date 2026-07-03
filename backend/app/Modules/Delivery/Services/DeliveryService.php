<?php

namespace App\Modules\Delivery\Services;

use App\Models\User;
use App\Modules\Delivery\Models\DeliveryOrder;
use App\Modules\Delivery\Models\DeliveryOrderItem;
use App\Modules\Delivery\Models\DeliveryTrackingPoint;
use App\Modules\Delivery\Repositories\DeliveryDriverRepository;
use App\Modules\Delivery\Repositories\DeliveryOrderRepository;
use App\Modules\Inventory\Models\Product;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class DeliveryService
{
    public function __construct(
        private readonly DeliveryOrderRepository $repository,
        private readonly DeliveryDriverRepository $driverRepository,
        private readonly DeliveryFeeService $feeService,
    ) {}

    public function list(
        ?int $outletId = null,
        ?string $status = null,
        ?int $driverId = null,
        int $perPage = 15,
    ): LengthAwarePaginator {
        return $this->repository->paginate($outletId, $status, $driverId, $perPage);
    }

    public function findByUuid(string $uuid): DeliveryOrder
    {
        $order = $this->repository->findByUuid($uuid);

        if (! $order) {
            abort(404, 'Pesanan delivery tidak ditemukan.');
        }

        return $order;
    }

    public function create(array $data, ?User $user = null): DeliveryOrder
    {
        return DB::transaction(function () use ($data) {
            $items = $this->buildItems($data['items']);
            $subtotal = collect($items)->sum('subtotal');

            $shippingFee = (float) ($data['shipping_fee'] ?? 0);
            $distanceKm = isset($data['distance_km']) ? (float) $data['distance_km'] : null;

            if (isset($data['delivery_zone_id'], $data['distance_km']) && ! isset($data['shipping_fee'])) {
                $fee = $this->feeService->calculate((int) $data['delivery_zone_id'], $distanceKm);
                $shippingFee = $fee['shipping_fee'];
                $data['estimated_minutes'] = $data['estimated_minutes'] ?? $fee['estimated_minutes'];
            }

            $count = $this->repository->countToday();
            $order = $this->repository->create([
                'tenant_id' => tenant('id'),
                'delivery_number' => 'DLV-'.now()->format('Ymd').'-'.str_pad((string) ($count + 1), 4, '0', STR_PAD_LEFT),
                'outlet_id' => $data['outlet_id'],
                'member_id' => $data['member_id'] ?? null,
                'delivery_zone_id' => $data['delivery_zone_id'] ?? null,
                'customer_name' => $data['customer_name'],
                'customer_phone' => $data['customer_phone'],
                'delivery_address' => $data['delivery_address'],
                'delivery_city' => $data['delivery_city'] ?? null,
                'delivery_notes' => $data['delivery_notes'] ?? null,
                'status' => 'waiting',
                'subtotal' => $subtotal,
                'shipping_fee' => $shippingFee,
                'total_amount' => round($subtotal + $shippingFee, 2),
                'distance_km' => $distanceKm,
                'estimated_minutes' => $data['estimated_minutes'] ?? null,
            ]);

            foreach ($items as $item) {
                DeliveryOrderItem::query()->create([
                    'tenant_id' => tenant('id'),
                    'delivery_order_id' => $order->id,
                    ...$item,
                ]);
            }

            return $this->repository->findByUuid($order->uuid);
        });
    }

    public function updateStatus(
        DeliveryOrder $order,
        string $status,
        ?User $user = null,
        ?string $notes = null,
    ): DeliveryOrder {
        $allowed = ['waiting', 'processing', 'cooking', 'ready', 'delivering', 'completed', 'cancelled'];

        if (! in_array($status, $allowed, true)) {
            abort(422, 'Status tidak valid.');
        }

        return DB::transaction(function () use ($order, $status) {
            $extra = ['status' => $status];

            if ($status === 'delivering' && ! $order->picked_up_at) {
                $extra['picked_up_at'] = now();
            }

            if ($status === 'completed' && ! $order->delivered_at) {
                $extra['delivered_at'] = now();
            }

            if ($status === 'completed' && $order->driver_id) {
                $this->driverRepository->findById($order->driver_id)?->update(['is_available' => true]);
            }

            $this->repository->update($order, $extra);

            return $this->repository->findByUuid($order->uuid);
        });
    }

    public function assignDriver(DeliveryOrder $order, int $driverId): DeliveryOrder
    {
        return DB::transaction(function () use ($order, $driverId) {
            $driver = $this->driverRepository->findById($driverId);

            if (! $driver || ! $driver->is_active) {
                abort(422, 'Driver tidak tersedia.');
            }

            if (! $driver->is_available) {
                abort(422, 'Driver sedang sibuk.');
            }

            $this->repository->update($order, [
                'driver_id' => $driver->id,
                'assigned_at' => now(),
                'status' => $order->status === 'waiting' ? 'processing' : $order->status,
            ]);

            $driver->update(['is_available' => false]);

            return $this->repository->findByUuid($order->uuid);
        });
    }

    public function recordLocation(DeliveryOrder $order, float $latitude, float $longitude, ?int $driverId = null): DeliveryOrder
    {
        DeliveryTrackingPoint::query()->create([
            'delivery_order_id' => $order->id,
            'driver_id' => $driverId ?? $order->driver_id,
            'latitude' => $latitude,
            'longitude' => $longitude,
            'recorded_at' => now(),
        ]);

        return $this->repository->findByUuid($order->uuid);
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
            ];
        }

        return $built;
    }
}