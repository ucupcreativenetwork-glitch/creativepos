<?php

namespace App\Modules\Notification\Notifications;

use App\Modules\Billing\Models\BillingInvoice;
use App\Shared\Support\FrontendUrl;
use App\Modules\Notification\Enums\NotificationEvent;
use App\Modules\Notification\Services\NotificationPreferenceService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class InvoiceDueNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public readonly BillingInvoice $invoice,
        public readonly ?string $dedupKey = null,
    ) {}

    public function eventType(): NotificationEvent
    {
        return NotificationEvent::InvoiceDue;
    }

    public function dedupKey(): ?string
    {
        return $this->dedupKey;
    }

    /**
     * @return list<string|class-string>
     */
    public function via(object $notifiable): array
    {
        return app(NotificationPreferenceService::class)
            ->channelsFor($notifiable, NotificationEvent::InvoiceDue);
    }

    public function toMail(object $notifiable): MailMessage
    {
        $dueDate = $this->invoice->due_date?->format('d M Y') ?? '-';

        return (new MailMessage)
            ->subject('Tagihan Jatuh Tempo — '.$this->invoice->invoice_number)
            ->greeting('Halo '.$notifiable->name.',')
            ->line('Invoice langganan CreativePOS Anda jatuh tempo.')
            ->line('Invoice: '.$this->invoice->invoice_number)
            ->line('Total: Rp '.number_format((float) $this->invoice->total_amount, 0, ',', '.'))
            ->line('Jatuh tempo: '.$dueDate)
            ->action('Bayar Sekarang', FrontendUrl::path('settings?tab=subscription'))
            ->line('Terima kasih telah menggunakan CreativePOS.');
    }

    public function toWhatsapp(object $notifiable): string
    {
        $dueDate = $this->invoice->due_date?->format('d M Y') ?? '-';
        $total = number_format((float) $this->invoice->total_amount, 0, ',', '.');

        return implode("\n", [
            '*Tagihan Jatuh Tempo*',
            '',
            'Invoice: '.$this->invoice->invoice_number,
            'Total: Rp '.$total,
            'Jatuh tempo: '.$dueDate,
            '',
            'Silakan bayar melalui menu Pengaturan > Langganan di CreativePOS.',
        ]);
    }

    /**
     * @return array{title: string, body: string, data: array<string, mixed>}
     */
    public function toFirebase(object $notifiable): array
    {
        return [
            'title' => 'Tagihan Jatuh Tempo',
            'body' => $this->invoice->invoice_number.' — Rp '.number_format((float) $this->invoice->total_amount, 0, ',', '.'),
            'data' => [
                'event' => NotificationEvent::InvoiceDue->value,
                'invoice_id' => (string) $this->invoice->id,
                'invoice_number' => $this->invoice->invoice_number,
            ],
        ];
    }

    /**
     * @return array{type: string, title: string, body: string, data: array<string, mixed>}
     */
    public function toInApp(object $notifiable): array
    {
        return [
            'type' => NotificationEvent::InvoiceDue->value,
            'title' => 'Tagihan Jatuh Tempo',
            'body' => $this->invoice->invoice_number.' jatuh tempo '.$this->invoice->due_date?->format('d M Y'),
            'data' => [
                'invoice_id' => $this->invoice->id,
                'invoice_number' => $this->invoice->invoice_number,
                'total_amount' => (float) $this->invoice->total_amount,
                'due_date' => $this->invoice->due_date?->toDateString(),
            ],
        ];
    }
}