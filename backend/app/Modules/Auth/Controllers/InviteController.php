<?php

namespace App\Modules\Auth\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Services\InviteService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InviteController extends Controller
{
    public function __construct(
        private readonly InviteService $inviteService,
    ) {}

    public function invite(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can('tenant.users.manage')) {
            abort(403, 'Anda tidak memiliki izin untuk mengundang staff.');
        }

        $validated = $request->validate([
            'email' => 'required|email|max:255',
            'name' => 'sometimes|nullable|string|max:255',
            'role' => 'required|string|in:cashier,manager',
        ]);

        $result = $this->inviteService->invite($validated);

        return ApiResponse::created($result);
    }
}