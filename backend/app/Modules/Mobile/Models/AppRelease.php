<?php

namespace App\Modules\Mobile\Models;

use Illuminate\Database\Eloquent\Model;

class AppRelease extends Model
{
    protected $fillable = [
        'platform',
        'version',
        'build_number',
        'apk_path',
        'original_filename',
        'file_size',
        'checksum_sha256',
        'release_notes',
        'is_mandatory',
        'is_active',
        'published_at',
    ];

    protected function casts(): array
    {
        return [
            'build_number' => 'integer',
            'file_size' => 'integer',
            'is_mandatory' => 'boolean',
            'is_active' => 'boolean',
            'published_at' => 'datetime',
        ];
    }
}