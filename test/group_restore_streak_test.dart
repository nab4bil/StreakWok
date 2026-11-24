import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streakwok/features/group/presentation/group_screen.dart';

void main() {
  group('UC-12: Me-restore Streak Grup & UC-03 Upgrade Pro Bridge', () {
    testWidgets('1. Streak broken when past deadline and member undone; Restore button restores streak and decrements quota', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GroupScreen(
              userName: 'ambaroni',
              isLeader: true,
              isUserCompleted: true,
              isPastDeadline: true, // Simulate past 13:00 deadline
              initialRestoresLeft: 3,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Because mahmud buah is undone and isPastDeadline is true, streak is broken
      expect(find.text('Restore Streak'), findsOneWidget);
      expect(find.text('3 / 3'), findsOneWidget);

      // Tap Restore Streak button
      final restoreBtn = find.byKey(const Key('restore_streak_btn'));
      await tester.tap(restoreBtn);
      await tester.pump(); // Start jiggle animation
      await tester.pump(const Duration(milliseconds: 300)); // Midway in jiggle
      await tester.pumpAndSettle(); // Complete animation and show snackbar

      // Restores left decremented to 2 / 3
      expect(find.text('2 / 3'), findsOneWidget);

      // Streak is now restored, so the Restore Streak action button disappears
      expect(find.byKey(const Key('restore_streak_btn')), findsNothing);

      // Success SnackBar is shown
      expect(find.text('Streak restored! 2 restores left this month.'), findsOneWidget);
    });

    testWidgets('2. When monthly restores are exhausted (0/3), tapping Restore Streak opens Pro upgrade modal (UC-03)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GroupScreen(
              userName: 'ambaroni',
              isLeader: true,
              isUserCompleted: true,
              isPastDeadline: true,
              initialRestoresLeft: 0, // Exhausted restores
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Restores left card displays 0 / 3
      expect(find.text('0 / 3'), findsOneWidget);

      // Restore Streak button is still available
      final restoreBtn = find.byKey(const Key('restore_streak_btn'));
      expect(restoreBtn, findsOneWidget);

      // Tap Restore Streak with 0 restores left -> opens StreakWok Pro upgrade modal
      await tester.tap(restoreBtn);
      await tester.pumpAndSettle();

      // Pro modal is shown
      expect(find.text('StreakWok Pro'), findsOneWidget);
      expect(find.text('Unlimited Streak Restores'), findsOneWidget);
      expect(find.text('10 Members Group Capacity'), findsOneWidget);
      expect(find.text('Save 40%'), findsOneWidget);
      expect(find.byKey(const Key('confirm_upgrade_pro_btn')), findsOneWidget);

      // Confirm upgrade to Pro
      await tester.tap(find.byKey(const Key('confirm_upgrade_pro_btn')));
      await tester.pump();
      await tester.pumpAndSettle();

      // Pro is activated: Restores card shows Unlimited, and streak is revived
      expect(find.text('Unlimited'), findsOneWidget);
      expect(find.byKey(const Key('restore_streak_btn')), findsNothing);
      expect(find.textContaining('Upgraded to StreakWok Pro!'), findsOneWidget);
    });
  });
}
