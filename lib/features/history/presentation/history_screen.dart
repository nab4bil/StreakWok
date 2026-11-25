import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/user_progress_service.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  final List<WorkoutHistoryEntry> historyEntries;
  final int currentStreakDays;
  final DateTime? referenceDate;

  const HistoryScreen({
    super.key,
    this.onBackPressed,
    this.historyEntries = const [],
    this.currentStreakDays = 0,
    this.referenceDate,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _displayedMonth;

  DateTime get _today => widget.referenceDate ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = _today;
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  void _changeMonth(int deltaMonths) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + deltaMonths,
        1,
      );
    });
  }

  String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatTotalMinutesLabel(int totalSeconds) {
    if (totalSeconds <= 0) return '0 min';
    if (totalSeconds < 60) return '${totalSeconds}s';
    final minutes = totalSeconds / 60.0;
    final formatted = minutes.toStringAsFixed(1);
    return '${formatted.endsWith('.0') ? formatted.substring(0, formatted.length - 2) : formatted} min';
  }

  @override
  Widget build(BuildContext context) {
    final totalWorkouts =
        widget.historyEntries.where((e) => !e.isRestDay).length;
    final totalSeconds = widget.historyEntries.fold<int>(
      0,
      (sum, e) => sum + e.durationSeconds,
    );

    final monthEntries = widget.historyEntries
        .where(
          (e) =>
              e.completedAt.year == _displayedMonth.year &&
              e.completedAt.month == _displayedMonth.month,
        )
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    final monthSeconds =
        monthEntries.fold<int>(0, (sum, e) => sum + e.durationSeconds);
    final monthReps =
        monthEntries.fold<int>(0, (sum, e) => sum + e.totalReps);
    final monthLabel = DateFormat('MMMM yyyy').format(_displayedMonth);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFB),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFCFB),
                border: Border(bottom: BorderSide(color: Color(0xFFEEF2F0))),
              ),
              child: Row(
                children: [
                  if (widget.onBackPressed != null) ...[
                    GestureDetector(
                      onTap: widget.onBackPressed,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.centerLeft,
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          size: 26,
                          color: Color(0xFF1A1D1E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1D1E),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                children: [
                  // UC-02 Summary Metrics (Total Workouts, Total Minutes, Streak)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          label: 'Total Workouts',
                          value: '$totalWorkouts',
                          icon: Icons.fitness_center_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricCard(
                          label: 'Total Minutes',
                          value: _formatTotalMinutesLabel(totalSeconds),
                          icon: Icons.schedule_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricCard(
                          label: 'Streak',
                          value: '${widget.currentStreakDays}d',
                          icon: Icons.local_fire_department_rounded,
                          accentColor: const Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Interactive Month Selector
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          key: const Key('history_prev_month_btn'),
                          onTap: () => _changeMonth(-1),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 22,
                              color: Color(0xFF1A1D1E),
                            ),
                          ),
                        ),
                        Text(
                          monthLabel,
                          key: const Key('history_month_label'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1D1E),
                          ),
                        ),
                        GestureDetector(
                          key: const Key('history_next_month_btn'),
                          onTap: () => _changeMonth(1),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: Color(0xFF1A1D1E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // DYNAMIC CALENDAR GRID CARD
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFE6ECE8), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _WeekdayLabel('Sun'),
                            _WeekdayLabel('Mon'),
                            _WeekdayLabel('Tue'),
                            _WeekdayLabel('Wed'),
                            _WeekdayLabel('Thu'),
                            _WeekdayLabel('Fri'),
                            _WeekdayLabel('Sat'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildCalendarGrid(monthEntries),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // SECTION: ACTIVITY HISTORY FOR SELECTED MONTH
                  const Text(
                    'Activity history',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1D1E),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (monthEntries.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 28, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFE6ECE8), width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F3),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              color: Color(0xFF8C949D),
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No workout history in $monthLabel',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1D1E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Complete a daily workout or rest day to track your progress here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8C949D),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFE6ECE8), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      monthLabel,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A1D1E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${monthEntries.length} ${monthEntries.length == 1 ? 'Activity' : 'Activities'}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF8C949D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.schedule_rounded,
                                      size: 14, color: Color(0xFF6B7280)),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDuration(monthSeconds),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4B5563),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.bolt_rounded,
                                      size: 14, color: Color(0xFF00D09E)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$monthReps Reps',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF00A87A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          for (int i = 0; i < monthEntries.length; i++) ...[
                            const SizedBox(height: 14),
                            Divider(color: Colors.grey.shade100, height: 1),
                            const SizedBox(height: 14),
                            _buildActivityRow(
                              tag: monthEntries[i].isRestDay
                                  ? 'Rest day'
                                  : 'Workout plan',
                              tagColor: monthEntries[i].isRestDay
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF00A87A),
                              title: monthEntries[i].formattedTitle,
                              time: DateFormat('h:mm a')
                                  .format(monthEntries[i].completedAt),
                              date: DateFormat('MMM d')
                                  .format(monthEntries[i].completedAt),
                              duration: monthEntries[i].isRestDay
                                  ? 'Recovery'
                                  : _formatDuration(
                                      monthEntries[i].durationSeconds),
                              reps: monthEntries[i].isRestDay
                                  ? 'Rest Complete'
                                  : (monthEntries[i].totalReps > 0
                                      ? '${monthEntries[i].totalReps} Reps'
                                      : 'Completed'),
                              isRest: monthEntries[i].isRestDay,
                            ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    Color accentColor = const Color(0xFF00D09E),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accentColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1D1E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8C949D),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(List<WorkoutHistoryEntry> monthEntries) {
    final daysInMonth =
        DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
    final leadingEmpty =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday % 7;

    final entriesByDay = <int, WorkoutHistoryEntry>{};
    for (final entry in monthEntries) {
      entriesByDay[entry.completedAt.day] = entry;
    }

    final today = _today;
    final isCurrentMonth = today.year == _displayedMonth.year &&
        today.month == _displayedMonth.month;

    final List<Widget> cells = [];
    for (int i = 0; i < leadingEmpty; i++) {
      cells.add(const SizedBox(width: 34, height: 34));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final entry = entriesByDay[day];
      final isActiveToday = isCurrentMonth && today.day == day;
      cells.add(
        _buildDateCell(
          '$day',
          isDone: entry != null,
          isActiveToday: isActiveToday,
          isRest: entry?.isRestDay ?? false,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 4,
      children: cells,
    );
  }

  static Widget _buildDateCell(
    String text, {
    bool isDone = false,
    bool isActiveToday = false,
    bool isRest = false,
  }) {
    Color bg = Colors.transparent;
    Color textColor = const Color(0xFF6B7280);
    FontWeight fw = FontWeight.w500;
    BoxBorder? border;

    if (isDone) {
      bg = isRest ? const Color(0xFF3B82F6) : const Color(0xFF00D09E);
      textColor = Colors.white;
      fw = FontWeight.w800;
    } else if (isActiveToday) {
      bg = const Color(0xFFE8F9F3);
      textColor = const Color(0xFF007A58);
      fw = FontWeight.w800;
      border = Border.all(color: const Color(0xFF00D09E), width: 1.5);
    }

    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: border,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: fw,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildActivityRow({
    required String tag,
    required Color tagColor,
    required String title,
    required String time,
    required String date,
    required String duration,
    required String reps,
    required bool isRest,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isRest ? const Color(0xFF3B82F6) : const Color(0xFFFF5722),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              isRest ? Icons.spa_rounded : Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tag,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: tagColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D1E),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 2,
                children: [
                  Text(
                    '$time • $date',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8C949D),
                    ),
                  ),
                  Text(
                    '$duration • $reps',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;
  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8C949D),
          ),
        ),
      ),
    );
  }
}
