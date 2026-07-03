<?php

namespace App\Modules\Notification\Enums;

enum NotificationEvent: string
{
    case InvoiceDue = 'invoice_due';
    case LowStock = 'low_stock';
    case NewOrder = 'new_order';
    case TableServiceRequest = 'table_service_request';
    case UserLoggedIn = 'user_logged_in';
    case PasswordResetConfirmation = 'password_reset_confirmation';

    public function label(): string
    {
        return match ($this) {
            self::InvoiceDue => 'Tagihan Jatuh Tempo',
            self::LowStock => 'Stok Menipis',
            self::NewOrder => 'Pesanan Masuk',
            self::TableServiceRequest => 'Permintaan Meja',
            self::UserLoggedIn => 'Notifikasi Login',
            self::PasswordResetConfirmation => 'Konfirmasi Reset Password',
        };
    }

    /**
     * @return list<string>
     */
    public function defaultPermissions(): array
    {
        return match ($this) {
            self::InvoiceDue => ['tenant.settings.view'],
            self::LowStock => ['inventory.view', 'inventory.stock.adjust'],
            self::NewOrder => ['order.view', 'kitchen.view'],
            self::TableServiceRequest => ['order.view', 'kitchen.view'],
            self::UserLoggedIn => [],
            self::PasswordResetConfirmation => [],
        };
    }
}