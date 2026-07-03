<?php

namespace App\Modules\Notification\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Notification\Services\NotificationService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function __construct(
        private readonly NotificationService $notificationService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $paginator = $this->notificationService->listForUser(
            $request->user(),
            $request->integer('per_page', 20),
        );

        return ApiResponse::success(
            collect($paginator->items())->map(fn ($n) => [
                'id' => $n->id,
                'type' => $n->type,
                'title' => $n->title,
                'body' => $n->body,
                'data' => $n->data,
                'read_at' => $n->read_at?->toIso8601String(),
                'created_at' => $n->created_at?->toIso8601String(),
            ])->all(),
            'Operation successful',
            200,
            [
                'current_page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
                'unread_count' => $this->notificationService->unreadCount($request->user()),
            ],
        );
    }

    public function unreadCount(Request $request): JsonResponse
    {
        return ApiResponse::success([
            'count' => $this->notificationService->unreadCount($request->user()),
        ]);
    }

    public function markRead(Request $request, int $notification): JsonResponse
    {
        $item = $this->notificationService->markAsRead($request->user(), $notification);

        return ApiResponse::success([
            'id' => $item->id,
            'read_at' => $item->read_at?->toIso8601String(),
        ]);
    }

    public function markAllRead(Request $request): JsonResponse
    {
        $count = $this->notificationService->markAllAsRead($request->user());

        return ApiResponse::success(['updated' => $count]);
    }

    public function preferences(Request $request): JsonResponse
    {
        return ApiResponse::success(
            $this->notificationService->getPreferences($request->user()),
        );
    }

    public function updatePreferences(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'preferences' => ['required', 'array'],
            'preferences.*.event' => ['required', 'string', 'in:invoice_due,low_stock,new_order'],
            'preferences.*.channel' => ['required', 'string', 'in:email,whatsapp,push,in_app'],
            'preferences.*.is_enabled' => ['required', 'boolean'],
        ]);

        $this->notificationService->updatePreferences(
            $request->user(),
            $validated['preferences'],
        );

        return ApiResponse::success(
            $this->notificationService->getPreferences($request->user()),
            'Preferensi notifikasi disimpan',
        );
    }
}