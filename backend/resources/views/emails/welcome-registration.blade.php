@include('emails.partials.document-open', [
    'title' => 'Selamat Datang — CreativePOS',
    'preheader' => 'Akun ' . $businessName . ' berhasil didaftarkan di CreativePOS.',
])
@include('emails.partials.header', [
    'heading' => 'Selamat Datang!',
    'subtitle' => 'Akun bisnis Anda siap digunakan',
    'badge' => '🎉',
])

<p style="margin:0 0 16px;font-size:15px;color:#334155;line-height:1.7;">
    Halo <strong style="color:#0f172a;">{{ $userName }}</strong>,
</p>
<p style="margin:0 0 20px;font-size:15px;color:#475569;line-height:1.7;">
    Akun bisnis <strong>{{ $businessName }}</strong> berhasil didaftarkan di CreativePOS.
    Anda sekarang dapat mengelola penjualan, inventori, member, dan laporan dalam satu platform.
</p>

@include('emails.partials.button', [
    'url' => $loginUrl,
    'label' => 'Masuk ke Dashboard',
])

@include('emails.partials.alert', [
    'type' => 'info',
    'message' => '💡 Aktifkan notifikasi login dan 2FA di Pengaturan untuk keamanan akun yang lebih baik.',
])

@include('emails.partials.footer')