<?php

namespace App\Modules\Loyalty\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Loyalty\Models\Member;
use App\Modules\Loyalty\Requests\WalletTopupRequest;
use App\Modules\Loyalty\Requests\WalletTransferRequest;
use App\Modules\Loyalty\Requests\WalletWithdrawRequest;
use App\Modules\Loyalty\Resources\WalletTransactionResource;
use App\Modules\Loyalty\Services\WalletService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    public function __construct(
        private readonly WalletService $walletService,
    ) {}

    public function show(Request $request, Member $member): JsonResponse
    {
        $this->authorizePermission($request, 'wallet.view');

        $wallet = $this->walletService->getWallet($member);

        return ApiResponse::success([
            'member_id' => $member->id,
            'balance' => (float) $wallet->balance,
            'lifetime_topup' => (float) $wallet->lifetime_topup,
            'lifetime_spent' => (float) $wallet->lifetime_spent,
            'status' => $wallet->status,
        ]);
    }

    public function transactions(Request $request, Member $member): JsonResponse
    {
        $this->authorizePermission($request, 'wallet.view');

        $paginator = $this->walletService->transactions(
            $member,
            $request->integer('per_page', 20),
        );

        return ApiResponse::success(
            WalletTransactionResource::collection($paginator->items()),
            'Operation successful',
            200,
            [
                'current_page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
            ],
        );
    }

    public function topup(WalletTopupRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'wallet.topup');

        $member = Member::query()->findOrFail($request->integer('member_id'));
        $wallet = $this->walletService->topup(
            $member,
            (float) $request->input('amount'),
            $request->input('description'),
        );

        return ApiResponse::created([
            'balance' => (float) $wallet->balance,
        ], 'Top-up berhasil.');
    }

    public function withdraw(WalletWithdrawRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'wallet.withdraw');

        $member = Member::query()->findOrFail($request->integer('member_id'));
        $wallet = $this->walletService->withdraw(
            $member,
            (float) $request->input('amount'),
            $request->input('description'),
        );

        return ApiResponse::success([
            'balance' => (float) $wallet->balance,
        ], 'Penarikan berhasil.');
    }

    public function transfer(WalletTransferRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'wallet.transfer');

        $from = Member::query()->findOrFail($request->integer('from_member_id'));
        $to = Member::query()->findOrFail($request->integer('to_member_id'));

        $result = $this->walletService->transfer(
            $from,
            $to,
            (float) $request->input('amount'),
            $request->input('description'),
        );

        return ApiResponse::success([
            'from_balance' => (float) $result['from_wallet']->balance,
            'to_balance' => (float) $result['to_wallet']->balance,
        ], 'Transfer berhasil.');
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses wallet.');
        }
    }
}