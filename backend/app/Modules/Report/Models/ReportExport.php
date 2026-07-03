<?php

namespace App\Modules\Report\Models;

use App\Models\User;
use App\Shared\Traits\BelongsToTenant;
use App\Shared\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ReportExport extends Model
{
    use BelongsToTenant;
    use HasUuid;

    public $timestamps = false;

    protected $fillable = [
        'tenant_id',
        'uuid',
        'report_type',
        'format',
        'file_path',
        'status',
        'error_message',
        'filters',
        'created_by',
        'created_at',
        'generated_at',
    ];

    protected function casts(): array
    {
        return [
            'filters' => 'array',
            'created_at' => 'datetime',
            'generated_at' => 'datetime',
        ];
    }

    public function getStoragePathAttribute(): ?string
    {
        return $this->file_path;
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}