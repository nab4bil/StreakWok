import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:streakwok/features/dashboard/domain/workout_plan_model.dart';
import 'package:streakwok/features/pose_detection/data/camera_image_converter.dart';
import 'package:streakwok/features/pose_detection/domain/exercise_pose_analyzer.dart';
import 'package:streakwok/features/pose_detection/domain/mediapipe_pose_detector.dart';
import 'package:streakwok/features/workout_session/presentation/workout_session_screen.dart';

LandmarkPoint _pt(int id, double x, double y, {double visibility = 0.95}) {
  return LandmarkPoint(id: id, x: x, y: y, z: 0.0, visibility: visibility);
}

PoseLandmarkResult _result(List<LandmarkPoint> points, DateTime ts) {
  return PoseLandmarkResult(
    landmarks: points,
    confidenceScore: 0.95,
    timestamp: ts,
  );
}

/// Feeds identical landmarks several times to advance EMA smoothing past thresholds.
PoseAnalysisResult _feedSteady(
  ExercisePoseAnalyzer analyzer,
  List<LandmarkPoint> points,
  DateTime startTime, {
  int frames = 6,
}) {
  late PoseAnalysisResult last;
  for (int i = 0; i < frames; i++) {
    final ts = startTime.add(Duration(milliseconds: i * 80));
    last = analyzer.analyze(_result(points, ts), now: ts);
    if (last.repIncremented) return last;
  }
  return last;
}

void main() {
  group('ExercisePoseAnalyzer - Geometry & Parsing', () {
    test('calculates 90 and 180 degree joint angles accurately', () {
      final a = _pt(11, 0, 0);
      final b = _pt(13, 0, 100);
      final c90 = _pt(15, 100, 100);
      final c180 = _pt(15, 0, 200);

      expect(ExercisePoseAnalyzer.calculateAngle(a, b, c90), closeTo(90.0, 0.01));
      expect(ExercisePoseAnalyzer.calculateAngle(a, b, c180), closeTo(180.0, 0.01));
    });

    test('parses all 6 agreed exercises uniformly', () {
      expect(ExercisePoseAnalyzer.parseExerciseType('Push-up'), ExerciseType.pushUp);
      expect(ExercisePoseAnalyzer.parseExerciseType('Squat'), ExerciseType.squat);
      expect(ExercisePoseAnalyzer.parseExerciseType('Sit-up'), ExerciseType.sitUp);
      expect(ExercisePoseAnalyzer.parseExerciseType('Plank'), ExerciseType.plank);
      expect(ExercisePoseAnalyzer.parseExerciseType('Lunges'), ExerciseType.lunges);
      expect(ExercisePoseAnalyzer.parseExerciseType('Leg Raises'), ExerciseType.legRaises);
      expect(ExercisePoseAnalyzer.cameraGuideFor('Push-up'), 'Side view • Full body');
      expect(ExercisePoseAnalyzer.cameraGuideFor('Squat'), 'Side / 45° view • Full body');
    });
  });

  group('ExercisePoseAnalyzer - All 6 SDD/Program Exercises', () {
    test('1. Push-up: full-body rep counts cleanly; knee push-ups & standing blocked', () {
      final analyzer = ExercisePoseAnalyzer(exerciseName: 'Push-up');
      var t = DateTime(2026, 11, 25, 8, 0, 0);

      // Full-body side plank top: wrist & ankle on floor (y=200), knee lifted cleanly
      final upPose = [
        _pt(11, 100, 100),
        _pt(13, 100, 150),
        _pt(15, 100, 200),
        _pt(23, 210, 135),
        _pt(25, 305, 168),
        _pt(27, 400, 200),
      ];
      // Lowered chest -> elbow bent ~101 deg (<= 108 deg), torso & legs aligned
      final downPose = [
        _pt(11, 100, 150),
        _pt(13, 60, 150),
        _pt(15, 100, 200),
        _pt(23, 210, 167),
        _pt(25, 305, 183),
        _pt(27, 400, 200),
      ];
      // Knee push-up with shins raised (knee angle ~90 deg)
      final bentKneePushUp = [
        _pt(11, 100, 150),
        _pt(13, 60, 150),
        _pt(15, 100, 200),
        _pt(23, 200, 170),
        _pt(25, 290, 200),
        _pt(27, 290, 120),
      ];
      // Knee push-up with knees resting flat on mat & toes down
      final floorKneePushUp = [
        _pt(11, 100, 100),
        _pt(13, 100, 150),
        _pt(15, 100, 200),
        _pt(23, 200, 150),
        _pt(25, 280, 200),
        _pt(27, 400, 200),
      ];
      // Missing ankle (half-body framing)
      final halfBodyPose = [
        _pt(11, 100, 100),
        _pt(13, 100, 150),
        _pt(15, 100, 200),
        _pt(23, 210, 135),
        _pt(25, 305, 168),
      ];

      expect(
        analyzer.analyze(_result(halfBodyPose, t), now: t).stage,
        ExerciseStage.waitingForPose,
      );
      expect(
        analyzer.analyze(_result(bentKneePushUp, t), now: t).feedbackMessage,
        'Straighten legs onto toes (no knee push-ups)',
      );
      expect(
        analyzer.analyze(_result(floorKneePushUp, t), now: t).feedbackMessage,
        'Straighten legs onto toes (no knee push-ups)',
      );

      final r1 = _feedSteady(analyzer, upPose, t);
      expect(r1.stage, ExerciseStage.ready);
      expect(r1.repIncremented, isFalse);

      t = t.add(const Duration(milliseconds: 500));
      final r2 = _feedSteady(analyzer, downPose, t);
      expect(r2.stage, ExerciseStage.activePhase);
      expect(r2.repIncremented, isFalse);

      t = t.add(const Duration(milliseconds: 600));
      final r3 = _feedSteady(analyzer, upPose, t);
      expect(r3.repIncremented, isTrue);
      expect(r3.stage, ExerciseStage.ready);
    });

    test('2. Squat: full-body deep squat counts 1 rep; half squat & lying cheat ignored', () {
      final analyzer = ExercisePoseAnalyzer(exerciseName: 'Squat');
      var t = DateTime(2026, 11, 25, 8, 5, 0);

      final standing = [
        _pt(11, 200, 100),
        _pt(23, 200, 200),
        _pt(25, 200, 300),
        _pt(27, 200, 400),
      ];
      final halfSquat = [
        _pt(11, 160, 130),
        _pt(23, 160, 230),
        _pt(25, 200, 300),
        _pt(27, 200, 400),
      ]; // Knee ~135 deg
      final deepSquat = [
        _pt(11, 110, 200),
        _pt(23, 100, 300),
        _pt(25, 200, 300),
        _pt(27, 200, 400),
      ]; // Knee = 90 deg, hip.y drops 200 -> 300
      final lyingBentKnees = [
        _pt(11, 100, 300),
        _pt(23, 200, 300),
        _pt(25, 260, 230),
        _pt(27, 310, 300),
      ];

      expect(
        analyzer.analyze(_result(lyingBentKnees, t), now: t).feedbackMessage,
        'Stand upright in side / 45° view',
      );

      _feedSteady(analyzer, standing, t);

      // Half squat should not transition to activePhase
      t = t.add(const Duration(milliseconds: 500));
      final halfRes = _feedSteady(analyzer, halfSquat, t);
      expect(halfRes.stage, ExerciseStage.ready);

      // Full depth squat triggers activePhase, then standing counts +1 rep
      t = t.add(const Duration(milliseconds: 500));
      final downRes = _feedSteady(analyzer, deepSquat, t);
      expect(downRes.stage, ExerciseStage.activePhase);

      t = t.add(const Duration(milliseconds: 600));
      final upRes = _feedSteady(analyzer, standing, t);
      expect(upRes.repIncremented, isTrue);
    });

    test('3. Sit-up: lying mat crunch counts cleanly and rejects standing bow', () {
      final analyzer = ExercisePoseAnalyzer(exerciseName: 'Sit-up');
      var t = DateTime(2026, 11, 25, 8, 10, 0);

      // Full-body lying back on mat: shoulder(100, 300), hip(200, 300), knee(260, 230), ankle(310, 300)
      final lyingPose = [
        _pt(11, 100, 300),
        _pt(23, 200, 300),
        _pt(25, 260, 230),
        _pt(27, 310, 300),
      ];
      // Crunch up: shoulder(210, 210), hip(200, 300), knee(260, 230), ankle(310, 300) -> ~47 deg
      final crunchPose = [
        _pt(11, 210, 210),
        _pt(23, 200, 300),
        _pt(25, 260, 230),
        _pt(27, 310, 300),
      ];
      // Standing upright bowing forward (ankle well below hip vertically)
      final standingBow = [
        _pt(11, 270, 200),
        _pt(23, 200, 200),
        _pt(25, 200, 300),
        _pt(27, 200, 400),
      ];

      expect(
        analyzer.analyze(_result(standingBow, t), now: t).feedbackMessage,
        'Lie down on mat with knees bent',
      );

      final r1 = _feedSteady(analyzer, lyingPose, t);
      expect(r1.stage, ExerciseStage.ready);

      t = t.add(const Duration(milliseconds: 500));
      final r2 = _feedSteady(analyzer, crunchPose, t);
      expect(r2.repIncremented, isTrue);
      expect(r2.stage, ExerciseStage.activePhase);

      // Staying curled up must not double-count
      t = t.add(const Duration(milliseconds: 600));
      final rStillUp = analyzer.analyze(_result(crunchPose, t), now: t);
      expect(rStillUp.repIncremented, isFalse);

      // Returning down resets to ready, allowing rep #2
      t = t.add(const Duration(milliseconds: 500));
      _feedSteady(analyzer, lyingPose, t);
      t = t.add(const Duration(milliseconds: 600));
      final rSecond = _feedSteady(analyzer, crunchPose, t);
      expect(rSecond.repIncremented, isTrue);
    });

    test('4. Plank: validates supported straight plank; rejects sagging hips, lying flat, knee plank, and standing', () {
      final analyzer = ExercisePoseAnalyzer(exerciseName: 'Plank');
      var t = DateTime(2026, 11, 25, 8, 15, 0);

      // Supported high/forearm plank: shoulder propped above wrist & straight line to ankle
      final validPlank = [
        _pt(11, 100, 200),
        _pt(13, 100, 230),
        _pt(15, 100, 260),
        _pt(23, 200, 220),
        _pt(25, 290, 240),
        _pt(27, 380, 260),
      ];
      // Sagging hips (< 145 deg)
      final badHipPlank = [
        _pt(11, 100, 200),
        _pt(13, 100, 230),
        _pt(15, 100, 260),
        _pt(23, 200, 285),
        _pt(25, 290, 255),
        _pt(27, 380, 260),
      ];
      // Lying flat on mat without supporting upper body on forearms/hands
      final lyingFlat = [
        _pt(11, 100, 260),
        _pt(13, 130, 260),
        _pt(15, 160, 260),
        _pt(23, 220, 260),
        _pt(25, 300, 260),
        _pt(27, 380, 260),
      ];
      // Knee plank with knees resting on mat
      final kneePlank = [
        _pt(11, 100, 200),
        _pt(13, 100, 230),
        _pt(15, 100, 260),
        _pt(23, 190, 230),
        _pt(25, 280, 260),
        _pt(27, 380, 260),
      ];
      // Standing upright
      final standingUpright = [
        _pt(11, 180, 100),
        _pt(13, 180, 160),
        _pt(15, 180, 220),
        _pt(23, 185, 260),
        _pt(25, 185, 340),
        _pt(27, 185, 420),
      ];

      final good = _feedSteady(analyzer, validPlank, t);
      expect(good.isHoldingForm, isTrue);
      expect(good.stage, ExerciseStage.holdGood);

      t = t.add(const Duration(milliseconds: 600));
      final bad = _feedSteady(analyzer, badHipPlank, t);
      expect(bad.isHoldingForm, isFalse);

      t = t.add(const Duration(milliseconds: 600));
      final flat = _feedSteady(analyzer, lyingFlat, t);
      expect(flat.isHoldingForm, isFalse);
      expect(flat.feedbackMessage, 'Prop body up on forearms or hands');

      t = t.add(const Duration(milliseconds: 600));
      final knees = _feedSteady(analyzer, kneePlank, t);
      expect(knees.isHoldingForm, isFalse);
      expect(knees.feedbackMessage, 'Keep knees lifted & straight');

      t = t.add(const Duration(milliseconds: 600));
      final standing = _feedSteady(analyzer, standingUpright, t);
      expect(standing.isHoldingForm, isFalse);
    });

    test('5. Lunges: standing -> deep lunge -> standing counts 1 rep; flamingo curl rejected', () {
      final analyzer = ExercisePoseAnalyzer(exerciseName: 'Lunges');
      var t = DateTime(2026, 11, 25, 8, 20, 0);

      final standing = [
        _pt(11, 180, 100),
        _pt(12, 220, 100),
        _pt(23, 180, 200),
        _pt(25, 180, 300),
        _pt(27, 180, 400),
        _pt(24, 220, 200),
        _pt(26, 220, 300),
        _pt(28, 220, 400),
      ];
      final lungeBottom = [
        _pt(11, 140, 160),
        _pt(12, 160, 160),
        // Front left knee 90 deg, hip.y drops 200 -> 260
        _pt(23, 140, 260),
        _pt(25, 200, 260),
        _pt(27, 200, 380),
        // Back right knee bent 110 deg
        _pt(24, 140, 260),
        _pt(26, 140, 360),
        _pt(28, 80, 360),
      ];
      // Bending one knee behind while keeping hips standing high (no descent)
      final flamingoCheat = [
        _pt(11, 180, 100),
        _pt(12, 220, 100),
        _pt(23, 180, 200),
        _pt(25, 180, 300),
        _pt(27, 180, 400),
        _pt(24, 220, 200),
        _pt(26, 220, 300),
        _pt(28, 120, 300),
      ];

      _feedSteady(analyzer, standing, t);

      t = t.add(const Duration(milliseconds: 500));
      final cheatRes = _feedSteady(analyzer, flamingoCheat, t);
      expect(cheatRes.stage, ExerciseStage.ready);
      expect(cheatRes.feedbackMessage, 'Lower hips down into lunge');

      t = t.add(const Duration(milliseconds: 500));
      final bottom = _feedSteady(analyzer, lungeBottom, t);
      expect(bottom.stage, ExerciseStage.activePhase);

      t = t.add(const Duration(milliseconds: 600));
      final finish = _feedSteady(analyzer, standing, t);
      expect(finish.repIncremented, isTrue);
    });

    test('6. Leg Raises: extended -> raised straight -> lowered counts 1 rep; bent knees & standing kick blocked', () {
      final analyzer = ExercisePoseAnalyzer(exerciseName: 'Leg Raises');
      var t = DateTime(2026, 11, 25, 8, 25, 0);

      final legsDown = [
        _pt(11, 100, 300),
        _pt(23, 200, 300),
        _pt(25, 280, 300),
        _pt(27, 360, 300),
      ];
      final legsUpStraight = [
        _pt(11, 100, 300),
        _pt(23, 200, 300),
        _pt(25, 200, 220),
        _pt(27, 200, 140),
      ];
      final kneesBent = [
        _pt(11, 100, 300),
        _pt(23, 200, 300),
        _pt(25, 200, 220),
        _pt(27, 280, 220), // Knee 90 deg (< 125 deg)
      ];
      final standingKick = [
        _pt(11, 200, 100),
        _pt(23, 200, 220),
        _pt(25, 280, 220),
        _pt(27, 360, 220),
      ];

      expect(
        analyzer.analyze(_result(standingKick, t), now: t).feedbackMessage,
        'Lie flat on mat for leg raises',
      );

      _feedSteady(analyzer, legsDown, t);

      t = t.add(const Duration(milliseconds: 500));
      final bentRes = analyzer.analyze(_result(kneesBent, t), now: t);
      expect(bentRes.feedbackMessage, 'Keep your legs straight');

      t = t.add(const Duration(milliseconds: 500));
      final upRes = _feedSteady(analyzer, legsUpStraight, t);
      expect(upRes.stage, ExerciseStage.activePhase);

      t = t.add(const Duration(milliseconds: 600));
      final downRes = _feedSteady(analyzer, legsDown, t);
      expect(downRes.repIncremented, isTrue);
    });
  });

  group('CameraImageConverter', () {
    test('packs 3-plane YUV420 with stride padding into tightly packed NV21', () {
      const width = 4;
      const height = 2;
      // Y plane has yRowStride = 6 (2 extra padding bytes per row)
      final yBytes = Uint8List.fromList([
        10, 11, 12, 13, 99, 99,
        20, 21, 22, 23, 99, 99,
      ]);
      // UV dimensions = 2x1, pixelStride = 2 (semi-planar)
      final uBytes = Uint8List.fromList([100, 0, 101, 0]);
      final vBytes = Uint8List.fromList([200, 0, 201, 0]);

      final nv21 = CameraImageConverter.packYuv420ToNv21(
        width: width,
        height: height,
        yBytes: yBytes,
        yRowStride: 6,
        uBytes: uBytes,
        uRowStride: 4,
        uPixelStride: 2,
        vBytes: vBytes,
        vRowStride: 4,
        vPixelStride: 2,
      );

      expect(nv21.length, 12); // 4*2 + 4*2/2
      expect(nv21, Uint8List.fromList([
        10, 11, 12, 13,
        20, 21, 22, 23,
        200, 100, 201, 101, // V0, U0, V1, U1
      ]));
    });

    test('resolves front and back camera rotation degrees on Android', () {
      const front = CameraDescription(
        name: '1',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 270,
      );
      const back = CameraDescription(
        name: '0',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
      );

      expect(
        CameraImageConverter.resolveRotation(
          camera: front,
          deviceOrientation: DeviceOrientation.portraitUp,
          isIosOverride: false,
        ),
        InputImageRotation.rotation270deg,
      );
      expect(
        CameraImageConverter.resolveRotation(
          camera: back,
          deviceOrientation: DeviceOrientation.portraitUp,
          isIosOverride: false,
        ),
        InputImageRotation.rotation90deg,
      );
      expect(
        CameraImageConverter.uprightSizeFor(
          const Size(640, 480),
          InputImageRotation.rotation270deg,
        ),
        const Size(480, 640),
      );
    });
  });

  group('UC-09 Camera Permission Denied Flow', () {
    const cameraChannel = MethodChannel('plugins.flutter.io/camera');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(cameraChannel, (call) async {
        if (call.method == 'availableCameras') {
          throw PlatformException(
            code: 'CameraAccessDenied',
            message: 'Camera access permission was denied.',
          );
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(cameraChannel, null);
    });

    testWidgets('shows SDD exception message when OS denies camera access', (tester) async {
      const plan = WorkoutDayPlan(
        dayNumber: 1,
        isRestDay: false,
        category: 'Upper & Core',
        exerciseNames: ['Push-up'],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutSessionScreen(
            dayPlan: plan,
            userName: 'Tester',
            enableLiveCamera: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Izinkan akses kamera untuk memulai latihan.'), findsOneWidget);
      expect(find.byKey(const Key('retry_camera_permission_btn')), findsOneWidget);
    });

    testWidgets('shows unavailable camera screen without manual bypass when live camera fails', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(cameraChannel, (call) async {
        if (call.method == 'availableCameras') {
          return <dynamic>[];
        }
        return null;
      });

      const plan = WorkoutDayPlan(
        dayNumber: 1,
        isRestDay: false,
        category: 'Upper & Core',
        exerciseNames: ['Push-up'],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutSessionScreen(
            dayPlan: plan,
            userName: 'Tester',
            enableLiveCamera: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Kamera Tidak Tersedia'), findsOneWidget);
      expect(find.text('+1 Rep (Tap / Detected)'), findsNothing);
      expect(find.text('Manual +1 Rep'), findsNothing);
    });
  });
}
