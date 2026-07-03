<?php

namespace App\Shared\Services;

use App\Models\User;
use App\Modules\Inventory\Models\Product;
use App\Modules\Loyalty\Models\Member;
use App\Modules\Platform\Models\Subscription;
use App\Modules\Tenant\Models\Outlet;
use Illuminate\Validation\ValidationException;

class PackageLimitService
{
    public function getLimits(): ?array
    {
        $package = $this->resolvePackage();

        if (! $package) {
            return null;
        }

        return [
            'max_outlets' => (int) $package->max_outlets,
            'max_users' => (int) $package->max_users,
            'max_products' => (int) $package->max_products,
            'max_members' => (int) $package->max_members,
        ];
    }

    public function getUsage(): array
    {
        $tenantId = tenant('id');

        return [
            'outlets' => Outlet::query()->count(),
            'users' => User::query()
                ->where('tenant_id', $tenantId)
                ->where('is_super_admin', false)
                ->count(),
            'products' => Product::query()->count(),
            'members' => Member::query()->count(),
        ];
    }

    public function getQuotaSummary(): array
    {
        $limits = $this->getLimits();
        $usage = $this->getUsage();

        return [
            'limits' => $limits,
            'usage' => $usage,
            'remaining' => $limits ? [
                'outlets' => $this->remaining($limits['max_outlets'], $usage['outlets']),
                'users' => $this->remaining($limits['max_users'], $usage['users']),
                'products' => $this->remaining($limits['max_products'], $usage['products']),
                'members' => $this->remaining($limits['max_members'] ?? 0, $usage['members']),
            ] : null,
        ];
    }

    public function assertCanCreateOutlet(): void
    {
        $this->assertWithinLimit('outlets', Outlet::query()->count(), 'outlet');
    }

    public function assertCanInviteUser(): void
    {
        $tenantId = tenant('id');

        $this->assertWithinLimit(
            'users',
            User::query()->where('tenant_id', $tenantId)->where('is_super_admin', false)->count(),
            'pengguna',
        );
    }

    public function assertCanCreateProduct(): void
    {
        $this->assertWithinLimit('products', Product::query()->count(), 'produk');
    }

    public function assertCanCreateMember(): void
    {
        $this->assertWithinLimit('members', Member::query()->count(), 'member');
    }

    protected function assertWithinLimit(string $key, int $current, string $label): void
    {
        $limits = $this->getLimits();

        if (! $limits) {
            return;
        }

        $maxMap = [
            'outlets' => $limits['max_outlets'],
            'users' => $limits['max_users'],
            'products' => $limits['max_products'],
            'members' => $limits['max_members'] ?? 0,
        ];

        $max = $maxMap[$key] ?? 0;

        if ($max > 0 && $current >= $max) {
            throw ValidationException::withMessages([
                $key => ["Batas paket tercapai: maksimal {$max} {$label}. Upgrade paket untuk menambah."],
            ]);
        }
    }

    protected function remaining(int $max, int $used): ?int
    {
        if ($max <= 0) {
            return null;
        }

        return max(0, $max - $used);
    }

    protected function resolvePackage()
    {
        $subscription = Subscription::query()
            ->with('package:id,max_outlets,max_users,max_products,max_members')
            ->where('status', 'active')
            ->latest()
            ->first();

        return $subscription?->package;
    }
}