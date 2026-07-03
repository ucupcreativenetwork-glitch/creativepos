<?php

namespace App\Shared\Contracts;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Model;

interface RepositoryInterface
{
    public function find(int|string $id): ?Model;

    public function findOrFail(int|string $id): Model;

    public function all(array $columns = ['*']): Collection;

    public function create(array $data): Model;

    public function update(Model $model, array $data): Model;

    public function delete(Model $model): bool;

    public function paginate(int $perPage = 15, array $filters = []): LengthAwarePaginator;
}