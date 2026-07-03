<?php

namespace App\Modules\CRM\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\CRM\Models\SupportTicket;
use App\Modules\CRM\Requests\AssignTicketRequest;
use App\Modules\CRM\Requests\RateTicketRequest;
use App\Modules\CRM\Requests\StoreTicketMessageRequest;
use App\Modules\CRM\Requests\StoreTicketRequest;
use App\Modules\CRM\Requests\UpdateTicketStatusRequest;
use App\Modules\CRM\Resources\TicketResource;
use App\Modules\CRM\Services\TicketService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TicketController extends Controller
{
    public function __construct(
        private readonly TicketService $ticketService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'crm.view');

        $paginator = $this->ticketService->list(
            $request->input('status'),
            $request->input('priority'),
            $request->input('channel'),
            $request->integer('assigned_to') ?: null,
            $request->input('search'),
            $request->integer('per_page', 15),
        );

        return ApiResponse::success(
            TicketResource::collection($paginator->items()),
            'Operation successful',
            200,
            [
                'current_page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
            ],
        );
    }

    public function show(Request $request, SupportTicket $ticket): JsonResponse
    {
        $this->authorizePermission($request, 'crm.view');

        $ticket = $this->ticketService->findByUuid($ticket->uuid);

        return ApiResponse::success(new TicketResource($ticket));
    }

    public function store(StoreTicketRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'crm.create');

        $ticket = $this->ticketService->create($request->validated(), $request->user());

        return ApiResponse::created(new TicketResource($ticket));
    }

    public function assign(AssignTicketRequest $request, SupportTicket $ticket): JsonResponse
    {
        $this->authorizePermission($request, 'crm.assign');

        $ticket = $this->ticketService->assign(
            $ticket,
            $request->integer('assigned_to'),
            $request->user(),
        );

        return ApiResponse::success(new TicketResource($ticket));
    }

    public function updateStatus(UpdateTicketStatusRequest $request, SupportTicket $ticket): JsonResponse
    {
        $this->authorizePermission($request, 'crm.update');

        $ticket = $this->ticketService->updateStatus(
            $ticket,
            $request->input('status'),
            $request->user(),
        );

        return ApiResponse::success(new TicketResource($ticket));
    }

    public function storeMessage(StoreTicketMessageRequest $request, SupportTicket $ticket): JsonResponse
    {
        $permission = $request->input('sender_type') === 'agent' ? 'crm.update' : 'crm.create';
        $this->authorizePermission($request, $permission);

        $ticket = $this->ticketService->addMessage(
            $ticket,
            $request->input('message'),
            $request->input('sender_type'),
            $request->user(),
            $request->boolean('is_internal'),
        );

        return ApiResponse::created(new TicketResource($ticket));
    }

    public function rate(RateTicketRequest $request, SupportTicket $ticket): JsonResponse
    {
        $this->authorizePermission($request, 'crm.update');

        $ticket = $this->ticketService->rate(
            $ticket,
            $request->integer('rating'),
            $request->input('rating_comment'),
        );

        return ApiResponse::success(new TicketResource($ticket));
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses CRM.');
        }
    }
}