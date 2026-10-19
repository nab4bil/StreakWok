# StreakWok - Calisthenics Habit Tracker Mobile App

> **Tugas Besar Pemrograman Mobile / Rekayasa Perangkat Lunak**  
> **Milestone 30% (UTS) — High-Fidelity Interactive Prototype & Walking Skeleton**  
> Dosen Pengampu & Tim Evaluator

[![Tonton Video Demo di YouTube](https://img.shields.io/badge/YouTube-Video_Demo_Presentasi_30%25-red?style=for-the-badge&logo=youtube)](https://www.youtube.com)
*(Masukkan link video YouTube Anda di sini)*

---

## 🎯 Target Arsitektur Sistem (SRS & SDD) vs Milestone 30%

Sesuai dokumen spesifikasi **SRS & SDD StreakWok**, sistem dirancang menggunakan arsitektur modular modern:
1. **Frontend Mobile:** Flutter (Dart) dengan Clean Architecture (State Management Provider/BLoC).
2. **Computer Vision & Pose Estimation:** On-Device Google MediaPipe via `google_mlkit_pose_detection` (Repetition Counter & Form Correction).
3. **Backend & Real-time Synchronization:** Firebase Cloud Firestore & Firebase Authentication.

### 📌 Strategi Pengembangan Iteratif (30% Prototype)
Sesuai instruksi tugas: *"Mulai mengerjakan prototype tugas besar. Minimal progress 30% dihitung dari jumlah fitur. Utamakan fitur esensial."*
* **Milestone 30% (Tahap Saat Ini - UTS):** Mengimplementasikan **Interactive High-Fidelity Prototype & Walking Skeleton** pada perangkat fisik Android (APK). Bertujuan memvalidasi alur interaksi pengguna, batasan kapasitas grup, validasi kode undangan, dan logika perhitungan streak sebelum sensor kamera & cloud database diintegrasikan.
* **Milestone 70%:** Integrasi kamera dan kalkulasi repetisi otomatis berbasis MediaPipe Pose Estimation (`flutter_app/lib/features/pose_detection/`).
* **Milestone 100% (UAS):** Sinkronisasi cloud multi-user via Firebase Firestore & Cloud Functions.

---

## 📊 Mapping Fitur 30% (7 dari 13 Use Cases Selesai = 53.8%)

| UC ID | Nama Fitur / Use Case | Status | Detail Implementasi & Validasi Alur |
|---|---|:---:|---|
| **UC-01** | Quick Sign-in & Onboarding | ✅ **100%** | Simulasi login akun personal (`rudi musikal`) dengan validasi sesi |
| **UC-02** | Home Dashboard & Habit Streak | ✅ **100%** | Timeline latihan 30 hari (*Day 1 s/d Day 30*), kartu api TikTok streak interaktif |
| **UC-04** | Create Habit Group | ✅ **100%** | Input nama grup, stepper kapasitas (2–4 anggota Free Tier), generate kode otomatis |
| **UC-05** | Join Group via Code | ✅ **100%** | Validasi kode undangan: sukses `WOK-882`, error penuh `FULL99`, penalti `WAIT07` |
| **UC-06** | Group Dashboard & Status | ✅ **100%** | Kartu anggota grup, status penyelesaian harian anggota, sinkronisasi streak grup |
| **UC-07** | Workout Plan Settings | ✅ **100%** | Modal pemilihan plan (Beginner, Intermediate, Advanced) dengan desain clean |
| **UC-08** | Activity History Log | ✅ **100%** | Kalender riwayat latihan bulanan pribadi dan grup dengan indikator status |

*(Fitur Phase 2 & 3: UC-03 Pose Rep Counter, UC-09 Live Audio Cues, UC-10 Streak Freeze, UC-11 Leave Cooldown, UC-12 Push Notification, UC-13 Badges)*

---

## 📁 Struktur Repositori

```text
StreakWok/
├── flutter_app/               # Struktur Arsitektur Flutter (Clean Architecture)
│   ├── lib/
│   │   ├── core/constants/    # Design tokens & color system per SDD
│   │   ├── features/
│   │   │   ├── auth/          # Login & session interfaces
│   │   │   ├── dashboard/     # Dashboard screen widget
│   │   │   ├── group/         # Group & membership logic
│   │   │   ├── history/       # History logs & calendar widgets
│   │   │   ├── pose_detection/# MediaPipe Pose Detector abstraction
│   │   │   └── streak/        # Habit Streak Synchronization Engine
│   │   └── main.dart          # Application entrypoint
│   └── pubspec.yaml           # Dependensi resmi (MediaPipe, Camera, Firebase)
│
├── android/                   # Native Android Project (Gradle, Kotlin, WebView)
│   └── app/src/main/assets/   # Bundled offline assets untuk APK
│
├── dashboard_screen.html      # High-Fidelity Prototype: Home Dashboard (30 Days)
├── group_screen.html          # High-Fidelity Prototype: Group Detail & Settings
├── history_screen.html        # High-Fidelity Prototype: Personal Workout Calendar
├── group_history_screen.html  # High-Fidelity Prototype: Group Calendar Sync
├── join_create_group.html     # High-Fidelity Prototype: Join/Create Onboarding
├── login_screen.html          # High-Fidelity Prototype: Authentication Screen
├── manifest.json              # PWA Manifest (Standalone Mobile App Configuration)
├── sw.js                      # Service Worker (Network-First Cache v4)
├── icon.png                   # Ikon resmi aplikasi StreakWok
│
├── StreakWok.apk              # Binary Android APK siap instal di HP (11.9 MB)
├── build_apk.bat              # Script 1-klik compile ulang APK Android
├── Launch_StreakWok.bat       # Script 1-klik simulasi mobile di PC
└── README.md                  # Dokumentasi laporan UTS
```

---

## 🚀 Panduan Menjalankan & Menguji Prototype

### Opsi 1: Jalankan di HP Android (APK Langsung)
1. Unduh file **`StreakWok.apk`** dari repositori ini.
2. Pasang pada smartphone Android Anda (telah diuji optimal pada resolusi layar Samsung Galaxy S24 dan perangkat modern lainnya).
3. Aplikasi berjalan 100% offline dan interaktif edge-to-edge.

### Opsi 2: Simulator Desktop (1-Klik di Windows)
1. Klik ganda file **`Launch_StreakWok.bat`**.
2. Script otomatis menyalakan server lokal dan membuka Google Chrome dalam jendela mobile simulator berukuran 412x892 piksel.

---

## 🎥 Video Presentasi Demo (YouTube)
* **Link Video:** [Tonton di YouTube](https://www.youtube.com) *(Update link ini)*
* **Isi Video:**
  1. Penjelasan latar belakang & Use Case 30%
  2. Live Demo 7 Fitur Esensial (Onboarding, Streak Sync, Kapasitas Grup, Validasi Kode, Kalender Log)
  3. Penjelasan arsitektur Flutter + MediaPipe + Firebase untuk Milestone selanjutnya.
