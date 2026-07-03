<?php

namespace App\Modules\Reservation\Requests;

use App\Shared\Rules\TenantRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreReservationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'outlet_id' => ['required', 'integer', TenantRule::exists('outlets')],
            'member_id' => ['nullable', 'integer', TenantRule::exists('members')],
            'table_id' => ['nullable', 'integer', TenantRule::exists('tables')],
            'customer_name' => ['required', 'string', 'max:100'],
            'customer_phone' => ['required', 'string', 'max:20'],
            'customer_email' => ['nullable', 'email', 'max:100'],
            'guest_count' => ['required', 'integer', 'min:1', 'max:50'],
            'reservation_date' => ['required', 'date', 'after_or_equal:today'],
            'reservation_time' => ['required', 'date_format:H:i'],
            'notes' => ['nullable', 'string', 'max:500'],
        ];
    }
}