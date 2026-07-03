<?php

namespace App\Modules\Inventory\Requests;

use App\Shared\Rules\TenantRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreProductRequest extends FormRequest
{
    use ModifierGroupRules;
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $tenantId = tenant('id');

        return [
            'name' => ['required', 'string', 'max:200'],
            'image_url' => ['nullable', 'string', 'max:500'],
            'sku' => [
                'required',
                'string',
                'max:100',
                Rule::unique('products', 'sku')->where(fn ($q) => $q->where('tenant_id', $tenantId)),
            ],
            'barcode' => ['nullable', 'string', 'max:100'],
            'category_id' => ['nullable', 'integer', TenantRule::exists('categories')],
            'base_price' => ['required', 'numeric', 'min:0'],
            'cost_price' => ['nullable', 'numeric', 'min:0'],
            'min_stock' => ['nullable', 'integer', 'min:0'],
            'track_stock' => ['sometimes', 'boolean'],
            'is_active' => ['sometimes', 'boolean'],
            'is_available' => ['sometimes', 'boolean'],
            'show_in_pos' => ['sometimes', 'boolean'],
            'initial_stock' => ['nullable', 'numeric', 'min:0'],
            ...$this->modifierGroupRules(),
        ];
    }
}