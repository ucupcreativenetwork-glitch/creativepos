export default function OfflinePage() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-4 p-6 text-center">
      <h1 className="text-2xl font-bold">Anda sedang offline</h1>
      <p className="max-w-md text-muted-foreground">
        Buka halaman POS untuk melanjutkan transaksi. Data akan disinkronkan
        otomatis saat koneksi kembali.
      </p>
      <a
        href="/pos"
        className="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground"
      >
        Buka POS
      </a>
    </div>
  );
}