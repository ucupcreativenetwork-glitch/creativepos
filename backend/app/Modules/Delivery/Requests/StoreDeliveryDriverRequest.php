<?php

namespace App\Modules\Delivery\Requests;

use App\Shared\Rules\TenantRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreDeliveryDriverRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'user_id' => ['required', 'integer', TenantRule::exists('users')],
            'outlet_id' => ['nullable', 'integer', TenantRule::exists('outlets')],
            'vehicle_type' => ['nullable', 'string', 'max:50'],
            'vehicle_plate' => ['nullable', 'string', 'max:20'],
            'is_available' => ['sometimes', 'boolean'],
        ];
    }
}