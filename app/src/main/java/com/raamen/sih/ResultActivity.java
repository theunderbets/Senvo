package com.raamen.sih;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.TextView;

import com.android.volley.AuthFailureError;
import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.w3c.dom.Text;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ResultActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_result);

        TextView name = findViewById(R.id.name);
        TextView score = findViewById(R.id.scoreText);
        TextView normal = findViewById(R.id.normal);
        View aiBadge = findViewById(R.id.aiBadge);
        TextView aiAdviceText = findViewById(R.id.aiAdviceText);

        Intent intent = getIntent();
        if (intent != null) {
            String nameText = intent.getStringExtra("name");
            name.setText(nameText);
            
            String normalRange = intent.getStringExtra("normal");
            normal.setText("Normal range\n" + normalRange);
            
            int scoreVal = intent.getIntExtra("score", 0);
            boolean isAiRefined = intent.getBooleanExtra("ai_refined", false);
            
            String scoreString;
            if (isAiRefined) {
                aiBadge.setVisibility(View.VISIBLE);
            }

            if (nameText.equals("Blood Pressure")) {
                scoreString = intent.getStringExtra("score");
                score.setText(scoreString);
            } else {
                if (scoreVal == -1) {
                    scoreString = "Insufficient data";
                    score.setText(scoreString);
                    score.setTextSize(24);
                } else {
                    scoreString = Integer.toString(scoreVal) + (nameText.equals("Blood Oxygen") ? "%" : "");
                    score.setText(scoreString);
                }
            }

            // Fetch AI Advice from NVIDIA
            if (!scoreString.equals("Insufficient data")) {
                NvidiaHealthManager.getInstance().getAiAdvice(this, nameText, scoreString, normalRange, response -> {
                    try {
                        String advice = response.getJSONArray("choices")
                                .getJSONObject(0)
                                .getJSONObject("message")
                                .getString("content");
                        aiAdviceText.setText(advice);
                    } catch (Exception e) {
                        aiAdviceText.setText("Advice unavailable. Please consult a doctor.");
                    }
                });
            } else {
                aiAdviceText.setText("No data to analyze.");
            }

            // Only save if we have valid data
            if (scoreVal != -1 || nameText.equals("Blood Pressure")) {
                DatabaseReference database = FirebaseDatabase.getInstance("https://sih-raamen-default-rtdb.firebaseio.com/").getReference("username");
                HashMap<String, Object> map = new HashMap<>();

                map.put("date", System.currentTimeMillis());
                map.put("type", nameText);
                if (nameText.equals("Blood Pressure")) {
                    map.put("score", intent.getStringExtra("score"));
                } else {
                    map.put("score", scoreVal);
                }
                database.child(Long.toString(System.currentTimeMillis())).setValue(map);
            }
        }
    }
}