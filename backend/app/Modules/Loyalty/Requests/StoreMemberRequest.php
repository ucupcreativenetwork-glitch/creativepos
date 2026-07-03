<?php

namespace App\Modules\Loyalty\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreMemberRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $tenantId = tenant('id');

        return [
            'name' => ['required', 'string', 'max:255'],
            'phone' => [
                'required',
                'string',
                'max:20',
                Rule::unique('members', 'phone')->where(fn ($q) => $q->where('tenant_id', $tenantId)),
            ],
            'email' => ['nullable', 'email', 'max:255'],
            'birthday' => ['nullable', 'date'],
            'member_code' => ['nullable', 'string', 'max:50'],
            'status' => ['sometimes', 'in:active,inactive,blocked'],
        ];
    }
}