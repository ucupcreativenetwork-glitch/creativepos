<?php

namespace App\Modules\Loyalty\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AdjustPointsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'points' => ['required', 'integer', 'not_in:0'],
            'description' => ['required', 'string', 'max:255'],
        ];
    }
}