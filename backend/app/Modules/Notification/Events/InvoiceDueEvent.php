<?php

namespace App\Modules\Notification\Events;

use App\Modules\Billing\Models\BillingInvoice;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class InvoiceDueEvent
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(
        public readonly BillingInvoice $invoice,
        public readonly ?string $dedupKey = null,
    ) {}
}