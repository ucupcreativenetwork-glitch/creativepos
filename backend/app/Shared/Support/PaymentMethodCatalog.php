<?php

namespace App\Shared\Support;

use App\Modules\POS\Models\PaymentMethod;

class PaymentMethodCatalog
{
    public static function definitions(): array
    {
        return [
            ['code' => 'cash', 'name' => 'Tunai', 'type' => 'cash'],
            ['code' => 'transfer_bca', 'name' => 'Transfer BCA', 'type' => 'transfer'],
            ['code' => 'transfer_bni', 'name' => 'Transfer BNI', 'type' => 'transfer'],
            ['code' => 'transfer_bri', 'name' => 'Transfer BRI', 'type' => 'transfer'],
            ['code' => 'gopay', 'name' => 'GoPay', 'type' => 'e_wallet'],
            ['code' => 'ovo', 'name' => 'OVO', 'type' => 'e_wallet'],
            ['code' => 'qris', 'name' => 'QRIS', 'type' => 'qris'],
            ['code' => 'debit', 'name' => 'Kartu Debit', 'type' => 'debit_card'],
            ['code' => 'credit', 'name' => 'Kartu Kredit', 'type' => 'credit_card'],
        ];
    }

    public static function codes(): array
    {
        return array_column(self::definitions(), 'code');
    }

    public static function syncToDatabase(): void
    {
        foreach (self::definitions() as $method) {
            PaymentMethod::query()->updateOrCreate(
                ['code' => $method['code']],
                [
                    'name' => $method['name'],
                    'type' => $method['type'],
                    'is_active' => true,
                ],
            );
        }
    }
}