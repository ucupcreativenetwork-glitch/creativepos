<?php

namespace App\Modules\CRM\Models;

use App\Models\User;
use App\Modules\Loyalty\Models\Member;
use App\Shared\Traits\BelongsToTenant;
use App\Shared\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class SupportTicket extends Model
{
    use BelongsToTenant;
    use HasUuid;

    protected $table = 'support_tickets';

    protected $fillable = [
        'tenant_id',
        'uuid',
        'ticket_number',
        'member_id',
        'customer_name',
        'customer_email',
        'customer_phone',
        'channel',
        'subject',
        'priority',
        'status',
        'assigned_to',
        'sla_deadline',
        'first_response_at',
        'resolved_at',
        'closed_at',
        'rating',
        'rating_comment',
    ];

    protected function casts(): array
    {
        return [
            'sla_deadline' => 'datetime',
            'first_response_at' => 'datetime',
            'resolved_at' => 'datetime',
            'closed_at' => 'datetime',
            'rating' => 'integer',
        ];
    }

    public function member(): BelongsTo
    {
        return $this->belongsTo(Member::class);
    }

    public function assignee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_to');
    }

    public function messages(): HasMany
    {
        return $this->hasMany(TicketMessage::class, 'ticket_id');
    }

    public function statusHistories(): HasMany
    {
        return $this->hasMany(TicketStatusHistory::class, 'ticket_id');
    }
}