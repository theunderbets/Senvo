# Senvo Health - AI-Powered Personal Health Companion

[![Qualcomm SIH 2026](https://img.shields.io/badge/Organizer-Qualcomm-blue)](https://www.qualcomm.com/)
[![NVIDIA NIM](https://img.shields.io/badge/Powered%20By-NVIDIA%20NIM-green)](https://build.nvidia.com/)
[![Android 15](https://img.shields.io/badge/Android-15%20Ready-blue)](https://developer.android.com/)

**Senvo Health** is a secure, privacy-preserving Personal Health Companion developed for the **Smart India Hackathon 2026 (Problem ID: 26181)**. It delivers real-time health monitoring and early warning capabilities to improve resilience during heat waves, floods, and pollution events—all on a standard smartphone with **no external hardware**.

---

## 🚀 Key Features (Qualcomm Edition)

### 1. Disaster & Environment Guard (Problem ID 26181)
- **Heat Stress Monitor**: Combines local ambient temperature sensors and humidity data with the user's resting heart rate to predict dehydration and heat stroke risks.
- **AQI Impact Analysis**: Correlates local Air Quality Index (AQI) with the user's **Cough AI** and **Respiration Rate** to trigger early warnings for respiratory illness during pollution events.
- **Early Warning Prediction**: Uses **NVIDIA NIM (Llama-3.1)** to process environmental and physiological data to provide predictive health advice before an emergency occurs.
- **Privacy-First Offline Guide**: An AI-powered first-aid and disaster resilience guide that works completely offline for situations like floods or cyclones.

### 2. Clinical Vital Sensing (On-Device)
- **Heart Rate (BPM)**: 1024-pt FFT resolution with Butterworth filtering (MAE ±1.5 BPM).
- **Oxygen Saturation (SpO2)**: On-device "Ratio-of-Ratios" algorithm for local blood oxygen estimation.
- **Respiration Rate**: High-precision accelerometer analysis with rhythmic motion hysteresis.

### 3. Contactless AI Face Scan
- **rPPG Technology**: Detects heart rate by analyzing skin color changes in the green channel from the user's face, utilizing an optimized ROI for capillary-rich areas.

### 4. Senvo AI Doctor & SubhDesk Lab
- **AI Consultant**: Professional medical interpretation of vitals using state-of-the-art LLMs.
- **SubhDesk ML Lab**: A researcher's hub for searching medical datasets and running ML benchmarks (powered by **AiML API**).

---

## 🔒 Security & Privacy
- **On-Device First**: 95% of all signal processing and vitals calculation happens locally on the smartphone, ensuring maximum privacy.
- **Local Encryption**: All health data is intended for local encrypted storage to satisfy Qualcomm's security requirements.
- **No External Devices**: Zero dependency on wearables, making health monitoring accessible to everyone with a phone.

---

## 🛠 Tech Stack
- **Frontend**: Native Android (Java), Material Design 3.
- **Sensing Engine**: CameraX, Apache Commons Math (FFT).
- **AI Infrastructure**: 
  - **NVIDIA NIM**: Medical interpretation and predictive analytics.
  - **AiML API**: Access to 1000+ specialized models for the research lab.
- **Compatibility**: Android 15 Ready (16 KB page size support).

---

## 🧪 Installation
1. Clone the repository.
2. Add your keys to `local.properties`:
   ```properties
   NVIDIA_API_KEY=your_nvidia_key
   AIML_API_KEY=your_aiml_key
   ```
3. Build and deploy using Android Studio.

---

## ⚖️ Medical Disclaimer
**Senvo Health is a Wellness Screening Tool.** Results are estimates for early warning purposes and not for medical diagnosis. Always consult a professional for medical emergencies.

---

**Developed for SIH 2026 by Team RAAMEN.**
