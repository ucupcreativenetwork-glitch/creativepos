<?php

namespace App\Modules\Inventory\Services;

use App\Modules\Inventory\Models\Category;
use App\Modules\Inventory\Repositories\CategoryRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Str;

class CategoryService
{
    public function __construct(
        private readonly CategoryRepository $repository,
    ) {}

    public function list(?string $search = null, int $perPage = 50): LengthAwarePaginator
    {
        return $this->repository->paginateFiltered($perPage, $search);
    }

    public function listActive(): Collection
    {
        return $this->repository->listActive();
    }

    public function create(array $data): Category
    {
        $data['slug'] = $this->uniqueSlug($data['name']);

        return $this->repository->create($data);
    }

    public function update(Category $category, array $data): Category
    {
        if (isset($data['name']) && $data['name'] !== $category->name) {
            $data['slug'] = $this->uniqueSlug($data['name'], $category->id);
        }

        return $this->repository->update($category, $data);
    }

    public function delete(Category $category): bool
    {
        if ($category->products()->exists()) {
            abort(422, 'Kategori masih memiliki produk dan tidak dapat dihapus.');
        }

        return $this->repository->delete($category);
    }

    protected function uniqueSlug(string $name, ?int $exceptId = null): string
    {
        $base = Str::slug($name);
        $slug = $base;
        $counter = 1;

        while ($this->slugExists($slug, $exceptId)) {
            $slug = "{$base}-{$counter}";
            $counter++;
        }

        return $slug;
    }

    protected function slugExists(string $slug, ?int $exceptId = null): bool
    {
        $query = Category::query()->where('slug', $slug);

        if ($exceptId) {
            $query->where('id', '!=', $exceptId);
        }

        return $query->exists();
    }
}