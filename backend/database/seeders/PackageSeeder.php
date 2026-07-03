<?php

namespace Database\Seeders;

use App\Modules\Platform\Models\Package;
use App\Modules\Platform\Models\PackageFeature;
use Illuminate\Database\Seeder;

class PackageSeeder extends Seeder
{
    public function run(): void
    {
        $packages = [
            [
                'name' => 'Starter',
                'slug' => 'starter',
                'description' => 'Paket dasar untuk UMKM dan bisnis kecil',
                'price_monthly' => 99000,
                'price_yearly' => 990000,
                'max_outlets' => 1,
                'max_users' => 3,
                'max_products' => 100,
                'max_members' => 200,
                'wa_quota_monthly' => 100,
                'trial_days' => 14,
                'sort_order' => 1,
                'features' => [
                    'pos' => '1 outlet',
                    'inventory' => 'basic',
                    'loyalty' => 'basic',
                    'report' => 'basic',
                ],
            ],
            [
                'name' => 'Business',
                'slug' => 'business',
                'description' => 'Paket lengkap untuk bisnis berkembang',
                'price_monthly' => 299000,
                'price_yearly' => 2990000,
                'max_outlets' => 3,
                'max_users' => 10,
                'max_products' => 500,
                'max_members' => 2000,
                'wa_quota_monthly' => 500,
                'trial_days' => 14,
                'sort_order' => 2,
                'features' => [
                    'pos' => '3 outlets',
                    'inventory' => 'full',
                    'loyalty' => 'full',
                    'order' => 'kds',
                    'reservation' => 'basic',
                    'report' => 'full',
                    'crm' => 'basic',
                ],
            ],
            [
                'name' => 'Enterprise',
                'slug' => 'enterprise',
                'description' => 'Paket enterprise dengan fitur lengkap dan multi-outlet',
                'price_monthly' => 799000,
                'price_yearly' => 7990000,
                'max_outlets' => 10,
                'max_users' => 50,
                'max_products' => 5000,
                'max_members' => 10000,
                'wa_quota_monthly' => 2000,
                'trial_days' => 14,
                'sort_order' => 3,
                'features' => [
                    'pos' => 'unlimited',
                    'inventory' => 'full',
                    'loyalty' => 'full',
                    'order' => 'kds',
                    'delivery' => 'full',
                    'reservation' => 'full',
                    'report' => 'full',
                    'crm' => 'full',
                    'whatsapp' => 'full',
                    'wallet' => 'full',
                ],
            ],
        ];

        foreach ($packages as $packageData) {
            $features = $packageData['features'];
            unset($packageData['features']);

            $package = Package::query()->updateOrCreate(
                ['slug' => $packageData['slug']],
                $packageData
            );

            foreach ($features as $key => $value) {
                PackageFeature::query()->updateOrCreate(
                    [
                        'package_id' => $package->id,
                        'feature_key' => $key,
                    ],
                    [
                        'feature_value' => $value,
                        'is_enabled' => true,
                    ]
                );
            }
        }
    }
}