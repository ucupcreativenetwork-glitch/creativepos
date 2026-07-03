<?php

namespace App\Modules\Delivery\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateDeliveryStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'status' => ['required', 'in:waiting,processing,cooking,ready,delivering,completed,cancelled'],
            'notes' => ['nullable', 'string', 'max:500'],
        ];
    }
}