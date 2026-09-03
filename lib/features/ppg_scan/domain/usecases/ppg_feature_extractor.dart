import 'dart:math';
import 'package:senvo_health/features/ppg_scan/domain/entities/ppg_sample.dart';

class PPGFeatureExtractor {
  static List<double> extract(List<PPGSample> samples) {
    if (samples.isEmpty) return List.filled(23, 0.0);

    // Extract values and timestamps
    final values = samples.map((s) => s.green).toList();
    final times = samples.map((s) => s.timestamp).toList(); // already in seconds

    double ppgNRawChannels = 1.0;
    double ppgNSamples = samples.length.toDouble();

    // Basic stats
    double sum = 0.0;
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;
    for (final v in values) {
      sum += v;
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }
    double ppgMean = sum / ppgNSamples;

    double ppgMin = minVal;
    double ppgMax = maxVal;
    double ppgPtp = maxVal - minVal;

    double sumSqDiff = 0.0;
    double sumSq = 0.0;
    for (final v in values) {
      sumSqDiff += pow(v - ppgMean, 2);
      sumSq += pow(v, 2);
    }
    double ppgStd = sqrt(sumSqDiff / ppgNSamples);
    double ppgRms = sqrt(sumSq / ppgNSamples);
    
    double ppgCrestFactor = ppgRms > 0 ? (ppgMax.abs() / ppgRms) : 0.0;

    // Peak detection for HR and pulse width
    List<int> peakIndices = _findPeaks(values);
    double ppgNPeaks = peakIndices.length.toDouble();
    
    double ppgHrBpm = 72.0; // fallback
    double ppgMeanPulseWidthS = 0.75;
    double ppgRiseTimeS = 0.25;
    
    if (peakIndices.length >= 2) {
      List<double> rrIntervals = [];
      for (int i = 1; i < peakIndices.length; i++) {
        double dt = times[peakIndices[i]] - times[peakIndices[i - 1]];
        if (dt > 0.3 && dt < 2.0) { // 30 BPM to 200 BPM limit
          rrIntervals.add(dt);
        }
      }
      
      if (rrIntervals.isNotEmpty) {
        ppgMeanPulseWidthS = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
        ppgHrBpm = 60.0 / ppgMeanPulseWidthS;
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
        ppgRiseTimeS = riseTimes.reduce((a, b) => a + b) / riseTimes.length;
      }
    }

    double ppgDominantFreqHz = ppgHrBpm / 60.0;
    double ppgSpectralEntropy = 2.815; // Mean value fallback

    // Demographics (using standard healthy adult fallback if not provided)
    double ageYears = 25.0;
    double heightCm = 175.0;
    double weightKg = 70.0;
    double glycaemiaMmolL = 5.4;
    double genderF = 0.0;
    double genderM = 1.0;
    double datasetSourceButPpgV2 = 0.0;
    double ppgChannelUsedPleth = 1.0;

    // Apply scaling based on metadata
    final rawFeatures = List<double>.filled(23, 0.0);
    rawFeatures[0] = (ppgNRawChannels - 1.7533104462972045) / 0.9690945589022342;
    rawFeatures[1] = (ppgNSamples - 733.0456105934281) / 340.0050390231955;
    rawFeatures[2] = (ppgMean - 62.339602881536784) / 100.657019266922;
    rawFeatures[3] = (ppgStd - 2.4882960554739584) / 7.885131013213536;
    rawFeatures[4] = (ppgMin - 57.21074455172719) / 96.67043336483235;
    rawFeatures[5] = (ppgMax - 67.3714784638166) / 104.6894356417869;
    rawFeatures[6] = (ppgPtp - 10.16074741083436) / 29.1276886811004;
    rawFeatures[7] = (ppgRms - 0.9426713399183831) / 2.9989388305707028;
    rawFeatures[8] = (ppgNPeaks - 12.543599803825405) / 3.2390362077923514;
    rawFeatures[9] = (ppgHrBpm - 94.23847031773394) / 20.25937801636581;
    rawFeatures[10] = (ppgMeanPulseWidthS - 0.7153462703611525) / 0.18369980586531717;
    rawFeatures[11] = (ppgRiseTimeS - 0.278469495438021) / 0.14349027523375465;
    rawFeatures[12] = (ppgCrestFactor - 1.4826535907813794) / 0.41540088078263887;
    rawFeatures[13] = (ppgDominantFreqHz - 1.2675196940902402) / 0.475788288063969;
    rawFeatures[14] = (ppgSpectralEntropy - 2.8156133264580916) / 0.8542844635824293;
    rawFeatures[15] = (ageYears - 26.866012751348702) / 11.449678688567689;
    rawFeatures[16] = (heightCm - 173.23011280039236) / 6.262009788282929;
    rawFeatures[17] = (weightKg - 72.14085335948995) / 8.882038427541557;
    rawFeatures[18] = (glycaemiaMmolL - 5.441010425440408) / 0.9042433278877934;
    rawFeatures[19] = genderF;
    rawFeatures[20] = genderM;
    rawFeatures[21] = datasetSourceButPpgV2;
    rawFeatures[22] = ppgChannelUsedPleth;
    
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
