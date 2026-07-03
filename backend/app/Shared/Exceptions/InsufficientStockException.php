<?php

namespace App\Shared\Exceptions;

use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InsufficientStockException extends Exception
{
    public function __construct(
        public readonly string $productName = '',
        public readonly float $available = 0,
        public readonly float $requested = 0,
    ) {
        $message = $productName
            ? "Insufficient stock for '{$productName}'. Available: {$available}, Requested: {$requested}."
            : 'Insufficient stock for one or more products.';

        parent::__construct($message);
    }

    public function render(Request $request): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $this->getMessage(),
            'data' => [
                'product' => $this->productName,
                'available' => $this->available,
                'requested' => $this->requested,
            ],
        ], 422);
    }
}