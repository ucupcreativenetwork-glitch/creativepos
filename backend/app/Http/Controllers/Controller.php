<?php

namespace App\Http\Controllers;

use App\Shared\Responses\ApiResponse;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Routing\Controller as BaseController;

abstract class Controller extends BaseController
{
    use AuthorizesRequests, ValidatesRequests;

    protected function success(mixed $data = null, string $message = 'Operation successful', int $status = 200)
    {
        return ApiResponse::success($data, $message, $status);
    }

    protected function created(mixed $data = null, string $message = 'Created successfully')
    {
        return ApiResponse::created($data, $message);
    }

    protected function error(string $message = 'An error occurred', int $status = 400, ?array $errors = null)
    {
        return ApiResponse::error($message, $status, $errors);
    }
}