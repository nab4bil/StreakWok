import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  final VoidCallback? onBackPressed;

  const HistoryScreen({super.key, this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFB),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Header (Identik dengan history_screen.html)
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
                    onTap: onBackPressed,
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
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1D1E),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 32), // Placeholder balance
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                children: [
                  // Month Selector (October 2026)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Icon(Icons.chevron_left_rounded, size: 22, color: Color(0xFF1A1D1E)),
                        Text(
                          'October 2026',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1D1E),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF1A1D1E)),
                      ],
                    ),
                  ),

                  // CALENDAR GRID CARD (OCTOBER 2026)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        // Weekday names
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
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

                        // Calendar Grid (7 columns x 5 rows)
                        _buildCalendarGrid(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // SECTION: WEEKLY HISTORY
                  const Text(
                    'Weekly history',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1D1E),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Week Summary Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Week Summary Top
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Oct 11 - Oct 17',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1D1E),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '7 Activities',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8C949D),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF6B7280)),
                                    SizedBox(width: 4),
                                    Text(
                                      '24:18',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Row(
                                  children: const [
                                    Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF00D09E)),
                                    SizedBox(width: 4),
                                    Text(
                                      '100% Reps',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF00A87A),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Divider(color: Colors.grey.shade100, height: 1),
                        const SizedBox(height: 14),

                        // Activity 1: Oct 17 (Push-up • Sit-up • Plank)
                        _buildActivityRow(
                          tag: 'Workout plan',
                          tagColor: const Color(0xFF00A87A),
                          title: 'Day 13 | Push-up • Sit-up • Plank',
                          time: '5:20 PM',
                          date: 'Oct 17',
                          duration: '04:12',
                          reps: '45 Reps',
                          isRest: false,
                        ),
                        const SizedBox(height: 14),
                        Divider(color: Colors.grey.shade100, height: 1),
                        const SizedBox(height: 14),

                        // Activity 2: Oct 16 (Rest Day)
                        _buildActivityRow(
                          tag: 'Rest day',
                          tagColor: const Color(0xFF3B82F6),
                          title: 'Day 12 | Rest & Recovery',
                          time: 'All Day',
                          date: 'Oct 16',
                          duration: 'Recovery',
                          reps: '100% Rest',
                          isRest: true,
                        ),
                        const SizedBox(height: 14),
                        Divider(color: Colors.grey.shade100, height: 1),
                        const SizedBox(height: 14),

                        // Activity 3: Oct 15 (Squat • Lunges)
                        _buildActivityRow(
                          tag: 'Workout plan',
                          tagColor: const Color(0xFF00A87A),
                          title: 'Day 11 | Squat • Lunges • Leg Raises',
                          time: '6:15 PM',
                          date: 'Oct 15',
                          duration: '05:30',
                          reps: '60 Reps',
                          isRest: false,
                        ),
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

  static Widget _buildCalendarGrid() {
    // 35 items total for 5 weeks
    // Days 1-3 empty, Days 4-17 done (green), Day 18 active-today (dark), Days 19-31 default
    final List<Widget> cells = [];

    // Week 1: 4 empty, then 1, 2, 3
    for (int i = 0; i < 4; i++) {
      cells.add(const SizedBox(width: 34, height: 34));
    }
    cells.add(_buildDateCell('1'));
    cells.add(_buildDateCell('2'));
    cells.add(_buildDateCell('3'));

    // Week 2: 4 to 10 (all done)
    for (int d = 4; d <= 10; d++) {
      cells.add(_buildDateCell('$d', isDone: true));
    }

    // Week 3: 11 to 17 (all done)
    for (int d = 11; d <= 17; d++) {
      cells.add(_buildDateCell('$d', isDone: true));
    }

    // Week 4: 18 (active today), 19-24 upcoming
    cells.add(_buildDateCell('18', isActiveToday: true));
    for (int d = 19; d <= 24; d++) {
      cells.add(_buildDateCell('$d'));
    }

    // Week 5: 25-31
    for (int d = 25; d <= 31; d++) {
      cells.add(_buildDateCell('$d'));
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

  static Widget _buildDateCell(String text, {bool isDone = false, bool isActiveToday = false}) {
    Color bg = Colors.transparent;
    Color textColor = const Color(0xFF6B7280);
    FontWeight fw = FontWeight.w500;

    if (isActiveToday) {
      bg = const Color(0xFF1A1D1E);
      textColor = Colors.white;
      fw = FontWeight.w800;
    } else if (isDone) {
      bg = const Color(0xFFE8F9F3);
      textColor = const Color(0xFF00A87A);
      fw = FontWeight.w700;
    }

    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
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
            color: isRest ? const Color(0xFFE0E7FF) : const Color(0xFFFFF3ED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              isRest ? Icons.spa_rounded : Icons.local_fire_department_rounded,
              color: isRest ? const Color(0xFF3B82F6) : const Color(0xFFFF5722),
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
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tagColor),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1E)),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('$time • $date', style: const TextStyle(fontSize: 11, color: Color(0xFF8C949D))),
                  const SizedBox(width: 8),
                  Text('$duration • $reps', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
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
