<?php

namespace Database\Seeders;

use App\Models\User;
use App\Modules\Delivery\Models\DeliveryDriver;
use App\Modules\Delivery\Models\DeliveryOrder;
use App\Modules\Delivery\Models\DeliveryZone;
use App\Modules\Delivery\Models\DeliveryZoneRate;
use App\Modules\Inventory\Models\Product;
use App\Modules\Loyalty\Models\Member;
use App\Modules\Order\Models\Table;
use App\Modules\Platform\Models\Tenant;
use App\Modules\Reservation\Models\Reservation;
use App\Modules\Reservation\Models\ReservationTimeSlot;
use App\Modules\Tenant\Models\Outlet;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class OperationsDemoSeeder extends Seeder
{
    public function run(): void
    {
        $tenants = Tenant::query()->get();

        foreach ($tenants as $tenant) {
            set_tenant($tenant);
            $this->seedForTenant($tenant);
        }
    }

    protected function seedForTenant(Tenant $tenant): void
    {
        $outlet = Outlet::query()->where('tenant_id', $tenant->id)->first();

        if (! $outlet) {
            return;
        }

        if (ReservationTimeSlot::query()->where('tenant_id', $tenant->id)->exists()) {
            return;
        }

        $this->seedTimeSlots($tenant, $outlet);
        $this->seedReservations($tenant, $outlet);
        $zones = $this->seedDeliveryZones($tenant, $outlet);
        $drivers = $this->seedDrivers($tenant, $outlet);
        $this->seedDeliveryOrders($tenant, $outlet, $zones, $drivers);
    }

    protected function seedTimeSlots(Tenant $tenant, Outlet $outlet): void
    {
        $slots = [
            ['day' => 1, 'start' => '11:00:00', 'end' => '13:00:00', 'capacity' => 8],
            ['day' => 1, 'start' => '18:00:00', 'end' => '20:00:00', 'capacity' => 10],
            ['day' => 5, 'start' => '11:00:00', 'end' => '13:00:00', 'capacity' => 8],
            ['day' => 5, 'start' => '18:00:00', 'end' => '21:00:00', 'capacity' => 12],
            ['day' => 6, 'start' => '10:00:00', 'end' => '14:00:00', 'capacity' => 15],
            ['day' => 0, 'start' => '10:00:00', 'end' => '14:00:00', 'capacity' => 15],
        ];

        foreach ($slots as $slot) {
            ReservationTimeSlot::query()->create([
                'tenant_id' => $tenant->id,
                'outlet_id' => $outlet->id,
                'day_of_week' => $slot['day'],
                'start_time' => $slot['start'],
                'end_time' => $slot['end'],
                'capacity' => $slot['capacity'],
                'is_active' => true,
            ]);
        }
    }

    protected function seedReservations(Tenant $tenant, Outlet $outlet): void
    {
        $members = Member::query()->limit(3)->get();
        $tables = Table::query()->limit(2)->get();

        $reservations = [
            ['name' => 'Budi Santoso', 'phone' => '08111111111', 'guests' => 4, 'days' => 1, 'time' => '12:00:00', 'status' => 'confirmed'],
            ['name' => 'Siti Aminah', 'phone' => '08222222222', 'guests' => 2, 'days' => 2, 'time' => '19:00:00', 'status' => 'pending'],
            ['name' => 'Andi Wijaya', 'phone' => '08333333333', 'guests' => 6, 'days' => 3, 'time' => '12:30:00', 'status' => 'confirmed'],
            ['name' => 'Dewi Lestari', 'phone' => '08444444444', 'guests' => 3, 'days' => 5, 'time' => '19:30:00', 'status' => 'arrived'],
            ['name' => 'Rudi Hartono', 'phone' => '08555555555', 'guests' => 5, 'days' => 7, 'time' => '11:30:00', 'status' => 'pending'],
            ['name' => 'Maya Sari', 'phone' => '08666666666', 'guests' => 2, 'days' => 10, 'time' => '13:00:00', 'status' => 'confirmed'],
        ];

        foreach ($reservations as $index => $data) {
            $date = now()->addDays($data['days']);

            Reservation::query()->create([
                'tenant_id' => $tenant->id,
                'uuid' => (string) Str::uuid(),
                'reservation_number' => 'RSV-'.now()->format('Ymd').'-'.str_pad((string) ($index + 1), 4, '0', STR_PAD_LEFT),
                'outlet_id' => $outlet->id,
                'member_id' => $members->get($index % $members->count())?->id,
                'table_id' => $tables->get($index % max(1, $tables->count()))?->id,
                'customer_name' => $data['name'],
                'customer_phone' => $data['phone'],
                'customer_email' => strtolower(str_replace(' ', '.', $data['name'])).'@demo.com',
                'guest_count' => $data['guests'],
                'reservation_date' => $date->toDateString(),
                'reservation_time' => $data['time'],
                'status' => $data['status'],
                'notes' => 'Reservasi demo',
                'confirmed_at' => in_array($data['status'], ['confirmed', 'arrived'], true) ? now() : null,
                'arrived_at' => $data['status'] === 'arrived' ? now() : null,
            ]);
        }
    }

    protected function seedDeliveryZones(Tenant $tenant, Outlet $outlet): array
    {
        $zones = [];

        $zoneData = [
            ['name' => 'Zona Dalam Kota', 'code' => 'ZDK', 'rates' => [
                ['min' => 0, 'max' => 5, 'base' => 10000, 'per_km' => 2000],
                ['min' => 5.01, 'max' => 10, 'base' => 15000, 'per_km' => 2500],
            ]],
            ['name' => 'Zona Luar Kota', 'code' => 'ZLK', 'rates' => [
                ['min' => 0, 'max' => 15, 'base' => 20000, 'per_km' => 3000],
                ['min' => 15.01, 'max' => 30, 'base' => 35000, 'per_km' => 4000],
            ]],
        ];

        foreach ($zoneData as $data) {
            $zone = DeliveryZone::query()->create([
                'tenant_id' => $tenant->id,
                'uuid' => (string) Str::uuid(),
                'outlet_id' => $outlet->id,
                'name' => $data['name'],
                'code' => $data['code'],
                'description' => 'Zona pengiriman demo',
                'is_active' => true,
            ]);

            foreach ($data['rates'] as $rate) {
                DeliveryZoneRate::query()->create([
                    'tenant_id' => $tenant->id,
                    'delivery_zone_id' => $zone->id,
                    'min_distance_km' => $rate['min'],
                    'max_distance_km' => $rate['max'],
                    'base_fee' => $rate['base'],
                    'fee_per_km' => $rate['per_km'],
                    'is_active' => true,
                ]);
            }

            $zones[] = $zone;
        }

        return $zones;
    }

    protected function seedDrivers(Tenant $tenant, Outlet $outlet): array
    {
        $drivers = [];

        $driverUsers = [
            ['name' => 'Driver Demo 1', 'email' => 'driver1@'.($tenant->slug ?? 'tenant'.$tenant->id).'.demo', 'plate' => 'B 1234 DLV'],
            ['name' => 'Driver Demo 2', 'email' => 'driver2@'.($tenant->slug ?? 'tenant'.$tenant->id).'.demo', 'plate' => 'B 5678 DLV'],
        ];

        foreach ($driverUsers as $index => $data) {
            $user = User::query()->firstOrCreate(
                ['email' => $data['email']],
                [
                    'tenant_id' => $tenant->id,
                    'uuid' => (string) Str::uuid(),
                    'name' => $data['name'],
                    'phone' => '0877000000'.($index + 1),
                    'password' => Hash::make('password'),
                    'status' => 'active',
                ]
            );

            $drivers[] = DeliveryDriver::query()->create([
                'tenant_id' => $tenant->id,
                'uuid' => (string) Str::uuid(),
                'user_id' => $user->id,
                'outlet_id' => $outlet->id,
                'vehicle_type' => 'motorcycle',
                'vehicle_plate' => $data['plate'],
                'is_active' => true,
                'is_available' => $index === 1,
            ]);
        }

        return $drivers;
    }

    protected function seedDeliveryOrders(Tenant $tenant, Outlet $outlet, array $zones, array $drivers): void
    {
        if (DeliveryOrder::query()->where('tenant_id', $tenant->id)->exists()) {
            return;
        }

        $products = Product::query()->limit(4)->get();

        if ($products->isEmpty()) {
            return;
        }

        $orders = [
            ['name' => 'Ahmad Rizki', 'phone' => '08120000001', 'address' => 'Jl. Merdeka No. 10', 'city' => 'Jakarta', 'distance' => 3.5, 'status' => 'waiting'],
            ['name' => 'Lina Marlina', 'phone' => '08120000002', 'address' => 'Jl. Sudirman No. 25', 'city' => 'Jakarta', 'distance' => 7.2, 'status' => 'processing'],
            ['name' => 'Hendra Gunawan', 'phone' => '08120000003', 'address' => 'Jl. Gatot Subroto No. 5', 'city' => 'Jakarta', 'distance' => 12.0, 'status' => 'delivering'],
            ['name' => 'Putri Anggraini', 'phone' => '08120000004', 'address' => 'Jl. Thamrin No. 88', 'city' => 'Jakarta', 'distance' => 2.1, 'status' => 'completed'],
        ];

        foreach ($orders as $index => $data) {
            $zone = $zones[$index < 2 ? 0 : 1];
            $rate = DeliveryZoneRate::query()
                ->where('delivery_zone_id', $zone->id)
                ->where('min_distance_km', '<=', $data['distance'])
                ->where('max_distance_km', '>=', $data['distance'])
                ->first();

            $shippingFee = $rate
                ? round((float) $rate->base_fee + ($data['distance'] * (float) $rate->fee_per_km), 2)
                : 15000;

            $product = $products[$index % $products->count()];
            $qty = rand(1, 3);
            $subtotal = round($product->base_price * $qty, 2);

            $order = DeliveryOrder::query()->create([
                'tenant_id' => $tenant->id,
                'uuid' => (string) Str::uuid(),
                'delivery_number' => 'DLV-'.now()->format('Ymd').'-'.str_pad((string) ($index + 1), 4, '0', STR_PAD_LEFT),
                'outlet_id' => $outlet->id,
                'driver_id' => in_array($data['status'], ['processing', 'delivering', 'completed'], true)
                    ? $drivers[0]->id
                    : null,
                'delivery_zone_id' => $zone->id,
                'customer_name' => $data['name'],
                'customer_phone' => $data['phone'],
                'delivery_address' => $data['address'],
                'delivery_city' => $data['city'],
                'delivery_notes' => 'Pesanan delivery demo',
                'status' => $data['status'],
                'subtotal' => $subtotal,
                'shipping_fee' => $shippingFee,
                'total_amount' => round($subtotal + $shippingFee, 2),
                'distance_km' => $data['distance'],
                'estimated_minutes' => (int) ceil($data['distance'] * 5),
                'assigned_at' => in_array($data['status'], ['processing', 'delivering', 'completed'], true) ? now()->subMinutes(30) : null,
                'picked_up_at' => in_array($data['status'], ['delivering', 'completed'], true) ? now()->subMinutes(15) : null,
                'delivered_at' => $data['status'] === 'completed' ? now()->subMinutes(5) : null,
            ]);

            $order->items()->create([
                'tenant_id' => $tenant->id,
                'product_id' => $product->id,
                'product_name' => $product->name,
                'quantity' => $qty,
                'unit_price' => $product->base_price,
                'subtotal' => $subtotal,
            ]);
        }
    }
}