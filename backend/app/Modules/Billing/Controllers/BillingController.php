<?php

namespace App\Modules\Billing\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Billing\Models\BillingInvoice;
use App\Modules\Billing\Requests\InitiatePaymentRequest;
use App\Modules\Billing\Services\BillingService;
use App\Modules\Billing\Services\PaymentService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BillingController extends Controller
{
    public function __construct(
        private readonly BillingService $billingService,
        private readonly PaymentService $paymentService,
    ) {}

    public function subscription(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.view');

        $data = $this->billingService->getSubscription();

        return ApiResponse::success($data);
    }

    public function invoices(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.view');

        $paginator = $this->billingService->listInvoices($request->integer('per_page', 15));

        $paginator->through(fn (BillingInvoice $invoice) => [
            'id' => $invoice->id,
            'invoice_number' => $invoice->invoice_number,
            'amount' => (float) $invoice->amount,
            'tax_amount' => (float) $invoice->tax_amount,
            'total_amount' => (float) $invoice->total_amount,
            'status' => $invoice->status,
            'due_date' => $invoice->due_date?->toDateString(),
            'paid_at' => $invoice->paid_at?->toIso8601String(),
            'period_start' => $invoice->period_start?->toDateString(),
            'period_end' => $invoice->period_end?->toDateString(),
            'package' => $invoice->subscription?->package?->only(['id', 'name', 'slug']),
            'created_at' => $invoice->created_at?->toIso8601String(),
        ]);

        return ApiResponse::success(
            $paginator->items(),
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

    public function showInvoice(Request $request, BillingInvoice $invoice): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.view');

        return ApiResponse::success($this->billingService->getInvoice($invoice));
    }

    public function paymentMethods(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.view');

        return ApiResponse::success($this->paymentService->listPaymentMethods());
    }

    public function initiatePayment(InitiatePaymentRequest $request, BillingInvoice $invoice): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.update');

        try {
            $result = $this->paymentService->initiatePayment(
                $invoice,
                $request->string('payment_method')->toString(),
                $request->boolean('enable_recurring'),
            );
        } catch (\InvalidArgumentException $e) {
            return ApiResponse::error($e->getMessage(), 422);
        } catch (\RuntimeException $e) {
            return ApiResponse::error($e->getMessage(), 500);
        }

        return ApiResponse::success($result, 'Pembayaran berhasil diproses');
    }

    public function paymentStatus(Request $request, BillingInvoice $invoice): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.view');

        return ApiResponse::success($this->paymentService->getPaymentStatus($invoice));
    }

    public function setupRecurring(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'tenant.settings.update');

        try {
            $result = $this->paymentService->setupRecurringSubscription();
        } catch (\InvalidArgumentException $e) {
            return ApiResponse::error($e->getMessage(), 422);
        } catch (\RuntimeException $e) {
            return ApiResponse::error($e->getMessage(), 500);
        }

        return ApiResponse::success($result, 'Setup langganan otomatis berhasil');
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses billing.');
        }
    }
}