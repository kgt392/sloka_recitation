# Sloka Recitation App

A devotional Flutter application reconstructed directly from the original APK, faithfully preserving every feature, layout, color pattern, font, and asset.

---

## 📱 Features

- **Sacred Verses Management (`HomeScreen`)**:
  - Browse, search, add, edit, and delete sacred verses (Sanskrit & transliteration).
  - Search by verse title or text in real-time.
  - Swipe-to-delete with confirmation modal.
  - **Inspirational Quote Carousel**:
    - **A.C. Bhaktivedanta Swami Prabhupada** reading banner: *“Reading and studying ślokas from scriptures like the Bhagavad-gītā As It Is and Śrīmad-Bhāgavatam is not an academic or a mechanical exercise, but a direct spiritual connection with Krishna.”*
    - **Srila Prabhupada Divine Presence** banner: *“When we read Srila Prabhupada’s books, we are sitting in His divine presence...”*
    - **H.H. Radhanath Swami** wisdom & contemplation banners.
    - Interactive dot indicators, auto-rotation, and tap-for-detail modal.

- **Synchronized Recitation Player (`SlokaDetailScreen` & `HighlightedSlokaText`)**:
  - Line-by-line verse auto-highlighting synchronized with audio progress.
  - Smooth auto-scrolling with the *"Following along"* badge indicator.
  - Speed control: `0.75x`, `1.0x`, `1.25x`, `1.5x`.
  - Loop mode: Repeat One, Repeat Off.
  - **Focus Mode**: Distraction-free, dark full-screen recitation interface for contemplation and chanting.
  - In-app microphone audio recording and audio file upload (`.mp3`, `.m4a`, `.wav`, etc.).

- **Quick Play Tab (`PlayScreen`)**:
  - Curated list of all verses with attached audio for rapid recitation practice.

- **Devotional Playlists (`PlaylistScreen` & `PlaylistDetailScreen`)**:
  - Create, rename, and manage custom playlists (e.g., Morning Prayers, Chapter recitations).
  - Add slokas from your library with a multi-select modal picker.
  - Reorderable verse sequence with drag-and-drop.
  - Continuous *"Play All"* audio player with next/previous track controls.

- **Offline-First Playlist Export & Import (`.slokapack`)**:
  - Export entire playlists into self-contained `.slokapack` zip archives containing verses metadata (`manifest.json`) and compressed audio recordings.
  - One-tap sharing via WhatsApp, Telegram, email, or drive.
  - Deep-link / Share-target integration (`ReceiveSharingIntent`): tapping a received `.slokapack` file automatically imports and registers the playlist and audio.
  - Smart de-duplication so existing verses are not overwritten.

- **Branding & Menu (`MenuScreen`)**:
  - Official ISKCON Youth Services (IYS) emblem and branding.
  - Comprehensive *"How to Import / Export a Playlist"* guide.
  - Offline-first Privacy Policy and Terms of Service.

---

## 🎨 Visual Identity & Assets

- **Colors**: Devotional Saffron & Amber Ochre (`#C25E00` / `#B85300`) with warm parchment background (`#FFFBF7`).
- **Typography**: Classical `Noto Serif` for sacred verses and titles.
- **Assets Preserved**:
  - `assets/images/prabhupada_reading.jpg` (Srila Prabhupada reading his books)
  - `assets/images/prabhupada_quote.jpg` (Srila Prabhupada quote banner)
  - `assets/images/swami_reading.jpg` & `assets/images/swami_study.jpg` (H.H. Radhanath Swami)
  - `assets/images/iys_logo.png` & `assets/images/iys_icon.png`
  - `assets/images/deity.jpg`
  - `assets/fonts/MaterialIcons-Regular.otf`

---

## 🛠️ Project Structure

```
sloka_recitation/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       └── kotlin/com/example/sloka_recitation/MainActivity.kt
├── assets/
│   ├── images/
│   │   ├── deity.jpg
│   │   ├── iys_icon.png
│   │   ├── iys_logo.png
│   │   ├── swami_reading.jpg
│   │   └── swami_study.jpg
│   └── fonts/
│       └── MaterialIcons-Regular.otf
├── lib/
│   ├── models/
│   │   ├── sloka.dart
│   │   └── playlist.dart
│   ├── services/
│   │   ├── audio_import.dart
│   │   ├── playlist_share.dart
│   │   └── storage_service.dart
│   ├── widgets/
│   │   ├── branding.dart
│   │   └── sloka_highlight.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── play_screen.dart
│   │   ├── playlist_screen.dart
│   │   ├── playlist_detail_screen.dart
│   │   ├── sloka_detail_screen.dart
│   │   ├── add_edit_sloka_screen.dart
│   │   └── menu_screen.dart
│   ├── theme.dart
│   └── main.dart
└── pubspec.yaml
```

---

## 🚀 Running the App

```bash
# Get dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```
