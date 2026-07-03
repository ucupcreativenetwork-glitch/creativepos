<?php

namespace App\Modules\Notification\Notifications;

use App\Shared\Support\FrontendUrl;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ResetPasswordNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        #[\SensitiveParameter]
        public readonly string $token,
    ) {}

    /**
     * @return list<string>
     */
    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $expire = (int) config('auth.passwords.'.config('auth.defaults.passwords').'.expire', 60);

        return (new MailMessage)
            ->subject('Reset Password — CreativePOS')
            ->view('emails.password-reset-link', [
                'userName' => $notifiable->name ?? 'Pengguna',
                'resetUrl' => $this->resetUrl($notifiable),
                'expireMinutes' => $expire,
            ]);
    }

    protected function resetUrl(object $notifiable): string
    {
        return FrontendUrl::resetPassword(
            $this->token,
            $notifiable->getEmailForPasswordReset(),
        );
    }
}