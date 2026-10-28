import 'package:flutter/material.dart';

class GroupHistoryScreen extends StatelessWidget {
  final String groupName;
  final bool isLeader;
  final String userName;
  final bool isUserCompleted;

  const GroupHistoryScreen({
    super.key,
    this.groupName = 'gerup ketat',
    this.isLeader = false,
    this.userName = 'rudi musikal',
    this.isUserCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFB),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Header (Identik 1:1 dengan group_history_screen.html)
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
                        groupName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF009E74),
                        ),
                      ),
                    ],
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

                  // CALENDAR GRID (GROUP STREAK REPUTATION)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
                    ),
                    child: Column(
                      children: [
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
                        _buildGroupCalendarGrid(),
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

                  if (isLeader) ...[
                    if (isUserCompleted) ...[
                      _buildGroupActivityCard(
                        title: 'Day 1 | Push-up • Squat • Plank',
                        date: 'Sunday, Oct 18, 2026',
                        statusText: '1/1 Done',
                        isSuccess: true,
                        members: [userName.toLowerCase()],
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
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
                                child: const Icon(Icons.history_rounded, color: Color(0xFF8C949D), size: 24),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No activity recorded yet',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1E)),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Complete today\'s workout to start your group streak log!',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF8C949D)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // Activity 1: Day 13 (Push-up • Sit-up • Plank)
                    _buildGroupActivityCard(
                      title: 'Day 13 | Push-up • Sit-up • Plank',
                      date: 'Saturday, Oct 17, 2026',
                      statusText: '3/3 Done',
                      isSuccess: true,
                      members: ['tono hardija', 'rudi musikal', 'mahmud buah'],
                    ),

                    const SizedBox(height: 12),

                    // Activity 2: Day 12 (Rest Day)
                    _buildRestDayCard(
                      title: 'Day 12 | Rest & Muscle Recovery',
                      date: 'Friday, Oct 16, 2026',
                    ),

                    const SizedBox(height: 12),

                    // Activity 3: Day 11 (Push-up • Squat • Plank)
                    _buildGroupActivityCard(
                      title: 'Day 11 | Push-up • Squat • Plank',
                      date: 'Thursday, Oct 15, 2026',
                      statusText: '3/3 Done',
                      isSuccess: true,
                      members: ['tono hardija', 'rudi musikal', 'mahmud buah'],
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

  // 35 Cells Calendar Grid (Identik dengan group_history_screen.html)
  Widget _buildGroupCalendarGrid() {
    final cells = <Widget>[
      // Row 1: 4 empty (Thu Oct 1)
      const _EmptyCell(),
      const _EmptyCell(),
      const _EmptyCell(),
      const _EmptyCell(),
      const _DayCell('1'),
      const _DayCell('2'),
      const _DayCell('3'),

      // Row 2: Oct 4 - 10 Done by all if existing group
      _DayCell('4', isDone: !isLeader),
      _DayCell('5', isDone: !isLeader),
      _DayCell('6', isDone: !isLeader),
      _DayCell('7', isDone: !isLeader),
      _DayCell('8', isDone: !isLeader),
      _DayCell('9', isDone: !isLeader),
      _DayCell('10', isDone: !isLeader),

      // Row 3: Oct 11 - 17 Done by all if existing group
      _DayCell('11', isDone: !isLeader),
      _DayCell('12', isDone: !isLeader),
      _DayCell('13', isDone: !isLeader),
      _DayCell('14', isDone: !isLeader),
      _DayCell('15', isDone: !isLeader),
      _DayCell('16', isDone: !isLeader),
      _DayCell('17', isDone: !isLeader),

      // Row 4: Oct 18 Active Today (In Progress)
      _DayCell('18', isActiveToday: true, isDone: isLeader ? isUserCompleted : false),
      const _DayCell('19'),
      const _DayCell('20'),
      const _DayCell('21'),
      const _DayCell('22'),
      const _DayCell('23'),
      const _DayCell('24'),

      // Row 5: Remaining days
      const _DayCell('25'),
      const _DayCell('26'),
      const _DayCell('27'),
      const _DayCell('28'),
      const _DayCell('29'),
      const _DayCell('30'),
      const _DayCell('31'),
    ];

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
              Column(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSuccess ? const Color(0xFFE8F9F3) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSuccess ? const Color(0xFF00A87A) : const Color(0xFFDC2626),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              Column(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
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

  const _DayCell(this.day, {this.isDone = false, this.isActiveToday = false});

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
      bgColor = const Color(0xFF00D09E);
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
