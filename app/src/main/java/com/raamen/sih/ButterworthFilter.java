package com.raamen.sih;

/**
 * A 2nd order Butterworth Bandpass Filter.
 * Optimized for 0.7Hz - 4.0Hz (approx 42 - 240 BPM) at 30 FPS.
 */
public class ButterworthFilter {
    private final double[] x = new double[3];
    private final double[] y = new double[3];
    
    // Coefficients for 30 FPS, 0.7Hz-4Hz Bandpass
    private final double[] a = {1.0, -1.5610180758695182, 0.6413515380575631};
    private final double[] b = {0.03916110609402263, 0.0, -0.03916110609402263};

    public double filter(double sample) {
        x[2] = x[1];
        x[1] = x[0];
        x[0] = sample;

        y[2] = y[1];
        y[1] = y[0];
        y[0] = (b[0] * x[0] + b[1] * x[1] + b[2] * x[2]
                - a[1] * y[1] - a[2] * y[2]) / a[0];

        return y[0];
    }
    
    public void reset() {
        for (int i = 0; i < 3; i++) {
            x[i] = 0;
            y[i] = 0;
        }
    }
}
