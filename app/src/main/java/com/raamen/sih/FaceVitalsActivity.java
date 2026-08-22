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
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.google.common.util.concurrent.ListenableFuture;

import java.util.concurrent.ExecutionException;

public class FaceVitalsActivity extends AppCompatActivity {

    private static final String TAG = "FaceVitalsActivity";
    private static final int PERMISSION_REQUEST_CAMERA = 20;
    private static final int MEASUREMENT_DURATION = 20000; // 20s for face scan

    private PreviewView previewView;
    private TextView statusText;
    private TextView vitalsText;
    private ProgressBar scanProgress;

    private SignalProcessor signalProcessor;
    private ListenableFuture<ProcessCameraProvider> cameraProviderFuture;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_face_vitals);

        previewView = findViewById(R.id.previewView);
        statusText = findViewById(R.id.statusText);
        vitalsText = findViewById(R.id.vitalsText);
        scanProgress = findViewById(R.id.scanProgress);

        signalProcessor = new SignalProcessor();

        if (allPermissionsGranted()) {
            startCamera();
        } else {
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.CAMERA}, PERMISSION_REQUEST_CAMERA);
        }
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

        // Use Front Camera for Face Scan
        CameraSelector cameraSelector = new CameraSelector.Builder()
                .requireLensFacing(CameraSelector.LENS_FACING_FRONT)
                .build();

        ImageAnalysis imageAnalysis = new ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build();

        imageAnalysis.setAnalyzer(ContextCompat.getMainExecutor(this), new VitalsAnalyzer((r, g, b) -> {
            runOnUiThread(() -> {
                signalProcessor.addSample(r, g, b);
                if (signalProcessor.isReady()) {
                    int bpm = signalProcessor.calculateBPM(true); // Priority: Green channel
                    if (bpm != -1) {
                        vitalsText.setText("rPPG Pulse: " + bpm + " BPM");
                        vitalsText.setTextColor(Color.GREEN);
                    }
                }
            });
        }));

        try {
            cameraProvider.unbindAll();
            cameraProvider.bindToLifecycle(this, cameraSelector, preview, imageAnalysis);
            startMeasurement();
        } catch (Exception e) {
            Log.e(TAG, "Use case binding failed", e);
        }
    }

    private void startMeasurement() {
        new CountDownTimer(MEASUREMENT_DURATION, 100) {
            public void onTick(long millisUntilFinished) {
                int progress = (int) ((MEASUREMENT_DURATION - millisUntilFinished) * 100 / MEASUREMENT_DURATION);
                scanProgress.setProgress(progress);
                if (millisUntilFinished < 5000) {
                    statusText.setText("Finalizing Scan...");
                }
            }

            public void onFinish() {
                finishMeasurement();
            }
        }.start();
    }

    private void finishMeasurement() {
        int bpm = signalProcessor.calculateBPM();
        int spo2 = signalProcessor.calculateSpO2();

        Intent intent = new Intent(FaceVitalsActivity.this, ResultActivity.class);
        intent.putExtra("name", "Contactless Vitals");
        // Using Green channel primarily for rPPG face
        intent.putExtra("score", bpm != -1 ? bpm : -1);
        intent.putExtra("normal", "Heart Rate: 60-100 BPM");
        startActivity(intent);
        finish();
    }

    private boolean allPermissionsGranted() {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == PERMISSION_REQUEST_CAMERA && allPermissionsGranted()) {
            startCamera();
        } else {
            finish();
        }
    }
}
