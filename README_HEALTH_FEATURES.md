# Health feature boundaries

Senvo's current production-safe foundation is local camera PPG capture, filtering, SQI gating, encrypted local history, and a seven-day valid-record baseline. The heat-stress domain now provides an injectable deterministic scoring engine with cache freshness and explainable factors.

No `.tflite` artifact or training contract is present in this repository, so no model tensor shape, feature order, output mapping, or parity claim is invented. Add a validated model and contract before enabling TFLite inference.

Emergency motion, location, and SMS contracts are platform-neutral. Native Android/iOS adapters must report permission, service, SIM, unsupported, and dispatch outcomes honestly. iOS does not provide a general unattended SMS API; use a user-confirmed compose fallback there. Android background monitoring requires a foreground service and visible notification where supported.

All health values and risk classifications are wellness estimates, not diagnoses. The advisory boundary accepts only high-level summaries and must never receive raw PPG, camera frames, filtered waveforms, feature vectors, tensors, GPS, contacts, or identifiers.
