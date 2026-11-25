import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/user_progress_service.dart';

class GroupHistoryScreen extends StatefulWidget {
  final String groupName;
  final bool isLeader;
  final String userName;
  final bool isUserCompleted;
  final List<WorkoutHistoryEntry> historyEntries;
  final List<String> memberNames;
  final DateTime? referenceDate;

  const GroupHistoryScreen({
    super.key,
    this.groupName = 'gerup ketat',
    this.isLeader = false,
    this.userName = 'rudi musikal',
    this.isUserCompleted = false,
    this.historyEntries = const [],
    this.memberNames = const [],
    this.referenceDate,
  });

  @override
  State<GroupHistoryScreen> createState() => _GroupHistoryScreenState();
}

class _GroupHistoryScreenState extends State<GroupHistoryScreen> {
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

  @override
  Widget build(BuildContext context) {
    final monthEntries = widget.historyEntries
        .where(
          (e) =>
              e.completedAt.year == _displayedMonth.year &&
              e.completedAt.month == _displayedMonth.month,
        )
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    final monthLabel = DateFormat('MMMM yyyy').format(_displayedMonth);
    final activeMembers = widget.memberNames.isNotEmpty
        ? widget.memberNames
        : [widget.userName.toLowerCase()];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFB),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFCFB),
                border: Border(bottom: BorderSide(color: Color(0xFFEEF2F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                  Column(
                    children: [
                      const Text(
                        'Group History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1D1E),
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        widget.groupName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF009E74),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                children: [
                  // Month Selector
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => _changeMonth(-1),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.chevron_left_rounded,
                                size: 22, color: Color(0xFF1A1D1E)),
                          ),
                        ),
                        Text(
                          monthLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1D1E),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _changeMonth(1),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.chevron_right_rounded,
                                size: 22, color: Color(0xFF1A1D1E)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // DYNAMIC CALENDAR GRID (GROUP STREAK REPUTATION)
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
                            _WeekdayLabel('S'),
                            _WeekdayLabel('M'),
                            _WeekdayLabel('T'),
                            _WeekdayLabel('W'),
                            _WeekdayLabel('T'),
                            _WeekdayLabel('F'),
                            _WeekdayLabel('S'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildGroupCalendarGrid(monthEntries),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // SECTION: GROUP ACTIVITY LOG
                  const Text(
                    'Group Activity Log',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1D1E),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (monthEntries.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 36, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFE6ECE8), width: 1.5),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.history_rounded,
                                  color: Color(0xFF8C949D), size: 24),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No activity recorded in $monthLabel',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1D1E)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Complete today\'s workout to record your group streak log!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8C949D)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    for (int i = 0; i < monthEntries.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      if (monthEntries[i].isRestDay)
                        _buildRestDayCard(
                          title: monthEntries[i].formattedTitle,
                          date: DateFormat('EEEE, MMM d, yyyy')
                              .format(monthEntries[i].completedAt),
                        )
                      else
                        _buildGroupActivityCard(
                          title: monthEntries[i].formattedTitle,
                          date: DateFormat('EEEE, MMM d, yyyy')
                              .format(monthEntries[i].completedAt),
                          statusText:
                              '${activeMembers.length}/${activeMembers.length} Active',
                          isSuccess: true,
                          members: activeMembers,
                        ),
                    ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCalendarGrid(List<WorkoutHistoryEntry> monthEntries) {
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

    final cells = <Widget>[];
    for (int i = 0; i < leadingEmpty; i++) {
      cells.add(const _EmptyCell());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final entry = entriesByDay[day];
      final isActiveToday = isCurrentMonth && today.day == day;
      cells.add(
        _DayCell(
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
      crossAxisSpacing: 6,
      children: cells,
    );
  }

  Widget _buildGroupActivityCard({
    required String title,
    required String date,
    required String statusText,
    required bool isSuccess,
    required List<String> members,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8C949D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? const Color(0xFF00D09E)
                      : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF4F7F5)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: members.map((member) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE6ECE8)),
                ),
                child: Text(
                  member,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D1E),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRestDayCard({required String title, required String date}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8C949D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Rest Day',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF4F7F5)),
          const SizedBox(height: 10),
          const Text(
            'Auto-Completed for all members',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8C949D),
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 32, height: 32);
  }
}

class _DayCell extends StatelessWidget {
  final String day;
  final bool isDone;
  final bool isActiveToday;
  final bool isRest;

  const _DayCell(
    this.day, {
    this.isDone = false,
    this.isActiveToday = false,
    this.isRest = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Color textColor = const Color(0xFF4B5563);
    FontWeight fontWeight = FontWeight.w600;

    if (isActiveToday) {
      bgColor = isDone ? const Color(0xFF00D09E) : const Color(0xFF1A1D1E);
      textColor = Colors.white;
      fontWeight = FontWeight.w800;
    } else if (isDone) {
      bgColor = isRest ? const Color(0xFF3B82F6) : const Color(0xFF00D09E);
      textColor = Colors.white;
      fontWeight = FontWeight.w800;
    }

    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              fontSize: 12,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
