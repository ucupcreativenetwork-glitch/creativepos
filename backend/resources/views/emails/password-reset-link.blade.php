@include('emails.partials.document-open', [
    'title' => 'Reset Password — CreativePOS',
    'preheader' => 'Klik link untuk mengatur ulang password akun CreativePOS Anda. Berlaku ' . ($expireMinutes ?? 60) . ' menit.',
])
@include('emails.partials.header', [
    'heading' => 'Atur Ulang Password',
    'subtitle' => 'Permintaan reset password untuk akun Anda',
    'badge' => '🔐',
])

<p style="margin:0 0 16px;font-size:15px;color:#334155;line-height:1.7;">
    Halo <strong style="color:#0f172a;">{{ $userName }}</strong>,
</p>
<p style="margin:0 0 20px;font-size:15px;color:#475569;line-height:1.7;">
    Kami menerima permintaan untuk mengatur ulang password akun <strong>CreativePOS</strong> Anda.
    Klik tombol di bawah untuk membuat password baru:
</p>

@include('emails.partials.button', [
    'url' => $resetUrl,
    'label' => 'Buat Password Baru',
])

@include('emails.partials.alert', [
    'type' => 'warning',
    'message' => '⏱ Link ini berlaku selama ' . $expireMinutes . ' menit. Setelah itu Anda perlu meminta link baru.',
])

<p style="margin:0 0 8px;font-size:13px;color:#64748b;line-height:1.6;">
    Jika tombol tidak berfungsi, salin dan tempel link berikut ke browser:
</p>
<p style="margin:0 0 20px;padding:12px 14px;background-color:#f8fafc;border:1px solid #e2e8f0;border-radius:8px;font-size:12px;color:#2563eb;word-break:break-all;line-height:1.5;">
    {{ $resetUrl }}
</p>

@include('emails.partials.alert', [
    'type' => 'danger',
    'message' => '⚠️ Jika Anda tidak meminta reset password, abaikan email ini. Password Anda tidak akan berubah.',
])

@include('emails.partials.footer')