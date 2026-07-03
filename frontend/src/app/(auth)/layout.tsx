import Link from "next/link";
import { Store } from "lucide-react";

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen flex flex-col bg-gradient-to-br from-slate-50 via-blue-50/30 to-slate-100">
      <header className="px-6 py-8">
        <Link href="/" className="inline-flex items-center gap-2.5 group">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-md shadow-primary/25 transition-transform group-hover:scale-105">
            <Store className="h-5 w-5" />
          </div>
          <div>
            <p className="text-lg font-bold text-foreground leading-tight">
              CreativePOS
            </p>
            <p className="text-xs text-muted-foreground">
              by Creative Network
            </p>
          </div>
        </Link>
      </header>

      <main className="flex flex-1 items-center justify-center px-4 pb-12">
        <div className="w-full max-w-md">{children}</div>
      </main>

      <footer className="px-6 py-6 text-center text-sm text-muted-foreground">
        &copy; {new Date().getFullYear()} Creative Network. All rights reserved.
      </footer>
    </div>
  );
}