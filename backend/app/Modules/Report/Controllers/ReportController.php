<?php

namespace App\Modules\Report\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Report\Models\ReportExport;
use App\Modules\Report\Services\ReportService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ReportController extends Controller
{
    public function __construct(
        private readonly ReportService $reportService,
    ) {}

    public function sales(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'report.view');

        $data = $this->reportService->getSalesReport(
            $request->integer('outlet_id') ?: null,
            $request->input('date_from'),
            $request->input('date_to'),
            $request->input('type', 'daily'),
        );

        return ApiResponse::success($data);
    }

    public function products(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'report.view');

        $data = $this->reportService->getProductsReport(
            $request->integer('outlet_id') ?: null,
            $request->input('date_from'),
            $request->input('date_to'),
            $request->integer('limit', 20),
        );

        return ApiResponse::success($data);
    }

    public function inventory(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'report.view');

        $data = $this->reportService->getInventoryReport(
            $request->integer('outlet_id') ?: null,
            $request->input('date_from'),
            $request->input('date_to'),
        );

        return ApiResponse::success($data);
    }

    public function members(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'report.view');

        $data = $this->reportService->getMembersReport(
            $request->input('date_from'),
            $request->input('date_to'),
            $request->input('type', 'daily'),
        );

        return ApiResponse::success($data);
    }

    public function profitLoss(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'report.view');
        $this->requireFullReport();

        $data = $this->reportService->getProfitLossReport(
            $request->integer('outlet_id') ?: null,
            $request->input('date_from'),
            $request->input('date_to'),
        );

        return ApiResponse::success($data);
    }

    public function cashFlow(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'report.view');
        $this->requireFullReport();

        $data = $this->reportService->getCashFlowReport(
            $request->integer('outlet_id') ?: null,
            $request->input('date_from'),
            $request->input('date_to'),
        );

        return ApiResponse::success($data);
    }

    public function export(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'report.export');

        $validated = $request->validate([
            'report_type' => 'required|in:sales,products,inventory',
            'format' => 'required|in:xlsx,pdf,csv',
            'filters' => 'sometimes|array',
            'date_from' => 'sometimes|date',
            'date_to' => 'sometimes|date',
            'outlet_id' => 'sometimes|integer',
            'type' => 'sometimes|in:daily,weekly,monthly',
            'limit' => 'sometimes|integer|min:1|max:500',
        ]);

        $filters = array_merge(
            $validated['filters'] ?? [],
            array_filter([
                'date_from' => $validated['date_from'] ?? null,
                'date_to' => $validated['date_to'] ?? null,
                'outlet_id' => $validated['outlet_id'] ?? null,
                'type' => $validated['type'] ?? null,
                'limit' => $validated['limit'] ?? null,
            ], fn ($value) => $value !== null),
        );

        $export = $this->reportService->createExport(
            $validated['report_type'],
            $validated['format'],
            $filters,
            $request->user()?->id,
        );

        return ApiResponse::created($this->formatExportResponse($export));
    }

    public function showExport(Request $request, ReportExport $export): JsonResponse
    {
        $this->authorizePermission($request, 'report.view');

        return ApiResponse::success($this->formatExportResponse($export));
    }

    public function downloadExport(Request $request, ReportExport $export): StreamedResponse|JsonResponse
    {
        $this->authorizePermission($request, 'report.export');

        if ($export->status !== 'completed' || blank($export->file_path)) {
            return ApiResponse::error('File export belum tersedia.', 404);
        }

        if (! Storage::disk('local')->exists($export->file_path)) {
            return ApiResponse::error('File export tidak ditemukan.', 404);
        }

        $filename = basename($export->file_path);

        return Storage::disk('local')->download($export->file_path, $filename);
    }

    public function exports(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'report.view');

        $paginator = $this->reportService->listExports($request->integer('per_page', 15));

        $paginator->through(fn (ReportExport $item) => $this->formatExportResponse($item));

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

    /**
     * @return array<string, mixed>
     */
    protected function formatExportResponse(ReportExport $export): array
    {
        return [
            'uuid' => $export->uuid,
            'report_type' => $export->report_type,
            'format' => $export->format,
            'status' => $export->status,
            'storage_path' => $export->file_path,
            'error_message' => $export->error_message,
            'filters' => $export->filters,
            'generated_at' => $export->generated_at?->toIso8601String(),
            'created_at' => $export->created_at?->toIso8601String(),
            'download_url' => $export->status === 'completed'
                ? url('/api/v1/reports/export/'.$export->uuid.'/download')
                : null,
        ];
    }

    protected function requireFullReport(): void
    {
        $tenant = tenant();
        $subscription = $tenant?->activeSubscription;
        $package = $subscription?->package ?? $tenant?->trialPackage();

        if ($package === null || $package->getFeatureValue('report') === 'basic') {
            abort(403, 'Laporan laba rugi dan arus kas hanya tersedia pada paket Business ke atas.');
        }
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses laporan.');
        }
    }
}