@include('emails.partials.document-open', [
    'title' => 'Uji Email — CreativePOS',
    'preheader' => 'Email uji coba dari CreativePOS. Gateway SMTP berhasil dikonfigurasi.',
])
@include('emails.partials.header', [
    'heading' => 'Uji Koneksi Email',
    'subtitle' => 'Gateway SMTP CreativePOS',
    'badge' => '✉️',
])

<p style="margin:0 0 16px;font-size:15px;color:#334155;line-height:1.7;">
    Halo,
</p>
<p style="margin:0 0 20px;font-size:15px;color:#475569;line-height:1.7;">
    Ini adalah email uji coba dari <strong>CreativePOS</strong>.
    Jika Anda menerima email ini dengan tampilan yang benar, berarti gateway SMTP sudah dikonfigurasi dengan baik.
</p>

@include('emails.partials.alert', [
    'type' => 'success',
    'message' => '✓ Koneksi SMTP berhasil. Email notifikasi (reset password, login, 2FA) akan dikirim melalui gateway ini.',
])

<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 20px;background-color:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;">
    <tr>
        <td style="padding:18px 20px;">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                <tr>
                    <td style="padding:6px 0;font-size:13px;color:#64748b;width:100px;">Waktu uji</td>
                    <td style="padding:6px 0;font-size:14px;color:#0f172a;font-weight:600;">{{ $sentAt }}</td>
                </tr>
                @if (!empty($businessName))
                    <tr>
                        <td style="padding:6px 0;font-size:13px;color:#64748b;">Bisnis</td>
                        <td style="padding:6px 0;font-size:14px;color:#0f172a;font-weight:600;">{{ $businessName }}</td>
                    </tr>
                @endif
            </table>
        </td>
    </tr>
</table>

<p style="margin:0;font-size:13px;color:#94a3b8;line-height:1.6;">
    Email ini bukan email reset password. Untuk menguji reset password, gunakan menu <strong>Lupa Password</strong> di halaman login.
</p>

@include('emails.partials.footer')