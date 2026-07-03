<?php

namespace App\Modules\Loyalty\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Loyalty\Models\TierConfig;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TierConfigController extends Controller
{
    public function update(Request $request, TierConfig $tier): JsonResponse
    {
        $this->authorizePermission($request, 'loyalty.update');

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:50'],
            'min_spend' => ['sometimes', 'numeric', 'min:0'],
            'point_multiplier' => ['sometimes', 'numeric', 'min:0.1', 'max:10'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $tier->update($validated);

        return ApiResponse::success([
            'id' => $tier->id,
            'name' => $tier->name,
            'slug' => $tier->slug,
            'min_spend' => (float) $tier->min_spend,
            'point_multiplier' => (float) $tier->point_multiplier,
            'is_active' => $tier->is_active,
        ]);
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses tier loyalty.');
        }
    }
}