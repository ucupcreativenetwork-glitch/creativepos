<?php

namespace Database\Seeders;

use App\Models\Permission;
use App\Models\Role;
use Illuminate\Database\Seeder;

class RoleSeeder extends Seeder
{
    public function run(): void
    {
        $rolePermissions = [
            'super-admin' => Permission::all()->pluck('name')->toArray(),

            'owner' => [
                'dashboard.view',
                'pos.create', 'pos.view', 'pos.void', 'pos.refund', 'pos.discount', 'pos.shift.open', 'pos.shift.close',
                'inventory.view', 'inventory.create', 'inventory.update', 'inventory.delete', 'inventory.stock.adjust', 'inventory.purchase.create',
                'loyalty.view', 'loyalty.create', 'loyalty.update', 'loyalty.points.adjust',
                'wallet.view', 'wallet.topup', 'wallet.withdraw', 'wallet.transfer',
                'order.view', 'order.create', 'order.update', 'kitchen.view',
                'delivery.view', 'delivery.create', 'delivery.update', 'delivery.assign',
                'reservation.view', 'reservation.create', 'reservation.update',
                'crm.view', 'crm.create', 'crm.update', 'crm.assign',
                'report.view', 'report.export',
                'tenant.settings.view', 'tenant.settings.update', 'tenant.users.view', 'tenant.users.manage', 'tenant.outlets.manage',
            ],

            'manager' => [
                'dashboard.view',
                'pos.create', 'pos.view', 'pos.void', 'pos.refund', 'pos.discount', 'pos.shift.open', 'pos.shift.close',
                'inventory.view', 'inventory.create', 'inventory.update', 'inventory.stock.adjust', 'inventory.purchase.create',
                'loyalty.view', 'loyalty.create', 'loyalty.update',
                'wallet.view', 'wallet.topup',
                'order.view', 'order.create', 'order.update', 'kitchen.view',
                'delivery.view', 'delivery.create', 'delivery.update', 'delivery.assign',
                'reservation.view', 'reservation.create', 'reservation.update',
                'crm.view', 'crm.create', 'crm.update', 'crm.assign',
                'report.view', 'report.export',
                'tenant.settings.view', 'tenant.users.view',
            ],

            'supervisor' => [
                'dashboard.view',
                'pos.create', 'pos.view', 'pos.void', 'pos.discount', 'pos.shift.open', 'pos.shift.close',
                'inventory.view',
                'loyalty.view',
                'order.view', 'order.update', 'kitchen.view',
                'delivery.view',
                'reservation.view',
                'crm.view',
                'report.view',
            ],

            'cashier' => [
                'pos.create', 'pos.view', 'pos.discount', 'pos.shift.open', 'pos.shift.close',
                'inventory.view',
                'loyalty.view', 'loyalty.create',
                'order.view', 'order.create',
            ],

            'waiter' => [
                'order.view', 'order.create', 'order.update',
                'reservation.view',
                'loyalty.view',
            ],

            'kitchen' => [
                'kitchen.view',
                'order.view', 'order.update',
            ],

            'driver' => [
                'delivery.view', 'delivery.update', 'delivery.assign',
            ],

            'customer-service' => [
                'crm.view', 'crm.create', 'crm.update', 'crm.assign',
                'loyalty.view',
                'order.view',
            ],

            'customer' => [
                'order.view',
            ],
        ];

        foreach ($rolePermissions as $roleName => $permissions) {
            $role = Role::query()->updateOrCreate(
                [
                    'name' => $roleName,
                    'guard_name' => 'web',
                    'tenant_id' => null,
                ],
                [
                    'is_system' => true,
                ]
            );

            $role->syncPermissions($permissions);
        }
    }
}