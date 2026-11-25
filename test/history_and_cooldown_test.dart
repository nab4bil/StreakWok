import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streakwok/core/services/user_progress_service.dart';
import 'package:streakwok/features/group/presentation/group_history_screen.dart';
import 'package:streakwok/features/group/presentation/group_screen.dart';
import 'package:streakwok/features/history/presentation/history_screen.dart';
import 'package:streakwok/features/navigation/main_navigation_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserProgressService - History & 7-Day Cooldown Persistence', () {
    test('saves and loads workoutHistory entries and cooldownUntil per account', () async {
      final accountKey = UserProgressService.getAccountKey(email: 'nabil@gmail.com');
      final now = DateTime(2026, 11, 25, 8, 30);
      final cooldownEnd = now.add(const Duration(days: 7));

      final entry1 = WorkoutHistoryEntry(
        dayNumber: 1,
        category: 'Upper & Core',
        exerciseNames: const ['Push-up', 'Sit-up', 'Plank'],
        completedAt: now,
        durationSeconds: 185,
        totalReps: 27,
        isRestDay: false,
      );
      final entry2 = WorkoutHistoryEntry(
        dayNumber: 4,
        category: 'Rest & Muscle Recovery',
        exerciseNames: const [],
        completedAt: now.subtract(const Duration(days: 1)),
        durationSeconds: 0,
        totalReps: 0,
        isRestDay: true,
      );

      final progress = UserAccountProgress(
        accountKey: accountKey,
        currentActiveDay: 2,
        streakDays: 2,
        isUserCompleted: true,
        hasGroup: false,
        cooldownUntil: cooldownEnd,
        workoutHistory: [entry1, entry2],
      );

      await UserProgressService.saveProgress(progress);
      final loaded = await UserProgressService.loadProgress(accountKey);

      expect(loaded.workoutHistory.length, 2);
      expect(loaded.totalWorkoutsCount, 1);
      expect(loaded.totalWorkoutSeconds, 185);
      expect(loaded.totalWorkoutMinutes, 3);
      expect(loaded.workoutHistory.first.formattedTitle, 'Day 1 | Push-up • Sit-up • Plank');
      expect(loaded.workoutHistory.last.isRestDay, isTrue);
      expect(loaded.cooldownUntil, isNotNull);
      expect(loaded.isOnCooldown(now: now), isTrue);
      expect(loaded.remainingCooldownDays(now: now), 7);
      expect(
        loaded.remainingCooldownDays(now: cooldownEnd.subtract(const Duration(minutes: 5))),
        1,
      );
      expect(loaded.isOnCooldown(now: cooldownEnd.add(const Duration(seconds: 1))), isFalse);
      expect(loaded.remainingCooldownDays(now: cooldownEnd.add(const Duration(seconds: 1))), 0);

      // Clear cooldown explicitly
      await UserProgressService.saveProgress(loaded.copyWith(clearCooldown: true));
      final cleared = await UserProgressService.loadProgress(accountKey);
      expect(cleared.cooldownUntil, isNull);
      expect(cleared.isOnCooldown(now: now), isFalse);
    });
  });

  group('UC-02 Dynamic HistoryScreen & GroupHistoryScreen', () {
    testWidgets('HistoryScreen displays empty state for fresh account and navigates months', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: HistoryScreen(
            historyEntries: const [],
            currentStreakDays: 0,
            referenceDate: DateTime(2026, 11, 25),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total Workouts'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('0 min'), findsOneWidget);
      expect(find.text('November 2026'), findsOneWidget);
      final listScroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('No workout history in November 2026'),
        200,
        scrollable: listScroll,
      );
      expect(find.text('No workout history in November 2026'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('history_prev_month_btn')),
        -200,
        scrollable: listScroll,
      );
      await tester.tap(find.byKey(const Key('history_prev_month_btn')));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('No workout history in October 2026'),
        200,
        scrollable: listScroll,
      );
      expect(find.text('No workout history in October 2026'), findsOneWidget);
    });

    testWidgets('HistoryScreen computes real total workouts, minutes, and renders entries', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      final entries = [
        WorkoutHistoryEntry(
          dayNumber: 1,
          category: 'Upper & Core',
          exerciseNames: const ['Push-up', 'Sit-up', 'Plank'],
          completedAt: DateTime(2026, 11, 25, 17, 20),
          durationSeconds: 180, // 3 min
          totalReps: 27,
          isRestDay: false,
        ),
        WorkoutHistoryEntry(
          dayNumber: 2,
          category: 'Lower & Core',
          exerciseNames: const ['Squat', 'Lunges', 'Leg Raises'],
          completedAt: DateTime(2026, 11, 24, 18, 0),
          durationSeconds: 120, // 2 min -> total 5 min
          totalReps: 42,
          isRestDay: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: HistoryScreen(
            historyEntries: entries,
            currentStreakDays: 2,
            referenceDate: DateTime(2026, 11, 25),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets); // Total Workouts = 2 & calendar date
      expect(find.text('5 min'), findsOneWidget); // Total Minutes = 5 min
      expect(find.text('2d'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Day 2 | Squat • Lunges • Leg Raises'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('2 Activities'), findsOneWidget);
      expect(find.text('05:00'), findsOneWidget);
      expect(find.text('69 Reps'), findsOneWidget);
      expect(find.text('Day 1 | Push-up • Sit-up • Plank'), findsOneWidget);
      expect(find.text('Day 2 | Squat • Lunges • Leg Raises'), findsOneWidget);
    });

    testWidgets('GroupHistoryScreen renders dynamic month and entries instead of static Oct 2026', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      final entries = [
        WorkoutHistoryEntry(
          dayNumber: 3,
          category: 'Full Body',
          exerciseNames: const ['Push-up', 'Squat', 'Plank'],
          completedAt: DateTime(2026, 11, 25, 7, 30),
          durationSeconds: 150,
          totalReps: 27,
          isRestDay: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: GroupHistoryScreen(
            groupName: 'gerup ketat',
            isLeader: true,
            userName: 'ambaroni',
            historyEntries: entries,
            memberNames: const ['ambaroni', 'tono hardija'],
            referenceDate: DateTime(2026, 11, 25),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('October 2026'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Day 3 | Push-up • Squat • Plank'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Day 3 | Push-up • Squat • Plank'), findsOneWidget);
      expect(find.text('2/2 Active'), findsOneWidget);
    });
  });

  group('UC-06 & UC-07 Real 7-Day Cooldown Enforcement', () {
    testWidgets('GroupScreen blocks Join Group when user has active cooldownUntil', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool joined = false;
      final cooldownUntil = DateTime.now().add(const Duration(days: 4, hours: 12));

      await tester.pumpWidget(
        MaterialApp(
          home: GroupScreen(
            userName: 'ambaroni',
            hasGroup: false,
            cooldownUntil: cooldownUntil,
            onJoinGroup: (_) => joined = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('group_cooldown_banner')), findsOneWidget);
      expect(
        find.text('Anda belum bisa bergabung grup selama 5 hari'),
        findsOneWidget,
      );

      final joinBtn = find.widgetWithText(ElevatedButton, 'Join Group');
      await tester.scrollUntilVisible(
        joinBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(joinBtn);
      await tester.pumpAndSettle();

      expect(joined, isFalse);
      expect(
        find.text('Anda belum bisa bergabung grup selama 5 hari'),
        findsWidgets,
      );
    });

    testWidgets('Leaving a group in MainNavigationScreen activates 7-day cooldown and blocks rejoin', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      const email = 'nabil@streakwok.id';
      final accountKey = UserProgressService.getAccountKey(email: email);
      await UserProgressService.saveProgress(
        UserAccountProgress(
          accountKey: accountKey,
          currentActiveDay: 3,
          streakDays: 2,
          hasGroup: true,
          groupName: 'gerup ketat',
          isLeader: false,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigationScreen(
            userName: 'nabil',
            userEmail: email,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Group tab
      await tester.tap(find.text('Group'));
      await tester.pumpAndSettle();

      // Scroll to Leave Group button and tap it
      final leaveBtn = find.text('Leave Group');
      await tester.scrollUntilVisible(
        leaveBtn,
        250,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('group_active_list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(leaveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Leave Group?'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Leave'));
      await tester.pumpAndSettle();

      // Now on No-Group screen with real 7-day cooldown banner persisted
      final savedAfterLeave = await UserProgressService.loadProgress(accountKey);
      expect(savedAfterLeave.hasGroup, isFalse);
      expect(savedAfterLeave.isOnCooldown(), isTrue);
      expect(savedAfterLeave.remainingCooldownDays(), 7);

      expect(
        find.text('Anda belum bisa bergabung grup selama 7 hari'),
        findsOneWidget,
      );

      // Dismiss the leave confirmation SnackBar so bottom controls are unobstructed
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Scroll to Join Group button and tap it -> blocked
      final joinBtn = find.widgetWithText(ElevatedButton, 'Join Group');
      await tester.scrollUntilVisible(
        joinBtn,
        250,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('group_empty_list')),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.tap(joinBtn);
      await tester.pumpAndSettle();

      final savedAfterAttempt = await UserProgressService.loadProgress(accountKey);
      expect(savedAfterAttempt.hasGroup, isFalse);
      expect(
        find.text('Anda belum bisa bergabung grup selama 7 hari'),
        findsNWidgets(2),
      );
    });
  });
}
