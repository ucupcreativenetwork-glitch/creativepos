import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const PUBLIC_ROUTES = [
  "/login",
  "/register",
  "/forgot-password",
  "/reset-password",
  "/two-factor",
  "/verify-email",
  "/change-password",
];

const AUTH_ROUTES = [
  "/login",
  "/register",
  "/forgot-password",
  "/two-factor",
];

function readAuthToken(request: NextRequest): string | undefined {
  const rawToken = request.cookies.get("auth_token")?.value;
  if (!rawToken) return undefined;

  try {
    return decodeURIComponent(rawToken);
  } catch {
    return rawToken;
  }
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const token = readAuthToken(request);

  const isPublicRoute = PUBLIC_ROUTES.some(
    (route) => pathname === route || pathname.startsWith(`${route}/`)
  );
  const isAuthRoute = AUTH_ROUTES.some(
    (route) => pathname === route || pathname.startsWith(`${route}/`)
  );
  const isDashboardRoute =
    pathname.startsWith("/dashboard") ||
    pathname.startsWith("/inventory") ||
    pathname.startsWith("/members") ||
    pathname.startsWith("/settings") ||
    pathname.startsWith("/reports") ||
    pathname.startsWith("/crm") ||
    pathname.startsWith("/pos") ||
    pathname.startsWith("/kitchen") ||
    pathname.startsWith("/reservations") ||
    pathname.startsWith("/delivery") ||
    pathname.startsWith("/kasir");

  // Always allow /login so users can sign in again (stale cookie fix).
  if (token && isAuthRoute && pathname !== "/login") {
    return NextResponse.redirect(new URL("/dashboard", request.url));
  }

  if (!token && isDashboardRoute) {
    const loginUrl = new URL("/login", request.url);
    loginUrl.searchParams.set("redirect", pathname);
    return NextResponse.redirect(loginUrl);
  }

  if (!token && !isPublicRoute && pathname !== "/") {
    const protectedPrefixes = [
      "/dashboard",
      "/inventory",
      "/members",
      "/settings",
      "/reports",
      "/crm",
      "/pos",
      "/kitchen",
      "/reservations",
      "/delivery",
      "/platform",
      "/kasir",
    ];
    if (protectedPrefixes.some((prefix) => pathname.startsWith(prefix))) {
      const loginUrl = new URL("/login", request.url);
      loginUrl.searchParams.set("redirect", pathname);
      return NextResponse.redirect(loginUrl);
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|api|menu).*)"],
};