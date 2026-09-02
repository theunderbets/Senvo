# Senvo Health

**"Your health, watched over - quietly, privately, offline."**

Senvo is a Flutter camera-based PPG wellness screening application developed by Team **The Underbets** for Smart India Hackathon 2026, Problem ID 26181.

The app is designed as a privacy-first wellness screening tool for personal vital monitoring and disaster-resilient health awareness. Results are estimates and are not intended for diagnosis or emergency decision-making.

## Team

| Name | Role | Stream |
| --- | --- | --- |
| Pratik Raj | Team Leader | CS IT |
| Anjali Kumari | Team Member | CSE (IoT & CS) |
| Abhineet | Team Member | CSE |
| Soumyashree Panigrahi | Team Member | CSE (AIML) |
| Subham Kumar | Team Member | ECE |
| Amlan Das | Team Member | CSE |

**Institute:** C. V. Raman Global University

## Features

- **Vital Scanning (PPG):** Rear-camera PPG acquisition to estimate Heart Rate, SpO2, and Blood Pressure, alongside Respiration Rate and HRV metrics. Uses a configurable 64x64 ROI with SQI gating.
- **AI Health Risk Assessment:** Embedded TFLite (`senvo_vitals.tflite`) model evaluates scanned vitals against official WHO physiological baselines to dynamically compute risks across Cardiovascular, Respiratory, Hydration, and Fatigue domains.
- **Environmental Insights:** Live GPS-based environmental data integration (via OpenWeather API) assessing external risks (AQI, Extreme Temperatures) and linking them to personal health advisories.
- **Sleep & Activity Tracking:** Heuristics and sensors to track activity states and sleep contexts, enhancing overall risk predictions.
- **Encrypted Local Storage:** All health history and risk analysis data is locally encrypted using Hive and an OS-backed secure encryption key (`flutter_secure_storage`). History includes pagination, trend rolling, deletion, and full data wipe functionality.
- **Privacy By Design:** 100% offline capable for core features. No cloud sync, analytics, telemetry, or raw camera-frame storage.
- **Dynamic UI:** Intuitive dashboard, real-time risk feedback loop, and time-based personalized greetings. Featuring branding for Make in India, Skill India, and C.V. Raman Global University.

## Architecture & Tech Stack

- **Framework:** Flutter (SDK 3.12.2+)
- **State Management:** BLoC (Business Logic Component)
- **Machine Learning:** TensorFlow Lite (`tflite_flutter`)
- **Sensors:** `camera`, `sensors_plus`, `geolocator`
- **Data Persistence:** `hive`, `shared_preferences`

```text
lib/
├── core/
│   ├── environment/
│   ├── risk/
│   ├── sleep/
│   └── theme/
├── features/
│   ├── emergency/
│   ├── health_risk/
│   ├── ppg_scan/
│   └── vitals_history/
├── presentation/
│   ├── dashboard/
│   ├── history/
│   ├── layout/
│   ├── splash/
│   └── vitals/
└── services/
    ├── camera/
    ├── signal_processing/
    └── tflite/
```

## Privacy and Storage

- Vital history is stored in an encrypted Hive box.
- The database key is generated locally and stored in Android Keystore/iOS Keychain via `flutter_secure_storage`.
- Raw camera frames are never persisted; raw PPG retention is disabled.
- Android backup is disabled for the Flutter application.
- The storage layer contains no cloud database, upload, sync, or telemetry API.
- Users can delete individual measurements, clear history, or wipe the database and encryption key completely.

## Medical Status

Heart rate is estimated from the filtered green-channel PPG waveform. SpO2 uses the ratio-of-ratios behavior, and blood pressure is currently an experimental demo estimator. Health risk assessments use generic WHO baselines. These values are **not clinically validated and must not be used for medical decisions**.

## Development

```sh
flutter pub get       # Install dependencies
flutter analyze       # Static analysis
flutter test          # Unit tests
flutter build apk     # Compile Android App
flutter run           # Launch on a connected device
```
