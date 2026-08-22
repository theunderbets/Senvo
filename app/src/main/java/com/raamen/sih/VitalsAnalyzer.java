package com.raamen.sih;

import androidx.annotation.NonNull;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.ImageProxy;

import java.nio.ByteBuffer;

public class VitalsAnalyzer implements ImageAnalysis.Analyzer {

    public interface OnFrameProcessedListener {
        void onIntensityExtracted(double r, double g, double b);
    }

    private final OnFrameProcessedListener listener;

    public VitalsAnalyzer(OnFrameProcessedListener listener) {
        this.listener = listener;
    }

    @Override
    public void analyze(@NonNull ImageProxy image) {
        ImageProxy.PlaneProxy[] planes = image.getPlanes();
        ByteBuffer yBuffer = planes[0].getBuffer();
        ByteBuffer uBuffer = planes[1].getBuffer();
        ByteBuffer vBuffer = planes[2].getBuffer();

        int ySize = yBuffer.remaining();
        int vSize = vBuffer.remaining();

        int width = image.getWidth();
        int height = image.getHeight();
        
        int rowStride = planes[0].getRowStride();
        int pixelStride = planes[0].getPixelStride();
        
        // NVIDIA clinical pipeline: Focus on forehead and upper cheeks
        // ROI: Top-middle 20% of the image (Assuming portrait face)
        int startX = width * 35 / 100;
        int endX = width * 65 / 100;
        int startY = height * 25 / 100;
        int endY = height * 45 / 100;

        long sumR = 0, sumG = 0, sumB = 0;
        int count = 0;

        for (int y = startY; y < endY; y += 4) { // Step 4 to save CPU
            for (int x = startX; x < endX; x += 4) {
                int yIdx = y * rowStride + x * pixelStride;
                int uvIdx = (y / 2) * planes[1].getRowStride() + (x / 2) * planes[1].getPixelStride();

                if (yIdx < ySize && uvIdx < vSize) {
                    int Y = yBuffer.get(yIdx) & 0xFF;
                    int U = uBuffer.get(uvIdx) & 0xFF;
                    int V = vBuffer.get(uvIdx) & 0xFF;

                    // Standard conversion - Green is Y
                    int R = (int) (Y + 1.402 * (V - 128));
                    int G = (int) (Y - 0.344136 * (U - 128) - 0.714136 * (V - 128));
                    int B = (int) (Y + 1.772 * (U - 128));

                    sumR += Math.max(0, Math.min(255, R));
                    sumG += Math.max(0, Math.min(255, G));
                    sumB += Math.max(0, Math.min(255, B));
                    count++;
                }
            }
        }

        if (count > 0) {
            listener.onIntensityExtracted((double) sumR / count, (double) sumG / count, (double) sumB / count);
        }

        image.close();
    }
}
