import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../domain/workout_plan_model.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final bool isUserCompleted;
  final bool hasGroup;
  final String groupName;
  final bool isLeader;
  final VoidCallback onToggleWorkout;
  final VoidCallback? onViewGroup;
  final VoidCallback? onJoinGroupTap;
  final VoidCallback? onCreateGroupTap;
  final VoidCallback? onToggleGroupState;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.isUserCompleted,
    this.hasGroup = false,
    this.groupName = 'gerup ketat',
    this.isLeader = false,
    required this.onToggleWorkout,
    this.onViewGroup,
    this.onJoinGroupTap,
    this.onCreateGroupTap,
    this.onToggleGroupState,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _day14Key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToDay14(animated: false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  void _scrollToDay14({bool animated = true}) {
    final context = _day14Key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.15,
        duration: animated ? const Duration(milliseconds: 350) : Duration.zero,
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleStartWorkout() {
    widget.onToggleWorkout();
  }

  @override
  Widget build(BuildContext context) {
    final streakDays = widget.isLeader
        ? (widget.isUserCompleted ? 1 : 0)
        : (widget.isUserCompleted ? 15 : 14);

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
                    Column(
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

            // Scrollable Content
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                children: [
                  // CARD 1: GROUP INFO CARD / NO-GROUP CARD
                  if (widget.hasGroup)
                    _buildInGroupCard(streakDays)
                  else
                    _buildNoGroupCard(),

                  const SizedBox(height: 24),

                  // WORKOUT PLAN STAGE HEADER
                  Row(
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
                        onTap: () => _scrollToDay14(animated: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F9F3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBCE7D6), width: 1),
                          ),
                          child: const Text(
                            'Day 14',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF009E74),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // TIMELINE WITH VERTICAL CONNECTING LINE
                  _buildTimelineSection(),

                  const SizedBox(height: 30),
                ],
              ),
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

  // TIMELINE WITH LEFT CONNECTING LINE (30 DAYS FULL PROGRAM)
  Widget _buildTimelineSection() {
    const plans = WorkoutPlanRepository.plan30Days;

    return Stack(
      children: [
        // Connecting vertical line (runs from center of first node to center of last node)
        Positioned(
          left: 11,
          top: 38,
          bottom: 38,
          child: Container(
            width: 2,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE7E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // 30 Days Column
        Column(
          children: List.generate(plans.length, (index) {
            final plan = plans[index];
            final isLast = index == plans.length - 1;

            Widget nodeWidget;
            Widget cardWidget;
            Key? rowKey;

            if (plan.dayNumber < WorkoutPlanRepository.currentActiveDay) {
              // Past / Completed Days (1 - 13)
              if (plan.isRestDay) {
                nodeWidget = _buildPastRestNode();
                cardWidget = _buildRestDayCard(plan.dayNumber, isPast: true);
              } else {
                nodeWidget = _buildCompletedNode();
                cardWidget = _buildCompletedCard(plan);
              }
            } else if (plan.dayNumber == WorkoutPlanRepository.currentActiveDay) {
              // Active Day (Day 14 - Today)
              rowKey = _day14Key;
              nodeWidget = _buildActiveNode();
              cardWidget = _buildDay14Card();
            } else {
              // Upcoming Days (15 - 30)
              nodeWidget = _buildDefaultNode();
              if (plan.isRestDay) {
                cardWidget = _buildRestDayCard(plan.dayNumber, isPast: false);
              } else {
                cardWidget = _buildUpcomingCard(
                  plan.dayNumber,
                  plan.dayNumber == 30
                      ? '${plan.category} (${plan.exerciseSummary})'
                      : plan.exerciseSummary,
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: _buildTimelineRow(
                key: rowKey,
                node: nodeWidget,
                card: cardWidget,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTimelineRow({Key? key, required Widget node, required Widget card}) {
    return Row(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        node,
        const SizedBox(width: 14),
        Expanded(child: card),
      ],
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
      decoration: BoxDecoration(
        color: const Color(0xFFE8F9F3),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF00D09E), width: 2),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF00D09E),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildPastRestNode() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF93C5FD), width: 2),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF3B82F6),
            shape: BoxShape.circle,
          ),
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
  // Strictly ZERO CHECKMARK: Menggunakan teks badge "Completed"
  Widget _buildCompletedCard(WorkoutDayPlan plan) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EFE7), width: 1.5),
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
                        color: Color(0xFF1A1D1E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F9F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF009E74),
                        ),
                      ),
                    ),
                  ],
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
              color: Color(0xFFE8F9F3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: Color(0xFF00B789),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // DAY 14 CARD (Identik dengan workout-card today)
  Widget _buildDay14Card() {
    final isDone = widget.isUserCompleted;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF8F3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6EFE5), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Day 14',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D1E),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Squat • Lunges • Leg Raises',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 96,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: _handleStartWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDone ? const Color(0xFF00A87A) : const Color(0xFF00D09E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isDone ? 'DONE' : 'START',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Illustration circle
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFCFF0E4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: Color(0xFF00B789),
              size: 38,
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

  // REST DAY CARD (Bebas dari icon bulan / moon emoji dan label redundant)
  Widget _buildRestDayCard(int day, {bool isPast = false}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E3F8), width: 1.5),
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
                      'Day $day',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    if (isPast) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Rest Day',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Rest & Muscle Recovery',
                  style: TextStyle(
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
              color: Color(0xFFE0E7FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: Color(0xFF3B82F6),
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
