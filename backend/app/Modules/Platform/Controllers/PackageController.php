<?php

namespace App\Modules\Platform\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Platform\Models\Package;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PackageController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->authorizePlatform($request);

        $packages = Package::query()
            ->with('features')
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        return ApiResponse::success($packages->map(fn (Package $package) => [
            'id' => $package->id,
            'name' => $package->name,
            'slug' => $package->slug,
            'description' => $package->description,
            'price_monthly' => (float) $package->price_monthly,
            'price_yearly' => (float) $package->price_yearly,
            'max_outlets' => $package->max_outlets,
            'max_users' => $package->max_users,
            'max_products' => $package->max_products,
            'max_members' => $package->max_members,
            'wa_quota_monthly' => $package->wa_quota_monthly,
            'trial_days' => $package->trial_days,
            'features' => $package->features->map(fn ($f) => [
                'feature_key' => $f->feature_key,
                'feature_value' => $f->feature_value,
                'is_enabled' => $f->is_enabled,
            ])->values()->all(),
        ]));
    }

    protected function authorizePlatform(Request $request): void
    {
        if (! $request->user()?->is_super_admin) {
            abort(403, 'Super admin access required.');
        }
    }
}