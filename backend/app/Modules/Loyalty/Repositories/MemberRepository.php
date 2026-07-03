<?php

namespace App\Modules\Loyalty\Repositories;

use App\Modules\Loyalty\Models\Member;
use App\Shared\Repositories\BaseRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class MemberRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct(new Member);
    }

    public function paginateFiltered(
        int $perPage = 15,
        ?string $search = null,
        ?string $status = null,
    ): LengthAwarePaginator {
        $query = $this->query()
            ->with(['tier:id,name,slug', 'points', 'wallet']);

        $query->search($search, ['name', 'member_code', 'phone', 'email']);

        if ($status) {
            $query->where('status', $status);
        }

        return $query->orderByDesc('created_at')->paginate($perPage);
    }

    public function findWithRelations(string $uuid): ?Member
    {
        return $this->query()
            ->with(['tier', 'points', 'wallet'])
            ->where('uuid', $uuid)
            ->first();
    }

    public function findByCode(string $code): ?Member
    {
        return $this->query()
            ->with(['tier', 'points', 'wallet'])
            ->where('member_code', $code)
            ->first();
    }

    public function findByQrToken(string $token): ?Member
    {
        return $this->query()
            ->with(['tier', 'points', 'wallet'])
            ->where('qr_token', $token)
            ->first();
    }

    public function countMembers(): int
    {
        return $this->query()->count();
    }
}