<?php

namespace App\Modules\Inventory\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Inventory\Models\Product;
use App\Modules\Inventory\Requests\SyncRecipeRequest;
use App\Modules\Inventory\Resources\ProductRecipeResource;
use App\Modules\Inventory\Services\RecipeService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RecipeController extends Controller
{
    public function __construct(
        private readonly RecipeService $recipeService,
    ) {}

    public function show(Request $request, Product $product): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.view');

        $recipes = $this->recipeService->getRecipe($product);
        $cogs = $this->recipeService->calculateCOGS($product);

        return ApiResponse::success([
            'product_id' => $product->id,
            'product_name' => $product->name,
            'ingredients' => ProductRecipeResource::collection($recipes),
            'cogs' => $cogs,
        ]);
    }

    public function sync(SyncRecipeRequest $request, Product $product): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.update');

        $recipes = $this->recipeService->syncRecipe($product, $request->input('ingredients', []));
        $cogs = $this->recipeService->calculateCOGS($product);

        return ApiResponse::success([
            'product_id' => $product->id,
            'product_name' => $product->name,
            'ingredients' => ProductRecipeResource::collection($recipes),
            'cogs' => $cogs,
        ], 'Resep produk berhasil disimpan.');
    }

    public function cogs(Request $request, Product $product): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.view');

        return ApiResponse::success([
            'product_id' => $product->id,
            'product_name' => $product->name,
            'cogs' => $this->recipeService->calculateCOGS($product),
        ]);
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses inventori.');
        }
    }
}