package com.raamen.sih;

import android.content.Context;
import android.content.Intent;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.button.MaterialButton;

public class DisasterGuardActivity extends AppCompatActivity implements SensorEventListener {

    private TextView tempText;
    private TextView predictionText;
    private MaterialButton offlineGuideBtn;
    private SensorManager sensorManager;
    private Sensor tempSensor;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_disaster_guard);

        tempText = findViewById(R.id.tempText);
        predictionText = findViewById(R.id.predictionText);
        offlineGuideBtn = findViewById(R.id.offlineFirstAidButton);

        sensorManager = (SensorManager) getSystemService(Context.SENSOR_SERVICE);
        tempSensor = sensorManager.getDefaultSensor(Sensor.TYPE_AMBIENT_TEMPERATURE);

        if (tempSensor == null) {
            tempText.setText("Ambient: 32°C (Simulated)");
        }

        offlineGuideBtn.setOnClickListener(v -> {
            Toast.makeText(this, "Opening Offline Emergency Guide...", Toast.LENGTH_SHORT).show();
            // In a real app, this would open a local Markdown/PDF with first aid
        });

        fetchAiEarlyWarning();
    }

    private void fetchAiEarlyWarning() {
        String prompt = "Local temperature is 38C, AQI is 245. User has a resting HR of 85. " +
                "Predict the health risk for a potential heat wave event and give advice in 3 short points.";
        
        AiMlManager.getInstance().fetchCompletion(this, prompt, response -> {
            try {
                String aiResponse = response.getJSONArray("choices")
                        .getJSONObject(0)
                        .getJSONObject("message")
                        .getString("content");
                predictionText.setText(aiResponse);
            } catch (Exception e) {
                predictionText.setText("Stay hydrated and avoid outdoor activity during peak heat hours.");
            }
        });
    }

    @Override
    public void onSensorChanged(SensorEvent event) {
        if (event.sensor.getType() == Sensor.TYPE_AMBIENT_TEMPERATURE) {
            tempText.setText("Ambient: " + event.values[0] + "°C");
        }
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {}

    @Override
    protected void onResume() {
        super.onResume();
        if (tempSensor != null) {
            sensorManager.registerListener(this, tempSensor, SensorManager.SENSOR_DELAY_NORMAL);
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        sensorManager.unregisterListener(this);
    }
}
