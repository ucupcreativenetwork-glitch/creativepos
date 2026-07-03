<?php

namespace App\Shared\Responses;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Pagination\LengthAwarePaginator;

class ApiResponse
{
    public static function success(
        mixed $data = null,
        string $message = 'Operation successful',
        int $status = 200,
        ?array $meta = null,
    ): JsonResponse {
        $response = [
            'success' => true,
            'message' => $message,
        ];

        if ($data !== null) {
            $response['data'] = $data instanceof JsonResource
                ? $data->resolve()
                : $data;
        }

        if ($meta !== null) {
            $response['meta'] = $meta;
        } elseif ($data instanceof LengthAwarePaginator) {
            $response['meta'] = [
                'current_page' => $data->currentPage(),
                'per_page' => $data->perPage(),
                'total' => $data->total(),
                'last_page' => $data->lastPage(),
            ];
            $response['data'] = $data->items();
        }

        return response()->json($response, $status);
    }

    public static function error(
        string $message = 'An error occurred',
        int $status = 400,
        ?array $errors = null,
    ): JsonResponse {
        $response = [
            'success' => false,
            'message' => $message,
        ];

        if ($errors !== null) {
            $response['errors'] = $errors;
        }

        return response()->json($response, $status);
    }

    public static function created(mixed $data = null, string $message = 'Created successfully'): JsonResponse
    {
        return self::success($data, $message, 201);
    }

    public static function noContent(): JsonResponse
    {
        return response()->json(null, 204);
    }
}