import 'dart:math' as math;
import 'mediapipe_pose_detector.dart';

/// Supported bodyweight exercises defined in StreakWok's 30-day program & SDD.
enum ExerciseType {
  pushUp,
  squat,
  sitUp,
  plank,
  lunges,
  legRaises,
}

enum ExerciseStage {
  waitingForPose,
  ready,
  activePhase,
  holdGood,
}

class PoseAnalysisResult {
  final bool repIncremented;
  final bool isHoldingForm;
  final ExerciseStage stage;
  final String feedbackMessage;
  final double? primaryAngle;
  final double confidence;

  const PoseAnalysisResult({
    this.repIncremented = false,
    this.isHoldingForm = false,
    required this.stage,
    required this.feedbackMessage,
    this.primaryAngle,
    this.confidence = 0.0,
  });
}

/// Evaluates 33-point BlazePose/MediaPipe skeletal landmarks for each exercise
/// defined in the StreakWok program and tracks clean, debounced repetitions.
class ExercisePoseAnalyzer {
  static const int leftShoulderId = 11;
  static const int rightShoulderId = 12;
  static const int leftElbowId = 13;
  static const int rightElbowId = 14;
  static const int leftWristId = 15;
  static const int rightWristId = 16;
  static const int leftHipId = 23;
  static const int rightHipId = 24;
  static const int leftKneeId = 25;
  static const int rightKneeId = 26;
  static const int leftAnkleId = 27;
  static const int rightAnkleId = 28;

  static const double minVisibility = 0.45;
  static const Duration _repCooldown = Duration(milliseconds: 400);

  ExerciseType _exerciseType;
  ExerciseStage _stage = ExerciseStage.waitingForPose;
  double? _smoothedAngle;
  DateTime? _lastRepAt;
  int _missingPoseFrames = 0;

  ExercisePoseAnalyzer({required String exerciseName})
      : _exerciseType = parseExerciseType(exerciseName);

  ExerciseType get exerciseType => _exerciseType;
  ExerciseStage get stage => _stage;

  static ExerciseType parseExerciseType(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('push-up') || lower.contains('pushup') || lower.contains('push up')) {
      return ExerciseType.pushUp;
    }
    if (lower.contains('squat')) {
      return ExerciseType.squat;
    }
    if (lower.contains('sit-up') || lower.contains('situp') || lower.contains('sit up')) {
      return ExerciseType.sitUp;
    }
    if (lower.contains('plank')) {
      return ExerciseType.plank;
    }
    if (lower.contains('lunge')) {
      return ExerciseType.lunges;
    }
    if (lower.contains('leg')) {
      return ExerciseType.legRaises;
    }
    return ExerciseType.pushUp;
  }

  /// Resets tracking state cleanly when advancing to the next exercise.
  void resetForExercise(String exerciseName) {
    _exerciseType = parseExerciseType(exerciseName);
    _stage = ExerciseStage.waitingForPose;
    _smoothedAngle = null;
    _lastRepAt = null;
    _missingPoseFrames = 0;
  }

  /// Computes interior joint angle at vertex [b] between segments BA and BC (0..180 deg).
  static double calculateAngle(LandmarkPoint a, LandmarkPoint b, LandmarkPoint c) {
    final radians =
        math.atan2(c.y - b.y, c.x - b.x) - math.atan2(a.y - b.y, a.x - b.x);
    var angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }

  PoseAnalysisResult analyze(PoseLandmarkResult result, {DateTime? now}) {
    final timestamp = now ?? result.timestamp;
    final byId = <int, LandmarkPoint>{
      for (final p in result.landmarks) p.id: p,
    };

    switch (_exerciseType) {
      case ExerciseType.pushUp:
        return _analyzePushUp(byId, timestamp);
      case ExerciseType.squat:
        return _analyzeSquat(byId, timestamp);
      case ExerciseType.sitUp:
        return _analyzeSitUp(byId, timestamp);
      case ExerciseType.plank:
        return _analyzePlank(byId);
      case ExerciseType.lunges:
        return _analyzeLunges(byId, timestamp);
      case ExerciseType.legRaises:
        return _analyzeLegRaises(byId, timestamp);
    }
  }

  PoseAnalysisResult _analyzePushUp(Map<int, LandmarkPoint> byId, DateTime now) {
    final triplet = _bestVisibleTriplet(
      byId,
      leftIds: (leftShoulderId, leftElbowId, leftWristId),
      rightIds: (rightShoulderId, rightElbowId, rightWristId),
    );
    if (triplet == null) {
      return _missingPose('Show arms & shoulders in camera');
    }

    // Soft body alignment guard when lower body is visible so casual standing gestures don't trigger.
    final hipGuard = _bestVisibleTriplet(
      byId,
      leftIds: (leftShoulderId, leftHipId, leftKneeId),
      rightIds: (rightShoulderId, rightHipId, rightKneeId),
    );
    if (hipGuard != null && calculateAngle(hipGuard.$1, hipGuard.$2, hipGuard.$3) < 120.0) {
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Keep your torso straight',
        confidence: _tripletConfidence(triplet),
      );
    }

    final elbowAngle = _smooth(calculateAngle(triplet.$1, triplet.$2, triplet.$3));
    return _evaluateCycleDownUp(
      angle: elbowAngle,
      upThreshold: 150.0,
      downThreshold: 100.0,
      readyPrompt: 'Lower chest down',
      downPrompt: 'Good depth • Push up!',
      repDonePrompt: 'Push-up counted!',
      confidence: _tripletConfidence(triplet),
      now: now,
    );
  }

  PoseAnalysisResult _analyzeSquat(Map<int, LandmarkPoint> byId, DateTime now) {
    final left = _getTriplet(byId, leftHipId, leftKneeId, leftAnkleId);
    final right = _getTriplet(byId, rightHipId, rightKneeId, rightAnkleId);

    double? kneeAngle;
    double confidence = 0.0;

    if (left != null && right != null) {
      kneeAngle = (calculateAngle(left.$1, left.$2, left.$3) +
              calculateAngle(right.$1, right.$2, right.$3)) /
          2.0;
      confidence = (_tripletConfidence(left) + _tripletConfidence(right)) / 2.0;
    } else {
      final best = left ?? right;
      if (best == null) {
        return _missingPose('Step back so hips, knees & ankles are visible');
      }
      kneeAngle = calculateAngle(best.$1, best.$2, best.$3);
      confidence = _tripletConfidence(best);
    }

    final smoothed = _smooth(kneeAngle);
    return _evaluateCycleDownUp(
      angle: smoothed,
      upThreshold: 155.0,
      downThreshold: 105.0,
      readyPrompt: 'Squat down',
      downPrompt: 'Good squat • Stand back up!',
      repDonePrompt: 'Squat counted!',
      confidence: confidence,
      now: now,
    );
  }

  PoseAnalysisResult _analyzeSitUp(Map<int, LandmarkPoint> byId, DateTime now) {
    final triplet = _bestVisibleTriplet(
      byId,
      leftIds: (leftShoulderId, leftHipId, leftKneeId),
      rightIds: (rightShoulderId, rightHipId, rightKneeId),
    );
    if (triplet == null) {
      return _missingPose('Keep shoulders, hips & knees in view');
    }

    final hipAngle = _smooth(calculateAngle(triplet.$1, triplet.$2, triplet.$3));
    final confidence = _tripletConfidence(triplet);

    // Peak-counted cycle: lie back (>= 115 deg) -> curl up (<= 75 deg) counts rep immediately
    // while user faces screen, then must return >= 115 deg before next rep triggers.
    if (hipAngle >= 115.0) {
      _stage = ExerciseStage.ready;
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Curl torso up toward knees',
        primaryAngle: hipAngle,
        confidence: confidence,
      );
    }

    if (hipAngle <= 75.0 && _stage == ExerciseStage.ready) {
      if (_canTriggerRep(now)) {
        _stage = ExerciseStage.activePhase;
        _lastRepAt = now;
        return PoseAnalysisResult(
          repIncremented: true,
          stage: _stage,
          feedbackMessage: 'Sit-up counted! Lower back down',
          primaryAngle: hipAngle,
          confidence: confidence,
        );
      }
    }

    return PoseAnalysisResult(
      stage: _stage,
      feedbackMessage: _stage == ExerciseStage.activePhase
          ? 'Lower back down to start next rep'
          : 'Keep curling up',
      primaryAngle: hipAngle,
      confidence: confidence,
    );
  }

  PoseAnalysisResult _analyzePlank(Map<int, LandmarkPoint> byId) {
    final body = _bestVisibleTriplet(
      byId,
      leftIds: (leftShoulderId, leftHipId, leftAnkleId),
      rightIds: (rightShoulderId, rightHipId, rightAnkleId),
    ) ??
        _bestVisibleTriplet(
          byId,
          leftIds: (leftShoulderId, leftHipId, leftKneeId),
          rightIds: (rightShoulderId, rightHipId, rightKneeId),
        );

    if (body == null) {
      _stage = ExerciseStage.waitingForPose;
      return const PoseAnalysisResult(
        isHoldingForm: false,
        stage: ExerciseStage.waitingForPose,
        feedbackMessage: 'Position full body in camera view',
      );
    }

    _missingPoseFrames = 0;
    final bodyAngle = _smooth(calculateAngle(body.$1, body.$2, body.$3));
    final confidence = _tripletConfidence(body);

    final shoulder = body.$1;
    final hip = body.$2;
    final dx = (shoulder.x - hip.x).abs();
    final dy = (shoulder.y - hip.y).abs();

    // Distinguish plank hold (side horizontal OR foreshortened front-on mat pose)
    // from upright standing facing the camera.
    bool isPlankPosture = dx >= dy * 0.9;
    if (!isPlankPosture) {
      final lShoulder = byId[leftShoulderId];
      final rShoulder = byId[rightShoulderId];
      if (lShoulder != null &&
          rShoulder != null &&
          lShoulder.visibility >= minVisibility &&
          rShoulder.visibility >= minVisibility) {
        final shoulderWidth = (lShoulder.x - rShoulder.x).abs();
        if (shoulderWidth > 0 && dy <= shoulderWidth * 1.45) {
          isPlankPosture = true;
        }
      }
    }

    if (isPlankPosture && bodyAngle >= 140.0) {
      _stage = ExerciseStage.holdGood;
      return PoseAnalysisResult(
        isHoldingForm: true,
        stage: _stage,
        feedbackMessage: 'Hold steady • Great plank form!',
        primaryAngle: bodyAngle,
        confidence: confidence,
      );
    }

    _stage = ExerciseStage.ready;
    return PoseAnalysisResult(
      isHoldingForm: false,
      stage: _stage,
      feedbackMessage: !isPlankPosture
          ? 'Get down into plank position'
          : 'Keep back & hips aligned',
      primaryAngle: bodyAngle,
      confidence: confidence,
    );
  }

  PoseAnalysisResult _analyzeLunges(Map<int, LandmarkPoint> byId, DateTime now) {
    final left = _getTriplet(byId, leftHipId, leftKneeId, leftAnkleId);
    final right = _getTriplet(byId, rightHipId, rightKneeId, rightAnkleId);

    if (left == null && right == null) {
      return _missingPose('Keep legs visible in camera view');
    }

    final angles = <double>[
      if (left != null) calculateAngle(left.$1, left.$2, left.$3),
      if (right != null) calculateAngle(right.$1, right.$2, right.$3),
    ];

    final minKneeAngle = _smooth(angles.reduce(math.min));
    final standingAllStraight = angles.every((a) => a >= 155.0);
    final confidence = [
      if (left != null) _tripletConfidence(left),
      if (right != null) _tripletConfidence(right),
    ].reduce((a, b) => a + b) /
        angles.length;

    if (standingAllStraight) {
      if (_stage == ExerciseStage.activePhase && _canTriggerRep(now)) {
        _stage = ExerciseStage.ready;
        _lastRepAt = now;
        return PoseAnalysisResult(
          repIncremented: true,
          stage: _stage,
          feedbackMessage: 'Lunge counted!',
          primaryAngle: minKneeAngle,
          confidence: confidence,
        );
      }
      _stage = ExerciseStage.ready;
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Step forward & bend knee',
        primaryAngle: minKneeAngle,
        confidence: confidence,
      );
    }

    if (minKneeAngle <= 115.0 && _stage == ExerciseStage.ready) {
      _stage = ExerciseStage.activePhase;
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Good lunge • Step back up!',
        primaryAngle: minKneeAngle,
        confidence: confidence,
      );
    }

    return PoseAnalysisResult(
      stage: _stage,
      feedbackMessage: _stage == ExerciseStage.activePhase
          ? 'Return to standing'
          : 'Bend deeper into lunge',
      primaryAngle: minKneeAngle,
      confidence: confidence,
    );
  }

  PoseAnalysisResult _analyzeLegRaises(Map<int, LandmarkPoint> byId, DateTime now) {
    final bodyWithAnkle = _bestVisibleTriplet(
      byId,
      leftIds: (leftShoulderId, leftHipId, leftAnkleId),
      rightIds: (rightShoulderId, rightHipId, rightAnkleId),
    );
    final bodyFallback = _bestVisibleTriplet(
      byId,
      leftIds: (leftShoulderId, leftHipId, leftKneeId),
      rightIds: (rightShoulderId, rightHipId, rightKneeId),
    );
    final triplet = bodyWithAnkle ?? bodyFallback;
    if (triplet == null) {
      return _missingPose('Show torso, hips & legs in camera view');
    }

    // Keep legs mostly straight when ankles are visible so bent knees are discouraged.
    final legStraight = _bestVisibleTriplet(
      byId,
      leftIds: (leftHipId, leftKneeId, leftAnkleId),
      rightIds: (rightHipId, rightKneeId, rightAnkleId),
    );
    if (legStraight != null &&
        calculateAngle(legStraight.$1, legStraight.$2, legStraight.$3) < 125.0) {
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Keep your legs straight',
        confidence: _tripletConfidence(triplet),
      );
    }

    final hipAngle = _smooth(calculateAngle(triplet.$1, triplet.$2, triplet.$3));
    return _evaluateCycleDownUp(
      angle: hipAngle,
      upThreshold: 145.0,
      downThreshold: 110.0,
      readyPrompt: 'Raise straight legs up',
      downPrompt: 'Hold & lower legs slowly',
      repDonePrompt: 'Leg raise counted!',
      confidence: _tripletConfidence(triplet),
      now: now,
    );
  }

  PoseAnalysisResult _evaluateCycleDownUp({
    required double angle,
    required double upThreshold,
    required double downThreshold,
    required String readyPrompt,
    required String downPrompt,
    required String repDonePrompt,
    required double confidence,
    required DateTime now,
  }) {
    if (angle >= upThreshold) {
      if (_stage == ExerciseStage.activePhase && _canTriggerRep(now)) {
        _stage = ExerciseStage.ready;
        _lastRepAt = now;
        return PoseAnalysisResult(
          repIncremented: true,
          stage: _stage,
          feedbackMessage: repDonePrompt,
          primaryAngle: angle,
          confidence: confidence,
        );
      }
      _stage = ExerciseStage.ready;
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: readyPrompt,
        primaryAngle: angle,
        confidence: confidence,
      );
    }

    if (angle <= downThreshold && _stage == ExerciseStage.ready) {
      _stage = ExerciseStage.activePhase;
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: downPrompt,
        primaryAngle: angle,
        confidence: confidence,
      );
    }

    return PoseAnalysisResult(
      stage: _stage,
      feedbackMessage:
          _stage == ExerciseStage.activePhase ? downPrompt : readyPrompt,
      primaryAngle: angle,
      confidence: confidence,
    );
  }

  PoseAnalysisResult _missingPose(String prompt) {
    _missingPoseFrames++;
    if (_missingPoseFrames > 10) {
      _stage = ExerciseStage.waitingForPose;
      _smoothedAngle = null;
    }
    return PoseAnalysisResult(
      stage: ExerciseStage.waitingForPose,
      feedbackMessage: prompt,
    );
  }

  double _smooth(double rawAngle) {
    _missingPoseFrames = 0;
    if (_smoothedAngle == null) {
      _smoothedAngle = rawAngle;
      return rawAngle;
    }
    _smoothedAngle = (0.5 * rawAngle) + (0.5 * _smoothedAngle!);
    return _smoothedAngle!;
  }

  bool _canTriggerRep(DateTime now) {
    if (_lastRepAt == null) return true;
    return now.difference(_lastRepAt!) >= _repCooldown;
  }

  (LandmarkPoint, LandmarkPoint, LandmarkPoint)? _getTriplet(
    Map<int, LandmarkPoint> byId,
    int aId,
    int bId,
    int cId,
  ) {
    final a = byId[aId];
    final b = byId[bId];
    final c = byId[cId];
    if (a == null || b == null || c == null) return null;
    if (a.visibility < minVisibility ||
        b.visibility < minVisibility ||
        c.visibility < minVisibility) {
      return null;
    }
    return (a, b, c);
  }

  (LandmarkPoint, LandmarkPoint, LandmarkPoint)? _bestVisibleTriplet(
    Map<int, LandmarkPoint> byId, {
    required (int, int, int) leftIds,
    required (int, int, int) rightIds,
  }) {
    final left = _getTriplet(byId, leftIds.$1, leftIds.$2, leftIds.$3);
    final right = _getTriplet(byId, rightIds.$1, rightIds.$2, rightIds.$3);
    if (left != null && right != null) {
      return _tripletMinVisibility(left) >= _tripletMinVisibility(right)
          ? left
          : right;
    }
    return left ?? right;
  }

  double _tripletMinVisibility((LandmarkPoint, LandmarkPoint, LandmarkPoint) t) =>
      math.min(t.$1.visibility, math.min(t.$2.visibility, t.$3.visibility));

  double _tripletConfidence((LandmarkPoint, LandmarkPoint, LandmarkPoint) t) =>
      (t.$1.visibility + t.$2.visibility + t.$3.visibility) / 3.0;
}
