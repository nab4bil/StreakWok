import 'package:flutter/material.dart';
import '../domain/mediapipe_pose_detector.dart';

/// Draws detected BlazePose skeletal connections and joints over the camera preview.
class LivePoseSkeletonPainter extends CustomPainter {
  final List<LandmarkPoint> landmarks;
  final Size imageSize;
  final bool mirrorHorizontally;
  final Color lineColor;
  final double minVisibility;

  const LivePoseSkeletonPainter({
    required this.landmarks,
    required this.imageSize,
    this.mirrorHorizontally = true,
    this.lineColor = const Color(0xFF00D09E),
    this.minVisibility = 0.45,
  });

  static const List<(int, int)> _boneConnections = [
    // Torso
    (11, 12),
    (11, 23),
    (12, 24),
    (23, 24),
    // Left Arm
    (11, 13),
    (13, 15),
    // Right Arm
    (12, 14),
    (14, 16),
    // Left Leg
    (23, 25),
    (25, 27),
    // Right Leg
    (24, 26),
    (26, 28),
  ];

  static const Set<int> _bodyJointIds = {
    0, // nose
    11, 12, 13, 14, 15, 16,
    23, 24, 25, 26, 27, 28,
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty || imageSize.width <= 0 || imageSize.height <= 0) {
      return;
    }

    final byId = <int, LandmarkPoint>{
      for (final p in landmarks)
        if (p.visibility >= minVisibility) p.id: p,
    };

    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.9)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final jointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (final (startId, endId) in _boneConnections) {
      final a = byId[startId];
      final b = byId[endId];
      if (a == null || b == null) continue;
      canvas.drawLine(_project(a, size), _project(b, size), linePaint);
    }

    for (final id in _bodyJointIds) {
      final p = byId[id];
      if (p == null) continue;
      final offset = _project(p, size);
      canvas.drawCircle(offset, 5.5, borderPaint);
      canvas.drawCircle(offset, 4.0, jointPaint);
    }
  }

  Offset _project(LandmarkPoint p, Size canvasSize) {
    final nx = (p.x / imageSize.width).clamp(0.0, 1.0);
    final ny = (p.y / imageSize.height).clamp(0.0, 1.0);
    final dx = mirrorHorizontally
        ? (1.0 - nx) * canvasSize.width
        : nx * canvasSize.width;
    final dy = ny * canvasSize.height;
    return Offset(dx, dy);
  }

  @override
  bool shouldRepaint(covariant LivePoseSkeletonPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.mirrorHorizontally != mirrorHorizontally ||
        oldDelegate.lineColor != lineColor;
  }
}
