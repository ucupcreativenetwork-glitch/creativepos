<?php

namespace App\Modules\CRM\Requests;

use App\Shared\Rules\TenantRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreTicketRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'member_id' => ['nullable', 'integer', TenantRule::exists('members')],
            'customer_name' => ['nullable', 'string', 'max:100'],
            'customer_email' => ['nullable', 'email', 'max:100'],
            'customer_phone' => ['nullable', 'string', 'max:20'],
            'channel' => ['nullable', 'in:whatsapp,telegram,email,website,phone'],
            'subject' => ['required', 'string', 'max:255'],
            'priority' => ['nullable', 'in:low,medium,high,critical'],
            'message' => ['nullable', 'string', 'max:5000'],
        ];
    }
}