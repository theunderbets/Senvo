package com.raamen.sih;

import android.content.Context;
import android.util.Log;
import org.json.JSONObject;
import com.android.volley.Response;

/**
 * Singleton Manager to handle NVIDIA AI services for Senvo.
 * This class reads the API key from BuildConfig and provides 
 * a high-level interface for vitals refinement.
 */
public class NvidiaHealthManager {
    private static final String TAG = "NvidiaHealthManager";
    private static NvidiaHealthManager instance;
    private final String apiKey;
    private final NvidiaClient client;

    private NvidiaHealthManager() {
        // Read the key from the securely generated BuildConfig
        this.apiKey = BuildConfig.NVIDIA_API_KEY;
        this.client = new NvidiaClient();
        
        if (apiKey == null || apiKey.isEmpty()) {
            Log.e(TAG, "NVIDIA API Key is missing! Please check local.properties");
        } else {
            Log.i(TAG, "NVIDIA AI Services initialized successfully.");
        }
    }

    public static synchronized NvidiaHealthManager getInstance() {
        if (instance == null) {
            instance = new NvidiaHealthManager();
        }
        return instance;
    }

    /**
     * Sends raw signal data to NVIDIA for high-precision refinement.
     */
    public void refineVitals(Context context, JSONObject rawData, Response.Listener<JSONObject> listener) {
        if (apiKey == null || apiKey.isEmpty()) return;
        client.processSignal(context, rawData, listener, error -> Log.e(TAG, "NVIDIA Refinement Failed: " + error.getMessage()));
    }

    /**
     * Uses NVIDIA Llama-3 NIM to provide medical-contextual advice based on vitals.
     */
    public void getAiAdvice(Context context, String vitalName, String value, String normalRange, Response.Listener<JSONObject> listener) {
        if (apiKey == null || apiKey.isEmpty()) return;

        try {
            JSONObject payload = new JSONObject();
            payload.put("model", "meta/llama-3.1-8b-instruct"); // Using a lighter, highly available model
            
            org.json.JSONArray messages = new org.json.JSONArray();
            
            JSONObject systemMsg = new JSONObject();
            systemMsg.put("role", "system");
            systemMsg.put("content", "You are Senvo AI, a professional medical assistant. " +
                    "Analyze the vital signs provided and explain their health implications in 2-3 clear sentences. " +
                    "Always end with: 'Disclaimer: This is an AI estimate, not medical advice.'");
            messages.put(systemMsg);

            JSONObject userMsg = new JSONObject();
            userMsg.put("role", "user");
            userMsg.put("content", String.format("The user's %s is %s. The normal range is %s.", 
                    vitalName, value, normalRange));
            messages.put(userMsg);

            payload.put("messages", messages);
            payload.put("temperature", 0.5);
            payload.put("top_p", 1);
            payload.put("max_tokens", 1024);
            payload.put("stream", false);

            // Using the primary stable API endpoint
            String llmUrl = "https://integrate.api.nvidia.com/v1/chat/completions";
            
            com.android.volley.toolbox.JsonObjectRequest request = new com.android.volley.toolbox.JsonObjectRequest(
                    com.android.volley.Request.Method.POST,
                    llmUrl,
                    payload,
                    listener,
                    error -> {
                        String errBody = "null";
                        if (error.networkResponse != null && error.networkResponse.data != null) {
                            errBody = new String(error.networkResponse.data);
                        }
                        Log.e(TAG, "NVIDIA LLM Failed: " + error.getMessage() + " | Body: " + errBody);
                    }
            ) {
                @Override
                public java.util.Map<String, String> getHeaders() {
                    java.util.HashMap<String, String> headers = new java.util.HashMap<>();
                    headers.put("Authorization", "Bearer " + BuildConfig.NVIDIA_API_KEY);
                    headers.put("Content-Type", "application/json");
                    return headers;
                }
            };

            com.android.volley.toolbox.Volley.newRequestQueue(context).add(request);

        } catch (Exception e) {
            Log.e(TAG, "Error building LLM payload", e);
        }
    }
}
