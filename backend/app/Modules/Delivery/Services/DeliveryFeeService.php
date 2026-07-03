<?php

namespace App\Modules\Delivery\Services;

use App\Modules\Delivery\Repositories\DeliveryZoneRepository;

class DeliveryFeeService
{
    public function __construct(
        private readonly DeliveryZoneRepository $zoneRepository,
    ) {}

    public function calculate(int $zoneId, float $distanceKm): array
    {
        if ($distanceKm < 0) {
            abort(422, 'Jarak tidak valid.');
        }

        $zone = $this->zoneRepository->findById($zoneId);

        if (! $zone) {
            abort(404, 'Zona pengiriman tidak ditemukan.');
        }

        $rate = $this->zoneRepository->findRateForDistance($zoneId, $distanceKm);

        if (! $rate) {
            abort(422, 'Tidak ada tarif untuk jarak ini.');
        }

        $distanceFee = round($distanceKm * (float) $rate->fee_per_km, 2);
        $shippingFee = round((float) $rate->base_fee + $distanceFee, 2);
        $estimatedMinutes = (int) max(15, ceil($distanceKm * 5));

        return [
            'zone' => [
                'id' => $zone->id,
                'uuid' => $zone->uuid,
                'name' => $zone->name,
                'code' => $zone->code,
            ],
            'distance_km' => $distanceKm,
            'base_fee' => (float) $rate->base_fee,
            'fee_per_km' => (float) $rate->fee_per_km,
            'distance_fee' => $distanceFee,
            'shipping_fee' => $shippingFee,
            'estimated_minutes' => $estimatedMinutes,
        ];
    }
}