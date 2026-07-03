<?php

namespace App\Modules\Delivery\Repositories;

use App\Modules\Delivery\Models\DeliveryZone;
use App\Modules\Delivery\Models\DeliveryZoneRate;
use Illuminate\Database\Eloquent\Collection;

class DeliveryZoneRepository
{
    public function list(?int $outletId = null): Collection
    {
        $query = DeliveryZone::query()
            ->with(['rates' => fn ($q) => $q->where('is_active', true)->orderBy('min_distance_km')])
            ->where('is_active', true)
            ->orderBy('name');

        if ($outletId) {
            $query->where('outlet_id', $outletId);
        }

        return $query->get();
    }

    public function findRateForDistance(int $zoneId, float $distanceKm): ?DeliveryZoneRate
    {
        return DeliveryZoneRate::query()
            ->where('delivery_zone_id', $zoneId)
            ->where('is_active', true)
            ->where('min_distance_km', '<=', $distanceKm)
            ->where('max_distance_km', '>=', $distanceKm)
            ->first();
    }

    public function findById(int $id): ?DeliveryZone
    {
        return DeliveryZone::query()
            ->with(['rates' => fn ($q) => $q->where('is_active', true)])
            ->find($id);
    }

    public function findByUuid(string $uuid): ?DeliveryZone
    {
        return DeliveryZone::query()
            ->with(['rates' => fn ($q) => $q->where('is_active', true)])
            ->where('uuid', $uuid)
            ->first();
    }
}