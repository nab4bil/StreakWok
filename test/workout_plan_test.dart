import 'package:flutter_test/flutter_test.dart';
import 'package:streakwok/features/dashboard/domain/workout_plan_model.dart';

void main() {
  group('WorkoutPlanRepository 30-Day Program Verification', () {
    const plans = WorkoutPlanRepository.plan30Days;

    test('should contain exactly 30 days', () {
      expect(plans.length, 30);
      for (int i = 0; i < 30; i++) {
        expect(plans[i].dayNumber, i + 1);
      }
    });

    test('should have exactly 7 rest days on days 4, 8, 12, 16, 20, 24, 28', () {
      final restDays = plans.where((p) => p.isRestDay).map((p) => p.dayNumber).toList();
      expect(restDays, [4, 8, 12, 16, 20, 24, 28]);
      expect(restDays.length, 7);
    });

    test('should contain only the 6 agreed bodyweight exercises', () {
      const allowedExercises = {
        'Push-up',
        'Squat',
        'Sit-up',
        'Plank',
        'Lunges',
        'Leg Raises',
      };

      for (final plan in plans) {
        if (!plan.isRestDay) {
          expect(plan.exerciseNames.isNotEmpty, true);
          for (final exercise in plan.exerciseNames) {
            expect(
              allowedExercises.contains(exercise),
              true,
              reason: 'Day ${plan.dayNumber} has invalid exercise "$exercise"',
            );
          }
        }
      }
    });

    test('Day 14 is active day with Lower & Core pattern', () {
      final day14 = plans.firstWhere((p) => p.dayNumber == 14);
      expect(day14.isRestDay, false);
      expect(day14.category, 'Lower & Core');
      expect(day14.exerciseNames, ['Squat', 'Lunges', 'Leg Raises']);
    });

    test('Day 30 is closing Full Body Challenge', () {
      final day30 = plans.firstWhere((p) => p.dayNumber == 30);
      expect(day30.isRestDay, false);
      expect(day30.category, 'Full Body Challenge');
      expect(day30.exerciseNames, ['Push-up', 'Squat', 'Plank']);
    });
  });
}
