<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            PermissionSeeder::class,
            RoleSeeder::class,
            PackageSeeder::class,
            PaymentMethodSeeder::class,
            DefaultAccountsSeeder::class,
            DashboardDemoSeeder::class,
            LoyaltySeeder::class,
            QrMenuSeeder::class,
            OperationsDemoSeeder::class,
            CrmDemoSeeder::class,
            BillingDemoSeeder::class,
            NotificationTemplateSeeder::class,
        ]);
    }
}