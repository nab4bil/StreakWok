import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/domain/workout_plan_model.dart';

enum WorkoutSessionPhase {
  countdown,
  active,
  rest,
  summary,
}

enum WorkoutSessionExitAction {
  keepExercising,
  doItLater,
  quit,
  completed,
}

class WorkoutSessionResult {
  final WorkoutSessionExitAction action;
  final int dayNumber;
  final int exerciseIndex;

  const WorkoutSessionResult({
    required this.action,
    required this.dayNumber,
    this.exerciseIndex = 0,
  });
}

class WorkoutSessionScreen extends StatefulWidget {
  final WorkoutDayPlan dayPlan;
  final VoidCallback? onSessionCompleted;
  final String userName;
  final int initialExerciseIndex;

  const WorkoutSessionScreen({
    super.key,
    required this.dayPlan,
    this.onSessionCompleted,
    this.userName = 'User',
    this.initialExerciseIndex = 0,
  });

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  WorkoutSessionPhase _phase = WorkoutSessionPhase.countdown;

  // Countdown state
  int _countdownSeconds = 3;
  Timer? _countdownTimer;

  // Global Workout Timer
  int _totalElapsedSeconds = 0;
  Timer? _workoutTimer;

  // Current Exercise State
  int _currentExerciseIndex = 0;
  int _currentReps = 0;
  int _targetReps = 12;
  bool _isTimedExercise = false;
  int _timedSecondsRemaining = 30;

  // Rest Interval State
  int _restSecondsRemaining = 20;
  Timer? _restTimer;

  // Pause State (UC-10)
  bool _isPaused = false;
  bool _isCancelDialogOpen = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    if (widget.initialExerciseIndex > 0 &&
        widget.initialExerciseIndex < _exercises.length) {
      _currentExerciseIndex = widget.initialExerciseIndex;
    }

    _startInitialCountdown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (!_isPaused &&
          !_isCancelDialogOpen &&
          (_phase == WorkoutSessionPhase.active ||
              _phase == WorkoutSessionPhase.rest ||
              _phase == WorkoutSessionPhase.countdown)) {
        setState(() {
          _isPaused = true;
        });
      }
    }
  }

  List<String> get _exercises {
    if (widget.dayPlan.exerciseNames.isEmpty) {
      return ['Full Body Stretch', 'Core Warm-up'];
    }
    return widget.dayPlan.exerciseNames;
  }

  String get _currentExerciseName => _exercises[_currentExerciseIndex];

  void _setupTargetForCurrentExercise() {
    final name = _currentExerciseName.toLowerCase();
    if (name.contains('plank')) {
      _isTimedExercise = true;
      _timedSecondsRemaining = 30;
      _targetReps = 30;
    } else if (name.contains('squat') || name.contains('sit-up') || name.contains('leg raises')) {
      _isTimedExercise = false;
      _targetReps = 15;
    } else {
      _isTimedExercise = false;
      _targetReps = 12;
    }
    _currentReps = 0;
  }

  void _startInitialCountdown() {
    setState(() {
      _phase = WorkoutSessionPhase.countdown;
      _countdownSeconds = 3;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && !_isCancelDialogOpen) {
        if (_countdownSeconds > 1) {
          setState(() {
            _countdownSeconds--;
          });
        } else {
          timer.cancel();
          _startWorkout();
        }
      }
    });
  }

  void _startWorkout() {
    _setupTargetForCurrentExercise();
    setState(() {
      _phase = WorkoutSessionPhase.active;
      _isPaused = false;
    });

    _startGlobalTimer();
  }

  void _startGlobalTimer() {
    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && !_isCancelDialogOpen) {
        setState(() {
          _totalElapsedSeconds++;
          if (_isTimedExercise && _timedSecondsRemaining > 0) {
            _timedSecondsRemaining--;
            _currentReps = 30 - _timedSecondsRemaining;
            if (_timedSecondsRemaining == 0) {
              _onCompleteCurrentExercise();
            }
          }
        });
      }
    });
  }

  // UC-10: Menunda Workout (Pause)
  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  // UC-10 & UC-11: Exit Options Dialog (Keep Exercising / Do It Later / Quit Workout)
  void _showExitOptionsDialog() async {
    if (_isCancelDialogOpen) return;

    setState(() {
      _isCancelDialogOpen = true;
    });

    final selectedAction = await showDialog<WorkoutSessionExitAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        title: const Row(
          children: [
            Icon(Icons.pause_circle_outline_rounded, color: AppColors.primary, size: 26),
            SizedBox(width: 8),
            Text(
              'Workout Options',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textMain, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Do you want to continue exercising, pause and do it later, or quit and reset progress?',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
        ),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Keep Exercising (Primary action, dismisses dialog)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(WorkoutSessionExitAction.keepExercising);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Keep Exercising', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),

              // 2. Do It Later (UC-10: Menunda Workout, saves exercise index and returns to dashboard)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(WorkoutSessionExitAction.doItLater);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F9F3),
                    foregroundColor: const Color(0xFF007A58),
                    side: const BorderSide(color: Color(0xFFBCEBDC), width: 1.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Do It Later', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),

              // 3. Quit Workout (UC-11: Membatalkan Workout, resets progress to start)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(WorkoutSessionExitAction.quit);
                },
                child: const Text(
                  'Quit Workout',
                  style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!mounted) return;
    setState(() {
      _isCancelDialogOpen = false;
    });

    if (selectedAction == WorkoutSessionExitAction.doItLater) {
      _countdownTimer?.cancel();
      _workoutTimer?.cancel();
      _restTimer?.cancel();
      Navigator.of(context).pop(
        WorkoutSessionResult(
          action: WorkoutSessionExitAction.doItLater,
          dayNumber: widget.dayPlan.dayNumber,
          exerciseIndex: _currentExerciseIndex,
        ),
      );
    } else if (selectedAction == WorkoutSessionExitAction.quit) {
      _countdownTimer?.cancel();
      _workoutTimer?.cancel();
      _restTimer?.cancel();
      Navigator.of(context).pop(
        WorkoutSessionResult(
          action: WorkoutSessionExitAction.quit,
          dayNumber: widget.dayPlan.dayNumber,
          exerciseIndex: 0,
        ),
      );
    }
  }

  void _showCancelDialog() => _showExitOptionsDialog();

  // Increment rep (simulates MediaPipe pose detection trigger)
  void _incrementRep() {
    if (_isPaused || _isCancelDialogOpen || _phase != WorkoutSessionPhase.active) return;

    if (_isTimedExercise) {
      setState(() {
        _timedSecondsRemaining = 0;
        _currentReps = _targetReps;
      });
      _onCompleteCurrentExercise();
      return;
    }

    setState(() {
      if (_currentReps < _targetReps) {
        _currentReps++;
      }
    });

    if (_currentReps >= _targetReps) {
      _onCompleteCurrentExercise();
    }
  }

  void _onCompleteCurrentExercise() {

    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _phase = WorkoutSessionPhase.rest;
        _restSecondsRemaining = 20;
      });
      _startRestTimer();
    } else {
      setState(() {
        _phase = WorkoutSessionPhase.summary;
      });
      _workoutTimer?.cancel();
    }
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && !_isCancelDialogOpen) {
        if (_restSecondsRemaining > 1) {
          setState(() {
            _restSecondsRemaining--;
          });
        } else {
          timer.cancel();
          _advanceToNextExercise();
        }
      }
    });
  }

  void _addRestTime(int seconds) {
    setState(() {
      _restSecondsRemaining += seconds;
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    _advanceToNextExercise();
  }

  void _advanceToNextExercise() {
    setState(() {
      _currentExerciseIndex++;
      _setupTargetForCurrentExercise();
      _phase = WorkoutSessionPhase.active;
    });
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase == WorkoutSessionPhase.summary,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitOptionsDialog();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildBodyForCurrentPhase(),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyForCurrentPhase() {
    switch (_phase) {
      case WorkoutSessionPhase.countdown:
        return _buildCountdownPhase();
      case WorkoutSessionPhase.active:
        return _buildActiveWorkoutPhase();
      case WorkoutSessionPhase.rest:
        return _buildRestPhase();
      case WorkoutSessionPhase.summary:
        return _buildSummaryPhase();
    }
  }

  // 1. COUNTDOWN PHASE (Light Theme sesuai SDD with Animated Preview)
  Widget _buildCountdownPhase() {
    final lottieAsset = _getExerciseLottieAsset(_currentExerciseName);

    return Stack(
      key: const ValueKey('countdown_view'),
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'GET READY!',
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.primary, width: 2.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$_countdownSeconds',
                    style: const TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Starting with:',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentExerciseName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 14),

                // Enlarged borderless Lottie animation
                SizedBox(
                  height: 200,
                  child: lottieAsset != null
                      ? Lottie.asset(
                          lottieAsset,
                          fit: BoxFit.contain,
                          repeat: true,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(_getExerciseIcon(_currentExerciseName), size: 56, color: AppColors.primary),
                          ),
                        )
                      : Center(
                          child: Icon(_getExerciseIcon(_currentExerciseName), size: 56, color: AppColors.primary),
                        ),
                ),
              ],
            ),
          ),
        ),
        if (_isPaused) _buildPauseOverlay(),
      ],
    );
  }

  // 2. ACTIVE WORKOUT PHASE (Clean Light Theme per SDD AppColors)
  Widget _buildActiveWorkoutPhase() {
    return Stack(
      key: const ValueKey('active_workout_view'),
      children: [
        Column(
          children: [
            // TOP BAR: Navigation, Progress, Pause & Cancel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(bottom: BorderSide(color: Color(0xFFEEF2F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _showExitOptionsDialog,
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textMain, size: 24),
                    tooltip: 'Back',
                  ),
                  Column(
                    children: [
                      Text(
                        'Day ${widget.dayPlan.dayNumber} • ${widget.dayPlan.category}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Exercise ${_currentExerciseIndex + 1} of ${_exercises.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // SIMULATED CAMERA & POSE TRACKING VIEWPORT (Clean Canvas Card)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Solid Watermark Icon Background
                      Center(
                        child: Icon(
                          _getExerciseIcon(_currentExerciseName),
                          size: 160,
                          color: const Color(0xFFF4F7F5),
                        ),
                      ),

                      // Animated Pose Tracking Skeletal Nodes (Solid Light Theme Overlay)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: Size.infinite,
                            painter: _PoseSkeletonPainter(
                              pulseFactor: _pulseController.value,
                              exerciseName: _currentExerciseName,
                            ),
                          );
                        },
                      ),

                      // AI Tracker Status Pill (Top Left inside viewport)
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F9F3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFBCEBDC)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'AI Pose Tracker Active',
                                style: TextStyle(
                                  color: Color(0xFF007A58),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Stopwatch Duration (Top Right inside viewport)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, color: AppColors.textMain, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(_totalElapsedSeconds),
                                style: const TextStyle(
                                  color: AppColors.textMain,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Center Exercise Name & Big Rep Counter Card
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFCFB),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentExerciseName,
                                style: const TextStyle(
                                  color: AppColors.textMain,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (_isTimedExercise)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${_timedSecondsRemaining}s',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '/ 30s remaining',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$_currentReps',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '/ $_targetReps Reps',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // INTERACTIVE ACTION BUTTON (Solid Mint-Emerald matching app buttons)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _incrementRep,
                  icon: Icon(
                    _isTimedExercise ? Icons.fast_forward_rounded : Icons.add_circle_outline_rounded,
                    size: 20,
                  ),
                  label: Text(
                    _isTimedExercise ? 'Complete Plank' : '+1 Rep (Tap / Detected)',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ],
        ),

        // UC-10: PAUSE OVERLAY (Modal Light Theme)
        if (_isPaused) _buildPauseOverlay(),
      ],
    );
  }

  // UC-10: Reusable Pause Overlay Modal
  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F9F3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pause_rounded, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Workout Paused',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take a breath. Timer is paused at ${_formatDuration(_totalElapsedSeconds)}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _togglePause,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Resume Workout', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _showExitOptionsDialog,
                child: const Text('Quit or Do It Later', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. REST INTERVAL PHASE (Clean Light Theme per SDD with Animated Preview)
  Widget _buildRestPhase() {
    final nextExercise = (_currentExerciseIndex + 1 < _exercises.length)
        ? _exercises[_currentExerciseIndex + 1]
        : 'Final stretch';
    final lottieAsset = _getExerciseLottieAsset(nextExercise);

    return Stack(
      key: const ValueKey('rest_view'),
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'REST INTERVAL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),

                // Circular Timer
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.primary, width: 2.5),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_restSecondsRemaining',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          height: 1.1,
                        ),
                      ),
                      const Text(
                        'SECONDS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                const Text(
                  'Next Up:',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  nextExercise,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textMain),
                ),
                const SizedBox(height: 14),

                // Enlarged borderless Lottie animation
                SizedBox(
                  height: 200,
                  child: lottieAsset != null
                      ? Lottie.asset(
                          lottieAsset,
                          fit: BoxFit.contain,
                          repeat: true,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(_getExerciseIcon(nextExercise), size: 56, color: AppColors.primary),
                          ),
                        )
                      : Center(
                          child: Icon(_getExerciseIcon(nextExercise), size: 56, color: AppColors.primary),
                        ),
                ),

                const SizedBox(height: 24),

                // Balanced Side-by-Side Action Buttons (Clean, equal width, no redundant icon)
                Row(
                  children: [
                    // +20s Button (Left side, equal width, clean text, no duplicate icon)
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _addRestTime(20);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF007A58),
                            backgroundColor: const Color(0xFFE8F9F3),
                            side: const BorderSide(color: Color(0xFFBCEBDC), width: 1.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text(
                            '+20s',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF007A58),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Skip Rest Button (Right side, equal width, solid emerald, balanced)
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _skipRest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text(
                            'Skip Rest',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_isPaused) _buildPauseOverlay(),
      ],
    );
  }

  // 4. SUMMARY PHASE (Clean Light Theme per SDD, without Calorie Estimation)
  Widget _buildSummaryPhase() {
    return Center(
      key: const ValueKey('summary_view'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Celebration Flame Badge
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFF3ED),
                border: Border.all(color: const Color(0xFFFFD7C2), width: 2),
              ),
              child: const Icon(Icons.local_fire_department_rounded, size: 52, color: AppColors.flameRed),
            ),
            const SizedBox(height: 20),
            const Text(
              'Workout Completed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textMain,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Great job, ${widget.userName}! Day ${widget.dayPlan.dayNumber} is officially done.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),

            const SizedBox(height: 28),

            // Performance Metrics Card (Without calorie estimation per user request)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryMetric(
                    icon: Icons.timer_outlined,
                    label: 'Total Time',
                    value: _formatDuration(_totalElapsedSeconds),
                  ),
                  Container(width: 1, height: 40, color: const Color(0xFFEEF2F0)),
                  _buildSummaryMetric(
                    icon: Icons.fitness_center_rounded,
                    label: 'Exercises',
                    value: '${_exercises.length}/${_exercises.length}',
                  ),
                  Container(width: 1, height: 40, color: const Color(0xFFEEF2F0)),
                  _buildSummaryMetric(
                    icon: Icons.whatshot_rounded,
                    label: 'Streak Status',
                    value: '+1 Day',
                    valueColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSessionCompleted?.call();
                  Navigator.pop(
                    context,
                    WorkoutSessionResult(
                      action: WorkoutSessionExitAction.completed,
                      dayNumber: widget.dayPlan.dayNumber,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  'Complete Workout',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: valueColor ?? AppColors.textMain,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  IconData _getExerciseIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('push-up') || lower.contains('pushup')) return Icons.fitness_center_rounded;
    if (lower.contains('squat')) return Icons.accessibility_new_rounded;
    if (lower.contains('sit-up') || lower.contains('situp') || lower.contains('crunch')) {
      return Icons.airline_seat_recline_extra_rounded;
    }
    if (lower.contains('plank')) return Icons.horizontal_rule_rounded;
    if (lower.contains('lunge')) return Icons.directions_walk_rounded;
    if (lower.contains('leg')) return Icons.sports_gymnastics_rounded;
    return Icons.directions_run_rounded;
  }

  String? _getExerciseLottieAsset(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('push-up') || lower.contains('pushup')) {
      return 'assets/animations/pushup.json';
    }
    if (lower.contains('squat')) {
      return 'assets/animations/squat.json';
    }
    if (lower.contains('sit-up') || lower.contains('situp') || lower.contains('crunch')) {
      return 'assets/animations/situp.json';
    }
    if (lower.contains('plank')) {
      return 'assets/animations/plank.json';
    }
    if (lower.contains('lunge')) {
      return 'assets/animations/lunges.json';
    }
    if (lower.contains('leg')) {
      return 'assets/animations/leg_raises.json';
    }
    return null;
  }
}

/// Custom painter to simulate skeletal landmark nodes in light theme
class _PoseSkeletonPainter extends CustomPainter {
  final double pulseFactor;
  final String exerciseName;

  _PoseSkeletonPainter({
    required this.pulseFactor,
    required this.exerciseName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF00D09E)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final paintNode = Paint()
      ..color = const Color(0xFF00A87A)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height * 0.45;

    // Simulated skeletal landmarks
    final head = Offset(cx, cy - 60);
    final neck = Offset(cx, cy - 30);
    final leftShoulder = Offset(cx - 40, cy - 20);
    final rightShoulder = Offset(cx + 40, cy - 20);
    final leftElbow = Offset(cx - 65, cy + 10);
    final rightElbow = Offset(cx + 65, cy + 10);
    final leftWrist = Offset(cx - 75, cy + 35);
    final rightWrist = Offset(cx + 75, cy + 35);

    final midHip = Offset(cx, cy + 50);
    final leftHip = Offset(cx - 28, cy + 50);
    final rightHip = Offset(cx + 28, cy + 50);
    final leftKnee = Offset(cx - 32, cy + 110);
    final rightKnee = Offset(cx + 32, cy + 110);
    final leftAnkle = Offset(cx - 35, cy + 160);
    final rightAnkle = Offset(cx + 35, cy + 160);

    // Draw torso & limbs
    canvas.drawLine(head, neck, paintLine);
    canvas.drawLine(leftShoulder, rightShoulder, paintLine);
    canvas.drawLine(neck, midHip, paintLine);
    canvas.drawLine(leftShoulder, leftElbow, paintLine);
    canvas.drawLine(leftElbow, leftWrist, paintLine);
    canvas.drawLine(rightShoulder, rightElbow, paintLine);
    canvas.drawLine(rightElbow, rightWrist, paintLine);

    canvas.drawLine(leftHip, leftKnee, paintLine);
    canvas.drawLine(leftKnee, leftAnkle, paintLine);
    canvas.drawLine(rightHip, rightKnee, paintLine);
    canvas.drawLine(rightKnee, rightAnkle, paintLine);

    // Draw landmark joints
    final points = [
      head, neck, leftShoulder, rightShoulder,
      leftElbow, rightElbow, leftWrist, rightWrist,
      leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle,
    ];

    for (final p in points) {
      canvas.drawCircle(p, 4.0, paintNode);
    }
  }

  @override
  bool shouldRepaint(covariant _PoseSkeletonPainter oldDelegate) {
    return oldDelegate.pulseFactor != pulseFactor || oldDelegate.exerciseName != exerciseName;
  }
}
