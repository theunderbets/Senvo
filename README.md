# Senvo Health

Senvo is a Flutter camera-based PPG wellness screening application.

## Features

- Rear-camera PPG acquisition with torch and a configurable 64x64 ROI.
- Timestamp-based sampling, RGB averaging, waveform display, filtering, and SQI gating.
- Consolidated experimental heart-rate, SpO2, and blood-pressure results.
- Encrypted local health history using Hive and an OS-backed secure encryption key.
- No cloud synchronization, network code, analytics, or raw camera-frame storage.

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

SpO2 and blood-pressure values are experimental, non-clinical estimates and must
not be used for medical decisions. Replace the estimator implementation with a
validated model before clinical use.
