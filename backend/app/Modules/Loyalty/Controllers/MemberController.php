<?php

namespace App\Modules\Loyalty\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Loyalty\Models\Member;
use App\Modules\Loyalty\Models\TierConfig;
use App\Modules\Loyalty\Requests\StoreMemberRequest;
use App\Modules\Loyalty\Requests\UpdateMemberRequest;
use App\Modules\Loyalty\Resources\MemberResource;
use App\Modules\Loyalty\Services\MemberService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MemberController extends Controller
{
    public function __construct(
        private readonly MemberService $memberService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'loyalty.view');

        $paginator = $this->memberService->list(
            $request->input('search'),
            $request->input('status'),
            $request->integer('per_page', 15),
        );

        return ApiResponse::success(
            MemberResource::collection($paginator->items()),
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

    public function show(Request $request, Member $member): JsonResponse
    {
        $this->authorizePermission($request, 'loyalty.view');

        $member = $this->memberService->findByUuid($member->uuid);

        return ApiResponse::success(new MemberResource($member));
    }

    public function findByCode(Request $request, string $code): JsonResponse
    {
        $this->authorizePermission($request, 'loyalty.view');

        return ApiResponse::success(
            new MemberResource($this->memberService->findByCode($code))
        );
    }

    public function findByQr(Request $request, string $token): JsonResponse
    {
        $this->authorizePermission($request, 'loyalty.view');

        return ApiResponse::success(
            new MemberResource($this->memberService->findByQrToken($token))
        );
    }

    public function store(StoreMemberRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'loyalty.create');

        $member = $this->memberService->create($request->validated());

        return ApiResponse::created(new MemberResource($member));
    }

    public function update(UpdateMemberRequest $request, Member $member): JsonResponse
    {
        $this->authorizePermission($request, 'loyalty.update');

        $member = $this->memberService->update($member, $request->validated());

        return ApiResponse::success(new MemberResource($member));
    }

    public function tiers(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'loyalty.view');

        $tiers = TierConfig::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        return ApiResponse::success($tiers->map(fn ($t) => [
            'id' => $t->id,
            'name' => $t->name,
            'slug' => $t->slug,
            'min_spend' => (float) $t->min_spend,
            'point_multiplier' => (float) $t->point_multiplier,
        ]));
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses member.');
        }
    }
}