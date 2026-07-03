<?php

namespace App\Modules\Platform\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Billing\Models\BillingInvoice;
use App\Modules\Platform\Services\PlatformBillingService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BillingAdminController extends Controller
{
    public function __construct(
        private readonly PlatformBillingService $billingService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorizePlatform($request);

        $paginator = $this->billingService->listInvoices(
            $request->input('status'),
            $request->integer('tenant_id') ?: null,
            $request->integer('per_page', 15),
        );

        $paginator->through(fn (BillingInvoice $invoice) => [
            'id' => $invoice->id,
            'tenant_id' => $invoice->tenant_id,
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

    public function store(Request $request): JsonResponse
    {
        $this->authorizePlatform($request);

        $validated = $request->validate([
            'tenant_id' => 'required|exists:tenants,id',
            'subscription_id' => 'sometimes|exists:subscriptions,id',
            'package_id' => 'sometimes|exists:packages,id',
            'billing_cycle' => 'sometimes|in:monthly,yearly',
            'tax_rate' => 'sometimes|numeric|min:0|max:100',
            'status' => 'sometimes|in:draft,sent,paid,overdue,cancelled',
            'due_date' => 'sometimes|date',
            'period_start' => 'sometimes|date',
            'period_end' => 'sometimes|date',
        ]);

        $invoice = $this->billingService->generateInvoice($validated);

        return ApiResponse::created([
            'id' => $invoice->id,
            'tenant_id' => $invoice->tenant_id,
            'invoice_number' => $invoice->invoice_number,
            'amount' => (float) $invoice->amount,
            'tax_amount' => (float) $invoice->tax_amount,
            'total_amount' => (float) $invoice->total_amount,
            'status' => $invoice->status,
            'due_date' => $invoice->due_date?->toDateString(),
            'period_start' => $invoice->period_start?->toDateString(),
            'period_end' => $invoice->period_end?->toDateString(),
        ]);
    }

    protected function authorizePlatform(Request $request): void
    {
        if (! $request->user()?->is_super_admin) {
            abort(403, 'Super admin access required.');
        }
    }
}