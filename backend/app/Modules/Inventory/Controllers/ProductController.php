<?php

namespace App\Modules\Inventory\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Inventory\Models\Product;
use App\Modules\Inventory\Requests\StoreProductRequest;
use App\Modules\Inventory\Requests\UpdateProductRequest;
use App\Modules\Inventory\Resources\ProductResource;
use App\Modules\Inventory\Services\ProductService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function __construct(
        private readonly ProductService $productService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.view');

        $paginator = $this->productService->list(
            $request->input('search'),
            $request->integer('category_id') ?: null,
            $request->has('is_active') ? $request->boolean('is_active') : null,
            $request->integer('per_page', 15),
        );

        return ApiResponse::success(
            ProductResource::collection($paginator->items()),
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

    public function show(Request $request, Product $product): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.view');

        $product = $this->productService->findByUuid($product->uuid);

        return ApiResponse::success(new ProductResource($product));
    }

    public function findByBarcode(Request $request, string $code): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.view');

        $product = $this->productService->findByBarcode($code);

        return ApiResponse::success(new ProductResource($product));
    }

    public function store(StoreProductRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.create');

        $product = $this->productService->create(
            $request->validated(),
            $request->user()?->id,
        );

        return ApiResponse::created(new ProductResource($product));
    }

    public function update(UpdateProductRequest $request, Product $product): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.update');

        $product = $this->productService->update($product, $request->validated());

        return ApiResponse::success(new ProductResource($product));
    }

    public function destroy(Request $request, Product $product): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.delete');

        $this->productService->delete($product);

        return ApiResponse::success(null, 'Produk berhasil dihapus.');
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses inventori.');
        }
    }
}