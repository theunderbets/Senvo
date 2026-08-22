package com.raamen.sih;

import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Toast;

public class VitalsActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_vitals);

        CardView spo2 = findViewById(R.id.spo2);
        CardView bp = findViewById(R.id.bp);
        CardView hr = findViewById(R.id.hr);
        CardView resp = findViewById(R.id.resp);
        CardView contactless = findViewById(R.id.contactless);
        CardView stress = findViewById(R.id.stress);
        CardView cough = findViewById(R.id.cough);
        CardView subhdesk = findViewById(R.id.subhdesk);

        spo2.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(VitalsActivity.this, TimerActivity.class);
                intent.putExtra("name", "spo2");
                startActivity(intent);
            }
        });

        bp.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(VitalsActivity.this, TimerActivity.class);
                intent.putExtra("name", "bp");
                startActivity(intent);
            }
        });

        hr.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(VitalsActivity.this, TimerActivity.class);
                intent.putExtra("name", "hr");
                startActivity(intent);
            }
        });

        resp.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(VitalsActivity.this, TimerActivity.class);
                intent.putExtra("name", "resp");
                startActivity(intent);
            }
        });

        contactless.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(VitalsActivity.this, FaceVitalsActivity.class);
                startActivity(intent);
            }
        });

        cough.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(VitalsActivity.this, CoughAnalysisActivity.class);
                startActivity(intent);
            }
        });

        subhdesk.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(VitalsActivity.this, SubhDeskActivity.class);
                startActivity(intent);
            }
        });

        stress.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Toast.makeText(VitalsActivity.this, "Stress measurement coming soon!", Toast.LENGTH_SHORT).show();
            }
        });
    }
}
