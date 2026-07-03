<?php

namespace App\Modules\Delivery\Requests;

use App\Shared\Rules\TenantRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreDeliveryZoneRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'outlet_id' => ['required', 'integer', TenantRule::exists('outlets')],
            'name' => ['required', 'string', 'max:100'],
            'code' => ['required', 'string', 'max:20'],
            'description' => ['nullable', 'string', 'max:255'],
            'base_fee' => ['required', 'numeric', 'min:0'],
            'fee_per_km' => ['nullable', 'numeric', 'min:0'],
            'max_distance_km' => ['nullable', 'numeric', 'min:0.1'],
        ];
    }
}