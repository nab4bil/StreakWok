import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../domain/workout_plan_model.dart';
import '../../workout_session/presentation/workout_session_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final bool isUserCompleted;
  final bool hasGroup;
  final String groupName;
  final bool isLeader;
  final int currentActiveDay;
  final int streakDays;
  final VoidCallback onToggleWorkout;
  final VoidCallback? onViewGroup;
  final VoidCallback? onJoinGroupTap;
  final VoidCallback? onCreateGroupTap;
  final VoidCallback? onToggleGroupState;
  final VoidCallback? onAdvanceDay;
  final VoidCallback? onWorkoutCompletedSession;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.isUserCompleted,
    this.hasGroup = false,
    this.groupName = 'gerup ketat',
    this.isLeader = false,
    this.currentActiveDay = 1,
    this.streakDays = 0,
    required this.onToggleWorkout,
    this.onViewGroup,
    this.onJoinGroupTap,
    this.onCreateGroupTap,
    this.onToggleGroupState,
    this.onAdvanceDay,
    this.onWorkoutCompletedSession,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ScrollController _scrollController;

  int? _pausedDayNumber;
  int? _pausedExerciseIndex;

  static const double _cardHeight = 99.0;
  static const double _cardSpacing = 14.0;

  static double _getItemHeight(int index) => _cardHeight;

  // Precomputed nominal top offsets for all 30 days
  static final List<double> _itemTops = () {
    final tops = <double>[];
    double current = 0.0;
    for (int i = 0; i < 30; i++) {
      tops.add(current);
      current += _cardHeight + _cardSpacing;
    }
    return tops;
  }();

  double get _initialOffset =>
      _itemTops[(widget.currentActiveDay - 1).clamp(0, 29)];

  static double get _totalTimelineHeight =>
      _itemTops.last + _cardHeight + 40.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _initialOffset,
    );
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentActiveDay != oldWidget.currentActiveDay) {
      _scrollToToday();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _initialOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleStartWorkout() {
    debugPrint('*** HANDLE_START_WORKOUT_CALLED: day=${widget.currentActiveDay}, completed=${widget.isUserCompleted} ***');
    final activeIndex = widget.currentActiveDay - 1;
    final plan = (activeIndex >= 0 && activeIndex < WorkoutPlanRepository.plan30Days.length)
        ? WorkoutPlanRepository.plan30Days[activeIndex]
        : null;

    if (widget.isUserCompleted && widget.onAdvanceDay != null) {
      _showWorkoutOptionsDialog();
    } else if (plan != null && plan.isRestDay) {
      _showRestDayDialog();
    } else if (plan != null) {
      final isPaused = _pausedDayNumber == plan.dayNumber;
      final initialIndex = isPaused ? (_pausedExerciseIndex ?? 0) : 0;
      _startInteractiveWorkoutSession(plan, initialExerciseIndex: initialIndex);
    } else {
      widget.onToggleWorkout();
    }
  }

  void _startInteractiveWorkoutSession(WorkoutDayPlan plan, {int initialExerciseIndex = 0}) async {
    final result = await Navigator.push<WorkoutSessionResult>(
      context,
      CupertinoPageRoute(
        builder: (context) => WorkoutSessionScreen(
          dayPlan: plan,
          userName: widget.userName,
          initialExerciseIndex: initialExerciseIndex,
        ),
      ),
    );

    if (result == null) return;

    if (result.action == WorkoutSessionExitAction.completed) {
      setState(() {
        _pausedDayNumber = null;
        _pausedExerciseIndex = null;
      });
      if (!widget.isUserCompleted) {
        widget.onToggleWorkout();
      }
      widget.onWorkoutCompletedSession?.call();
    } else if (result.action == WorkoutSessionExitAction.doItLater) {
      setState(() {
        _pausedDayNumber = result.dayNumber;
        _pausedExerciseIndex = result.exerciseIndex;
      });
    } else if (result.action == WorkoutSessionExitAction.quit) {
      setState(() {
        if (_pausedDayNumber == result.dayNumber) {
          _pausedDayNumber = null;
          _pausedExerciseIndex = null;
        }
      });
    }
  }

  void _showRestDayDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bedtime_rounded, color: Color(0xFF00D09E), size: 28),
            SizedBox(width: 8),
            Text('Rest Day', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1D1E))),
          ],
        ),
        content: const Text(
          'Today is designated for muscle recovery and resting. Rest days automatically maintain your group streak when validated!',
          style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onToggleWorkout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D09E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Mark Rest Completed', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showWorkoutOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF00D09E), size: 28),
            const SizedBox(width: 8),
            Text('Day ${widget.currentActiveDay} Done!'),
          ],
        ),
        content: Text(
          widget.currentActiveDay < 30
              ? 'Day ${widget.currentActiveDay} workout completed! Ready to advance to Day ${widget.currentActiveDay + 1} or mark as undone?'
              : 'Congratulations! You have completed the entire 30-day StreakWok program!',
          style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onToggleWorkout(); // toggle back to Undone
            },
            child: const Text('Mark as Undone', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          if (widget.currentActiveDay < 30)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onAdvanceDay?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D09E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Next: Day ${widget.currentActiveDay + 1}'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streakDays = widget.streakDays;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFB),
      body: SafeArea(
        child: Column(
          children: [
            // Pinned Top Header (Tap to Scroll to Top - Identik dengan dashboard_screen.html)
            GestureDetector(
              onTap: _scrollToTop,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFCFB),
                  border: Border(bottom: BorderSide(color: Color(0xFFEEF2F0))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1D1E),
                                letterSpacing: -0.5,
                              ),
                              children: [
                                TextSpan(text: 'Streak'),
                                TextSpan(
                                  text: 'Wok',
                                  style: TextStyle(color: Color(0xFF00D09E)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1D1E),
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Yo! ',
                                  style: TextStyle(
                                    color: Color(0xFF00D09E),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(text: widget.userName.toLowerCase()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // State Switch Pill
                    GestureDetector(
                      onTap: widget.onToggleGroupState,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFDCE7E1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.swap_horiz, size: 14, color: Color(0xFF4B5563)),
                            const SizedBox(width: 4),
                            Text(
                              widget.hasGroup ? '⇄ In Group' : '⇄ No Group',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // PINNED GROUP CARD (Tidak tenggelam saat scroll ke bawah)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: widget.hasGroup
                  ? _buildInGroupCard(streakDays)
                  : _buildNoGroupCard(),
            ),

            const SizedBox(height: 10),

            // PINNED WORKOUT PLAN HEADER WITH PERMANENT GREEN SHORTCUT BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Workout Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1D1E),
                      letterSpacing: -0.2,
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _scrollToToday,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D09E),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D09E).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Day ${widget.currentActiveDay}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // EXPANDED SCROLLABLE TIMELINE
            Expanded(
              child: _buildTimelineSection(),
            ),
          ],
        ),
      ),
    );
  }

  // CARD 1B: IN-GROUP CARD (Identik dengan group-info-card)
  Widget _buildInGroupCard(int streakDays) {
    final isDone = widget.isUserCompleted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.groupName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1D1E),
                  letterSpacing: -0.2,
                ),
              ),
              GestureDetector(
                onTap: widget.onViewGroup,
                child: Row(
                  children: const [
                    Text(
                      'View Group',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00D09E),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: Color(0xFF00D09E)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Body: Members at Left & TikTok Flame at Right
          Row(
            children: [
              // Left: Member List
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.isLeader
                      ? [
                          _buildMemberText('${widget.userName.toLowerCase()} (Leader)', isDone: isDone),
                          const SizedBox(height: 7),
                          _buildMemberText('waiting for members...', isDone: false),
                        ]
                      : [
                          _buildMemberText('tono hardija', isDone: true),
                          const SizedBox(height: 7),
                          _buildMemberText(widget.userName.toLowerCase(), isDone: isDone),
                          const SizedBox(height: 7),
                          _buildMemberText('mahmud buah', isDone: true),
                        ],
                ),
              ),

              // Vertical Divider
              Container(
                width: 1.5,
                height: 64,
                color: const Color(0xFFF0F4F2),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),

              // Right: TikTok Streak Badge (Identik dengan SVG di HTML)
              SizedBox(
                width: 72,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: CustomPaint(
                        painter: _TikTokFlamePainter(isLit: isDone),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$streakDays',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isDone ? const Color(0xFFFF5722) : const Color(0xFF9CA3AF),
                        letterSpacing: -0.5,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberText(String name, {required bool isDone}) {
    return Text(
      name,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDone ? const Color(0xFFFF5722) : const Color(0xFF9CA3AF),
        height: 1.2,
      ),
    );
  }

  // CARD 1A: NO-GROUP CARD (Matching HTML Prototype 1:1)
  Widget _buildNoGroupCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Group',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D1E),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                  height: 1.6,
                ),
                children: [
                  const TextSpan(text: "You don't have a group yet. "),
                  TextSpan(
                    text: 'Join',
                    style: const TextStyle(
                      color: Color(0xFF00D09E),
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF00D09E),
                    ),
                    recognizer: TapGestureRecognizer()..onTap = widget.onJoinGroupTap,
                  ),
                  const TextSpan(text: ' or '),
                  TextSpan(
                    text: 'create a group',
                    style: const TextStyle(
                      color: Color(0xFF00D09E),
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF00D09E),
                    ),
                    recognizer: TapGestureRecognizer()..onTap = widget.onCreateGroupTap,
                  ),
                  const TextSpan(text: ' to start building your streak!'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TIMELINE: MODEL BIASA DENGAN ANIMASI STACK UNTUK HARI YANG SUDAH DILEWATI
  Widget _buildTimelineSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth;

        return SingleChildScrollView(
          controller: _scrollController,
          clipBehavior: Clip.none,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: AnimatedBuilder(
            animation: _scrollController,
            builder: (context, _) {
              final scrollOffset = _scrollController.hasClients
                  ? _scrollController.offset
                  : _initialOffset;

              // Connecting line starts at top visible node and goes down to the last node (never offsides to top!)
              final lineTop = (scrollOffset + 30.0).clamp(30.0, _itemTops.last + 30.0);
              final lineBottom = _itemTops.last + 30.0;
              final lineHeight = (lineBottom - lineTop).clamp(0.0, double.infinity);

              return SizedBox(
                width: (contentWidth - 36).clamp(0.0, double.infinity),
                height: _totalTimelineHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Connecting vertical timeline line (Never offsides to top!)
                    if (lineHeight > 0)
                      Positioned(
                        key: const ValueKey('timeline_vertical_line'),
                        left: 11,
                        top: lineTop,
                        height: lineHeight,
                        child: Container(
                          width: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCE7E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                    // All 30 Day Rows (Day 1 to Day 30)
                    for (int i = 0; i < 30; i++)
                      _buildTimelineItem(i, scrollOffset),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem(int index, double scrollOffset) {
    final plan = WorkoutPlanRepository.plan30Days[index];
    final activeDay = widget.currentActiveDay;
    final nominalTop = _itemTops[index];
    final cardHeight = _getItemHeight(index);

    double visualTop;
    double scale = 1.0;
    double opacity = 1.0;
    double nodeOpacity = 1.0;

    if (nominalTop >= scrollOffset) {
      // Normal flow below/at top of viewport
      visualTop = nominalTop;
    } else {
      // Scrolled past -> Stack at top!
      final passedDistance = scrollOffset - nominalTop;
      final stackDepth = passedDistance / cardHeight;

      // Tuck upward 4px per card in stack up to max 12px
      final tuckY = (stackDepth * 4.0).clamp(0.0, 12.0);
      visualTop = scrollOffset - tuckY;

      // Subtle scale reduction for depth illusion
      scale = (1.0 - (stackDepth * 0.015)).clamp(0.95, 1.0);

      // Node on the left timeline fades out as card enters stack
      nodeOpacity = (1.0 - stackDepth * 2.0).clamp(0.0, 1.0);

      // Smooth gradual fade effect as cards go deeper into the stack
      opacity = (1.0 - stackDepth * 0.28).clamp(0.0, 1.0);
    }

    Widget node;
    if (plan.dayNumber == activeDay) {
      node = widget.isUserCompleted ? _buildCompletedNode() : _buildActiveNode();
    } else if (plan.isRestDay) {
      node = plan.dayNumber < activeDay ? _buildPastRestNode() : _buildDefaultNode();
    } else if (plan.dayNumber < activeDay) {
      node = _buildCompletedNode();
    } else {
      node = _buildDefaultNode();
    }

    Widget card;
    if (plan.dayNumber == activeDay) {
      card = _buildActiveDayCard(plan);
    } else if (plan.isRestDay) {
      card = _buildRestDayCard(plan.dayNumber, isPast: plan.dayNumber < activeDay);
    } else if (plan.dayNumber < activeDay) {
      card = _buildCompletedCard(plan);
    } else {
      card = _buildUpcomingCard(
        plan.dayNumber,
        plan.dayNumber == 30
            ? '${plan.category} (${plan.exerciseSummary})'
            : plan.exerciseSummary,
      );
    }

    return Positioned(
      key: ValueKey('timeline_item_$index'),
      top: visualTop,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Opacity(
                  opacity: nodeOpacity,
                  child: node,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: card),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveNode() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF00D09E),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x3300D09E),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
      ),
    );
  }

  Widget _buildCompletedNode() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF00D09E),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildPastRestNode() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF3B82F6),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildDefaultNode() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFCBD5E1),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  // COMPLETED CARD (Hari 1 - 13 selain Rest Day)
  // Desain solid putih bersih dengan icon aksen hijau solid
  Widget _buildCompletedCard(WorkoutDayPlan plan) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day ${plan.dayNumber}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D1E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  plan.exerciseSummary,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: Color(0xFF00D09E),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // ACTIVE DAY CARD (Today)
  // Desain Solid Emerald Green (#00D09E) tegas sesuai palet utama dokumen
  // Ukuran identik dengan kartu lainnya (tinggi seimbang), tombol START/DONE di sisi kanan
  Widget _buildActiveDayCard(WorkoutDayPlan plan) {
    final isDone = widget.isUserCompleted;
    final isPaused = !isDone && _pausedDayNumber == plan.dayNumber;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF00D09E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00B789), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D09E).withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Day ${plan.dayNumber}',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (isPaused) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007A58),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PAUSED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  plan.exerciseSummary,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE8F9F3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 60,
            child: Center(
              child: SizedBox(
                width: isPaused ? 104 : 96,
                height: 44,
                child: ElevatedButton(
                  onPressed: _handleStartWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDone ? const Color(0xFF007A58) : Colors.white,
                    foregroundColor: isDone ? Colors.white : const Color(0xFF00A87A),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isDone
                            ? Icons.check_rounded
                            : (isPaused ? Icons.replay_rounded : Icons.play_arrow_rounded),
                        size: 18,
                        color: isDone ? Colors.white : const Color(0xFF00A87A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isDone ? 'DONE' : (isPaused ? 'RESUME' : 'START'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.5,
                          color: isDone ? Colors.white : const Color(0xFF00A87A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UPCOMING CARD
  Widget _buildUpcomingCard(int day, String meta) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEFEA), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day $day',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D1E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: Color(0xFF9CA3AF),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // REST DAY CARD (Solid Blue #3B82F6 tegas)
  Widget _buildRestDayCard(int day, {bool isPast = false}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day $day',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Rest & Muscle Recovery',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEFF6FF),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter untuk TikTok Flame Identik dengan Path SVG di HTML
class _TikTokFlamePainter extends CustomPainter {
  final bool isLit;

  _TikTokFlamePainter({required this.isLit});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final outerPaint = Paint()
      ..color = isLit ? const Color(0xFFFF5722) : const Color(0xFF9CA3AF);
    final innerPaint = Paint()
      ..color = isLit ? const Color(0xFFFFA000) : const Color(0xFFD1D5DB);

    // Outer flame: d="M12 2C9.5 5.2 6.5 8.5 6.5 13C6.5 16.9 9 20 12 20C15 20 17.5 16.9 17.5 13C17.5 8.5 14.5 5.2 12 2Z"
    final outerPath = Path()
      ..moveTo(12, 2)
      ..cubicTo(9.5, 5.2, 6.5, 8.5, 6.5, 13)
      ..cubicTo(6.5, 16.9, 9, 20, 12, 20)
      ..cubicTo(15, 20, 17.5, 16.9, 17.5, 13)
      ..cubicTo(17.5, 8.5, 14.5, 5.2, 12, 2)
      ..close();
    canvas.drawPath(outerPath, outerPaint);

    // Inner flame: d="M12 8C10.8 10 9.5 11.8 9.5 14C9.5 15.8 10.6 17.5 12 17.5C13.4 17.5 14.5 15.8 14.5 14C14.5 11.8 13.2 10 12 8Z"
    final innerPath = Path()
      ..moveTo(12, 8)
      ..cubicTo(10.8, 10, 9.5, 11.8, 9.5, 14)
      ..cubicTo(9.5, 15.8, 10.6, 17.5, 12, 17.5)
      ..cubicTo(13.4, 17.5, 14.5, 15.8, 14.5, 14)
      ..cubicTo(14.5, 11.8, 13.2, 10, 12, 8)
      ..close();
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _TikTokFlamePainter oldDelegate) =>
      oldDelegate.isLit != isLit;
}
