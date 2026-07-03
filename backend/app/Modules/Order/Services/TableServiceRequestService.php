<?php

namespace App\Modules\Order\Services;

use App\Models\User;
use App\Modules\Notification\Enums\NotificationEvent;
use App\Modules\Notification\Notifications\TableServiceRequestNotification;
use App\Modules\Notification\Services\RecipientResolver;
use App\Modules\Order\Models\TableQrCode;
use App\Modules\Order\Models\TableServiceRequest;
use App\Modules\Tenant\Models\Outlet;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Str;

class TableServiceRequestService
{
    public function __construct(
        private readonly RecipientResolver $recipientResolver,
    ) {}

    public function create(string $type, TableQrCode $qr, Outlet $outlet): TableServiceRequest
    {
        $qr->loadMissing(['table.area']);

        $request = TableServiceRequest::query()->create([
            'uuid' => (string) Str::uuid(),
            'tenant_id' => tenant('id'),
            'outlet_id' => $outlet->id,
            'table_id' => $qr->table_id,
            'type' => $type,
            'status' => 'pending',
            'table_token' => $qr->qr_token,
            'table_number' => $qr->table?->table_number,
            'table_area' => $qr->table?->area?->name,
            'created_at' => now(),
        ]);

        $recipients = $this->recipientResolver->resolve(
            NotificationEvent::TableServiceRequest,
            $outlet->id,
        );

        if ($recipients->isNotEmpty()) {
            Notification::send($recipients, new TableServiceRequestNotification($request));
        }

        return $request->fresh(['outlet']);
    }

    public function list(?int $outletId, ?string $status, int $perPage = 20): LengthAwarePaginator
    {
        return TableServiceRequest::query()
            ->with(['outlet:id,name'])
            ->when($outletId, fn ($q) => $q->where('outlet_id', $outletId))
            ->when($status, fn ($q) => $q->where('status', $status))
            ->orderByDesc('created_at')
            ->paginate($perPage);
    }

    public function acknowledge(TableServiceRequest $request, User $user): TableServiceRequest
    {
        if ($request->status !== 'pending') {
            abort(422, 'Permintaan sudah ditangani.');
        }

        $request->update([
            'status' => 'acknowledged',
            'acknowledged_by' => $user->id,
            'acknowledged_at' => now(),
        ]);

        return $request->fresh(['outlet']);
    }
}