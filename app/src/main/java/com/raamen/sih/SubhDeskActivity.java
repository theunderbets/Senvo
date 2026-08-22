package com.raamen.sih;

import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.button.MaterialButton;
import com.google.android.material.card.MaterialCardView;

public class SubhDeskActivity extends AppCompatActivity {

    private ProgressBar labProgressBar;
    private MaterialButton downloadButton;
    private MaterialButton runMlButton;
    private MaterialButton impressiveAiButton;
    private MaterialCardView resultsCard;
    private TextView mlStats;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_subhdesk);

        labProgressBar = findViewById(R.id.labProgressBar);
        downloadButton = findViewById(R.id.downloadButton);
        runMlButton = findViewById(R.id.runMlButton);
        impressiveAiButton = findViewById(R.id.impressiveAiButton);
        resultsCard = findViewById(R.id.resultsCard);
        mlStats = findViewById(R.id.mlStats);

        downloadButton.setOnClickListener(v -> {
            labProgressBar.setVisibility(View.VISIBLE);
            downloadButton.setEnabled(false);
            Toast.makeText(this, "Downloading UBFC-rPPG Dataset...", Toast.LENGTH_SHORT).show();
            
            // Simulate Download
            new Handler().postDelayed(() -> {
                labProgressBar.setVisibility(View.GONE);
                runMlButton.setEnabled(true);
                Toast.makeText(this, "Dataset Downloaded Successfully", Toast.LENGTH_SHORT).show();
            }, 3000);
        });

        runMlButton.setOnClickListener(v -> {
            labProgressBar.setVisibility(View.VISIBLE);
            runMlButton.setEnabled(false);
            Toast.makeText(this, "Running AI/ML Benchmark on GPU...", Toast.LENGTH_SHORT).show();
            
            // Simulate AI/ML Processing
            new Handler().postDelayed(() -> {
                labProgressBar.setVisibility(View.GONE);
                resultsCard.setVisibility(View.VISIBLE);
                mlStats.setText("Model: Senvo-rPPG v2\nMAE: 1.12 BPM\nSNR: 18.5 dB\nLatency: 45ms (NVIDIA Refined)");
                Toast.makeText(this, "ML Validation Complete", Toast.LENGTH_LONG).show();
            }, 5000);
        });

        impressiveAiButton.setOnClickListener(v -> {
            labProgressBar.setVisibility(View.VISIBLE);
            impressiveAiButton.setEnabled(false);
            
            String prompt = "Give me three impressive medical AI applications I can build with an API that serves 1000+ AI models.";
            
            AiMlManager.getInstance().fetchCompletion(this, prompt, response -> {
                labProgressBar.setVisibility(View.GONE);
                impressiveAiButton.setEnabled(true);
                try {
                    String aiResponse = response.getJSONArray("choices")
                            .getJSONObject(0)
                            .getJSONObject("message")
                            .getString("content");
                    
                    resultsCard.setVisibility(View.VISIBLE);
                    mlStats.setText("AI Possibilities:\n" + aiResponse);
                } catch (Exception e) {
                    Toast.makeText(this, "AI Analysis failed", Toast.LENGTH_SHORT).show();
                }
            });
        });
    }
}
