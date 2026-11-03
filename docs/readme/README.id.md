# Terax

**Terminal ringan dengan penjelajah folder dan pelacakan Git. Tanpa agen AI bawaan.**

Versi ini adalah fork yang dimodifikasi dari [crynta/terax-ai](https://github.com/crynta/terax-ai), dikelola secara terpisah di [slaatarsi/terax-no-ai](https://github.com/slaatarsi/terax-no-ai). Kredit proyek asli diberikan kepada Crynta dan kontributor upstream.

## Fitur

- Terminal native dengan tab, panel terbagi, pencarian, dan integrasi shell.
- Penjelajah folder dengan pencarian, pengelolaan berkas, dan pembaruan langsung.
- Status Git, diff, staging, commit, push, dan riwayat grafis.
- Editor, server bahasa opsional, pratinjau, dan tema tetap tersedia sebagai alat pendukung.

Tidak ada chat AI, agen, penyedia AI, pelengkapan otomatis AI, atau input suara bawaan. Program CLI tetap dapat dijalankan secara manual. Data AI lama dan hook eksternal tidak dimuat atau dihapus secara otomatis.

## Build dari sumber

Memerlukan Rust stable, Node 22+, pnpm, dan [prasyarat Tauri](https://tauri.app/start/prerequisites/).

```bash
git clone https://github.com/slaatarsi/terax-no-ai.git
cd terax-no-ai
pnpm install
pnpm tauri dev
# Paket produksi:
pnpm tauri build
```

**Peringatan:** konfigurasi pembaruan masih mengarah ke rilis upstream. Menerima pembaruan tersebut dapat mengganti fork ini dengan versi asli. Installer dan paket upstream bukan jaminan versi tanpa AI ini. Tanda tangan khusus fork tidak dijamin.

Lihat [README bahasa Inggris](../../README.md) untuk petunjuk lengkap dan batasan distribusi. Lihat juga [dokumentasi](../README.md), [panduan kontribusi](../../CONTRIBUTING.md), dan [keamanan](../../SECURITY.md). Laporkan masalah di repositori fork ini.

Lisensi [Apache-2.0](../../LICENSE). Kredit dan pemberitahuan asli tetap dipertahankan.
