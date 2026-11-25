import 'dart:async';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../domain/mediapipe_pose_detector.dart';

/// On-device MediaPipe/BlazePose detector powered by Google ML Kit.
class MlKitPoseDetector implements MediaPipePoseDetector {
  PoseDetector? _detector;
  final PoseDetectionModel model;
  final PoseDetectionMode mode;
  final StreamController<PoseLandmarkResult> _controller =
      StreamController<PoseLandmarkResult>.broadcast();
  bool _isDisposed = false;

  MlKitPoseDetector({
    this.model = PoseDetectionModel.base,
    this.mode = PoseDetectionMode.stream,
  });

  bool get isInitialized => _detector != null && !_isDisposed;

  @override
  Future<void> initialize() async {
    if (_isDisposed || _detector != null) return;
    _detector = PoseDetector(
      options: PoseDetectorOptions(
        model: model,
        mode: mode,
      ),
    );
  }

  /// Runs single-frame pose inference from an [InputImage] and converts ML Kit's
  /// first detected pose into domain [PoseLandmarkResult].
  Future<PoseLandmarkResult?> detectFromInputImage(InputImage inputImage) async {
    if (_isDisposed) return null;
    if (_detector == null) {
      await initialize();
    }
    final detector = _detector;
    if (detector == null || _isDisposed) return null;

    final poses = await detector.processImage(inputImage);
    if (_isDisposed) return null;

    if (poses.isEmpty) {
      final empty = PoseLandmarkResult(
        landmarks: const [],
        confidenceScore: 0.0,
        timestamp: DateTime.now(),
      );
      if (!_controller.isClosed) _controller.add(empty);
      return empty;
    }

    final firstPose = poses.first;
    final points = <LandmarkPoint>[];
    double likelihoodSum = 0.0;

    for (final entry in firstPose.landmarks.entries) {
      final lm = entry.value;
      points.add(
        LandmarkPoint(
          id: entry.key.index,
          x: lm.x,
          y: lm.y,
          z: lm.z,
          visibility: lm.likelihood,
        ),
      );
      likelihoodSum += lm.likelihood;
    }

    final result = PoseLandmarkResult(
      landmarks: points,
      confidenceScore: points.isEmpty ? 0.0 : likelihoodSum / points.length,
      timestamp: DateTime.now(),
    );

    if (!_controller.isClosed) _controller.add(result);
    return result;
  }

  @override
  Stream<PoseLandmarkResult> processFrameStream(dynamic cameraImage) {
    if (cameraImage is InputImage) {
      unawaited(detectFromInputImage(cameraImage));
    }
    return _controller.stream;
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await _detector?.close();
    _detector = null;
    await _controller.close();
  }
}
