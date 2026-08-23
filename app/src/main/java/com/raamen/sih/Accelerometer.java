package com.raamen.sih;

import android.content.Intent;
import android.graphics.Color;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.util.Log;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import com.github.mikephil.charting.charts.LineChart;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineData;
import com.github.mikephil.charting.data.LineDataSet;

import java.util.ArrayList;
import java.util.List;

public class Accelerometer extends AppCompatActivity implements SensorEventListener {
    private SensorManager sensorManager;
    private final List<Float> zValues = new ArrayList<>();
    private final List<Float> filteredValues = new ArrayList<>();
    
    private TextView timerText;
    private ProgressBar progressBar;
    private LineChart respChart;
    
    private static final int MEASUREMENT_DURATION = 30000;
    private boolean isRecording = false;

    // Lowpass filter for breathing (0.1Hz - 0.5Hz)
    // Simple Alpha filter for real-time visualization
    private float lastFilteredValue = 0;
    private final float alpha = 0.1f;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_accelerometer);

        timerText = findViewById(R.id.timer);
        progressBar = findViewById(R.id.progressBar);
        respChart = findViewById(R.id.respChart);

        setupChart();

        sensorManager = (SensorManager) getSystemService(SENSOR_SERVICE);
        sensorManager.registerListener(this, 
            sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER), 
            SensorManager.SENSOR_DELAY_UI);

        startMeasurement();
    }

    private void setupChart() {
        respChart.getDescription().setEnabled(false);
        respChart.setDrawGridBackground(false);
        respChart.getLegend().setEnabled(false);
        respChart.getXAxis().setEnabled(false);
        respChart.getAxisLeft().setEnabled(false);
        respChart.getAxisRight().setEnabled(false);
    }

    private void startMeasurement() {
        isRecording = true;
        new CountDownTimer(MEASUREMENT_DURATION, 100) {
            public void onTick(long millisUntilFinished) {
                timerText.setText((millisUntilFinished / 1000) + "s");
                int progress = (int) ((MEASUREMENT_DURATION - millisUntilFinished) * 100 / MEASUREMENT_DURATION);
                progressBar.setProgress(progress);
            }

            public void onFinish() {
                isRecording = false;
                timerText.setText("0s");
                calculateRespirationRate();
            }
        }.start();
    }

    @Override
    public void onSensorChanged(SensorEvent event) {
        if (event.sensor.getType() == Sensor.TYPE_ACCELEROMETER && isRecording) {
            float z = event.values[2];
            zValues.add(z);
            
            // Simple low-pass filter for visualization
            lastFilteredValue = alpha * z + (1 - alpha) * lastFilteredValue;
            filteredValues.add(lastFilteredValue);
            
            if (filteredValues.size() > 100) {
                filteredValues.remove(0);
            }
            updateChart();
        }
    }

    private void updateChart() {
        if (filteredValues.isEmpty()) return;

        List<Entry> entries = new ArrayList<>();
        for (int i = 0; i < filteredValues.size(); i++) {
            entries.add(new Entry(i, filteredValues.get(i)));
        }

        LineDataSet dataSet = new LineDataSet(entries, "Respiration");
        dataSet.setColor(Color.parseColor("#2A0371"));
        dataSet.setDrawCircles(false);
        dataSet.setDrawValues(false);
        dataSet.setLineWidth(2f);
        dataSet.setMode(LineDataSet.Mode.CUBIC_BEZIER);

        respChart.setData(new LineData(dataSet));
        respChart.invalidate();
    }

    private void calculateRespirationRate() {
        if (zValues.size() < 10) {
            finishWithResult(-1);
            return;
        }

        // Convert to double array for processing
        double[] data = new double[zValues.size()];
        for (int i = 0; i < zValues.size(); i++) {
            data[i] = zValues.get(i);
        }

        // 1. Remove DC offset (Mean subtraction)
        double sum = 0;
        for (double d : data) sum += d;
        double mean = sum / data.length;
        for (int i = 0; i < data.length; i++) data[i] -= mean;

        // 2. Simple peak detection on filtered data
        int peaks = countPeaks(data);
        
        // Duration is 30s, so multiply by 2 for RR per minute
        int rr = peaks * 2;
        
        // Sanity check for respiration rate (typically 12-20)
        if (rr < 5 || rr > 40) {
            finishWithResult(-1);
        } else {
            finishWithResult(rr);
        }
    }

    private int countPeaks(double[] data) {
        int count = 0;
        boolean lookingForMax = true;
        double threshold = 0.02; // Minimum amplitude to consider a breath
        
        for (int i = 1; i < data.length - 1; i++) {
            if (lookingForMax) {
                if (data[i] > data[i - 1] && data[i] > data[i + 1] && data[i] > threshold) {
                    count++;
                    lookingForMax = false;
                }
            } else {
                if (data[i] < data[i - 1] && data[i] < data[i + 1] && data[i] < -threshold) {
                    lookingForMax = true;
                }
            }
        }
        return count;
    }

    private void finishWithResult(int score) {
        sensorManager.unregisterListener(this);
        Intent intent = new Intent(Accelerometer.this, ResultActivity.class);
        intent.putExtra("name", "Respiration Rate");
        intent.putExtra("score", score);
        intent.putExtra("normal", "12 - 16");
        startActivity(intent);
        finish();
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {}

    @Override
    protected void onPause() {
        super.onPause();
        sensorManager.unregisterListener(this);
    }
}
