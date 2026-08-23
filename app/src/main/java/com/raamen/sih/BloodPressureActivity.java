package com.raamen.sih;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.util.Log;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.camera.core.Camera;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.github.mikephil.charting.charts.LineChart;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineData;
import com.github.mikephil.charting.data.LineDataSet;
import com.google.common.util.concurrent.ListenableFuture;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

public class BloodPressureActivity extends AppCompatActivity {

    private static final String TAG = "BloodPressureActivity";
    private static final int PERMISSION_REQUEST_CAMERA = 10;
    private static final int MEASUREMENT_DURATION = 30000;

    private PreviewView previewView;
    private TextView bpText;
    private TextView statusText;
    private ProgressBar progressBar;
    private LineChart ppgChart;

    private SignalProcessor signalProcessor;
    private ListenableFuture<ProcessCameraProvider> cameraProviderFuture;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_bloodpressure);

        previewView = findViewById(R.id.previewView);
        bpText = findViewById(R.id.bpText);
        statusText = findViewById(R.id.statusText);
        progressBar = findViewById(R.id.HRPB);
        ppgChart = findViewById(R.id.ppgChart);

        signalProcessor = new SignalProcessor();
        setupChart();

        if (allPermissionsGranted()) {
            startCamera();
        } else {
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.CAMERA}, PERMISSION_REQUEST_CAMERA);
        }
    }

    private void setupChart() {
        ppgChart.getDescription().setEnabled(false);
        ppgChart.setDrawGridBackground(false);
        ppgChart.getLegend().setEnabled(false);
        ppgChart.getXAxis().setEnabled(false);
        ppgChart.getAxisLeft().setEnabled(false);
        ppgChart.getAxisRight().setEnabled(false);
        ppgChart.setNoDataText("Initializing signal...");
    }

    private void startCamera() {
        cameraProviderFuture = ProcessCameraProvider.getInstance(this);
        cameraProviderFuture.addListener(() -> {
            try {
                ProcessCameraProvider cameraProvider = cameraProviderFuture.get();
                bindCameraUseCases(cameraProvider);
            } catch (ExecutionException | InterruptedException e) {
                Log.e(TAG, "Camera initialization failed", e);
            }
        }, ContextCompat.getMainExecutor(this));
    }

    private void bindCameraUseCases(@NonNull ProcessCameraProvider cameraProvider) {
        Preview preview = new Preview.Builder().build();
        preview.setSurfaceProvider(previewView.getSurfaceProvider());

        CameraSelector cameraSelector = new CameraSelector.Builder()
                .requireLensFacing(CameraSelector.LENS_FACING_BACK)
                .build();

        ImageAnalysis imageAnalysis = new ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build();

        imageAnalysis.setAnalyzer(ContextCompat.getMainExecutor(this), new VitalsAnalyzer((r, g, b) -> {
            runOnUiThread(() -> processIntensity(r, g, b));
        }));

        try {
            cameraProvider.unbindAll();
            Camera camera = cameraProvider.bindToLifecycle(this, cameraSelector, preview, imageAnalysis);
            
            if (camera.getCameraInfo().hasFlashUnit()) {
                camera.getCameraControl().enableTorch(true);
            }
            
            startMeasurement();
        } catch (Exception e) {
            Log.e(TAG, "Use case binding failed", e);
        }
    }

    private void processIntensity(double r, double g, double b) {
        signalProcessor.addSample(r, g, b);
        updateChart();

        if (signalProcessor.isReady()) {
            if (signalProcessor.getSQI()) {
                statusText.setText("Recording steady signal...");
                statusText.setTextColor(Color.GREEN);
            } else {
                statusText.setText("Adjust finger position - noisy signal");
                statusText.setTextColor(Color.RED);
            }
        }
    }

    private void updateChart() {
        List<Double> samples = signalProcessor.getFilteredSamples();
        if (samples.isEmpty()) return;

        List<Entry> entries = new ArrayList<>();
        for (int i = 0; i < samples.size(); i++) {
            entries.add(new Entry(i, samples.get(i).floatValue()));
        }

        LineDataSet dataSet = new LineDataSet(entries, "PPG");
        dataSet.setColor(Color.parseColor("#2A0371"));
        dataSet.setDrawCircles(false);
        dataSet.setDrawValues(false);
        dataSet.setLineWidth(2f);
        dataSet.setMode(LineDataSet.Mode.CUBIC_BEZIER);

        ppgChart.setData(new LineData(dataSet));
        ppgChart.invalidate();
    }

    private void startMeasurement() {
        new CountDownTimer(MEASUREMENT_DURATION, 100) {
            public void onTick(long millisUntilFinished) {
                int progress = (int) ((MEASUREMENT_DURATION - millisUntilFinished) * 100 / MEASUREMENT_DURATION);
                progressBar.setProgress(progress);
            }

            public void onFinish() {
                finishMeasurement();
            }
        }.start();
    }

    private void finishMeasurement() {
        boolean valid = signalProcessor.getSQI();
        
        // BP Estimation logic (Simplified for demo, based on ET/PPG features)
        // In a real app, this would use a more complex model or Pulse Arrival Time
        int hr = signalProcessor.calculateBPM();
        String bpResult = "Insufficient data";
        
        if (valid && hr != -1) {
            // Heuristic estimation for demo purposes
            int sys = 110 + (hr / 10);
            int dia = 70 + (hr / 15);
            bpResult = sys + "/" + dia;
        }

        Intent intent = new Intent(BloodPressureActivity.this, ResultActivity.class);
        intent.putExtra("name", "Blood Pressure");
        intent.putExtra("score", bpResult);
        intent.putExtra("normal", "90/60 - 120/80");
        startActivity(intent);
        finish();
    }

    private boolean allPermissionsGranted() {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == PERMISSION_REQUEST_CAMERA) {
            if (allPermissionsGranted()) {
                startCamera();
            } else {
                Toast.makeText(this, "Camera permission is required", Toast.LENGTH_SHORT).show();
                finish();
            }
        }
    }
}
