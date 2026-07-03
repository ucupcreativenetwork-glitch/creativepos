<?php

namespace App\Modules\Inventory\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Inventory\Models\Category;
use App\Modules\Inventory\Requests\StoreCategoryRequest;
use App\Modules\Inventory\Requests\UpdateCategoryRequest;
use App\Modules\Inventory\Resources\CategoryResource;
use App\Modules\Inventory\Services\CategoryService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    public function __construct(
        private readonly CategoryService $categoryService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.view');

        $paginator = $this->categoryService->list(
            $request->input('search'),
            $request->integer('per_page', 50),
        );

        return ApiResponse::success(
            CategoryResource::collection($paginator->items()),
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

    public function store(StoreCategoryRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.create');

        $category = $this->categoryService->create($request->validated());

        return ApiResponse::created(new CategoryResource($category));
    }

    public function update(UpdateCategoryRequest $request, Category $category): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.update');

        $category = $this->categoryService->update($category, $request->validated());

        return ApiResponse::success(new CategoryResource($category));
    }

    public function destroy(Request $request, Category $category): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.delete');

        $this->categoryService->delete($category);

        return ApiResponse::success(null, 'Kategori berhasil dihapus.');
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses inventori.');
        }
    }
}