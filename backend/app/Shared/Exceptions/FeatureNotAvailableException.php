<?php

namespace App\Shared\Exceptions;

use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FeatureNotAvailableException extends Exception
{
    public function __construct(string $feature = '')
    {
        $message = $feature
            ? "Feature '{$feature}' is not available on your current subscription plan."
            : 'This feature is not available on your current subscription plan.';

        parent::__construct($message);
    }

    public function render(Request $request): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $this->getMessage(),
        ], 403);
    }
}