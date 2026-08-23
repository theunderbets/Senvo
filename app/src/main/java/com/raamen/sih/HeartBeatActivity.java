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
import androidx.appcompat.widget.SwitchCompat;
import org.json.JSONObject;

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

public class HeartBeatActivity extends AppCompatActivity {

    private static final String TAG = "HeartBeatActivity";
    private static final int PERMISSION_REQUEST_CAMERA = 10;
    private static final int MEASUREMENT_DURATION = 30000; // 30 seconds

    private PreviewView previewView;
    private TextView bpmText;
    private TextView statusText;
    private ProgressBar progressBar;
    private LineChart ppgChart;
    private SwitchCompat aiSwitch;

    private SignalProcessor signalProcessor;
    private boolean isMeasurementActive = false;
    private ListenableFuture<ProcessCameraProvider> cameraProviderFuture;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_heartbeat);

        previewView = findViewById(R.id.previewView);
        bpmText = findViewById(R.id.bpmText);
        statusText = findViewById(R.id.statusText);
        progressBar = findViewById(R.id.HRPB);
        ppgChart = findViewById(R.id.ppgChart);
        aiSwitch = findViewById(R.id.aiSwitch);

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
            
            // Enable Flash/Torch
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
                int bpm = signalProcessor.calculateBPM();
                if (bpm != -1) {
                    bpmText.setText(String.valueOf(bpm));
                    statusText.setText("Recording steady signal...");
                    statusText.setTextColor(Color.GREEN);
                }
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

        LineData lineData = new LineData(dataSet);
        ppgChart.setData(lineData);
        ppgChart.notifyDataSetChanged();
        ppgChart.invalidate();
    }

    private void startMeasurement() {
        isMeasurementActive = true;
        new CountDownTimer(MEASUREMENT_DURATION, 100) {
            public void onTick(long millisUntilFinished) {
                int progress = (int) ((MEASUREMENT_DURATION - millisUntilFinished) * 100 / MEASUREMENT_DURATION);
                progressBar.setProgress(progress);
            }

            public void onFinish() {
                isMeasurementActive = false;
                finishMeasurement();
            }
        }.start();
    }

    private void finishMeasurement() {
        int finalBpm = signalProcessor.calculateBPM();
        boolean valid = signalProcessor.getSQI();

        if (valid && finalBpm != -1 && aiSwitch.isChecked()) {
            try {
                JSONObject payload = new JSONObject();
                payload.put("raw_bpm", finalBpm);
                
                NvidiaHealthManager.getInstance().refineVitals(this, payload, response -> {
                    int refinedBpm = response.optInt("refined_bpm", finalBpm);
                    sendResult(refinedBpm, true);
                });
            } catch (Exception e) {
                sendResult(finalBpm, false);
            }
        } else {
            sendResult((valid && finalBpm != -1) ? finalBpm : -1, false);
        }
    }

    private void sendResult(int score, boolean aiRefined) {
        Intent intent = new Intent(HeartBeatActivity.this, ResultActivity.class);
        intent.putExtra("name", "Heart Rate");
        intent.putExtra("score", score);
        intent.putExtra("ai_refined", aiRefined);
        intent.putExtra("normal", "60 - 100");
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
