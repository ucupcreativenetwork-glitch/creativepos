<?php

namespace App\Modules\CRM\Repositories;

use App\Modules\CRM\Models\SupportTicket;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class TicketRepository
{
    public function paginate(
        ?string $status = null,
        ?string $priority = null,
        ?string $channel = null,
        ?int $assignedTo = null,
        ?string $search = null,
        int $perPage = 15,
    ): LengthAwarePaginator {
        $query = SupportTicket::query()
            ->with(['member:id,name,member_code', 'assignee:id,name,email'])
            ->orderByDesc('created_at');

        if ($search) {
            $term = '%'.$search.'%';
            $query->where(function ($q) use ($term) {
                $q->where('ticket_number', 'like', $term)
                    ->orWhere('subject', 'like', $term)
                    ->orWhere('customer_name', 'like', $term)
                    ->orWhere('customer_phone', 'like', $term);
            });
        }

        if ($status) {
            $query->where('status', $status);
        }

        if ($priority) {
            $query->where('priority', $priority);
        }

        if ($channel) {
            $query->where('channel', $channel);
        }

        if ($assignedTo) {
            $query->where('assigned_to', $assignedTo);
        }

        return $query->paginate($perPage);
    }

    public function findByUuid(string $uuid): ?SupportTicket
    {
        return SupportTicket::query()
            ->with([
                'member:id,name,member_code,email,phone',
                'assignee:id,name,email',
                'messages.sender:id,name',
                'statusHistories.changer:id,name',
            ])
            ->where('uuid', $uuid)
            ->first();
    }

    public function create(array $data): SupportTicket
    {
        return SupportTicket::query()->create($data);
    }

    public function update(SupportTicket $ticket, array $data): SupportTicket
    {
        $ticket->update($data);

        return $ticket->fresh();
    }

    public function countToday(): int
    {
        return SupportTicket::query()->whereDate('created_at', today())->count();
    }
}