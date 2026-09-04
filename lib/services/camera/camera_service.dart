import 'package:camera/camera.dart';
import '../../core/errors/scan_exception.dart';

class CameraService {
  CameraController? _controller;
  CameraController? get controller => _controller;
  bool get isReady => _controller?.value.isInitialized ?? false;
  bool get hasTorch => _controller != null;

  Future<void> initialize() async {
    if (isReady) return;
    try {
      final cameras = await availableCameras();
      final rear = cameras
          .where((camera) => camera.lensDirection == CameraLensDirection.back)
          .firstOrNull;
      if (rear == null) throw const CameraInitializationFailed();
      final controller = CameraController(
        rear,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      _controller = controller;
    } on ScanException {
      rethrow;
    } catch (_) {
      throw const CameraInitializationFailed();
    }
  }

  Future<void> enableTorch() async {
    final controller = _controller;
    if (controller == null || !hasTorch) throw const TorchUnavailable();
    try {
      await controller.setFlashMode(FlashMode.torch);
    } catch (_) {
      throw const TorchUnavailable();
    }
  }

  Future<void> disableTorch() async {
    await _controller?.setFlashMode(FlashMode.off);
  }

  Future<void> dispose() async {
    await disableTorch();
    await _controller?.dispose();
    _controller = null;
  }
}
