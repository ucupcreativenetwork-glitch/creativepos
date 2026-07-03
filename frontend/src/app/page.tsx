import Link from "next/link";
import {
  ArrowRight,
  BarChart3,
  CalendarDays,
  Headphones,
  Package,
  QrCode,
  ShoppingCart,
  Store,
  Truck,
  Users,
} from "lucide-react";
import { Button } from "@/components/ui/button";

const features = [
  {
    icon: ShoppingCart,
    title: "POS",
    description: "Kasir cepat, multi-pembayaran, dan manajemen shift",
  },
  {
    icon: Package,
    title: "Inventori",
    description: "Stok real-time, pergerakan barang, dan alert restock",
  },
  {
    icon: Users,
    title: "Member",
    description: "Loyalty poin, tier member, dan wallet digital",
  },
  {
    icon: QrCode,
    title: "QR Menu",
    description: "Menu digital untuk dine-in tanpa antre",
  },
  {
    icon: CalendarDays,
    title: "Reservasi",
    description: "Kelola booking meja dan kapasitas outlet",
  },
  {
    icon: Truck,
    title: "Delivery",
    description: "Pesanan antar dengan tracking driver",
  },
  {
    icon: Headphones,
    title: "CRM",
    description: "Tiket dukungan pelanggan dan FAQ terintegrasi",
  },
  {
    icon: BarChart3,
    title: "Laporan",
    description: "Analitik penjualan, produk, dan performa bisnis",
  },
];

const packages = [
  {
    slug: "starter",
    name: "Starter",
    price: 99000,
    description: "Untuk UMKM dan bisnis kecil",
    highlights: ["1 outlet", "3 pengguna", "100 produk", "Laporan dasar"],
    featured: false,
  },
  {
    slug: "business",
    name: "Business",
    price: 299000,
    description: "Untuk bisnis berkembang",
    highlights: [
      "3 outlet",
      "10 pengguna",
      "500 produk",
      "KDS & Reservasi",
      "CRM dasar",
    ],
    featured: true,
  },
  {
    slug: "enterprise",
    name: "Enterprise",
    price: 799000,
    description: "Multi-outlet skala besar",
    highlights: [
      "10 outlet",
      "50 pengguna",
      "Delivery & WhatsApp",
      "CRM lengkap",
      "Semua fitur",
    ],
    featured: false,
  },
];

function formatPrice(amount: number) {
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

export default function HomePage() {
  return (
    <div className="flex min-h-screen flex-col bg-white">
      {/* Hero */}
      <header className="border-b border-border bg-gradient-to-br from-slate-50 via-blue-50/40 to-slate-100">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-4 sm:px-6">
          <div className="flex items-center gap-2.5">
            <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary text-primary-foreground">
              <Store className="h-4 w-4" />
            </div>
            <div>
              <p className="text-sm font-bold leading-tight">CreativePOS</p>
              <p className="text-[10px] text-muted-foreground">
                Creative Network
              </p>
            </div>
          </div>
          <div className="flex gap-2">
            <Link href="/login">
              <Button variant="ghost" size="sm">
                Masuk
              </Button>
            </Link>
            <Link href="/register">
              <Button size="sm">Daftar Gratis</Button>
            </Link>
          </div>
        </div>

        <div className="mx-auto max-w-6xl px-4 py-16 text-center sm:px-6 sm:py-24">
          <div className="mx-auto mb-6 flex h-16 w-16 items-center justify-center rounded-2xl bg-primary text-primary-foreground shadow-lg shadow-primary/30">
            <Store className="h-8 w-8" />
          </div>
          <h1 className="text-4xl font-bold tracking-tight text-foreground sm:text-5xl">
            Sistem POS Modern
            <br />
            <span className="text-primary">untuk Bisnis Indonesia</span>
          </h1>
          <p className="mx-auto mt-4 max-w-2xl text-lg text-muted-foreground">
            Kelola penjualan, inventori, member, reservasi, delivery, dan
            laporan dalam satu platform — didukung Creative Network.
          </p>
          <div className="mt-8 flex flex-col justify-center gap-3 sm:flex-row">
            <Link href="/register">
              <Button size="lg">
                Mulai Trial 14 Hari
                <ArrowRight className="h-4 w-4" />
              </Button>
            </Link>
            <Link href="/login">
              <Button variant="outline" size="lg">
                Masuk ke Dashboard
              </Button>
            </Link>
          </div>
        </div>
      </header>

      {/* Features */}
      <section className="py-16 sm:py-20">
        <div className="mx-auto max-w-6xl px-4 sm:px-6">
          <div className="text-center">
            <h2 className="text-3xl font-bold tracking-tight">
              Semua yang Bisnis Anda Butuhkan
            </h2>
            <p className="mt-2 text-muted-foreground">
              Modul lengkap dari kasir hingga analitik bisnis
            </p>
          </div>
          <div className="mt-12 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {features.map((feature) => {
              const Icon = feature.icon;
              return (
                <div
                  key={feature.title}
                  className="rounded-xl border border-border bg-white p-6 shadow-sm transition-shadow hover:shadow-md"
                >
                  <div className="mb-4 flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10 text-primary">
                    <Icon className="h-5 w-5" />
                  </div>
                  <h3 className="font-semibold">{feature.title}</h3>
                  <p className="mt-2 text-sm text-muted-foreground">
                    {feature.description}
                  </p>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section id="pricing" className="bg-slate-50 py-16 sm:py-20">
        <div className="mx-auto max-w-6xl px-4 sm:px-6">
          <div className="text-center">
            <h2 className="text-3xl font-bold tracking-tight">
              Harga Transparan
            </h2>
            <p className="mt-2 text-muted-foreground">
              Pilih paket sesuai skala bisnis Anda
            </p>
          </div>
          <div className="mt-12 grid gap-6 lg:grid-cols-3">
            {packages.map((pkg) => (
              <div
                key={pkg.name}
                className={`relative rounded-xl border bg-white p-8 shadow-sm ${
                  pkg.featured
                    ? "border-primary shadow-lg shadow-primary/10 ring-2 ring-primary/20"
                    : "border-border"
                }`}
              >
                {pkg.featured && (
                  <span className="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-primary px-3 py-1 text-xs font-medium text-primary-foreground">
                    Paling Populer
                  </span>
                )}
                <h3 className="text-xl font-bold">{pkg.name}</h3>
                <p className="mt-1 text-sm text-muted-foreground">
                  {pkg.description}
                </p>
                <p className="mt-6">
                  <span className="text-3xl font-bold">
                    {formatPrice(pkg.price)}
                  </span>
                  <span className="text-muted-foreground">/bulan</span>
                </p>
                <ul className="mt-6 space-y-2">
                  {pkg.highlights.map((item) => (
                    <li
                      key={item}
                      className="flex items-center gap-2 text-sm text-muted-foreground"
                    >
                      <span className="h-1.5 w-1.5 rounded-full bg-primary" />
                      {item}
                    </li>
                  ))}
                </ul>
                <Link href={`/register?package=${pkg.slug}`} className="mt-8 block">
                  <Button
                    className="w-full"
                    variant={pkg.featured ? "default" : "outline"}
                  >
                    Daftar Sekarang
                  </Button>
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-16">
        <div className="mx-auto max-w-6xl px-4 text-center sm:px-6">
          <h2 className="text-2xl font-bold sm:text-3xl">
            Siap mengembangkan bisnis Anda?
          </h2>
          <p className="mt-2 text-muted-foreground">
            Bergabung dengan ribuan bisnis yang mempercayai CreativePOS
          </p>
          <Link href="/register" className="mt-6 inline-block">
            <Button size="lg">
              Coba Gratis 14 Hari
              <ArrowRight className="h-4 w-4" />
            </Button>
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="mt-auto border-t border-border bg-slate-900 text-slate-300">
        <div className="mx-auto max-w-6xl px-4 py-12 sm:px-6">
          <div className="flex flex-col items-center justify-between gap-6 sm:flex-row">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary text-primary-foreground">
                <Store className="h-5 w-5" />
              </div>
              <div>
                <p className="font-bold text-white">CreativePOS</p>
                <p className="text-sm">by Creative Network</p>
              </div>
            </div>
            <p className="text-center text-sm">
              © {new Date().getFullYear()} Creative Network. Semua hak
              dilindungi.
            </p>
            <div className="flex gap-4 text-sm">
              <Link href="/login" className="hover:text-white">
                Masuk
              </Link>
              <Link href="/register" className="hover:text-white">
                Daftar
              </Link>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}