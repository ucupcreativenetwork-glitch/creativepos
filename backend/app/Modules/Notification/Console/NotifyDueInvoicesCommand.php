<?php

namespace App\Modules\Notification\Console;

use App\Modules\Billing\Models\BillingInvoice;
use App\Modules\Notification\Events\InvoiceDueEvent;
use App\Modules\Platform\Models\Tenant;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Event;

class NotifyDueInvoicesCommand extends Command
{
    protected $signature = 'notifications:invoice-due {--days=0 : Hari sebelum/sesudah jatuh tempo}';

    protected $description = 'Kirim notifikasi tagihan jatuh tempo via email, WhatsApp, dan push';

    public function handle(): int
    {
        $days = (int) $this->option('days');
        $targetDate = now()->addDays($days)->toDateString();

        $invoices = BillingInvoice::query()
            ->withoutGlobalScopes()
            ->with('tenant')
            ->whereIn('status', ['sent', 'overdue'])
            ->whereDate('due_date', '<=', $targetDate)
            ->get();

        $count = 0;

        foreach ($invoices as $invoice) {
            if ($invoice->tenant) {
                set_tenant($invoice->tenant);
            }

            $dedupKey = 'invoice_due:'.$invoice->id.':'.now()->toDateString();

            Event::dispatch(new InvoiceDueEvent($invoice, $dedupKey));

            if ($invoice->status === 'sent' && $invoice->due_date?->isPast()) {
                $invoice->update(['status' => 'overdue']);
            }

            $count++;
        }

        $this->info("Dispatched {$count} invoice due notification(s).");

        return self::SUCCESS;
    }
}