<?php

namespace App\Modules\Auth\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Repositories\LoginHistoryRepository;
use App\Modules\Auth\Services\AuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SessionController extends Controller
{
    public function __construct(
        private readonly AuthService $authService,
        private readonly LoginHistoryRepository $loginHistories,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $sessions = $request->user()
            ->tokens()
            ->orderByDesc('last_used_at')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn ($token) => [
                'id' => $token->id,
                'name' => $token->name,
                'last_used_at' => $token->last_used_at?->toIso8601String(),
                'created_at' => $token->created_at?->toIso8601String(),
                'expires_at' => $token->expires_at?->toIso8601String(),
                'is_current' => $token->id === $request->user()->currentAccessToken()?->id,
            ]);

        return $this->success($sessions, 'Active sessions retrieved.');
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $token = $request->user()->tokens()->where('id', $id)->first();

        if ($token === null) {
            return $this->error('Session not found.', 404);
        }

        if ($token->id === $request->user()->currentAccessToken()?->id) {
            return $this->error('Cannot revoke current session. Use logout instead.', 400);
        }

        $this->authService->logout($request->user(), $id);

        return $this->success(null, 'Session revoked successfully.');
    }

    public function loginHistory(Request $request): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 15);
        $histories = $this->loginHistories->paginateForUser($request->user(), $perPage);

        $data = collect($histories->items())->map(fn ($history) => [
            'id' => $history->id,
            'ip_address' => $history->ip_address,
            'device_name' => $history->device_name,
            'user_agent' => $history->user_agent,
            'location' => $history->location,
            'is_successful' => $history->is_successful,
            'failure_reason' => $history->failure_reason,
            'logged_in_at' => $history->logged_in_at?->toIso8601String(),
            'logged_out_at' => $history->logged_out_at?->toIso8601String(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Login history retrieved.',
            'data' => $data,
            'meta' => [
                'current_page' => $histories->currentPage(),
                'per_page' => $histories->perPage(),
                'total' => $histories->total(),
                'last_page' => $histories->lastPage(),
            ],
        ]);
    }
}