<?php

namespace App\Modules\Loyalty\Requests;

use Illuminate\Foundation\Http\FormRequest;

class WalletTransferRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'from_member_id' => ['required', 'integer', 'exists:members,id'],
            'to_member_id' => ['required', 'integer', 'exists:members,id', 'different:from_member_id'],
            'amount' => ['required', 'numeric', 'min:1000'],
            'description' => ['nullable', 'string', 'max:255'],
        ];
    }
}