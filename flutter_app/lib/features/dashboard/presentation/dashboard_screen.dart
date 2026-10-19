import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isRudiCompleted = false;
  int _streakCount = 0;

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _toggleWorkoutCompletion() {
    setState(() {
      _isRudiCompleted = !_isRudiCompleted;
      _streakCount = _isRudiCompleted ? 1 : 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isRudiCompleted
              ? 'Day 14 Completed! Rudi finished. Group streak flame is burning bright! 🔥'
              : 'Reset to Rudi Pending. Streak flame is dimmed gray.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Pinned Sticky Header (Tap to Scroll to Top)
            GestureDetector(
              onTap: _scrollToTop,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.background,
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
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMain,
                            ),
                            children: [
                              TextSpan(text: 'Streak'),
                              TextSpan(
                                text: 'Wok',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Yo! rudi musikal',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6ECE8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '⇄ No Group',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Timeline Content (Day 14 to Day 17 Prototype Sample)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                itemCount: 4,
                itemBuilder: (context, index) {
                  final dayNumber = 14 + index;
                  return _buildTimelineStep(dayNumber);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(int day) {
    final isToday = day == 14;
    final isRestDay = day == 16;
    final isFinale = false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isToday
              ? const Color(0xFFEBF8F3)
              : isRestDay
                  ? AppColors.restCardBg
                  : isFinale
                      ? const Color(0xFFFEF3C7)
                      : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isToday
                ? const Color(0xFFD6EFE5)
                : isRestDay
                    ? const Color(0xFFD8E3F8)
                    : isFinale
                        ? const Color(0xFFFCD34D)
                        : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day $day',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isRestDay
                        ? AppColors.restBlue
                        : isFinale
                            ? const Color(0xFFB45309)
                            : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isRestDay
                      ? 'Rest & Muscle Recovery'
                      : isFinale
                          ? 'Grand Finale: 30-Day Master Milestone! 🏆'
                          : 'Squat • Push-up • Calisthenics',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _toggleWorkoutCompletion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRudiCompleted ? AppColors.primaryDark : AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      _isRudiCompleted ? 'DONE ✓' : 'START',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
            Icon(
              isRestDay
                  ? Icons.nightlight_round
                  : isFinale
                      ? Icons.emoji_events
                      : Icons.fitness_center,
              color: isRestDay
                  ? AppColors.restBlue
                  : isFinale
                      ? AppColors.goldMilestone
                      : AppColors.primary,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
