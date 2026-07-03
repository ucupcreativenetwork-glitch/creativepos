<?php

namespace App\Modules\Delivery\Requests;

use App\Shared\Rules\TenantRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreDeliveryOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'outlet_id' => ['required', 'integer', TenantRule::exists('outlets')],
            'member_id' => ['nullable', 'integer', TenantRule::exists('members')],
            'delivery_zone_id' => ['nullable', 'integer', TenantRule::exists('delivery_zones')],
            'customer_name' => ['required', 'string', 'max:100'],
            'customer_phone' => ['required', 'string', 'max:20'],
            'delivery_address' => ['required', 'string', 'max:500'],
            'delivery_city' => ['nullable', 'string', 'max:100'],
            'delivery_notes' => ['nullable', 'string', 'max:500'],
            'distance_km' => ['nullable', 'numeric', 'min:0'],
            'shipping_fee' => ['nullable', 'numeric', 'min:0'],
            'estimated_minutes' => ['nullable', 'integer', 'min:1'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'integer', TenantRule::exists('products')],
            'items.*.quantity' => ['required', 'numeric', 'min:0.001'],
            'items.*.notes' => ['nullable', 'string', 'max:200'],
        ];
    }
}