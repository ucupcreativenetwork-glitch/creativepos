<?php

namespace App\Modules\POS\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class CreateTransactionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $tenantId = tenant('id');

        return [
            'outlet_id' => [
                'required',
                'integer',
                Rule::exists('outlets', 'id')->where(fn ($q) => $q->where('tenant_id', $tenantId)),
            ],
            'shift_id' => [
                'nullable',
                'integer',
                Rule::exists('shifts', 'id')->where(fn ($q) => $q
                    ->where('tenant_id', $tenantId)
                    ->where('status', 'open')),
            ],
            'order_type' => ['sometimes', 'in:dine_in,takeaway,delivery,quick_sale'],
            'member_id' => [
                'nullable',
                'integer',
                Rule::exists('members', 'id')->where(fn ($q) => $q->where('tenant_id', $tenantId)),
            ],
            'notes' => ['nullable', 'string', 'max:500'],
            'points_redeem' => ['nullable', 'integer', 'min:1'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => [
                'required',
                'integer',
                Rule::exists('products', 'id')->where(fn ($q) => $q->where('tenant_id', $tenantId)),
            ],
            'items.*.quantity' => ['required', 'numeric', 'min:0.001'],
            'items.*.modifiers' => ['sometimes', 'array'],
            'items.*.modifiers.*' => [
                'integer',
                Rule::exists('product_modifiers', 'id')->where(fn ($q) => $q->where('tenant_id', $tenantId)),
            ],
            'items.*.notes' => ['nullable', 'string', 'max:200'],
            'discounts' => ['sometimes', 'array'],
            'discounts.*.type' => ['required_with:discounts', 'in:percentage,nominal'],
            'discounts.*.value' => ['required_with:discounts', 'numeric', 'min:0'],
            'discounts.*.name' => ['nullable', 'string', 'max:100'],
            'payments' => ['required', 'array', 'min:1'],
            'payments.*.payment_method_id' => [
                'required',
                'integer',
                Rule::exists('payment_methods', 'id')->where(fn ($q) => $q->where('is_active', true)),
            ],
            'payments.*.amount' => ['required', 'numeric', 'min:0.01'],
            'payments.*.reference_number' => ['nullable', 'string', 'max:255'],
        ];
    }
}