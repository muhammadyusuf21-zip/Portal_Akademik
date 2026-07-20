# 📚 Portal Akademik

Portal Akademik merupakan aplikasi mobile berbasis **Flutter** yang dirancang untuk membantu pengelolaan informasi akademik secara digital. Aplikasi ini menyediakan akses bagi **Mahasiswa** dan **Dosen** untuk melihat informasi akademik secara cepat, mudah, dan efisien.

Backend aplikasi menggunakan **Supabase** sebagai layanan Backend-as-a-Service (BaaS), yang menyediakan autentikasi, database PostgreSQL, dan penyimpanan data secara cloud.

---

## 🚀 Fitur

### Mahasiswa

* Login akun
* Melihat profil
* Melihat jadwal kuliah
* Melihat daftar mata kuliah
* Melihat nilai tugas
* Melihat nilai UTS
* Melihat nilai UAS
* Melihat nilai akhir

### Dosen

* Login akun
* Melihat profil
* Melihat jadwal mengajar
* Menginput nilai mahasiswa
* Mengubah data nilai mahasiswa

### Admin
* Membuat akun Dosen/Mahasiswa
* Memmbuat Jadwal kelas
* approve krs
* Membuat Berita
* kontrol Penuh terhadap semua fitur

---

## 🛠️ Teknologi yang Digunakan

| Teknologi      | Keterangan                                                  |
| -------------- | ----------------------------------------------------------- |
| Flutter        | Framework pengembangan aplikasi mobile                      |
| Dart           | Bahasa pemrograman utama                                    |
| Supabase       | Backend as a Service (Authentication & PostgreSQL Database) |
| Android Studio | IDE pengembangan                                            |
| VS Code        | Code Editor                                                 |
| Git            | Version Control                                             |
| GitHub         | Repository Source Code                                      |

---

## 📂 Struktur Proyek

```text
academic/
├── android/
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── lib/
│   ├── models/
│   ├── pages/
│   ├── services/
│   ├── widgets/
│   ├── utils/
│   └── main.dart
├── test/
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── README.md
└── .gitignore
```

---

## ⚙️ Persyaratan

Sebelum menjalankan aplikasi, pastikan telah menginstal:

* Flutter SDK 3.x atau lebih baru
* Dart SDK
* Android Studio
* Android SDK
* Git

Pastikan perangkat Android atau emulator telah tersedia.

---

## ▶️ Cara Menjalankan Aplikasi

### 1. Clone Repository

```bash
git clone https://github.com/USERNAME/NAMA-REPOSITORY.git
```

### 2. Masuk ke Folder Proyek

```bash
cd NAMA-REPOSITORY
```

### 3. Install Dependency

```bash
flutter pub get
```

### 4. Jalankan Aplikasi

```bash
flutter run
```

---

## 🔑 Konfigurasi Supabase

Aplikasi menggunakan Supabase sebagai backend.

Buat proyek baru di Supabase kemudian sesuaikan konfigurasi berikut pada file konfigurasi aplikasi:

* Supabase URL
* Supabase Anon Key
---

## 📱 Platform

* Android

## 👨‍💻 Pengembang

**Nama:** MUHAMMAD YUSUF

Program Studi Rekayasa Perangkat Lunak

---

## 📄 Lisensi

Repositori ini dibuat untuk keperluan Ujian AKhir Semester. Penggunaan kembali kode sumber diperbolehkan dengan tetap mencantumkan sumber aslinya.

---

## ⭐ Catatan

Repository ini hanya berisi **source code aplikasi**. Data pengguna dan database dikelola menggunakan layanan **Supabase** sehingga tidak terdapat file database lokal pada repository ini.
