<?php

namespace App\Modules\Delivery\Requests;

use App\Shared\Rules\TenantRule;
use Illuminate\Foundation\Http\FormRequest;

class AssignDriverRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'driver_id' => ['required', 'integer', TenantRule::exists('delivery_drivers')],
        ];
    }
}