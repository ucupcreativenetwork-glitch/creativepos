<?php

namespace App\Modules\Inventory\Repositories;

use App\Modules\Inventory\Models\Category;
use App\Shared\Repositories\BaseRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;

class CategoryRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct(new Category);
    }

    public function listActive(): Collection
    {
        return $this->query()
            ->where('is_active', true)
            ->orderBy('name')
            ->get();
    }

    public function paginateFiltered(int $perPage = 15, ?string $search = null): LengthAwarePaginator
    {
        return $this->query()
            ->search($search, ['name', 'slug'])
            ->orderBy('name')
            ->paginate($perPage);
    }
}