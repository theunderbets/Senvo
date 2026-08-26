import 'package:camera/camera.dart';

abstract interface class CameraDataSource {
  Future<List<CameraDescription>> available();
}

class PluginCameraDataSource implements CameraDataSource {
  @override
  Future<List<CameraDescription>> available() => availableCameras();
}
