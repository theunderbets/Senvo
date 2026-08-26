import 'package:camera/camera.dart';
import '../../features/ppg_scan/data/models/roi_config.dart';
import '../../features/ppg_scan/domain/entities/ppg_sample.dart';

abstract interface class FrameProcessor {
  Future<PPGSample?> process(CameraImage frame, {required double timestamp});
}

class CameraFrameProcessor implements FrameProcessor {
  CameraFrameProcessor({this.roi = const RoiConfig()});
  final RoiConfig roi;

  @override
  Future<PPGSample?> process(
    CameraImage frame, {
    required double timestamp,
  }) async {
    if (frame.format.group == ImageFormatGroup.bgra8888) {
      return _processBgra(frame, timestamp);
    }
    if (frame.format.group != ImageFormatGroup.yuv420 ||
        frame.planes.length < 3) {
      return null;
    }
    final yPlane = frame.planes[0],
        uPlane = frame.planes[1],
        vPlane = frame.planes[2];
    final startX = ((frame.width - roi.width) ~/ 2).clamp(0, frame.width - 1);
    final startY = ((frame.height - roi.height) ~/ 2).clamp(
      0,
      frame.height - 1,
    );
    final endX = (startX + roi.width).clamp(0, frame.width);
    final endY = (startY + roi.height).clamp(0, frame.height);
    double red = 0, green = 0, blue = 0;
    var count = 0;
    for (var y = startY; y < endY; y += 2) {
      for (var x = startX; x < endX; x += 2) {
        final yIndex = y * yPlane.bytesPerRow + x * yPlane.bytesPerPixel!;
        final uvX = x ~/ 2, uvY = y ~/ 2;
        final uIndex = uvY * uPlane.bytesPerRow + uvX * uPlane.bytesPerPixel!;
        final vIndex = uvY * vPlane.bytesPerRow + uvX * vPlane.bytesPerPixel!;
        if (yIndex >= yPlane.bytes.length ||
            uIndex >= uPlane.bytes.length ||
            vIndex >= vPlane.bytes.length) {
          continue;
        }
        final luminance = yPlane.bytes[yIndex].toDouble();
        final chromaU = uPlane.bytes[uIndex].toDouble() - 128;
        final chromaV = vPlane.bytes[vIndex].toDouble() - 128;
        red += (luminance + 1.402 * chromaV).clamp(0, 255);
        green += (luminance - 0.344136 * chromaU - 0.714136 * chromaV).clamp(
          0,
          255,
        );
        blue += (luminance + 1.772 * chromaU).clamp(0, 255);
        count++;
      }
    }
    if (count == 0) {
      return null;
    }
    return PPGSample(
      timestamp: timestamp,
      red: red / count,
      green: green / count,
      blue: blue / count,
    );
  }

  PPGSample? _processBgra(CameraImage frame, double timestamp) {
    final plane = frame.planes.first;
    final bytesPerPixel = plane.bytesPerPixel ?? 4;
    double red = 0, green = 0, blue = 0;
    var count = 0;
    final startX = ((frame.width - roi.width) ~/ 2).clamp(0, frame.width - 1);
    final startY = ((frame.height - roi.height) ~/ 2).clamp(
      0,
      frame.height - 1,
    );
    final endX = (startX + roi.width).clamp(0, frame.width);
    final endY = (startY + roi.height).clamp(0, frame.height);
    for (var y = startY; y < endY; y += 2) {
      for (var x = startX; x < endX; x += 2) {
        final index = y * plane.bytesPerRow + x * bytesPerPixel;
        if (index + 2 >= plane.bytes.length) continue;
        blue += plane.bytes[index];
        green += plane.bytes[index + 1];
        red += plane.bytes[index + 2];
        count++;
      }
    }
    if (count == 0) {
      return null;
    }
    return PPGSample(
      timestamp: timestamp,
      red: red / count,
      green: green / count,
      blue: blue / count,
    );
  }
}
