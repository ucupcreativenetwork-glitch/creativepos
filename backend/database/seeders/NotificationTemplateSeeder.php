<?php

namespace Database\Seeders;

use App\Modules\Notification\Models\NotificationTemplate;
use Illuminate\Database\Seeder;

class NotificationTemplateSeeder extends Seeder
{
    public function run(): void
    {
        $templates = [
            [
                'event' => 'invoice_due',
                'channel' => 'whatsapp',
                'subject' => null,
                'body' => "Tagihan jatuh tempo\nInvoice: {{invoice_number}}\nTotal: Rp {{total_amount}}\nJatuh tempo: {{due_date}}",
            ],
            [
                'event' => 'invoice_due',
                'channel' => 'email',
                'subject' => 'Tagihan Jatuh Tempo — {{invoice_number}}',
                'body' => 'Invoice {{invoice_number}} sebesar Rp {{total_amount}} jatuh tempo {{due_date}}.',
            ],
            [
                'event' => 'low_stock',
                'channel' => 'whatsapp',
                'subject' => null,
                'body' => "Stok menipis\nProduk: {{product_name}}\nSKU: {{sku}}\nStok: {{quantity}} (min: {{min_stock}})",
            ],
            [
                'event' => 'new_order',
                'channel' => 'whatsapp',
                'subject' => null,
                'body' => "Pesanan masuk\nOrder: {{order_number}}\nTipe: {{order_type}}\nTotal: Rp {{subtotal}}",
            ],
        ];

        foreach ($templates as $template) {
            NotificationTemplate::query()->firstOrCreate(
                [
                    'tenant_id' => null,
                    'event' => $template['event'],
                    'channel' => $template['channel'],
                ],
                [
                    'subject' => $template['subject'],
                    'body' => $template['body'],
                    'is_active' => true,
                ],
            );
        }
    }
}