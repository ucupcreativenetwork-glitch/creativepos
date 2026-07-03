<?php

namespace App\Modules\CRM\Services;

use App\Modules\Settings\Models\WhatsappConfig;
use App\Modules\CRM\Repositories\KnowledgeBaseRepository;
use Illuminate\Database\Eloquent\Collection;

class KnowledgeBaseService
{
    public function __construct(
        private readonly KnowledgeBaseRepository $repository,
    ) {}

    public function faqs(): Collection
    {
        return $this->repository->activeFaqs();
    }

    public function knowledgeBase(): Collection
    {
        return $this->repository->knowledgeBase();
    }

    public function getWhatsappConfig(): ?WhatsappConfig
    {
        return $this->repository->getWhatsappConfig();
    }

    public function updateWhatsappConfig(array $data): WhatsappConfig
    {
        $payload = [
            'tenant_id' => tenant('id'),
            'phone_number' => $data['phone_number'],
            'webhook_secret' => $data['webhook_secret'] ?? null,
            'is_active' => $data['is_active'] ?? false,
        ];

        if (array_key_exists('api_token', $data)) {
            $payload['api_token'] = $data['api_token'];
        }

        return $this->repository->saveWhatsappConfig($payload);
    }
}