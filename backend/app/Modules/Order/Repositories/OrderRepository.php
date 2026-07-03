<?php

namespace App\Modules\Order\Repositories;

use App\Modules\Order\Models\Order;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;

class OrderRepository
{
    public function paginate(
        ?int $outletId = null,
        ?string $status = null,
        ?string $source = null,
        int $perPage = 15,
    ): LengthAwarePaginator {
        $query = Order::query()
            ->with(['outlet:id,name,code', 'table:id,table_number,name', 'items'])
            ->orderByDesc('created_at');

        if ($outletId) {
            $query->where('outlet_id', $outletId);
        }

        if ($status) {
            $query->where('status', $status);
        }

        if ($source) {
            $query->where('source', $source);
        }

        return $query->paginate($perPage);
    }

    public function kitchenQueue(?int $outletId = null): Collection
    {
        $query = Order::query()
            ->with(['table:id,table_number,name', 'items'])
            ->whereIn('status', ['pending', 'cooking', 'ready'])
            ->orderBy('created_at');

        if ($outletId) {
            $query->where('outlet_id', $outletId);
        }

        return $query->get();
    }

    public function findByUuid(string $uuid): ?Order
    {
        return Order::query()
            ->with(['outlet', 'table', 'items', 'statusHistories'])
            ->where('uuid', $uuid)
            ->first();
    }

    public function create(array $data): Order
    {
        return Order::query()->create($data);
    }

    public function update(Order $order, array $data): Order
    {
        $order->update($data);

        return $order->fresh();
    }

    public function countToday(): int
    {
        return Order::query()->whereDate('created_at', today())->count();
    }
}