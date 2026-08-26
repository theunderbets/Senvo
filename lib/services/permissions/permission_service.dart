import 'package:permission_handler/permission_handler.dart';
import '../../core/errors/scan_exception.dart';

class PermissionService {
  Future<void> ensureCameraPermission() async {
    final status = await Permission.camera.status;
    final resolved = status.isDenied
        ? await Permission.camera.request()
        : status;
    if (resolved.isPermanentlyDenied) {
      throw const CameraPermissionPermanentlyDenied();
    }
    if (!resolved.isGranted) throw const CameraPermissionDenied();
  }
}
