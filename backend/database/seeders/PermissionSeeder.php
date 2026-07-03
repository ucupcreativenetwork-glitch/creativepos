<?php

namespace Database\Seeders;

use App\Models\Permission;
use Illuminate\Database\Seeder;

class PermissionSeeder extends Seeder
{
    public function run(): void
    {
        $permissions = [
            // Dashboard
            ['name' => 'dashboard.view', 'module' => 'dashboard', 'description' => 'View dashboard KPIs'],

            // POS
            ['name' => 'pos.create', 'module' => 'pos', 'description' => 'Create transactions'],
            ['name' => 'pos.view', 'module' => 'pos', 'description' => 'View transactions'],
            ['name' => 'pos.void', 'module' => 'pos', 'description' => 'Void transactions'],
            ['name' => 'pos.refund', 'module' => 'pos', 'description' => 'Process refunds'],
            ['name' => 'pos.discount', 'module' => 'pos', 'description' => 'Apply discounts'],
            ['name' => 'pos.shift.open', 'module' => 'pos', 'description' => 'Open cashier shift'],
            ['name' => 'pos.shift.close', 'module' => 'pos', 'description' => 'Close cashier shift'],

            // Inventory
            ['name' => 'inventory.view', 'module' => 'inventory', 'description' => 'View inventory'],
            ['name' => 'inventory.create', 'module' => 'inventory', 'description' => 'Create products'],
            ['name' => 'inventory.update', 'module' => 'inventory', 'description' => 'Update products'],
            ['name' => 'inventory.delete', 'module' => 'inventory', 'description' => 'Delete products'],
            ['name' => 'inventory.stock.adjust', 'module' => 'inventory', 'description' => 'Adjust stock'],
            ['name' => 'inventory.purchase.create', 'module' => 'inventory', 'description' => 'Create purchase orders'],

            // Loyalty
            ['name' => 'loyalty.view', 'module' => 'loyalty', 'description' => 'View members'],
            ['name' => 'loyalty.create', 'module' => 'loyalty', 'description' => 'Create members'],
            ['name' => 'loyalty.update', 'module' => 'loyalty', 'description' => 'Update members'],
            ['name' => 'loyalty.points.adjust', 'module' => 'loyalty', 'description' => 'Adjust member points'],

            // Wallet
            ['name' => 'wallet.view', 'module' => 'wallet', 'description' => 'View member wallet'],
            ['name' => 'wallet.topup', 'module' => 'wallet', 'description' => 'Top-up wallet'],
            ['name' => 'wallet.withdraw', 'module' => 'wallet', 'description' => 'Withdraw wallet'],
            ['name' => 'wallet.transfer', 'module' => 'wallet', 'description' => 'Transfer wallet'],

            // Orders
            ['name' => 'order.view', 'module' => 'order', 'description' => 'View orders'],
            ['name' => 'order.create', 'module' => 'order', 'description' => 'Create orders'],
            ['name' => 'order.update', 'module' => 'order', 'description' => 'Update order status'],
            ['name' => 'kitchen.view', 'module' => 'order', 'description' => 'View kitchen display'],

            // Delivery
            ['name' => 'delivery.view', 'module' => 'delivery', 'description' => 'View deliveries'],
            ['name' => 'delivery.create', 'module' => 'delivery', 'description' => 'Create delivery orders'],
            ['name' => 'delivery.update', 'module' => 'delivery', 'description' => 'Update delivery status and location'],
            ['name' => 'delivery.assign', 'module' => 'delivery', 'description' => 'Assign delivery drivers'],

            // Reservation
            ['name' => 'reservation.view', 'module' => 'reservation', 'description' => 'View reservations'],
            ['name' => 'reservation.create', 'module' => 'reservation', 'description' => 'Create reservations'],
            ['name' => 'reservation.update', 'module' => 'reservation', 'description' => 'Update reservations'],

            // CRM
            ['name' => 'crm.view', 'module' => 'crm', 'description' => 'View CRM tickets'],
            ['name' => 'crm.create', 'module' => 'crm', 'description' => 'Create CRM tickets'],
            ['name' => 'crm.update', 'module' => 'crm', 'description' => 'Update CRM tickets'],
            ['name' => 'crm.assign', 'module' => 'crm', 'description' => 'Assign CRM tickets'],

            // Reports
            ['name' => 'report.view', 'module' => 'report', 'description' => 'View reports'],
            ['name' => 'report.export', 'module' => 'report', 'description' => 'Export reports'],

            // Tenant settings
            ['name' => 'tenant.settings.view', 'module' => 'tenant', 'description' => 'View tenant settings'],
            ['name' => 'tenant.settings.update', 'module' => 'tenant', 'description' => 'Update tenant settings'],
            ['name' => 'tenant.users.view', 'module' => 'tenant', 'description' => 'View tenant users'],
            ['name' => 'tenant.users.manage', 'module' => 'tenant', 'description' => 'Manage tenant users'],
            ['name' => 'tenant.outlets.manage', 'module' => 'tenant', 'description' => 'Manage outlets'],

            // Platform (super admin)
            ['name' => 'platform.tenants.view', 'module' => 'platform', 'description' => 'View all tenants'],
            ['name' => 'platform.tenants.manage', 'module' => 'platform', 'description' => 'Manage tenants'],
            ['name' => 'platform.packages.manage', 'module' => 'platform', 'description' => 'Manage packages'],
            ['name' => 'platform.billing.view', 'module' => 'platform', 'description' => 'View billing'],
        ];

        foreach ($permissions as $permission) {
            Permission::query()->updateOrCreate(
                ['name' => $permission['name'], 'guard_name' => 'web'],
                [
                    'module' => $permission['module'],
                    'description' => $permission['description'],
                ]
            );
        }
    }
}