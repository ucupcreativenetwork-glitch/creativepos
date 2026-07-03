<?php

namespace App\Modules\Auth\Jobs;

use App\Modules\Auth\Enums\OtpChannel;
use App\Modules\Auth\Enums\OtpPurpose;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Modules\Notification\Services\MailConfigService;
use App\Modules\Notification\Services\WhatsappService;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class SendOtpJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public readonly string $identifier,
        public readonly string $code,
        public readonly OtpChannel $channel,
        public readonly string $purpose,
        public readonly ?int $tenantId = null,
        public readonly ?string $userName = null,
    ) {}

    public function handle(): void
    {
        match ($this->channel) {
            OtpChannel::Email => $this->sendEmail(),
            OtpChannel::Whatsapp => $this->sendWhatsApp(),
            OtpChannel::Sms => $this->sendSms(),
        };
    }

    protected function sendEmail(): void
    {
        if ($this->tenantId) {
            app(MailConfigService::class)->applyForTenant($this->tenantId);
        }

        $purpose = OtpPurpose::tryFrom($this->purpose);
        $expiryMinutes = (int) config('creativepos.otp.expiry_minutes', 5);

        Mail::send(
            'emails.otp-code',
            [
                'code' => $this->code,
                'expiryMinutes' => $expiryMinutes,
                'purposeLabel' => $this->purposeLabel($purpose),
                'userName' => $this->userName,
            ],
            fn ($message) => $message
                ->to($this->identifier)
                ->subject($this->emailSubject($purpose))
        );
    }

    protected function sendWhatsApp(): void
    {
        $purpose = OtpPurpose::tryFrom($this->purpose);
        $expiryMinutes = (int) config('creativepos.otp.expiry_minutes', 5);

        $message = match ($purpose) {
            OtpPurpose::Login => implode("\n", [
                '*Kode Verifikasi 2FA CreativePOS*',
                '',
                'Kode Anda: *'.$this->code.'*',
                'Berlaku '.$expiryMinutes.' menit.',
                '',
                'Jangan bagikan kode ini kepada siapapun.',
            ]),
            OtpPurpose::ResetPassword => implode("\n", [
                '*Kode Reset Password CreativePOS*',
                '',
                'Kode Anda: *'.$this->code.'*',
                'Berlaku '.$expiryMinutes.' menit.',
            ]),
            default => 'Kode verifikasi CreativePOS: '.$this->code.'. Berlaku '
                .$expiryMinutes.' menit.',
        };

        app(WhatsappService::class)->send($this->identifier, $message, $this->tenantId);
    }

    protected function sendSms(): void
    {
        Log::info('SMS OTP (dev mode)', [
            'phone' => $this->identifier,
            'code' => $this->code,
        ]);
    }

    protected function purposeLabel(?OtpPurpose $purpose): string
    {
        return match ($purpose) {
            OtpPurpose::Login => 'Kode Verifikasi 2FA',
            OtpPurpose::ResetPassword => 'Kode Reset Password',
            OtpPurpose::Register => 'Kode Verifikasi Pendaftaran',
            OtpPurpose::VerifyPhone => 'Kode Verifikasi Nomor HP',
            OtpPurpose::Transaction => 'Kode Verifikasi Transaksi',
            default => 'Kode Verifikasi',
        };
    }

    protected function emailSubject(?OtpPurpose $purpose): string
    {
        return match ($purpose) {
            OtpPurpose::Login => 'Kode Verifikasi 2FA — CreativePOS',
            OtpPurpose::ResetPassword => 'Kode Reset Password — CreativePOS',
            default => 'Kode Verifikasi — CreativePOS',
        };
    }
}