/// MediaPipe On-Device Pose Detection Interface (Per SDD Architecture)
/// Designed for Phase 2 (70% Milestone: Camera Stream & Repetition Counter Engine)
abstract class MediaPipePoseDetector {
  /// Initializes the on-device ML model with low-latency GPU/NPU acceleration.
  Future<void> initialize();

  /// Processes camera frame stream and extracts 33 standard skeletal landmarks.
  Stream<PoseLandmarkResult> processFrameStream(dynamic cameraImage);

  /// Disposes active tensor buffers and delegates to prevent memory leaks.
  Future<void> dispose();
}

class PoseLandmarkResult {
  final List<LandmarkPoint> landmarks;
  final double confidenceScore;
  final DateTime timestamp;

  PoseLandmarkResult({
    required this.landmarks,
    required this.confidenceScore,
    required this.timestamp,
  });
}

class LandmarkPoint {
  final int id;
  final double x;
  final double y;
  final double z;
  final double visibility;

  LandmarkPoint({
    required this.id,
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
  });
}
