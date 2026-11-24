import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streakwok/features/profile/presentation/profile_screen.dart';

void main() {
  group('UC-03: Meng-upgrade akun - Profile Screen Entry Point', () {
    testWidgets('1. Free tier shows upgrade banner, tapping it opens modal with 5 restores & 10 members', (WidgetTester tester) async {
      bool upgraded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            userName: 'ambaroni',
            hasGroup: true,
            groupName: 'gerup ketat',
            isPro: false,
            restoresLeft: 3,
            onUpgradePro: () {
              upgraded = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Free Tier elements
      expect(find.text('FREE TIER'), findsOneWidget);
      expect(find.text('Free Tier'), findsOneWidget); // In Account Tier detail row
      expect(find.byKey(const Key('profile_upgrade_pro_btn')), findsOneWidget);

      // Tap Upgrade to Pro button
      await tester.tap(find.byKey(const Key('profile_upgrade_pro_btn')));
      await tester.pumpAndSettle();

      // Verify BottomSheet Modal with Official Benefits
      expect(find.text('StreakWok Pro'), findsWidgets);
      expect(find.text('5 Streak Restores per Month'), findsOneWidget);
      expect(find.text('10 Members Group Capacity'), findsOneWidget);
      expect(find.text('Save 40%'), findsOneWidget);

      // Confirm upgrade
      expect(find.byKey(const Key('confirm_upgrade_pro_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm_upgrade_pro_btn')));
      await tester.pump();
      await tester.pumpAndSettle();

      // Modal closed and callback fired
      expect(upgraded, isTrue);
      expect(find.textContaining('Upgraded to StreakWok Pro!'), findsOneWidget);
    });

    testWidgets('2. Pro tier shows PRO ACTIVE badge, active membership card and 10 members capacity', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(
            userName: 'ambaroni',
            hasGroup: true,
            groupName: 'gerup ketat',
            isPro: true,
            restoresLeft: 5,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify PRO ACTIVE elements
      expect(find.text('PRO ACTIVE'), findsOneWidget);
      expect(find.text('Premium squad tier active'), findsOneWidget);
      expect(find.text('5 / 5'), findsOneWidget);
      expect(find.text('10 Members'), findsOneWidget);
      expect(find.text('StreakWok Pro'), findsWidgets); // Header & Account Tier

      // No upgrade button when already Pro
      expect(find.byKey(const Key('profile_upgrade_pro_btn')), findsNothing);
    });
  });
}
