<?php

use App\Modules\Inventory\Controllers\CategoryController;
use App\Modules\Inventory\Controllers\ProductController;
use App\Modules\Inventory\Controllers\RawMaterialController;
use App\Modules\Inventory\Controllers\RecipeController;
use App\Modules\Inventory\Controllers\StockController;
use Illuminate\Support\Facades\Route;

Route::prefix('inventory')->group(function (): void {
    Route::get('/categories', [CategoryController::class, 'index']);
    Route::post('/categories', [CategoryController::class, 'store']);
    Route::put('/categories/{category}', [CategoryController::class, 'update']);
    Route::delete('/categories/{category}', [CategoryController::class, 'destroy']);

    Route::get('/products', [ProductController::class, 'index']);
    Route::get('/products/barcode/{code}', [ProductController::class, 'findByBarcode']);
    Route::get('/products/{product}', [ProductController::class, 'show']);
    Route::post('/products', [ProductController::class, 'store']);
    Route::post('/products/import', [ProductController::class, 'import']);
    Route::put('/products/{product}', [ProductController::class, 'update']);
    Route::delete('/products/{product}', [ProductController::class, 'destroy']);

    Route::get('/stocks', [StockController::class, 'index']);
    Route::get('/stocks/alerts', [StockController::class, 'alerts']);
    Route::get('/stocks/movements', [StockController::class, 'movements']);
    Route::get('/stocks/warehouses', [StockController::class, 'warehouses']);
    Route::post('/stocks/in', [StockController::class, 'stockIn']);
    Route::post('/stocks/out', [StockController::class, 'stockOut']);
    Route::post('/stocks/adjustment', [StockController::class, 'adjustment']);
    Route::post('/stocks/import', [StockController::class, 'import']);

    Route::get('/raw-materials', [RawMaterialController::class, 'index']);
    Route::get('/raw-materials/alerts', [RawMaterialController::class, 'alerts']);
    Route::get('/raw-materials/{rawMaterial}', [RawMaterialController::class, 'show']);
    Route::post('/raw-materials', [RawMaterialController::class, 'store']);
    Route::put('/raw-materials/{rawMaterial}', [RawMaterialController::class, 'update']);
    Route::delete('/raw-materials/{rawMaterial}', [RawMaterialController::class, 'destroy']);
    Route::post('/raw-materials/{rawMaterial}/stock-in', [RawMaterialController::class, 'stockIn']);
    Route::post('/raw-materials/{rawMaterial}/stock-out', [RawMaterialController::class, 'stockOut']);

    Route::get('/products/{product}/recipe', [RecipeController::class, 'show']);
    Route::put('/products/{product}/recipe', [RecipeController::class, 'sync']);
    Route::get('/products/{product}/cogs', [RecipeController::class, 'cogs']);
});