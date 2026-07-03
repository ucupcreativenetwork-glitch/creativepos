<?php

namespace App\Modules\Inventory\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateRawMaterialRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'string', 'max:200'],
            'unit' => ['sometimes', Rule::in(['gram', 'ml', 'pcs', 'liter'])],
            'current_stock' => ['sometimes', 'numeric', 'min:0'],
            'min_stock' => ['sometimes', 'numeric', 'min:0'],
            'cost_per_unit' => ['sometimes', 'numeric', 'min:0'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}