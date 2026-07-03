<?php

namespace App\Modules\Inventory\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class SyncRecipeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'ingredients' => ['present', 'array'],
            'ingredients.*.id' => ['nullable', 'integer', 'exists:product_recipes,id'],
            'ingredients.*.raw_material_id' => ['required', 'integer', 'exists:raw_materials,id'],
            'ingredients.*.quantity_needed' => ['required', 'numeric', 'min:0.001'],
            'ingredients.*.unit' => ['nullable', Rule::in(['gram', 'ml', 'pcs', 'liter'])],
            'ingredients.*.notes' => ['nullable', 'string', 'max:255'],
        ];
    }
}