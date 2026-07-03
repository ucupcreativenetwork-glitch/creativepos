<?php

namespace App\Modules\Billing\Requests;

use Illuminate\Foundation\Http\FormRequest;

class InitiatePaymentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'payment_method' => ['required', 'string', 'in:va_bca,va_bni,va_bri,qris,gopay,ovo,dana,credit_card,cod'],
            'enable_recurring' => ['sometimes', 'boolean'],
        ];
    }
}