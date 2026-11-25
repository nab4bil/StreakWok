import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streakwok/core/services/user_progress_service.dart';
import 'package:streakwok/features/dashboard/domain/workout_plan_model.dart';
import 'package:streakwok/features/dashboard/presentation/dashboard_screen.dart';
import 'package:streakwok/features/group/presentation/group_screen.dart';
import 'package:streakwok/features/workout_session/presentation/workout_session_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UC-08 Active Day Sync & UC-12 Monthly Quota Reset', () {
    test('computeEffectiveActiveDay advances from groupCreatedAt and resets daily completion', () async {
      final accountKey = UserProgressService.getAccountKey(email: 'sync@streakwok.id');
      final createdAt = DateTime(2026, 11, 20, 9, 0);
      final initial = UserAccountProgress(
        accountKey: accountKey,
        currentActiveDay: 1,
        streakDays: 4,
        isUserCompleted: true,
        hasGroup: true,
        groupCreatedAt: createdAt,
        workoutDifficulty: 'Advanced',
        lastQuotaResetMonth: '2026-11',
        restoresLeft: 1,
      );

      await UserProgressService.saveProgress(initial);
      final loaded = await UserProgressService.loadProgress(accountKey);
      expect(loaded.workoutDifficulty, 'Advanced');
      expect(loaded.groupCreatedAt, createdAt);

      // 4 days later -> Day 5, new day resets isUserCompleted to false
      final syncedSameMonth = loaded.syncForDate(DateTime(2026, 11, 24, 10, 0));
      expect(syncedSameMonth.currentActiveDay, 5);
      expect(syncedSameMonth.isUserCompleted, isFalse);
      expect(syncedSameMonth.restoresLeft, 1);

      // Next month -> quota resets back to 3 (Free) or 5 (Pro)
      final syncedNextMonth = syncedSameMonth.syncForDate(DateTime(2026, 12, 1, 8, 0));
      expect(syncedNextMonth.restoresLeft, 3);
      expect(syncedNextMonth.lastQuotaResetMonth, '2026-12');
    });

    test('Monthly quota reset restores Pro tier to 5/5', () {
      const proProgress = UserAccountProgress(
        accountKey: 'pro_user',
        isPro: true,
        restoresLeft: 0,
        lastQuotaResetMonth: '2026-11',
      );
      final reset = proProgress.syncForDate(DateTime(2026, 12, 2));
      expect(reset.restoresLeft, 5);
    });
  });

  group('Target Difficulty Multi-Set Workout Progression', () {
    testWidgets('Beginner difficulty enforces 3 sets, 8 Push-up reps, 45s rest, and 6/6 summary', (tester) async {
      const plan = WorkoutDayPlan(
        dayNumber: 1,
        isRestDay: false,
        category: 'Upper & Core',
        exerciseNames: ['Push-up', 'Plank'],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutSessionScreen(
            dayPlan: plan,
            userName: 'Tester',
            difficulty: 'Beginner',
            enableLiveCamera: false,
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Set 1/3 • Exercise 1 of 2'), findsOneWidget);
      expect(find.text('/ 8 Reps'), findsOneWidget);

      final repBtn = find.text('+1 Rep (Tap / Detected)');
      for (int setIndex = 1; setIndex <= 3; setIndex++) {
        expect(find.text('Set $setIndex/3 • Exercise 1 of 2'), findsOneWidget);
        for (int r = 0; r < 8; r++) {
          await tester.tap(repBtn);
          await tester.pump();
        }
        // Rest 45s before Plank in same set
        expect(find.text('REST INTERVAL'), findsOneWidget);
        expect(find.text('45'), findsOneWidget);
        expect(find.text('Set $setIndex of 3'), findsOneWidget);
        await tester.tap(find.text('Skip Rest'));
        await tester.pump();

        expect(find.text('Set $setIndex/3 • Exercise 2 of 2'), findsOneWidget);
        await tester.tap(find.text('Complete Plank'));
        await tester.pump();

        if (setIndex < 3) {
          expect(find.text('REST INTERVAL'), findsOneWidget);
          expect(find.text('Set ${setIndex + 1} of 3'), findsOneWidget);
          await tester.tap(find.text('Skip Rest'));
          await tester.pump();
        }
      }

      expect(find.text('Workout Completed!'), findsOneWidget);
      expect(find.text('6/6'), findsOneWidget);
    });

    testWidgets('Dashboard hides difficulty selector and Group Details lets Leader update difficulty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            userName: 'nabil',
            isUserCompleted: false,
            workoutDifficulty: 'Intermediate',
            onToggleWorkout: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dashboard_difficulty_btn')), findsNothing);
      expect(find.text('Intermediate • 3 sets'), findsNothing);

      String? selectedDiff;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupScreen(
              userName: 'nabil',
              hasGroup: true,
              isLeader: true,
              currentActiveDay: 3,
              workoutDifficulty: 'Intermediate',
              onDifficultyChanged: (value) => selectedDiff = value,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Leader • Day 3 of 30'), findsOneWidget);
      expect(find.text('Difficulty: Intermediate • 3 sets'), findsOneWidget);
      await tester.tap(find.byKey(const Key('group_difficulty_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Workout Difficulty'), findsOneWidget);
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Difficulty'));
      await tester.pumpAndSettle();

      expect(selectedDiff, 'Advanced');
      expect(find.text('Difficulty: Advanced • 4 sets'), findsOneWidget);
    });

    testWidgets('Group Details blocks non-leader member from changing difficulty', (tester) async {
      String? selectedDiff;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupScreen(
              userName: 'nabil',
              hasGroup: true,
              isLeader: false,
              currentActiveDay: 3,
              workoutDifficulty: 'Beginner',
              onDifficultyChanged: (value) => selectedDiff = value,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Difficulty: Beginner • 3 sets'), findsOneWidget);
      await tester.tap(find.byKey(const Key('group_difficulty_btn')));
      await tester.pumpAndSettle();

      expect(selectedDiff, isNull);
      expect(find.text('Workout Difficulty'), findsNothing);
      expect(
        find.text('Only the Group Leader can change target difficulty.'),
        findsOneWidget,
      );
    });
  });

  group('UC-07 Full Group & UC-04 Guard', () {
    testWidgets('FULL99 code shows Grup sudah penuh message', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GroupScreen(
              userName: 'nabil',
              hasGroup: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'FULL99');
      final joinBtn = find.widgetWithText(ElevatedButton, 'Join Group');
      await tester.scrollUntilVisible(
        joinBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(joinBtn);
      await tester.pumpAndSettle();
      await tester.tap(joinBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Grup sudah penuh'), findsOneWidget);
    });
  });
}
