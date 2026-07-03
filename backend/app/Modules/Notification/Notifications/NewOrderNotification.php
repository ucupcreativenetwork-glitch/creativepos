<?php

namespace App\Modules\Notification\Notifications;

use App\Modules\Notification\Enums\NotificationEvent;
use App\Modules\Notification\Services\NotificationPreferenceService;
use App\Modules\Order\Models\Order;
use App\Shared\Support\FrontendUrl;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class NewOrderNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public readonly Order $order,
    ) {}

    public function eventType(): NotificationEvent
    {
        return NotificationEvent::NewOrder;
    }

    /**
     * @return list<string|class-string>
     */
    public function via(object $notifiable): array
    {
        return app(NotificationPreferenceService::class)
            ->channelsFor($notifiable, NotificationEvent::NewOrder);
    }

    public function toMail(object $notifiable): MailMessage
    {
        $itemCount = $this->order->items()->count();

        return (new MailMessage)
            ->subject('Pesanan Baru — '.$this->order->order_number)
            ->greeting('Halo '.$notifiable->name.',')
            ->line('Pesanan baru telah masuk.')
            ->line('No. Order: '.$this->order->order_number)
            ->line('Tipe: '.$this->order->order_type)
            ->line('Sumber: '.$this->order->source)
            ->line('Item: '.$itemCount)
            ->line('Total: Rp '.number_format((float) $this->order->subtotal, 0, ',', '.'))
            ->action('Lihat Dapur', FrontendUrl::path('kitchen'));
    }

    public function toWhatsapp(object $notifiable): string
    {
        $itemCount = $this->order->items()->count();
        $total = number_format((float) $this->order->subtotal, 0, ',', '.');

        return implode("\n", [
            '*Pesanan Masuk*',
            '',
            'Order: '.$this->order->order_number,
            'Tipe: '.$this->order->order_type,
            'Sumber: '.$this->order->source,
            'Item: '.$itemCount,
            'Total: Rp '.$total,
            '',
            'Segera proses di Kitchen Display.',
        ]);
    }

    /**
     * @return array{title: string, body: string, data: array<string, mixed>}
     */
    public function toFirebase(object $notifiable): array
    {
        return [
            'title' => 'Pesanan Masuk',
            'body' => $this->order->order_number.' — '.$this->order->order_type,
            'data' => [
                'event' => NotificationEvent::NewOrder->value,
                'order_id' => (string) $this->order->id,
                'order_uuid' => $this->order->uuid,
                'outlet_id' => (string) $this->order->outlet_id,
            ],
        ];
    }

    /**
     * @return array{type: string, title: string, body: string, data: array<string, mixed>}
     */
    public function toInApp(object $notifiable): array
    {
        return [
            'type' => NotificationEvent::NewOrder->value,
            'title' => 'Pesanan Masuk',
            'body' => $this->order->order_number.' — '.$this->order->order_type,
            'data' => [
                'order_id' => $this->order->id,
                'order_uuid' => $this->order->uuid,
                'order_number' => $this->order->order_number,
                'outlet_id' => $this->order->outlet_id,
                'order_type' => $this->order->order_type,
                'source' => $this->order->source,
            ],
        ];
    }
}