import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "USD/JPY Binary Options System",
  description: "Trading signal system with self-learning capabilities",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ja">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased min-h-screen flex flex-col`}
      >
        <header className="bg-slate-900 text-white px-4 py-3 shadow-lg">
          <div className="max-w-7xl mx-auto flex items-center justify-between">
            <h1 className="text-xl font-bold">USD/JPY Binary Options</h1>
            <nav className="flex gap-4 text-sm">
              <span className="text-slate-400">Chart</span>
              <span className="text-slate-400">History</span>
              <span className="text-slate-400">Settings</span>
            </nav>
          </div>
        </header>
        <main className="flex-1 bg-slate-950">
          {children}
        </main>
        <footer className="bg-slate-900 text-slate-400 px-4 py-2 text-center text-sm">
          <p>USD/JPY Binary Options System v0.1.0</p>
        </footer>
      </body>
    </html>
  );
}
