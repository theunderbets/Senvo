package com.raamen.sih;

import org.apache.commons.math3.complex.Complex;
import org.apache.commons.math3.transform.DftNormalization;
import org.apache.commons.math3.transform.FastFourierTransformer;
import org.apache.commons.math3.transform.TransformType;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class SignalProcessor {
    private static final int WINDOW_SIZE = 256; 
    private static final double FPS = 30.0;
    
    private final List<Double> redSamples = new ArrayList<>();
    private final List<Double> greenSamples = new ArrayList<>();
    private final List<Double> blueSamples = new ArrayList<>();
    
    private final List<Double> filteredRed = new ArrayList<>();
    private final List<Double> filteredGreen = new ArrayList<>();
    private final List<Double> filteredBlue = new ArrayList<>();
    
    private final ButterworthFilter redFilter = new ButterworthFilter();
    private final ButterworthFilter greenFilter = new ButterworthFilter();
    private final ButterworthFilter blueFilter = new ButterworthFilter();
    
    public void addSample(double r, double g, double b) {
        redSamples.add(r);
        greenSamples.add(g);
        blueSamples.add(b);
        
        filteredRed.add(redFilter.filter(r));
        filteredGreen.add(greenFilter.filter(g));
        filteredBlue.add(blueFilter.filter(b));
        
        if (redSamples.size() > WINDOW_SIZE) {
            redSamples.remove(0);
            greenSamples.remove(0);
            blueSamples.remove(0);
            filteredRed.remove(0);
            filteredGreen.remove(0);
            filteredBlue.remove(0);
        }
    }
    
    public boolean isReady() {
        return redSamples.size() == WINDOW_SIZE;
    }
    
    public boolean getSQI() {
        if (!isReady()) return false;
        double sum = 0;
        for (double d : filteredGreen) sum += d;
        double mean = sum / WINDOW_SIZE;
        
        double sumSq = 0;
        for (double d : filteredGreen) sumSq += Math.pow(d - mean, 2);
        double stdDev = Math.sqrt(sumSq / WINDOW_SIZE);
        
        return stdDev > 0.05 && stdDev < 60.0;
    }
    
    /**
     * Enhanced BPM calculation using Detrending and NVIDIA-range (0.75 - 3.0 Hz)
     * Primary channel: Green (Index 1) for rPPG
     */
    public int calculateBPM(boolean isFaceScan) {
        if (!isReady()) return -1;
        
        List<Double> activeSignal = isFaceScan ? greenSamples : redSamples;
        int fftSize = 1024;
        double[] signal = new double[fftSize];
        
        // 1. Detrending (Subtract Mean)
        double mean = 0;
        for (double d : activeSignal) mean += d;
        mean /= WINDOW_SIZE;

        for (int i = 0; i < WINDOW_SIZE; i++) {
            signal[i] = activeSignal.get(i) - mean;
        }
        
        // 2. FFT
        FastFourierTransformer transformer = new FastFourierTransformer(DftNormalization.STANDARD);
        Complex[] fft = transformer.transform(signal, TransformType.FORWARD);
        
        double maxPower = -1;
        int maxIndex = -1;
        
        // NVIDIA Range: 0.75Hz to 3.0Hz (45 to 180 BPM)
        int minIdx = (int) (0.75 * fftSize / FPS);
        int maxIdx = (int) (3.0 * fftSize / FPS);
        
        for (int i = minIdx; i <= maxIdx; i++) {
            double power = fft[i].abs();
            if (power > maxPower) {
                maxPower = power;
                maxIndex = i;
            }
        }
        
        if (maxIndex == -1) return -1;
        double freq = (double) maxIndex * FPS / fftSize;
        return (int) (freq * 60);
    }

    public int calculateBPM() {
        return calculateBPM(false);
    }

    public int calculateSpO2() {
        if (!isReady()) return -1;

        double acRed = calculateAC(filteredRed);
        double dcRed = calculateDC(redSamples);
        
        double acBlue = calculateAC(filteredBlue);
        double dcBlue = calculateDC(blueSamples);
        
        if (dcRed == 0 || dcBlue == 0 || acBlue == 0) return -1;
        double R = (acRed / dcRed) / (acBlue / dcBlue);
        double spo2 = 110 - 25 * R;
        
        return (int) Math.max(70, Math.min(100, spo2));
    }

    private double calculateAC(List<Double> samples) {
        double max = -Double.MAX_VALUE;
        double min = Double.MAX_VALUE;
        for (double d : samples) {
            if (d > max) max = d;
            if (d < min) min = d;
        }
        return (max - min);
    }

    private double calculateDC(List<Double> samples) {
        double sum = 0;
        for (double d : samples) sum += d;
        return sum / samples.size();
    }
    
    public List<Double> getFilteredSamples() {
        return Collections.unmodifiableList(filteredGreen);
    }
    
    public void reset() {
        redSamples.clear();
        greenSamples.clear();
        blueSamples.clear();
        filteredRed.clear();
        filteredGreen.clear();
        filteredBlue.clear();
        redFilter.reset();
        greenFilter.reset();
        blueFilter.reset();
    }
}
