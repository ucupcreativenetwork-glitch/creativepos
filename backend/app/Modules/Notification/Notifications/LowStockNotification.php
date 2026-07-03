<?php

namespace App\Modules\Notification\Notifications;

use App\Modules\Inventory\Models\Product;
use App\Shared\Support\FrontendUrl;
use App\Modules\Inventory\Models\ProductStock;
use App\Modules\Notification\Enums\NotificationEvent;
use App\Modules\Notification\Services\NotificationPreferenceService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class LowStockNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public readonly Product $product,
        public readonly ProductStock $stock,
        public readonly float $quantity,
        public readonly int $minStock,
        public readonly ?string $dedupKey = null,
    ) {}

    public function eventType(): NotificationEvent
    {
        return NotificationEvent::LowStock;
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
            ->channelsFor($notifiable, NotificationEvent::LowStock);
    }

    public function toMail(object $notifiable): MailMessage
    {
        $warehouse = $this->stock->warehouse?->name ?? 'Gudang';

        return (new MailMessage)
            ->subject('Stok Menipis — '.$this->product->name)
            ->greeting('Halo '.$notifiable->name.',')
            ->line('Stok produk berikut sudah di bawah batas minimum.')
            ->line('Produk: '.$this->product->name.' ('.$this->product->sku.')')
            ->line('Gudang: '.$warehouse)
            ->line('Stok saat ini: '.$this->quantity.' (min: '.$this->minStock.')')
            ->action('Lihat Inventori', FrontendUrl::path('inventory'));
    }

    public function toWhatsapp(object $notifiable): string
    {
        $warehouse = $this->stock->warehouse?->name ?? 'Gudang';

        return implode("\n", [
            '*Stok Menipis*',
            '',
            'Produk: '.$this->product->name,
            'SKU: '.$this->product->sku,
            'Gudang: '.$warehouse,
            'Stok: '.$this->quantity.' (min: '.$this->minStock.')',
            '',
            'Segera lakukan restock melalui menu Inventori.',
        ]);
    }

    /**
     * @return array{title: string, body: string, data: array<string, mixed>}
     */
    public function toFirebase(object $notifiable): array
    {
        return [
            'title' => 'Stok Menipis',
            'body' => $this->product->name.' — sisa '.$this->quantity,
            'data' => [
                'event' => NotificationEvent::LowStock->value,
                'product_id' => (string) $this->product->id,
                'warehouse_id' => (string) $this->stock->warehouse_id,
            ],
        ];
    }

    /**
     * @return array{type: string, title: string, body: string, data: array<string, mixed>}
     */
    public function toInApp(object $notifiable): array
    {
        return [
            'type' => NotificationEvent::LowStock->value,
            'title' => 'Stok Menipis',
            'body' => $this->product->name.' sisa '.$this->quantity.' (min '.$this->minStock.')',
            'data' => [
                'product_id' => $this->product->id,
                'product_name' => $this->product->name,
                'sku' => $this->product->sku,
                'warehouse_id' => $this->stock->warehouse_id,
                'quantity' => $this->quantity,
                'min_stock' => $this->minStock,
            ],
        ];
    }
}