<?php

namespace App\Modules\Settings\Controllers;

use App\Http\Controllers\Controller;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class UploadController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $this->authorizeUpload($request);

        $validated = $request->validate([
            'file' => 'required|file|max:5120|mimes:jpg,jpeg,png,webp,gif,svg',
            'type' => 'sometimes|string|in:logo,product,general',
        ]);

        $type = $validated['type'] ?? 'general';
        $tenantId = tenant('id');
        $file = $request->file('file');
        $extension = $file->getClientOriginalExtension();
        $filename = Str::uuid().'.'.$extension;
        $path = "uploads/{$tenantId}/{$type}/{$filename}";

        Storage::disk('public')->put($path, file_get_contents($file->getRealPath()));

        $url = Storage::disk('public')->url($path);

        return ApiResponse::created([
            'url' => $url,
            'path' => $path,
            'type' => $type,
            'original_name' => $file->getClientOriginalName(),
            'size' => $file->getSize(),
        ]);
    }

    protected function authorizeUpload(Request $request): void
    {
        $user = $request->user();

        if (! $user || $user->is_super_admin) {
            return;
        }

        $type = $request->input('type', 'general');

        if ($type === 'product' && ($user->can('inventory.create') || $user->can('inventory.update'))) {
            return;
        }

        if ($user->can('tenant.settings.update')) {
            return;
        }

        abort(403, 'Anda tidak memiliki izin untuk mengunggah file.');
    }
}