package com.raamen.sih;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.media.MediaRecorder;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.util.Log;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.google.android.material.button.MaterialButton;

import java.io.File;
import java.io.IOException;

public class CoughAnalysisActivity extends AppCompatActivity {

    private static final String TAG = "CoughAnalysisActivity";
    private static final int PERMISSION_REQUEST_AUDIO = 30;
    
    private TextView statusText;
    private MaterialButton recordButton;
    private MediaRecorder recorder;
    private String audioPath;
    private boolean isRecording = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_cough_analysis);

        statusText = findViewById(R.id.statusText);
        recordButton = findViewById(R.id.recordButton);

        audioPath = getExternalCacheDir().getAbsolutePath() + "/cough_record.3gp";

        recordButton.setOnClickListener(v -> {
            if (!isRecording) {
                if (checkPermissions()) {
                    startRecording();
                } else {
                    requestPermissions();
                }
            } else {
                stopRecording();
            }
        });
    }

    private void startRecording() {
        recorder = new MediaRecorder();
        recorder.setAudioSource(MediaRecorder.AudioSource.MIC);
        recorder.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP);
        recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);
        recorder.setOutputFile(audioPath);

        try {
            recorder.prepare();
            recorder.start();
            isRecording = true;
            recordButton.setText("Stop Recording");
            statusText.setText("Recording... Cough now");
            
            // Auto stop after 5 seconds
            new CountDownTimer(5000, 1000) {
                public void onTick(long millisUntilFinished) {}
                public void onFinish() {
                    if (isRecording) stopRecording();
                }
            }.start();
            
        } catch (IOException e) {
            Log.e(TAG, "Recording failed", e);
        }
    }

    private void stopRecording() {
        if (recorder != null) {
            recorder.stop();
            recorder.release();
            recorder = null;
        }
        isRecording = false;
        recordButton.setText("Start Recording");
        statusText.setText("Analyzing Audio...");
        
        analyzeAudio();
    }

    private void analyzeAudio() {
        // Send to NVIDIA Riva/Audio NIM for analysis
        // For demo, we simulate a successful classification
        try {
            org.json.JSONObject payload = new org.json.JSONObject();
            payload.put("audio_metadata", "cough_sample_3gp");
            
            NvidiaHealthManager.getInstance().getAiAdvice(this, "Breath Sound", "Frequent Cough", "Clear", response -> {
                Intent intent = new Intent(CoughAnalysisActivity.this, ResultActivity.class);
                intent.putExtra("name", "Cough Analysis");
                intent.putExtra("score", 0); // Special case for analysis
                intent.putExtra("ai_refined", true);
                intent.putExtra("normal", "Clear lungs");
                startActivity(intent);
                finish();
            });
        } catch (Exception e) {
            Toast.makeText(this, "Analysis failed", Toast.LENGTH_SHORT).show();
        }
    }

    private boolean checkPermissions() {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED;
    }

    private void requestPermissions() {
        ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.RECORD_AUDIO}, PERMISSION_REQUEST_AUDIO);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == PERMISSION_REQUEST_AUDIO && grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            startRecording();
        }
    }
}
