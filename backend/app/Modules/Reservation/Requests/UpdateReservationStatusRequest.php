<?php

namespace App\Modules\Reservation\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateReservationStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'status' => ['required', 'in:pending,confirmed,arrived,completed,cancelled,no_show'],
            'notes' => ['nullable', 'string', 'max:500'],
        ];
    }
}