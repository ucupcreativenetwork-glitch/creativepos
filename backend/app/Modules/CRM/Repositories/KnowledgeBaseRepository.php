<?php

namespace App\Modules\CRM\Repositories;

use App\Modules\CRM\Models\Faq;
use App\Modules\CRM\Models\KnowledgeBaseCategory;
use App\Modules\Settings\Models\WhatsappConfig;
use Illuminate\Database\Eloquent\Collection;

class KnowledgeBaseRepository
{
    public function activeFaqs(): Collection
    {
        return Faq::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();
    }

    public function knowledgeBase(): Collection
    {
        return KnowledgeBaseCategory::query()
            ->with(['articles' => function ($query): void {
                $query->where('is_published', true)
                    ->orderBy('title')
                    ->select(['id', 'tenant_id', 'category_id', 'title', 'slug', 'content', 'view_count', 'created_at']);
            }])
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();
    }

    public function getWhatsappConfig(): ?WhatsappConfig
    {
        return WhatsappConfig::query()->first();
    }

    public function saveWhatsappConfig(array $data): WhatsappConfig
    {
        $config = WhatsappConfig::query()->first();

        if ($config) {
            $config->update($data);

            return $config->fresh();
        }

        return WhatsappConfig::query()->create($data);
    }
}