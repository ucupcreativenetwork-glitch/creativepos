<?php

namespace App\Shared\Support;

use App\Modules\Inventory\Models\Product;

class BarcodeGenerator
{
    /**
     * Generate EAN-13 internal barcode (prefix 2) from tenant + product id.
     */
    public function generateForProduct(Product $product): string
    {
        $tenantPart = str_pad((string) ($product->tenant_id % 10000), 4, '0', STR_PAD_LEFT);
        $productPart = str_pad((string) ($product->id % 10000000), 7, '0', STR_PAD_LEFT);
        $payload = '2'.$tenantPart.$productPart;

        return $this->withEan13CheckDigit($payload);
    }

    public function withEan13CheckDigit(string $twelveDigits): string
    {
        if (strlen($twelveDigits) !== 12 || ! ctype_digit($twelveDigits)) {
            throw new \InvalidArgumentException('EAN-13 membutuhkan 12 digit angka.');
        }

        $sum = 0;
        for ($i = 0; $i < 12; $i++) {
            $digit = (int) $twelveDigits[$i];
            $sum += $digit * ($i % 2 === 0 ? 1 : 3);
        }

        $check = (10 - ($sum % 10)) % 10;

        return $twelveDigits.$check;
    }

    public function isUniqueInTenant(string $barcode, ?int $excludeProductId = null): bool
    {
        $query = Product::query()->where('barcode', $barcode);

        if ($excludeProductId !== null) {
            $query->where('id', '!=', $excludeProductId);
        }

        return ! $query->exists();
    }
}