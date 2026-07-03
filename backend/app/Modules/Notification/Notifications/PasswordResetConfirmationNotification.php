<?php

namespace App\Modules\Notification\Notifications;

use App\Shared\Support\FrontendUrl;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class PasswordResetConfirmationNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public readonly ?string $changedAt = null,
    ) {}

    /**
     * @return list<string>
     */
    public function via(object $notifiable): array
    {
        return filled($notifiable->email) ? ['mail'] : [];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $changedAt = $this->changedAt ?? now()->timezone(config('app.timezone', 'Asia/Jakarta'))->format('d M Y H:i T');
        $loginUrl = FrontendUrl::login();

        return (new MailMessage)
            ->subject('Password Berhasil Diubah — CreativePOS')
            ->view('emails.password-reset-confirmation', [
                'userName' => $notifiable->name ?? 'Pengguna',
                'changedAt' => $changedAt,
                'loginUrl' => $loginUrl,
            ]);
    }
}