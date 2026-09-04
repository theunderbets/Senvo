import 'dart:async';
import 'package:camera/camera.dart';
import '../../../../core/errors/scan_exception.dart';
import '../../../../services/camera/camera_service.dart';
import '../../../../services/camera/frame_processor.dart';
import '../../../../services/permissions/permission_service.dart';
import '../../domain/entities/ppg_sample.dart';
import '../../domain/repositories/ppg_repository.dart';

class CameraPpgRepository implements PpgRepository {
  CameraPpgRepository({
    required this.permissions,
    required this.camera,
    required this.processor,
  });
  final PermissionService permissions;
  final CameraService camera;
  final FrameProcessor processor;

  @override
  Future<List<PPGSample>> acquire({
    required void Function(PPGSample sample) onSample,
    required void Function(double progress) onProgress,
  }) async {
    await permissions.ensureCameraPermission();
    await camera.initialize();
    await camera.enableTorch();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final controller = camera.controller;
    if (controller == null) throw const CameraInitializationFailed();
    final samples = <PPGSample>[];
    var busy = false;
    final stopwatch = Stopwatch()..start();
    try {
      await controller.startImageStream((CameraImage image) {
        if (busy || stopwatch.elapsed >= const Duration(seconds: 10)) return;
        busy = true;
        final timestamp =
            stopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond;
        processor
            .process(image, timestamp: timestamp)
            .then((sample) {
              if (sample != null) {
                samples.add(sample);
                onSample(sample);
              }
            })
            .whenComplete(() => busy = false);
      });
      while (stopwatch.elapsed < const Duration(seconds: 10)) {
        onProgress((stopwatch.elapsedMilliseconds / 10000).clamp(0.0, 1.0));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      onProgress(1);
      await controller.stopImageStream();
      if (samples.length < 30) throw const InsufficientFrames();
      return samples;
    } catch (error) {
      if (error is ScanException) rethrow;
      throw const ImageStreamFailed();
    } finally {
      // Keep camera active for preview, let PpgScanPage handle disposal.
      // We still want to make sure the flash goes off if it was aborted.
      await camera.disableTorch();
    }
  }
}
