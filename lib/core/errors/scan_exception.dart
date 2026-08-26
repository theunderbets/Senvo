sealed class ScanException implements Exception {
  const ScanException(this.userMessage);
  final String userMessage;
}

class CameraPermissionDenied extends ScanException {
  const CameraPermissionDenied()
    : super('Camera permission is needed to scan.');
}

class CameraPermissionPermanentlyDenied extends ScanException {
  const CameraPermissionPermanentlyDenied()
    : super('Camera access is blocked. Enable it in Settings to scan.');
}

class CameraInitializationFailed extends ScanException {
  const CameraInitializationFailed()
    : super('The rear camera could not be initialized.');
}

class TorchUnavailable extends ScanException {
  const TorchUnavailable()
    : super('This device has no usable torch. PPG scanning cannot continue.');
}

class ImageStreamFailed extends ScanException {
  const ImageStreamFailed() : super('The camera stream stopped unexpectedly.');
}

class InsufficientFrames extends ScanException {
  const InsufficientFrames()
    : super('Not enough camera frames were captured. Please try again.');
}

class PoorSignalQuality extends ScanException {
  const PoorSignalQuality()
    : super(
        'Signal quality is too low. Keep your finger steady and cover the lens completely.',
      );
}
