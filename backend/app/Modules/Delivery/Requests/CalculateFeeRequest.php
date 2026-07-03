<?php

namespace App\Modules\Delivery\Requests;

use App\Shared\Rules\TenantRule;
use Illuminate\Foundation\Http\FormRequest;

class CalculateFeeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'zone_id' => ['required', 'integer', TenantRule::exists('delivery_zones')],
            'distance_km' => ['required', 'numeric', 'min:0'],
        ];
    }
}