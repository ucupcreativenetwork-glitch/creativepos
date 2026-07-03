<?php

namespace App\Modules\Delivery\Repositories;

use App\Modules\Delivery\Models\DeliveryDriver;
use Illuminate\Database\Eloquent\Collection;

class DeliveryDriverRepository
{
    public function list(?int $outletId = null, ?bool $availableOnly = null): Collection
    {
        $query = DeliveryDriver::query()
            ->with(['user:id,name,phone,email', 'outlet:id,name,code'])
            ->where('is_active', true)
            ->orderBy('id');

        if ($outletId) {
            $query->where(function ($q) use ($outletId) {
                $q->where('outlet_id', $outletId)->orWhereNull('outlet_id');
            });
        }

        if ($availableOnly) {
            $query->where('is_available', true);
        }

        return $query->get();
    }

    public function findByUuid(string $uuid): ?DeliveryDriver
    {
        return DeliveryDriver::query()
            ->with(['user:id,name,phone,email'])
            ->where('uuid', $uuid)
            ->first();
    }

    public function findById(int $id): ?DeliveryDriver
    {
        return DeliveryDriver::query()->find($id);
    }
}