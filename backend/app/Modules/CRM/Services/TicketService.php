<?php

namespace App\Modules\CRM\Services;

use App\Models\User;
use App\Modules\CRM\Models\SupportTicket;
use App\Modules\CRM\Models\TicketMessage;
use App\Modules\CRM\Models\TicketStatusHistory;
use App\Modules\CRM\Repositories\TicketRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class TicketService
{
    public function __construct(
        private readonly TicketRepository $repository,
    ) {}

    public function list(
        ?string $status = null,
        ?string $priority = null,
        ?string $channel = null,
        ?int $assignedTo = null,
        ?string $search = null,
        int $perPage = 15,
    ): LengthAwarePaginator {
        return $this->repository->paginate($status, $priority, $channel, $assignedTo, $search, $perPage);
    }

    public function findByUuid(string $uuid): SupportTicket
    {
        $ticket = $this->repository->findByUuid($uuid);

        if (! $ticket) {
            abort(404, 'Tiket tidak ditemukan.');
        }

        return $ticket;
    }

    public function create(array $data, ?User $user = null): SupportTicket
    {
        return DB::transaction(function () use ($data, $user) {
            $priority = $data['priority'] ?? 'medium';
            $count = $this->repository->countToday();

            $ticket = $this->repository->create([
                'tenant_id' => tenant('id'),
                'ticket_number' => 'TKT-'.now()->format('Ymd').'-'.str_pad((string) ($count + 1), 4, '0', STR_PAD_LEFT),
                'member_id' => $data['member_id'] ?? null,
                'customer_name' => $data['customer_name'] ?? null,
                'customer_email' => $data['customer_email'] ?? null,
                'customer_phone' => $data['customer_phone'] ?? null,
                'channel' => $data['channel'] ?? 'website',
                'subject' => $data['subject'],
                'priority' => $priority,
                'status' => 'open',
                'sla_deadline' => $data['sla_deadline'] ?? $this->calculateSlaDeadline($priority),
            ]);

            $this->recordStatus($ticket, null, 'open', $user?->id);

            TicketMessage::query()->create([
                'ticket_id' => $ticket->id,
                'sender_type' => 'system',
                'sender_id' => null,
                'message' => 'Tiket dukungan telah dibuat.',
                'is_internal' => false,
                'created_at' => now(),
            ]);

            if (! empty($data['message'])) {
                TicketMessage::query()->create([
                    'ticket_id' => $ticket->id,
                    'sender_type' => 'customer',
                    'sender_id' => null,
                    'message' => $data['message'],
                    'is_internal' => false,
                    'created_at' => now(),
                ]);
            }

            return $this->repository->findByUuid($ticket->uuid);
        });
    }

    public function assign(SupportTicket $ticket, int $assignedTo, ?User $user = null): SupportTicket
    {
        return DB::transaction(function () use ($ticket, $assignedTo, $user) {
            $from = $ticket->status;

            $this->repository->update($ticket, [
                'assigned_to' => $assignedTo,
                'status' => 'assigned',
            ]);

            if ($from !== 'assigned') {
                $this->recordStatus($ticket, $from, 'assigned', $user?->id);
            }

            TicketMessage::query()->create([
                'ticket_id' => $ticket->id,
                'sender_type' => 'system',
                'sender_id' => null,
                'message' => 'Tiket ditugaskan ke agen.',
                'is_internal' => true,
                'created_at' => now(),
            ]);

            return $this->repository->findByUuid($ticket->uuid);
        });
    }

    public function updateStatus(
        SupportTicket $ticket,
        string $status,
        ?User $user = null,
    ): SupportTicket {
        $allowed = ['open', 'assigned', 'pending', 'resolved', 'closed'];

        if (! in_array($status, $allowed, true)) {
            abort(422, 'Status tidak valid.');
        }

        return DB::transaction(function () use ($ticket, $status, $user) {
            $from = $ticket->status;
            $extra = ['status' => $status];

            if ($status === 'resolved' && ! $ticket->resolved_at) {
                $extra['resolved_at'] = now();
            }

            if ($status === 'closed' && ! $ticket->closed_at) {
                $extra['closed_at'] = now();
            }

            $this->repository->update($ticket, $extra);

            if ($from !== $status) {
                $this->recordStatus($ticket, $from, $status, $user?->id);
            }

            return $this->repository->findByUuid($ticket->uuid);
        });
    }

    public function addMessage(
        SupportTicket $ticket,
        string $message,
        string $senderType,
        ?User $user = null,
        bool $isInternal = false,
    ): SupportTicket {
        $allowedSenderTypes = ['customer', 'agent'];

        if (! in_array($senderType, $allowedSenderTypes, true)) {
            abort(422, 'Tipe pengirim tidak valid.');
        }

        return DB::transaction(function () use ($ticket, $message, $senderType, $user, $isInternal) {
            TicketMessage::query()->create([
                'ticket_id' => $ticket->id,
                'sender_type' => $senderType,
                'sender_id' => $senderType === 'agent' ? $user?->id : null,
                'message' => $message,
                'is_internal' => $isInternal,
                'created_at' => now(),
            ]);

            if ($senderType === 'agent' && ! $ticket->first_response_at && ! $isInternal) {
                $this->repository->update($ticket, ['first_response_at' => now()]);
            }

            return $this->repository->findByUuid($ticket->uuid);
        });
    }

    public function rate(SupportTicket $ticket, int $rating, ?string $comment = null): SupportTicket
    {
        if ($rating < 1 || $rating > 5) {
            abort(422, 'Rating harus antara 1 dan 5.');
        }

        if (! in_array($ticket->status, ['resolved', 'closed'], true)) {
            abort(422, 'Tiket hanya dapat dinilai setelah diselesaikan.');
        }

        $this->repository->update($ticket, [
            'rating' => $rating,
            'rating_comment' => $comment,
        ]);

        return $this->repository->findByUuid($ticket->uuid);
    }

    protected function calculateSlaDeadline(string $priority): \Illuminate\Support\Carbon
    {
        return match ($priority) {
            'low' => now()->addHours(48),
            'high' => now()->addHours(8),
            'critical' => now()->addHours(2),
            default => now()->addHours(24),
        };
    }

    protected function recordStatus(
        SupportTicket $ticket,
        ?string $from,
        string $to,
        ?int $userId,
    ): void {
        TicketStatusHistory::query()->create([
            'ticket_id' => $ticket->id,
            'from_status' => $from,
            'to_status' => $to,
            'changed_by' => $userId,
            'created_at' => now(),
        ]);
    }
}