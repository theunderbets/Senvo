package com.raamen.sih;

import android.content.Context;
import android.util.Log;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.Volley;
import org.json.JSONArray;
import org.json.JSONObject;
import java.util.HashMap;
import java.util.Map;

/**
 * Manager for AiMLAPI.com - Accessing 1000+ AI models for Senvo.
 */
public class AiMlManager {
    private static final String TAG = "AiMlManager";
    private static AiMlManager instance;
    private final String apiKey;
    private static final String BASE_URL = "https://api.aimlapi.com/v1/chat/completions";

    private AiMlManager() {
        this.apiKey = BuildConfig.AIML_API_KEY;
    }

    public static synchronized AiMlManager getInstance() {
        if (instance == null) {
            instance = new AiMlManager();
        }
        return instance;
    }

    public void fetchCompletion(Context context, String prompt, Response.Listener<JSONObject> listener) {
        try {
            JSONObject payload = new JSONObject();
            payload.put("model", "mistralai/mistral-7b-instruct-v0.2"); // Fast, stable model
            
            JSONArray messages = new JSONArray();
            JSONObject msg = new JSONObject();
            msg.put("role", "user");
            msg.put("content", prompt);
            messages.put(msg);
            
            payload.put("messages", messages);

            JsonObjectRequest request = new JsonObjectRequest(
                    Request.Method.POST,
                    BASE_URL,
                    payload,
                    listener,
                    error -> Log.e(TAG, "AiML API Error: " + error.getMessage())
            ) {
                @Override
                public Map<String, String> getHeaders() {
                    Map<String, String> headers = new HashMap<>();
                    headers.put("Authorization", "Bearer " + apiKey);
                    headers.put("Content-Type", "application/json");
                    return headers;
                }
            };

            Volley.newRequestQueue(context).add(request);
        } catch (Exception e) {
            Log.e(TAG, "AiML Payload Error", e);
        }
    }
}
