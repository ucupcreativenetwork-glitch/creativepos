<?php

namespace App\Modules\Reservation\Requests;

use App\Shared\Rules\TenantRule;
use Illuminate\Foundation\Http\FormRequest;

class UpdateReservationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'outlet_id' => ['sometimes', 'integer', TenantRule::exists('outlets')],
            'member_id' => ['nullable', 'integer', TenantRule::exists('members')],
            'table_id' => ['nullable', 'integer', TenantRule::exists('tables')],
            'customer_name' => ['sometimes', 'string', 'max:100'],
            'customer_phone' => ['sometimes', 'string', 'max:20'],
            'customer_email' => ['nullable', 'email', 'max:100'],
            'guest_count' => ['sometimes', 'integer', 'min:1', 'max:50'],
            'reservation_date' => ['sometimes', 'date'],
            'reservation_time' => ['sometimes', 'date_format:H:i'],
            'notes' => ['nullable', 'string', 'max:500'],
        ];
    }
}