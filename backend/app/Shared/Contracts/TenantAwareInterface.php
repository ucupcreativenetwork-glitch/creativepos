<?php

namespace App\Shared\Contracts;

interface TenantAwareInterface
{
    public function getTenantId(): ?int;

    public function setTenantId(?int $tenantId): static;
}