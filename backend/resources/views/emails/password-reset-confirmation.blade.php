@include('emails.partials.document-open', [
    'title' => 'Password Berhasil Diubah — CreativePOS',
    'preheader' => 'Password akun CreativePOS Anda telah berhasil diubah.',
])
@include('emails.partials.header', [
    'heading' => 'Password Berhasil Diubah',
    'subtitle' => 'Konfirmasi perubahan password akun Anda',
    'badge' => '✅',
])

<p style="margin:0 0 16px;font-size:15px;color:#334155;line-height:1.7;">
    Halo <strong style="color:#0f172a;">{{ $userName }}</strong>,
</p>
<p style="margin:0 0 20px;font-size:15px;color:#475569;line-height:1.7;">
    Password akun CreativePOS Anda telah berhasil diubah.
</p>

<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 24px;background-color:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;">
    <tr>
        <td style="padding:18px 20px;">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                <tr>
                    <td style="padding:6px 0;font-size:13px;color:#64748b;width:130px;">Waktu perubahan</td>
                    <td style="padding:6px 0;font-size:14px;color:#0f172a;font-weight:600;">{{ $changedAt }}</td>
                </tr>
                <tr>
                    <td style="padding:6px 0;font-size:13px;color:#64748b;">Status</td>
                    <td style="padding:6px 0;font-size:14px;color:#16a34a;font-weight:600;">Berhasil dikonfirmasi</td>
                </tr>
            </table>
        </td>
    </tr>
</table>

@include('emails.partials.alert', [
    'type' => 'success',
    'message' => '✓ Anda sekarang dapat masuk ke CreativePOS menggunakan password baru.',
])

@include('emails.partials.button', [
    'url' => $loginUrl,
    'label' => 'Masuk ke CreativePOS',
])

@include('emails.partials.alert', [
    'type' => 'danger',
    'message' => '⚠️ Jika Anda tidak melakukan perubahan ini, segera hubungi administrator dan ubah password Anda.',
])

@include('emails.partials.footer')