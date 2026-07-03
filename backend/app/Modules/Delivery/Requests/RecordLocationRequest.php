<?php

namespace App\Modules\Delivery\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RecordLocationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'driver_id' => ['nullable', 'integer', 'exists:delivery_drivers,id'],
        ];
    }
}