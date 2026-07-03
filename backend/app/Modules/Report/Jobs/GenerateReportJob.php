<?php

namespace App\Modules\Report\Jobs;

use App\Modules\Platform\Models\Tenant;
use App\Modules\Report\Models\ReportExport;
use App\Modules\Report\Services\ReportExportGenerator;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class GenerateReportJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public int $tries = 2;

    public int $timeout = 300;

    public function __construct(
        public readonly int $exportId,
    ) {}

    public function handle(ReportExportGenerator $generator): void
    {
        $export = ReportExport::query()
            ->withoutGlobalScopes()
            ->find($this->exportId);

        if ($export === null) {
            return;
        }

        $tenant = Tenant::query()->find($export->tenant_id);

        if ($tenant !== null) {
            set_tenant($tenant);
        }

        $export->update([
            'status' => 'processing',
            'error_message' => null,
        ]);

        try {
            $path = $generator->generate($export);

            $export->update([
                'status' => 'completed',
                'file_path' => $path,
                'generated_at' => now(),
                'error_message' => null,
            ]);
        } catch (\Throwable $e) {
            Log::error('Report export failed', [
                'export_id' => $export->id,
                'uuid' => $export->uuid,
                'error' => $e->getMessage(),
            ]);

            $export->update([
                'status' => 'failed',
                'error_message' => $e->getMessage(),
            ]);

            throw $e;
        }
    }
}