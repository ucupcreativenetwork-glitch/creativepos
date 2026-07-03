<?php

namespace App\Modules\Order\Requests;

use App\Shared\Rules\TenantRule;
use Illuminate\Foundation\Http\FormRequest;

class CreateOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'outlet_id' => ['required', 'integer', TenantRule::exists('outlets')],
            'table_id' => ['nullable', 'integer', TenantRule::exists('tables')],
            'member_id' => ['nullable', 'integer', TenantRule::exists('members')],
            'source' => ['sometimes', 'in:pos,qr_menu,delivery,reservation'],
            'order_type' => ['sometimes', 'in:dine_in,takeaway,delivery'],
            'notes' => ['nullable', 'string', 'max:500'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'integer', TenantRule::exists('products')],
            'items.*.quantity' => ['required', 'numeric', 'min:0.001'],
            'items.*.notes' => ['nullable', 'string', 'max:200'],
        ];
    }
}