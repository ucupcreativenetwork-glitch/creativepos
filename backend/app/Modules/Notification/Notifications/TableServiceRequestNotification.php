<?php

namespace App\Modules\Notification\Notifications;

use App\Modules\Notification\Enums\NotificationEvent;
use App\Modules\Notification\Services\NotificationPreferenceService;
use App\Modules\Order\Models\TableServiceRequest;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class TableServiceRequestNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public readonly TableServiceRequest $request,
    ) {}

    public function eventType(): NotificationEvent
    {
        return NotificationEvent::TableServiceRequest;
    }

    /**
     * @return list<string|class-string>
     */
    public function via(object $notifiable): array
    {
        return app(NotificationPreferenceService::class)
            ->channelsFor($notifiable, NotificationEvent::TableServiceRequest);
    }

    /**
     * @return array{title: string, body: string, data: array<string, mixed>}
     */
    public function toFirebase(object $notifiable): array
    {
        $label = $this->typeLabel();

        return [
            'title' => $label,
            'body' => $this->tableLabel(),
            'data' => [
                'event' => NotificationEvent::TableServiceRequest->value,
                'type' => 'table_service',
                'request_uuid' => $this->request->uuid,
                'outlet_id' => (string) $this->request->outlet_id,
            ],
        ];
    }

    /**
     * @return array{type: string, title: string, body: string, data: array<string, mixed>}
     */
    public function toInApp(object $notifiable): array
    {
        return [
            'type' => NotificationEvent::TableServiceRequest->value,
            'title' => $this->typeLabel(),
            'body' => $this->tableLabel(),
            'data' => [
                'request_uuid' => $this->request->uuid,
                'request_type' => $this->request->type,
                'outlet_id' => $this->request->outlet_id,
                'table_number' => $this->request->table_number,
                'table_area' => $this->request->table_area,
            ],
        ];
    }

    protected function typeLabel(): string
    {
        return match ($this->request->type) {
            'call_waiter' => 'Panggilan Pelayan',
            'request_bill' => 'Permintaan Tagihan',
            default => 'Permintaan Meja',
        };
    }

    protected function tableLabel(): string
    {
        $parts = array_filter([
            $this->request->table_number ? 'Meja '.$this->request->table_number : null,
            $this->request->table_area,
        ]);

        return $parts !== [] ? implode(' · ', $parts) : 'Meja tamu';
    }
}