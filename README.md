# Senvo Health

Senvo is a Flutter camera-based PPG wellness screening application developed by
Team The_Underbets for Smart India Hackathon 2026, Problem ID 26181.

The app is designed as a privacy-first wellness screening tool for personal
vital monitoring and disaster-resilient health awareness. Results are estimates
and are not intended for diagnosis or emergency decision-making.

## Team

| Name | Role | Stream |
| --- | --- | --- |
| Pratik Raj | Team Leader | CS IT |
| Anjali Kumari | Team Member | CSE (IoT & CS) |
| Abhineet | Team Member | CSE |
| Soumyashree Panigrahi | Team Member | CSE (AIML) |
| Subham Kumar | Team Member | ECE |
| Amlan Das | Team Member | CSE |

Institute: C. V. Raman Global University

## Features

- Rear-camera PPG acquisition with torch and a configurable 64x64 ROI.
- Timestamp-based sampling, RGB averaging, waveform display, filtering, and SQI gating.
- Consolidated experimental heart-rate, SpO2, and blood-pressure results.
- Encrypted local health history using Hive and an OS-backed secure encryption key.
- Local-only history with pagination, rolling seven-day baseline, deletion, and full data wipe.
- No cloud synchronization, network code, analytics, or raw camera-frame storage.

## Architecture

```text
lib/
├── core/
│   ├── constants/
│   ├── database/
│   ├── errors/
│   └── security/
├── features/
│   ├── ppg_scan/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── vitals_history/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── services/
    ├── camera/
    ├── permissions/
    └── signal_processing/
```

The PPG pipeline captures one ten-second rear-camera stream, measures actual
frame timing, extracts stride-aware YUV/BGRA pixels from a centered 64x64 ROI,
and retains only RGB channel averages. A latest-frame guard prevents an
unbounded processing queue.

## Privacy and Storage

- Vital history is stored in an encrypted Hive box.
- The database key is generated locally and stored in Android Keystore/iOS Keychain via `flutter_secure_storage`.
- Raw camera frames are never persisted; raw PPG retention is disabled.
- Android backup is disabled for the Flutter application.
- The storage layer contains no HTTP client, cloud database, upload, sync, or telemetry API.
- Users can delete individual measurements, clear history, or wipe the database and encryption key.

## Medical Status

Heart rate is estimated from the filtered green-channel PPG waveform. SpO2 uses
the ratio-of-ratios behavior ported from the earlier prototype, and blood
pressure is currently an experimental demo estimator. These values are not
clinically validated and must not be used for medical decisions.

## Development

```sh
flutter pub get       # Install dependencies
flutter analyze       # Static analysis
flutter test          # Unit tests
flutter run           # Launch on a connected device
```

