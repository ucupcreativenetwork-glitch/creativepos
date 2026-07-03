<?php

namespace App\Modules\CRM\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\CRM\Requests\UpdateWhatsappConfigRequest;
use App\Modules\CRM\Resources\FaqResource;
use App\Modules\CRM\Resources\KnowledgeBaseResource;
use App\Modules\CRM\Resources\WhatsappConfigResource;
use App\Modules\CRM\Services\KnowledgeBaseService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class KnowledgeBaseController extends Controller
{
    public function __construct(
        private readonly KnowledgeBaseService $knowledgeBaseService,
    ) {}

    public function knowledgeBase(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'crm.view');

        $categories = $this->knowledgeBaseService->knowledgeBase();

        return ApiResponse::success(KnowledgeBaseResource::collection($categories));
    }

    public function faqs(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'crm.view');

        $faqs = $this->knowledgeBaseService->faqs();

        return ApiResponse::success(FaqResource::collection($faqs));
    }

    public function showWhatsappConfig(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'crm.view');

        $config = $this->knowledgeBaseService->getWhatsappConfig();

        if (! $config) {
            return ApiResponse::success([
                'phone_number' => null,
                'api_token_set' => false,
                'webhook_secret' => null,
                'is_active' => false,
            ]);
        }

        return ApiResponse::success(new WhatsappConfigResource($config));
    }

    public function updateWhatsappConfig(UpdateWhatsappConfigRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'crm.update');

        $config = $this->knowledgeBaseService->updateWhatsappConfig($request->validated());

        return ApiResponse::success(new WhatsappConfigResource($config));
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses CRM.');
        }
    }
}