import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streakwok/features/dashboard/domain/workout_plan_model.dart';
import 'package:streakwok/features/workout_session/presentation/workout_session_screen.dart';

void main() {
  const testPlan = WorkoutDayPlan(
    dayNumber: 1,
    isRestDay: false,
    category: 'Upper & Core',
    exerciseNames: ['Push-up', 'Plank'],
  );

  testWidgets('UC-09: Workout session initiates with countdown and transitions to active exercise', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WorkoutSessionScreen(
          dayPlan: testPlan,
          userName: 'Tester',
        ),
      ),
    );

    // Initial countdown phase
    expect(find.text('GET READY!'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Starting with:'), findsOneWidget);
    expect(find.text('Push-up'), findsOneWidget);

    // Tick countdown 3 seconds
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));

    // Now in active exercise phase
    expect(find.text('Day 1 • Upper & Core'), findsOneWidget);
    expect(find.text('Exercise 1 of 2'), findsOneWidget);
    expect(find.text('Push-up'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('/ 12 Reps'), findsOneWidget);
    expect(find.text('AI Pose Tracker Active'), findsOneWidget);
  });

  testWidgets('Top bar has Back button and no redundant pause button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WorkoutSessionScreen(
          dayPlan: testPlan,
          userName: 'Tester',
        ),
      ),
    );

    // Fast-forward countdown and let AnimatedSwitcher settle
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500));

    // Back button is present, top-right Pause button is removed
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Pause'), findsNothing);
  });

  testWidgets('UC-11: Back button triggers 3-option workout dialog (Keep Exercising, Do It Later, Quit Workout)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WorkoutSessionScreen(
          dayPlan: testPlan,
          userName: 'Tester',
        ),
      ),
    );

    // Fast-forward countdown and let AnimatedSwitcher settle
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500));

    // Tap back button
    final backButton = find.byTooltip('Back');
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pump();

    // 3-Option dialog appears
    expect(find.text('Workout Options'), findsOneWidget);
    expect(find.text('Keep Exercising'), findsOneWidget);
    expect(find.text('Do It Later'), findsOneWidget);
    expect(find.text('Quit Workout'), findsOneWidget);
    expect(find.text('Workout Paused'), findsNothing); // Pause overlay must NOT be visible

    // Tap Keep Exercising dismisses dialog
    await tester.tap(find.text('Keep Exercising'));
    await tester.pump();
    expect(find.text('Workout Options'), findsNothing);
    expect(find.text('Workout Paused'), findsNothing);
  });

  testWidgets('UC-10: Resume workout with initialExerciseIndex starts directly at target exercise', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WorkoutSessionScreen(
          dayPlan: testPlan,
          userName: 'Tester',
          initialExerciseIndex: 1, // Resume at Exercise 2 (Plank)
        ),
      ),
    );

    // Countdown announces Plank
    expect(find.text('Starting with:'), findsOneWidget);
    expect(find.text('Plank'), findsOneWidget);

    // Fast-forward countdown
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500));

    // In Plank exercise
    expect(find.text('Exercise 2 of 2'), findsOneWidget);
    expect(find.text('Plank'), findsOneWidget);
  });

  testWidgets('Auto-pause workout when app is backgrounded or minimized', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WorkoutSessionScreen(
          dayPlan: testPlan,
          userName: 'Tester',
        ),
      ),
    );

    // Fast-forward countdown and let AnimatedSwitcher settle
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Push-up'), findsOneWidget);
    expect(find.text('Workout Paused'), findsNothing);

    // Simulate user minimizing app / going to home screen
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    // Workout session should automatically pause
    expect(find.text('Workout Paused'), findsOneWidget);
    expect(find.text('Resume Workout'), findsOneWidget);

    // Simulate user returning to app (foreground)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    // Resume workout resumes smoothly
    await tester.tap(find.text('Resume Workout'));
    await tester.pump();
    expect(find.text('Workout Paused'), findsNothing);
  });

  testWidgets('Interactive reps increment to completion and reaches rest interval then summary', (tester) async {
    bool sessionCompletedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: WorkoutSessionScreen(
          dayPlan: testPlan,
          userName: 'Tester',
          onSessionCompleted: () {
            sessionCompletedCalled = true;
          },
        ),
      ),
    );

    // Fast-forward countdown and let AnimatedSwitcher settle
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500));

    // Tap rep button until target (12 reps)
    final repButton = find.text('+1 Rep (Tap / Detected)');
    expect(repButton, findsOneWidget);

    for (int i = 0; i < 12; i++) {
      await tester.tap(repButton);
      await tester.pump();
    }

    // Now should enter Rest Phase (20s)
    expect(find.text('REST INTERVAL'), findsOneWidget);
    expect(find.text('Next Up:'), findsOneWidget);
    expect(find.text('Plank'), findsOneWidget);
    expect(find.text('+20s'), findsOneWidget);

    // Tap +20s button to add 20s to rest time
    await tester.tap(find.text('+20s'));
    await tester.pump();
    expect(find.text('40'), findsOneWidget);

    // Skip rest
    await tester.tap(find.text('Skip Rest'));
    await tester.pump();

    // Now in Plank exercise
    expect(find.text('Exercise 2 of 2'), findsOneWidget);
    expect(find.text('Plank'), findsOneWidget);

    // Complete Plank
    await tester.tap(find.text('Complete Plank'));
    await tester.pump();

    // Now in Summary Phase
    expect(find.text('Workout Completed!'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('+1 Day'), findsOneWidget);
    expect(find.text('Complete Workout'), findsOneWidget);

    // Tap complete button
    await tester.tap(find.text('Complete Workout'));
    await tester.pump();

    expect(sessionCompletedCalled, isTrue);
  });
}
