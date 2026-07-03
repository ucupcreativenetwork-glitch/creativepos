@include('emails.partials.document-open', [
    'title' => 'Notifikasi Login — CreativePOS',
    'preheader' => 'Login baru terdeteksi di akun CreativePOS Anda dari ' . ($deviceName ?? 'perangkat tidak diketahui') . '.',
])
@include('emails.partials.header', [
    'heading' => 'Login Terdeteksi',
    'subtitle' => 'Aktivitas masuk baru di akun Anda',
    'badge' => '🔔',
])

<p style="margin:0 0 16px;font-size:15px;color:#334155;line-height:1.7;">
    Halo <strong style="color:#0f172a;">{{ $userName }}</strong>,
</p>
<p style="margin:0 0 20px;font-size:15px;color:#475569;line-height:1.7;">
    Akun CreativePOS Anda baru saja digunakan untuk masuk. Berikut detailnya:
</p>

<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 24px;background-color:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;">
    <tr>
        <td style="padding:18px 20px;">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                <tr>
                    <td style="padding:8px 0;font-size:13px;color:#64748b;width:120px;">🕐 Waktu</td>
                    <td style="padding:8px 0;font-size:14px;color:#0f172a;font-weight:600;">{{ $loginAt }}</td>
                </tr>
                <tr>
                    <td style="padding:8px 0;font-size:13px;color:#64748b;">📱 Perangkat</td>
                    <td style="padding:8px 0;font-size:14px;color:#0f172a;font-weight:600;">{{ $deviceName }}</td>
                </tr>
                <tr>
                    <td style="padding:8px 0;font-size:13px;color:#64748b;">🌐 Alamat IP</td>
                    <td style="padding:8px 0;font-size:14px;color:#0f172a;font-weight:600;">{{ $ipAddress }}</td>
                </tr>
            </table>
        </td>
    </tr>
</table>

@include('emails.partials.alert', [
    'type' => 'warning',
    'message' => '⚠️ Jika ini bukan Anda, segera ubah password dan aktifkan autentikasi dua faktor (2FA) di Pengaturan Akun.',
])

@include('emails.partials.footer')