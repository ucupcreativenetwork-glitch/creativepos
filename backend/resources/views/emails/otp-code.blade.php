@include('emails.partials.document-open', [
    'title' => $purposeLabel . ' — CreativePOS',
    'preheader' => 'Kode verifikasi Anda: ' . $code . '. Berlaku ' . $expiryMinutes . ' menit.',
])
@include('emails.partials.header', [
    'heading' => $purposeLabel,
    'subtitle' => 'Gunakan kode di bawah untuk melanjutkan',
    'badge' => '🔑',
])

@if (!empty($userName))
    <p style="margin:0 0 16px;font-size:15px;color:#334155;line-height:1.7;">
        Halo <strong style="color:#0f172a;">{{ $userName }}</strong>,
    </p>
@endif
<p style="margin:0 0 24px;font-size:15px;color:#475569;line-height:1.7;">
    Masukkan kode verifikasi berikut di aplikasi CreativePOS:
</p>

<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 24px;">
    <tr>
        <td align="center" style="background-color:#eff6ff;border:2px dashed #3b82f6;border-radius:14px;padding:28px 20px;">
            <p style="margin:0 0 6px;font-size:12px;color:#64748b;text-transform:uppercase;letter-spacing:1px;">Kode Verifikasi</p>
            <p style="margin:0;font-size:40px;font-weight:700;letter-spacing:10px;color:#1d4ed8;font-family:'Courier New',Courier,monospace;">{{ $code }}</p>
        </td>
    </tr>
</table>

@include('emails.partials.alert', [
    'type' => 'info',
    'message' => '⏱ Kode berlaku selama ' . $expiryMinutes . ' menit. Jangan bagikan kode ini kepada siapapun.',
])

@include('emails.partials.alert', [
    'type' => 'danger',
    'message' => '⚠️ Jika Anda tidak meminta kode ini, abaikan email ini dan pastikan akun Anda aman.',
])

@include('emails.partials.footer')