<?php

namespace App\Modules\CRM\Requests;

use App\Shared\Rules\TenantRule;
use Illuminate\Foundation\Http\FormRequest;

class AssignTicketRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'assigned_to' => ['required', 'integer', TenantRule::exists('users')],
        ];
    }
}