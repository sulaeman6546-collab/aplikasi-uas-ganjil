# Aplikasi UAS Ganjil — Online

Aplikasi web ujian online berbasis React + Supabase. Fitur: akun guru/siswa, bank soal per ujian, pilihan ganda A–E, essay, impor `.docx`, gambar soal, timer, simpan jawaban otomatis, nilai pilihan ganda otomatis, koreksi essay, dan ekspor rekap CSV/Excel.

## Menjalankan di komputer
1. Pasang Node.js 20 atau lebih baru.
2. Buat proyek gratis di https://supabase.com.
3. Buka **SQL Editor** pada proyek Supabase, jalankan seluruh isi `supabase.sql`.
4. Buka **Project Settings → API**, salin Project URL dan `anon public key`.
5. Salin `.env.example` menjadi `.env`, lalu isi kedua nilai tersebut.
6. Jalankan:
   ```bash
   npm install
   npm run dev
   ```
7. Untuk dipublikasikan: `npm run build`, lalu deploy folder `dist` ke Vercel/Netlify. Masukkan variabel `VITE_SUPABASE_URL` dan `VITE_SUPABASE_ANON_KEY` pada pengaturan environment hosting.

## Format impor Word (.docx)
Agar soal terbaca rapi, gunakan pola berikut (satu soal per blok):
```
1. Ibu kota Indonesia adalah ...
A. Bandung
B. Jakarta
C. Surabaya
D. Medan
E. Semarang
Kunci: B
Bobot: 2

2. Jelaskan makna persatuan!
Essay
Bobot: 5
```
- Baris soal dimulai dengan nomor dan titik.
- Pilihan ganda menggunakan awalan A. sampai E.
- Kunci: A/B/C/D/E untuk pilihan ganda.
- Tulis `Essay` untuk soal uraian.
- Gambar di dokumen Word diekstrak dan disisipkan sebagai gambar pada soal terdekat jika didukung oleh struktur dokumen. Setelah impor, periksa kembali hasilnya sebelum menerbitkan.
- Alternatif: tambahkan gambar langsung dari editor soal.

## Catatan keamanan dan kesiapan produksi
- Proyek ini merupakan starter aplikasi yang dapat dijalankan dan dikembangkan. Anda tetap perlu membuat proyek Supabase, menjalankan SQL, mengisi konfigurasi, dan melakukan deploy agar tersedia di internet.
- Untuk sekolah, jangan izinkan pendaftaran publik memilih peran guru. Atur pembuatan akun guru melalui admin/undangan sebelum ujian sungguhan.
- Untuk keamanan ujian berisiko tinggi, pindahkan penilaian kunci jawaban ke fungsi server (Edge Function), terapkan validasi jadwal di server, dan audit RLS. Versi starter ini mengirim kunci jawaban ke browser siswa agar koreksi MCQ langsung; jangan gunakan untuk ujian berisiko tinggi tanpa penguatan tersebut.
- Timer browser membantu mengatur waktu tampilan, tetapi bukan pengganti batas waktu server. Selesaikan penguatan server sebelum penggunaan ujian resmi.
