<?php

namespace App\Modules\Loyalty\Services;

use App\Modules\Loyalty\Models\Member;
use App\Modules\Loyalty\Models\TierConfig;
use App\Shared\Services\PackageLimitService;
use App\Modules\Loyalty\Repositories\MemberRepository;
use App\Modules\Loyalty\Repositories\PointRepository;
use App\Modules\Loyalty\Repositories\WalletRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Str;

class MemberService
{
    public function __construct(
        private readonly MemberRepository $members,
        private readonly PointRepository $points,
        private readonly WalletRepository $wallets,
    ) {}

    public function list(?string $search = null, ?string $status = null, int $perPage = 15): LengthAwarePaginator
    {
        return $this->members->paginateFiltered($perPage, $search, $status);
    }

    public function findByUuid(string $uuid): Member
    {
        $member = $this->members->findWithRelations($uuid);

        if (! $member) {
            abort(404, 'Member tidak ditemukan.');
        }

        return $member;
    }

    public function findByCode(string $code): Member
    {
        $member = $this->members->findByCode($code);

        if (! $member) {
            abort(404, 'Member tidak ditemukan.');
        }

        return $member;
    }

    public function findByQrToken(string $token): Member
    {
        $member = $this->members->findByQrToken($token);

        if (! $member) {
            abort(404, 'Member tidak ditemukan.');
        }

        return $member;
    }

    public function create(array $data): Member
    {
        app(LoyaltyBootstrapService::class)->ensureDefaults();
        app(PackageLimitService::class)->assertCanCreateMember();

        $data['member_code'] = $data['member_code'] ?? $this->generateMemberCode();
        $data['qr_token'] = Str::random(32);
        $data['tier_id'] = $data['tier_id'] ?? $this->defaultTierId();

        $member = $this->members->create($data);

        $this->points->findOrCreateMemberPoints($member->id);
        $this->wallets->findOrCreate($member->id);

        return $this->members->findWithRelations($member->uuid);
    }

    public function update(Member $member, array $data): Member
    {
        $this->members->update($member, $data);

        return $this->members->findWithRelations($member->uuid);
    }

    public function recordVisit(Member $member, float $spendAmount): Member
    {
        $member->increment('visit_count');
        $member->increment('total_spend', $spendAmount);
        $member->update(['last_visit_at' => now()]);

        $this->assignTierBySpend($member->fresh());

        return $this->members->findWithRelations($member->uuid);
    }

    protected function generateMemberCode(): string
    {
        $count = $this->members->countMembers();

        return 'MBR-'.str_pad((string) ($count + 1), 5, '0', STR_PAD_LEFT);
    }

    protected function defaultTierId(): ?int
    {
        return TierConfig::query()
            ->where('slug', 'bronze')
            ->where('is_active', true)
            ->value('id');
    }

    protected function assignTierBySpend(Member $member): void
    {
        $tier = TierConfig::query()
            ->where('is_active', true)
            ->where('min_spend', '<=', $member->total_spend)
            ->orderByDesc('min_spend')
            ->first();

        if ($tier && $member->tier_id !== $tier->id) {
            $member->update(['tier_id' => $tier->id]);
        }
    }
}