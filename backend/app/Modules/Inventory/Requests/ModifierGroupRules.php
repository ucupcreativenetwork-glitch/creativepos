<?php

namespace App\Modules\Inventory\Requests;

trait ModifierGroupRules
{
    protected function modifierGroupRules(): array
    {
        return [
            'modifier_groups' => ['sometimes', 'array'],
            'modifier_groups.*.id' => ['nullable', 'integer', 'exists:product_modifier_groups,id'],
            'modifier_groups.*.name' => ['required_with:modifier_groups', 'string', 'max:100'],
            'modifier_groups.*.is_required' => ['sometimes', 'boolean'],
            'modifier_groups.*.min_select' => ['sometimes', 'integer', 'min:0', 'max:50'],
            'modifier_groups.*.max_select' => ['sometimes', 'integer', 'min:1', 'max:50'],
            'modifier_groups.*.sort_order' => ['sometimes', 'integer', 'min:0'],
            'modifier_groups.*.modifiers' => ['sometimes', 'array'],
            'modifier_groups.*.modifiers.*.id' => ['nullable', 'integer', 'exists:product_modifiers,id'],
            'modifier_groups.*.modifiers.*.name' => ['required_with:modifier_groups.*.modifiers', 'string', 'max:100'],
            'modifier_groups.*.modifiers.*.price_adjustment' => ['sometimes', 'numeric'],
            'modifier_groups.*.modifiers.*.is_default' => ['sometimes', 'boolean'],
            'modifier_groups.*.modifiers.*.is_active' => ['sometimes', 'boolean'],
            'modifier_groups.*.modifiers.*.sort_order' => ['sometimes', 'integer', 'min:0'],
        ];
    }
}