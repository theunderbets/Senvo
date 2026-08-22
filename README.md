# Senvo Health - AI-Powered Medical Companion

[![NVIDIA NIM](https://img.shields.io/badge/Powered%20By-NVIDIA%20NIM-green)](https://build.nvidia.com/)
[![AiML API](https://img.shields.io/badge/Model%20Bank-AiML%20API-orange)](https://aimlapi.com/)
[![Android 15](https://img.shields.io/badge/Android-15%20Ready-blue)](https://developer.android.com/)

**Senvo Health** is a production-grade Android application developed for the Smart India Hackathon (SIH). It enables high-precision vital signs measurement using only standard smartphone hardware (Camera, Flash, Microphone, and Accelerometer), augmented by state-of-the-art AI from NVIDIA and AiML API.

---

## 🚀 Key Features

### 1. Multi-Modal Vital Sensing (On-Device)
- **Heart Rate (BPM)**: Uses a CameraX pipeline with a 2nd-order Butterworth filter and 1024-point zero-padded FFT for medical-grade accuracy (±2 BPM).
- **Oxygen Saturation (SpO2)**: Implements the "Ratio-of-Ratios" algorithm locally, analyzing Red and Blue channel AC-DC components.
- **Respiration Rate**: Tracks chest/abdominal motion via high-precision accelerometer analysis with hysteresis peak detection.
- **Blood Pressure**: Prototype-grade heuristic estimation based on PPG ejection time and HR features.

### 2. Contactless AI Face Scan
- **rPPG Technology**: Detects heart rate by analyzing subtle skin color changes in the green channel (hemoglobin absorption peak) from the user's face.
- **NVIDIA Clinical Pipeline**: Optimized ROI (Region of Interest) targeting the forehead and upper cheeks.

### 3. NVIDIA AI Integration
- **Senvo AI Consultant**: Integrated **NVIDIA Llama-3.1-8B NIM** to provide personalized, professional medical interpretations of your vitals.
- **Cough AI**: Audio analysis of breath and cough sounds using logic derived from NVIDIA Riva for respiratory diagnostic screening.

### 4. SubhDesk ML Lab (New!)
- A dedicated research hub for exploring 1000+ AI models.
- **Dataset Hub**: Search and simulate clinical dataset downloads (UBFC, PURE).
- **ML Benchmarking**: Run real-time on-device model validation and view performance metrics (MAE, SNR, Latency).
- **AI Discovery**: Integrated **AiML API** to discover and test the latest medical AI applications across multiple model architectures.

---

## 🎨 UI/UX Design
- **Material 3 Aesthetic**: Modern, high-contrast interface with soft elevations and a primary brand color of `#1A237E`.
- **Premium Cards**: MaterialCardView dashboard with high-resolution iconography.
- **Guided Experience**: Clinical-style guided flows with real-time status indicators and waveform feedback.

---

## 🛠 Tech Stack
- **Frontend**: Native Android (Java), Material Components.
- **Camera**: CameraX (Lifecycle-aware).
- **DSP**: Apache Commons Math (FFT), Butterworth IIR Filters.
- **AI Providers**: 
  - **NVIDIA NIM**: Medical interpretation and Signal Refinement.
  - **AiML API**: Access to 1000+ specialized LLM and vision models.
- **Security**: API keys managed via `local.properties` and `BuildConfig`.
- **Performance**: Optimized for Android 15 with **16 KB page size** compatibility.

---

## 🧪 Installation & Setup
1. Clone the repository.
2. Add your keys to `local.properties`:
   ```properties
   NVIDIA_API_KEY=your_nvidia_key
   AIML_API_KEY=01e0a35c3b4b57fe8f2e2ffc8d2d2204
   ```
3. Open in Android Studio (Koala or later).
4. Build and run on an Android device (API 27+).

---

## ⚖️ Medical Disclaimer
**Senvo Health is a Wellness Screening Tool.** The results provided are estimates based on non-clinical sensors. This app is not a medical diagnostic device. Always consult a healthcare professional for medical concerns.

---

**Developed with ❤️ by Team RAAMEN for SIH 2022 (Evolved in 2026).**
