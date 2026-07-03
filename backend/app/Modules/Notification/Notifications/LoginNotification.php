<?php

namespace App\Modules\Notification\Notifications;

use App\Modules\Notification\Channels\WhatsappChannel;
use App\Modules\Notification\Enums\NotificationEvent;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class LoginNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public readonly string $ipAddress,
        public readonly ?string $deviceName = null,
        public readonly ?string $loginAt = null,
    ) {}

    public function eventType(): NotificationEvent
    {
        return NotificationEvent::UserLoggedIn;
    }

    /**
     * @return list<string|class-string>
     */
    public function via(object $notifiable): array
    {
        $channels = [];

        if (filled($notifiable->email)) {
            $channels[] = 'mail';
        }

        if (filled($notifiable->phone)) {
            $channels[] = WhatsappChannel::class;
        }

        return $channels;
    }

    public function toMail(object $notifiable): MailMessage
    {
        $loginAt = $this->loginAt ?? now()->timezone(config('app.timezone', 'Asia/Jakarta'))->format('d M Y H:i T');

        return (new MailMessage)
            ->subject('Notifikasi Login — CreativePOS')
            ->view('emails.login-notification', [
                'userName' => $notifiable->name ?? 'Pengguna',
                'loginAt' => $loginAt,
                'deviceName' => $this->deviceName ?? 'Tidak diketahui',
                'ipAddress' => $this->ipAddress,
            ]);
    }

    public function toWhatsapp(object $notifiable): string
    {
        $loginAt = $this->loginAt ?? now()->timezone(config('app.timezone', 'Asia/Jakarta'))->format('d M Y H:i');

        return implode("\n", [
            '*Notifikasi Login CreativePOS*',
            '',
            'Halo '.($notifiable->name ?? 'Pengguna').',',
            'Akun Anda baru saja digunakan untuk masuk.',
            '',
            'Waktu: '.$loginAt,
            'Perangkat: '.($this->deviceName ?? 'Tidak diketahui'),
            'IP: '.$this->ipAddress,
            '',
            'Jika ini bukan Anda, segera ubah password dan aktifkan 2FA.',
        ]);
    }
}