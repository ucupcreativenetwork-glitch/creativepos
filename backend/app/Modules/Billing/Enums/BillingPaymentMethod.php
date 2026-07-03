<?php

namespace App\Modules\Billing\Enums;

enum BillingPaymentMethod: string
{
    case VaBca = 'va_bca';
    case VaBni = 'va_bni';
    case VaBri = 'va_bri';
    case Qris = 'qris';
    case Gopay = 'gopay';
    case Ovo = 'ovo';
    case Dana = 'dana';
    case CreditCard = 'credit_card';
    case Cod = 'cod';

    public function label(): string
    {
        return match ($this) {
            self::VaBca => 'Virtual Account BCA',
            self::VaBni => 'Virtual Account BNI',
            self::VaBri => 'Virtual Account BRI',
            self::Qris => 'QRIS',
            self::Gopay => 'GoPay',
            self::Ovo => 'OVO',
            self::Dana => 'DANA',
            self::CreditCard => 'Kartu Kredit',
            self::Cod => 'Bayar di Tempat (COD)',
        };
    }

    public function gateway(): string
    {
        return match ($this) {
            self::CreditCard => 'xendit',
            self::Cod => 'cod',
            default => 'midtrans',
        };
    }

    public function isRecurringCapable(): bool
    {
        return $this === self::CreditCard;
    }

    public static function tryFromString(string $value): ?self
    {
        return self::tryFrom($value);
    }

    /**
     * @return list<self>
     */
    public static function available(): array
    {
        return [
            self::VaBca,
            self::VaBni,
            self::VaBri,
            self::Qris,
            self::Gopay,
            self::Ovo,
            self::Dana,
            self::CreditCard,
            self::Cod,
        ];
    }
}