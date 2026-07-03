<?php

namespace App\Modules\Loyalty\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateMemberRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $tenantId = tenant('id');
        $memberId = $this->route('member')?->id;

        return [
            'name' => ['sometimes', 'string', 'max:255'],
            'phone' => [
                'sometimes',
                'string',
                'max:20',
                Rule::unique('members', 'phone')
                    ->where(fn ($q) => $q->where('tenant_id', $tenantId))
                    ->ignore($memberId),
            ],
            'email' => ['nullable', 'email', 'max:255'],
            'birthday' => ['nullable', 'date'],
            'status' => ['sometimes', 'in:active,inactive,blocked'],
        ];
    }
}