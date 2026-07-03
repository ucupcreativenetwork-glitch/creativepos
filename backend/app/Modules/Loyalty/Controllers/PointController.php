<?php

namespace App\Modules\Loyalty\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Loyalty\Models\Member;
use App\Modules\Loyalty\Requests\AdjustPointsRequest;
use App\Modules\Loyalty\Requests\RedeemPointsRequest;
use App\Modules\Loyalty\Resources\PointTransactionResource;
use App\Modules\Loyalty\Services\PointService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PointController extends Controller
{
    public function __construct(
        private readonly PointService $pointService,
    ) {}

    public function balance(Request $request, Member $member): JsonResponse
    {
        $this->authorizePermission($request, 'loyalty.view');

        $balance = $this->pointService->getBalance($member);
        $history = $this->pointService->history($member, $request->integer('per_page', 10));

        return ApiResponse::success([
            ...$balance,
            'history' => PointTransactionResource::collection($history->items()),
            'meta' => [
                'current_page' => $history->currentPage(),
                'per_page' => $history->perPage(),
                'total' => $history->total(),
                'last_page' => $history->lastPage(),
            ],
        ]);
    }

    public function redeem(RedeemPointsRequest $request, Member $member): JsonResponse
    {
        $this->authorizePermission($request, 'loyalty.points.adjust');

        $result = $this->pointService->redeem(
            $member,
            $request->integer('points'),
            $request->input('description'),
        );

        return ApiResponse::success($result, 'Poin berhasil ditukar.');
    }

    public function adjust(AdjustPointsRequest $request, Member $member): JsonResponse
    {
        $this->authorizePermission($request, 'loyalty.points.adjust');

        $this->pointService->adjust(
            $member,
            $request->integer('points'),
            $request->input('description'),
        );

        return ApiResponse::success(
            $this->pointService->getBalance($member),
            'Saldo poin berhasil disesuaikan.',
        );
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses poin member.');
        }
    }
}