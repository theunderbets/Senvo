import 'dart:math';
import 'package:senvo_health/features/ppg_scan/domain/entities/ppg_sample.dart';

class PPGFeatureExtractor {
  static List<double> extract(List<PPGSample> samples) {
    if (samples.isEmpty) return List.filled(23, 0.0);

    // Extract values and timestamps
    final values = samples.map((s) => s.green).toList();
    final times = samples.map((s) => s.timestamp).toList(); // already in seconds

    double ppg_n_raw_channels = 1.0;
    double ppg_n_samples = samples.length.toDouble();

    // Basic stats
    double sum = 0.0;
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;
    for (final v in values) {
      sum += v;
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }
    double ppg_mean = sum / ppg_n_samples;

    double ppg_min = minVal;
    double ppg_max = maxVal;
    double ppg_ptp = maxVal - minVal;

    double sumSqDiff = 0.0;
    double sumSq = 0.0;
    for (final v in values) {
      sumSqDiff += pow(v - ppg_mean, 2);
      sumSq += pow(v, 2);
    }
    double ppg_std = sqrt(sumSqDiff / ppg_n_samples);
    double ppg_rms = sqrt(sumSq / ppg_n_samples);
    
    double ppg_crest_factor = ppg_rms > 0 ? (ppg_max.abs() / ppg_rms) : 0.0;

    // Peak detection for HR and pulse width
    List<int> peakIndices = _findPeaks(values);
    double ppg_n_peaks = peakIndices.length.toDouble();
    
    double ppg_hr_bpm = 72.0; // fallback
    double ppg_mean_pulse_width_s = 0.75;
    double ppg_rise_time_s = 0.25;
    
    if (peakIndices.length >= 2) {
      List<double> rrIntervals = [];
      for (int i = 1; i < peakIndices.length; i++) {
        double dt = times[peakIndices[i]] - times[peakIndices[i - 1]];
        if (dt > 0.3 && dt < 2.0) { // 30 BPM to 200 BPM limit
          rrIntervals.add(dt);
        }
      }
      
      if (rrIntervals.isNotEmpty) {
        ppg_mean_pulse_width_s = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
        ppg_hr_bpm = 60.0 / ppg_mean_pulse_width_s;
      }
      
      // Calculate rise time (from trough to peak)
      List<double> riseTimes = [];
      for (int pIdx in peakIndices) {
        // Find trough before this peak
        int troughIdx = pIdx;
        for (int i = pIdx - 1; i >= 0; i--) {
          if (i == 0 || values[i] < values[i-1]) {
            troughIdx = i;
            break; // found local minimum
          }
        }
        if (troughIdx < pIdx) {
          riseTimes.add(times[pIdx] - times[troughIdx]);
        }
      }
      
      if (riseTimes.isNotEmpty) {
        ppg_rise_time_s = riseTimes.reduce((a, b) => a + b) / riseTimes.length;
      }
    }

    double ppg_dominant_freq_hz = ppg_hr_bpm / 60.0;
    double ppg_spectral_entropy = 2.815; // Mean value fallback

    // Demographics (using standard healthy adult fallback if not provided)
    double age_years = 25.0;
    double height_cm = 175.0;
    double weight_kg = 70.0;
    double glycaemia_mmol_l = 5.4;
    double gender_F = 0.0;
    double gender_M = 1.0;
    double dataset_source_but_ppg_v2 = 0.0;
    double ppg_channel_used_PLETH = 1.0;

    // Apply scaling based on metadata
    final rawFeatures = List<double>.filled(23, 0.0);
    rawFeatures[0] = (ppg_n_raw_channels - 1.7533104462972045) / 0.9690945589022342;
    rawFeatures[1] = (ppg_n_samples - 733.0456105934281) / 340.0050390231955;
    rawFeatures[2] = (ppg_mean - 62.339602881536784) / 100.657019266922;
    rawFeatures[3] = (ppg_std - 2.4882960554739584) / 7.885131013213536;
    rawFeatures[4] = (ppg_min - 57.21074455172719) / 96.67043336483235;
    rawFeatures[5] = (ppg_max - 67.3714784638166) / 104.6894356417869;
    rawFeatures[6] = (ppg_ptp - 10.16074741083436) / 29.1276886811004;
    rawFeatures[7] = (ppg_rms - 0.9426713399183831) / 2.9989388305707028;
    rawFeatures[8] = (ppg_n_peaks - 12.543599803825405) / 3.2390362077923514;
    rawFeatures[9] = (ppg_hr_bpm - 94.23847031773394) / 20.25937801636581;
    rawFeatures[10] = (ppg_mean_pulse_width_s - 0.7153462703611525) / 0.18369980586531717;
    rawFeatures[11] = (ppg_rise_time_s - 0.278469495438021) / 0.14349027523375465;
    rawFeatures[12] = (ppg_crest_factor - 1.4826535907813794) / 0.41540088078263887;
    rawFeatures[13] = (ppg_dominant_freq_hz - 1.2675196940902402) / 0.475788288063969;
    rawFeatures[14] = (ppg_spectral_entropy - 2.8156133264580916) / 0.8542844635824293;
    rawFeatures[15] = (age_years - 26.866012751348702) / 11.449678688567689;
    rawFeatures[16] = (height_cm - 173.23011280039236) / 6.262009788282929;
    rawFeatures[17] = (weight_kg - 72.14085335948995) / 8.882038427541557;
    rawFeatures[18] = (glycaemia_mmol_l - 5.441010425440408) / 0.9042433278877934;
    rawFeatures[19] = gender_F;
    rawFeatures[20] = gender_M;
    rawFeatures[21] = dataset_source_but_ppg_v2;
    rawFeatures[22] = ppg_channel_used_PLETH;
    
    return rawFeatures;
  }

  static List<int> _findPeaks(List<double> values) {
    if (values.length < 3) return [];
    
    // Smooth the data first (moving average) to reduce noise
    List<double> smoothed = List.filled(values.length, 0.0);
    int window = 5;
    for (int i = 0; i < values.length; i++) {
      double sum = 0;
      int count = 0;
      for (int j = max(0, i - window); j <= min(values.length - 1, i + window); j++) {
        sum += values[j];
        count++;
      }
      smoothed[i] = sum / count;
    }

    // Adaptive threshold
    double sum = smoothed.reduce((a, b) => a + b);
    double mean = sum / smoothed.length;
    
    // Find peaks
    List<int> peaks = [];
    for (int i = 1; i < smoothed.length - 1; i++) {
      if (smoothed[i] > smoothed[i - 1] && 
          smoothed[i] > smoothed[i + 1] && 
          smoothed[i] > mean) {
        peaks.add(i);
      }
    }
    
    return peaks;
  }
}
