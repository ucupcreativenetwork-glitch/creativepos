<?php

namespace App\Modules\Delivery\Repositories;

use App\Modules\Delivery\Models\DeliveryOrder;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class DeliveryOrderRepository
{
    public function paginate(
        ?int $outletId = null,
        ?string $status = null,
        ?int $driverId = null,
        int $perPage = 15,
    ): LengthAwarePaginator {
        $query = DeliveryOrder::query()
            ->with([
                'outlet:id,name,code',
                'driver:id,uuid,user_id,vehicle_type,vehicle_plate',
                'driver.user:id,name,phone',
                'items',
            ])
            ->orderByDesc('created_at');

        if ($outletId) {
            $query->where('outlet_id', $outletId);
        }

        if ($status) {
            $query->where('status', $status);
        }

        if ($driverId) {
            $query->where('driver_id', $driverId);
        }

        return $query->paginate($perPage);
    }

    public function findByUuid(string $uuid): ?DeliveryOrder
    {
        return DeliveryOrder::query()
            ->with([
                'outlet',
                'driver.user',
                'member',
                'zone.rates',
                'items',
                'trackingPoints' => fn ($q) => $q->orderByDesc('recorded_at')->limit(20),
            ])
            ->where('uuid', $uuid)
            ->first();
    }

    public function create(array $data): DeliveryOrder
    {
        return DeliveryOrder::query()->create($data);
    }

    public function update(DeliveryOrder $order, array $data): DeliveryOrder
    {
        $order->update($data);

        return $order->fresh();
    }

    public function countToday(): int
    {
        return DeliveryOrder::query()->whereDate('created_at', today())->count();
    }
}