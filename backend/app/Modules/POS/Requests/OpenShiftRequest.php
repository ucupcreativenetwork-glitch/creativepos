<?php

namespace App\Modules\POS\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class OpenShiftRequest extends FormRequest
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
            'opening_cash' => ['required', 'numeric', 'min:0'],
        ];
    }
}