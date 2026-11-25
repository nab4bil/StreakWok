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

class _SideBody {
  final LandmarkPoint shoulder;
  final LandmarkPoint? elbow;
  final LandmarkPoint? wrist;
  final LandmarkPoint hip;
  final LandmarkPoint knee;
  final LandmarkPoint ankle;
  final double minVisibility;
  final double confidence;

  const _SideBody({
    required this.shoulder,
    this.elbow,
    this.wrist,
    required this.hip,
    required this.knee,
    required this.ankle,
    required this.minVisibility,
    required this.confidence,
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
  double? _baselineHipY;
  double? _baselineBodyHeight;
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

  /// Camera framing hint shared between analyzer prompts and workout UI overlays.
  static String cameraGuideFor(String exerciseName) {
    switch (parseExerciseType(exerciseName)) {
      case ExerciseType.squat:
      case ExerciseType.lunges:
        return 'Side / 45° view • Full body';
      case ExerciseType.pushUp:
      case ExerciseType.plank:
      case ExerciseType.sitUp:
      case ExerciseType.legRaises:
        return 'Side view • Full body';
    }
  }

  /// Initial guidance shown before pose landmarks stabilize in the camera viewport.
  static String initialPromptFor(String exerciseName) {
    switch (parseExerciseType(exerciseName)) {
      case ExerciseType.pushUp:
        return 'Show full body from side (hands to ankles)';
      case ExerciseType.squat:
        return 'Step back: shoulders to ankles in view';
      case ExerciseType.sitUp:
        return 'Show full body side view on mat';
      case ExerciseType.plank:
        return 'Show full body plank from side (hands to ankles)';
      case ExerciseType.lunges:
        return 'Step back: full body in side / 45° view';
      case ExerciseType.legRaises:
        return 'Lie flat sideways: shoulders to ankles in frame';
    }
  }

  /// Resets tracking state cleanly when advancing to the next exercise.
  void resetForExercise(String exerciseName) {
    _exerciseType = parseExerciseType(exerciseName);
    _stage = ExerciseStage.waitingForPose;
    _smoothedAngle = null;
    _baselineHipY = null;
    _baselineBodyHeight = null;
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
    final side = _bestVisibleSide(byId, requireArm: true);
    if (side == null) {
      return _missingPose('Show full body from side (hands to ankles)');
    }

    final wrist = side.wrist!;
    final elbow = side.elbow!;
    final upperArmLen = _distance(side.shoulder, elbow);
    final isHorizontal = _isHorizontalPosture(
      side.shoulder,
      side.ankle,
      minHorizontalRatio: 0.75,
    );
    // Allow shoulder to descend near floor/wrist height at bottom depth, while blocking
    // hands raised noticeably above shoulders (e.g., lying face-up air punches).
    final handsAboveShoulders = wrist.y < side.shoulder.y - (upperArmLen * 0.20);
    if (!isHorizontal || handsAboveShoulders) {
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Get into full push-up plank position',
        confidence: side.confidence,
      );
    }

    final kneeAngle = calculateAngle(side.hip, side.knee, side.ankle);
    final shoulderLift = wrist.y - side.shoulder.y;
    final armSpan = _distance(side.shoulder, wrist);
    final kneesOnFloorAtTop =
        shoulderLift >= armSpan * 0.35 &&
        _hasKneeOnFloor(side, wrist, shoulderLift);
    if (kneeAngle < 150.0 || kneesOnFloorAtTop) {
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Straighten legs onto toes (no knee push-ups)',
        confidence: side.confidence,
      );
    }

    final bodyAngle = calculateAngle(side.shoulder, side.hip, side.ankle);
    if (bodyAngle < 140.0) {
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Keep torso & hips straight',
        confidence: side.confidence,
      );
    }

    final elbowAngle = _smooth(calculateAngle(side.shoulder, elbow, wrist));
    return _evaluateCycleDownUp(
      angle: elbowAngle,
      upThreshold: 150.0,
      downThreshold: 108.0,
      readyPrompt: 'Lower chest down',
      downPrompt: 'Good depth • Push up!',
      repDonePrompt: 'Push-up counted!',
      confidence: side.confidence,
      now: now,
    );
  }

  PoseAnalysisResult _analyzeSquat(Map<int, LandmarkPoint> byId, DateTime now) {
    final side = _bestVisibleSide(byId);
    if (side == null) {
      return _missingPose('Step back: shoulders to ankles must be visible');
    }

    final upright = _isUprightPosture(side.shoulder, side.ankle, minVerticalRatio: 0.7) &&
        side.shoulder.y < side.hip.y &&
        side.hip.y < side.ankle.y;
    if (!upright) {
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Stand upright in side / 45° view',
        confidence: side.confidence,
      );
    }

    final smoothedKnee = _smooth(calculateAngle(side.hip, side.knee, side.ankle));
    final bodyHeight = (side.ankle.y - side.shoulder.y).abs();

    if (smoothedKnee >= 150.0) {
      _baselineHipY = side.hip.y;
      _baselineBodyHeight = bodyHeight;
      if (_stage == ExerciseStage.activePhase && _canTriggerRep(now)) {
        _stage = ExerciseStage.ready;
        _lastRepAt = now;
        return PoseAnalysisResult(
          repIncremented: true,
          stage: _stage,
          feedbackMessage: 'Squat counted!',
          primaryAngle: smoothedKnee,
          confidence: side.confidence,
        );
      }
      _stage = ExerciseStage.ready;
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Squat down',
        primaryAngle: smoothedKnee,
        confidence: side.confidence,
      );
    }

    if (smoothedKnee <= 110.0 && _stage == ExerciseStage.ready) {
      final hasHipDescended = _baselineHipY == null ||
          _baselineBodyHeight == null ||
          (side.hip.y - _baselineHipY!) >= _baselineBodyHeight! * 0.08;
      if (!hasHipDescended) {
        return PoseAnalysisResult(
          stage: _stage,
          feedbackMessage: 'Lower hips down into squat',
          primaryAngle: smoothedKnee,
          confidence: side.confidence,
        );
      }
      _stage = ExerciseStage.activePhase;
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Good squat • Stand back up!',
        primaryAngle: smoothedKnee,
        confidence: side.confidence,
      );
    }

    return PoseAnalysisResult(
      stage: _stage,
      feedbackMessage: _stage == ExerciseStage.activePhase
          ? 'Good squat • Stand back up!'
          : 'Squat down',
      primaryAngle: smoothedKnee,
      confidence: side.confidence,
    );
  }

  PoseAnalysisResult _analyzeSitUp(Map<int, LandmarkPoint> byId, DateTime now) {
    final side = _bestVisibleSide(byId);
    if (side == null) {
      return _missingPose('Show full body side view on mat');
    }

    // Require hips and ankles grounded horizontally on mat (blocks standing & bowing).
    final legSpan = _distance(side.hip, side.ankle);
    final isGroundedOnMat = legSpan > 0 &&
        (side.hip.y - side.ankle.y).abs() <= legSpan * 0.60;
    if (!isGroundedOnMat) {
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Lie down on mat with knees bent',
        confidence: side.confidence,
      );
    }

    final hipAngle = _smooth(calculateAngle(side.shoulder, side.hip, side.knee));

    // Peak-counted cycle: lie back (>= 115 deg) -> curl up (<= 80 deg) counts rep immediately
    // while user faces screen, then must return >= 115 deg before next rep triggers.
    if (hipAngle >= 115.0) {
      _stage = ExerciseStage.ready;
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Curl torso up toward knees',
        primaryAngle: hipAngle,
        confidence: side.confidence,
      );
    }

    if (hipAngle <= 80.0 && _stage == ExerciseStage.ready) {
      if (_canTriggerRep(now)) {
        _stage = ExerciseStage.activePhase;
        _lastRepAt = now;
        return PoseAnalysisResult(
          repIncremented: true,
          stage: _stage,
          feedbackMessage: 'Sit-up counted! Lower back down',
          primaryAngle: hipAngle,
          confidence: side.confidence,
        );
      }
    }

    return PoseAnalysisResult(
      stage: _stage,
      feedbackMessage: _stage == ExerciseStage.activePhase
          ? 'Lower back down to start next rep'
          : 'Keep curling up',
      primaryAngle: hipAngle,
      confidence: side.confidence,
    );
  }

  PoseAnalysisResult _analyzePlank(Map<int, LandmarkPoint> byId) {
    final side = _bestVisibleSide(byId, requireArm: true);
    if (side == null) {
      _stage = ExerciseStage.waitingForPose;
      return const PoseAnalysisResult(
        isHoldingForm: false,
        stage: ExerciseStage.waitingForPose,
        feedbackMessage: 'Show full body plank from side (hands to ankles)',
      );
    }

    _missingPoseFrames = 0;
    final bodyAngle = _smooth(calculateAngle(side.shoulder, side.hip, side.ankle));
    final kneeAngle = calculateAngle(side.hip, side.knee, side.ankle);

    final elbow = side.elbow!;
    final wrist = side.wrist!;
    final supportPoint = wrist.y >= elbow.y ? wrist : elbow;
    final shoulderLift = supportPoint.y - side.shoulder.y;
    final upperArmLen = _distance(side.shoulder, elbow);

    final isHorizontal = _isHorizontalPosture(
      side.shoulder,
      side.ankle,
      minHorizontalRatio: 0.8,
    );
    if (!isHorizontal) {
      _stage = ExerciseStage.ready;
      return PoseAnalysisResult(
        isHoldingForm: false,
        stage: _stage,
        feedbackMessage: 'Get down into plank position',
        primaryAngle: bodyAngle,
        confidence: side.confidence,
      );
    }

    final isSupportedAboveMat =
        shoulderLift >= math.max(12.0, upperArmLen * 0.35) &&
        side.ankle.y >= side.shoulder.y;
    if (!isSupportedAboveMat) {
      _stage = ExerciseStage.ready;
      return PoseAnalysisResult(
        isHoldingForm: false,
        stage: _stage,
        feedbackMessage: 'Prop body up on forearms or hands',
        primaryAngle: bodyAngle,
        confidence: side.confidence,
      );
    }

    if (kneeAngle < 150.0 || _hasKneeOnFloor(side, supportPoint, shoulderLift)) {
      _stage = ExerciseStage.ready;
      return PoseAnalysisResult(
        isHoldingForm: false,
        stage: _stage,
        feedbackMessage: 'Keep knees lifted & straight',
        primaryAngle: bodyAngle,
        confidence: side.confidence,
      );
    }

    if (bodyAngle >= 145.0) {
      _stage = ExerciseStage.holdGood;
      return PoseAnalysisResult(
        isHoldingForm: true,
        stage: _stage,
        feedbackMessage: 'Hold steady • Great plank form!',
        primaryAngle: bodyAngle,
        confidence: side.confidence,
      );
    }

    _stage = ExerciseStage.ready;
    return PoseAnalysisResult(
      isHoldingForm: false,
      stage: _stage,
      feedbackMessage: 'Keep back & hips aligned',
      primaryAngle: bodyAngle,
      confidence: side.confidence,
    );
  }

  PoseAnalysisResult _analyzeLunges(Map<int, LandmarkPoint> byId, DateTime now) {
    final side = _bestVisibleSide(byId);
    if (side == null) {
      return _missingPose('Step back: full body must be visible');
    }

    final upright = _isUprightPosture(side.shoulder, side.ankle, minVerticalRatio: 0.7) &&
        side.shoulder.y < side.hip.y &&
        side.hip.y < side.ankle.y;
    if (!upright) {
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Stand upright to begin lunges',
        confidence: side.confidence,
      );
    }

    final left = _getTriplet(byId, leftHipId, leftKneeId, leftAnkleId);
    final right = _getTriplet(byId, rightHipId, rightKneeId, rightAnkleId);
    final angles = <double>[
      if (left != null) calculateAngle(left.$1, left.$2, left.$3),
      if (right != null) calculateAngle(right.$1, right.$2, right.$3),
    ];

    final minKneeAngle = _smooth(angles.reduce(math.min));
    final standingAllStraight = angles.every((a) => a >= 150.0);
    final hipYValues = <double>[
      if (left != null) left.$1.y,
      if (right != null) right.$1.y,
    ];
    final avgHipY =
        hipYValues.reduce((a, b) => a + b) / hipYValues.length;
    final bodyHeight = (side.ankle.y - side.shoulder.y).abs();

    if (standingAllStraight) {
      _baselineHipY = avgHipY;
      _baselineBodyHeight = bodyHeight;
      if (_stage == ExerciseStage.activePhase && _canTriggerRep(now)) {
        _stage = ExerciseStage.ready;
        _lastRepAt = now;
        return PoseAnalysisResult(
          repIncremented: true,
          stage: _stage,
          feedbackMessage: 'Lunge counted!',
          primaryAngle: minKneeAngle,
          confidence: side.confidence,
        );
      }
      _stage = ExerciseStage.ready;
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Step forward & bend knee',
        primaryAngle: minKneeAngle,
        confidence: side.confidence,
      );
    }

    if (minKneeAngle <= 115.0 && _stage == ExerciseStage.ready) {
      final hasHipDescended = _baselineHipY == null ||
          _baselineBodyHeight == null ||
          (avgHipY - _baselineHipY!) >= _baselineBodyHeight! * 0.08;
      if (!hasHipDescended) {
        return PoseAnalysisResult(
          stage: _stage,
          feedbackMessage: 'Lower hips down into lunge',
          primaryAngle: minKneeAngle,
          confidence: side.confidence,
        );
      }
      _stage = ExerciseStage.activePhase;
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Good lunge • Step back up!',
        primaryAngle: minKneeAngle,
        confidence: side.confidence,
      );
    }

    return PoseAnalysisResult(
      stage: _stage,
      feedbackMessage: _stage == ExerciseStage.activePhase
          ? 'Return to standing'
          : 'Bend deeper into lunge',
      primaryAngle: minKneeAngle,
      confidence: side.confidence,
    );
  }

  PoseAnalysisResult _analyzeLegRaises(Map<int, LandmarkPoint> byId, DateTime now) {
    final side = _bestVisibleSide(byId);
    if (side == null) {
      return _missingPose('Lie flat sideways: shoulders to ankles in frame');
    }

    // Require lying back/flat torso on mat so standing front kicks don't count.
    if (!_isHorizontalPosture(side.shoulder, side.hip, minHorizontalRatio: 0.75)) {
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Lie flat on mat for leg raises',
        confidence: side.confidence,
      );
    }

    final kneeAngle = calculateAngle(side.hip, side.knee, side.ankle);
    if (kneeAngle < 125.0) {
      return PoseAnalysisResult(
        stage: _stage,
        feedbackMessage: 'Keep your legs straight',
        confidence: side.confidence,
      );
    }

    final hipAngle = _smooth(calculateAngle(side.shoulder, side.hip, side.ankle));
    return _evaluateCycleDownUp(
      angle: hipAngle,
      upThreshold: 145.0,
      downThreshold: 110.0,
      readyPrompt: 'Raise straight legs up',
      downPrompt: 'Hold & lower legs slowly',
      repDonePrompt: 'Leg raise counted!',
      confidence: side.confidence,
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
      _baselineHipY = null;
      _baselineBodyHeight = null;
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

  bool _isHorizontalPosture(
    LandmarkPoint a,
    LandmarkPoint b, {
    double minHorizontalRatio = 0.8,
  }) {
    final dx = (a.x - b.x).abs();
    final dy = (a.y - b.y).abs();
    return dx >= dy * minHorizontalRatio;
  }

  bool _isUprightPosture(
    LandmarkPoint top,
    LandmarkPoint bottom, {
    double minVerticalRatio = 0.7,
  }) {
    final dy = bottom.y - top.y;
    final dx = (top.x - bottom.x).abs();
    return dy > dx * minVerticalRatio;
  }

  bool _hasKneeOnFloor(
    _SideBody side,
    LandmarkPoint supportPoint,
    double shoulderLift,
  ) {
    final spanX = (side.ankle.x - supportPoint.x).abs();
    if (spanX <= shoulderLift * 0.6 || shoulderLift < 20.0) {
      return false;
    }
    final rawT =
        (side.knee.x - supportPoint.x) / (side.ankle.x - supportPoint.x);
    final t = rawT.clamp(0.0, 1.0);
    final floorYAtKnee =
        supportPoint.y + t * (side.ankle.y - supportPoint.y);
    final kneeLift = floorYAtKnee - side.knee.y;
    return kneeLift < shoulderLift * 0.10;
  }

  double _distance(LandmarkPoint a, LandmarkPoint b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt((dx * dx) + (dy * dy));
  }

  _SideBody? _bestVisibleSide(
    Map<int, LandmarkPoint> byId, {
    bool requireArm = false,
  }) {
    final left = _extractSide(
      byId,
      shoulderId: leftShoulderId,
      elbowId: leftElbowId,
      wristId: leftWristId,
      hipId: leftHipId,
      kneeId: leftKneeId,
      ankleId: leftAnkleId,
      requireArm: requireArm,
    );
    final right = _extractSide(
      byId,
      shoulderId: rightShoulderId,
      elbowId: rightElbowId,
      wristId: rightWristId,
      hipId: rightHipId,
      kneeId: rightKneeId,
      ankleId: rightAnkleId,
      requireArm: requireArm,
    );
    if (left != null && right != null) {
      return left.minVisibility >= right.minVisibility ? left : right;
    }
    return left ?? right;
  }

  _SideBody? _extractSide(
    Map<int, LandmarkPoint> byId, {
    required int shoulderId,
    required int elbowId,
    required int wristId,
    required int hipId,
    required int kneeId,
    required int ankleId,
    required bool requireArm,
  }) {
    final shoulder = byId[shoulderId];
    final hip = byId[hipId];
    final knee = byId[kneeId];
    final ankle = byId[ankleId];
    final elbow = byId[elbowId];
    final wrist = byId[wristId];

    if (shoulder == null || hip == null || knee == null || ankle == null) {
      return null;
    }
    if (requireArm && (elbow == null || wrist == null)) {
      return null;
    }
    final requiredPoints = <LandmarkPoint>[
      shoulder,
      hip,
      knee,
      ankle,
      if (requireArm) ...[
        elbow!,
        wrist!,
      ],
    ];

    double minVis = 1.0;
    double sumVis = 0.0;
    for (final pt in requiredPoints) {
      if (pt.visibility < minVisibility) return null;
      if (pt.visibility < minVis) minVis = pt.visibility;
      sumVis += pt.visibility;
    }

    return _SideBody(
      shoulder: shoulder,
      elbow: elbow,
      wrist: wrist,
      hip: hip,
      knee: knee,
      ankle: ankle,
      minVisibility: minVis,
      confidence: sumVis / requiredPoints.length,
    );
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
}
