<?php

namespace App\Modules\POS\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\POS\Models\SaleTransaction;
use App\Modules\POS\Requests\CreateTransactionRequest;
use App\Modules\POS\Requests\VoidTransactionRequest;
use App\Modules\POS\Resources\TransactionResource;
use App\Modules\POS\Services\TransactionService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    public function __construct(
        private readonly TransactionService $transactionService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'pos.view');

        $paginator = $this->transactionService->list(
            $request->integer('outlet_id') ?: null,
            $request->input('status'),
            $request->input('search'),
            $request->integer('per_page', 15),
        );

        return ApiResponse::success(
            TransactionResource::collection($paginator->items()),
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

    public function show(Request $request, SaleTransaction $transaction): JsonResponse
    {
        $this->authorizePermission($request, 'pos.view');

        $transaction = $this->transactionService->findByUuid($transaction->uuid);

        return ApiResponse::success(new TransactionResource($transaction));
    }

    public function store(CreateTransactionRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'pos.create');

        $transaction = $this->transactionService->create(
            $request->validated(),
            $request->user(),
        );

        return ApiResponse::created(new TransactionResource($transaction));
    }

    public function void(VoidTransactionRequest $request, SaleTransaction $transaction): JsonResponse
    {
        $this->authorizePermission($request, 'pos.void');

        $transaction = $this->transactionService->void(
            $transaction,
            $request->user(),
            $request->input('reason'),
        );

        return ApiResponse::success(new TransactionResource($transaction), 'Transaksi berhasil dibatalkan.');
    }

    public function receipt(Request $request, SaleTransaction $transaction): JsonResponse
    {
        $this->authorizePermission($request, 'pos.view');

        $transaction = $this->transactionService->findByUuid($transaction->uuid);

        return ApiResponse::success($this->transactionService->getReceipt($transaction));
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses POS.');
        }
    }
}