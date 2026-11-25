import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streakwok/features/profile/presentation/profile_screen.dart';

void main() {
  group('UC-03: Meng-upgrade akun - Profile Screen Entry Point', () {
    testWidgets('1. Free tier shows upgrade banner inside hero card, tapping it opens modal with 5 restores & 10 members', (WidgetTester tester) async {
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

      // Proceed to confirmation dialog (UC-03 <<extend>>)
      expect(find.byKey(const Key('proceed_upgrade_pro_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('proceed_upgrade_pro_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Confirm Upgrade'), findsOneWidget);

      // Alternative Flow: canceling returns back to subscription plan modal
      await tester.tap(find.byKey(const Key('cancel_upgrade_payment_btn')));
      await tester.pumpAndSettle();
      expect(upgraded, isFalse);
      expect(find.byKey(const Key('proceed_upgrade_pro_btn')), findsOneWidget);

      // Proceed again and confirm payment
      await tester.tap(find.byKey(const Key('proceed_upgrade_pro_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confirm_upgrade_pro_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm_upgrade_pro_btn')));
      await tester.pump();
      await tester.pumpAndSettle();

      // Modal closed and callback fired
      expect(upgraded, isTrue);
      expect(find.textContaining('Upgraded to StreakWok Pro!'), findsOneWidget);
    });

    testWidgets('4. Interrupted upgrade transaction shows Upgrade dibatalkan without upgrading (UC-03 Exception)', (WidgetTester tester) async {
      bool upgraded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            userName: 'ambaroni',
            hasGroup: true,
            groupName: 'gerup ketat',
            isPro: false,
            restoresLeft: 3,
            onUpgradePro: () => upgraded = true,
            onProcessUpgradePayment: (_) async => false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile_upgrade_pro_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('proceed_upgrade_pro_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_upgrade_pro_btn')));
      await tester.pumpAndSettle();

      expect(upgraded, isFalse);
      expect(find.text('Upgrade dibatalkan'), findsOneWidget);
    });

    testWidgets('2. Pro tier shows Pro Active label under name, and 10 members capacity', (WidgetTester tester) async {
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

      // Verify PRO elements inside hero card
      expect(find.text('Pro Active'), findsOneWidget); // Directly under profile name
      expect(find.text('5 / 5 Restores'), findsOneWidget);
      expect(find.text('10 Members Capacity'), findsOneWidget);
      expect(find.text('StreakWok Pro'), findsWidgets); // Account Tier row

      // No upgrade button when already Pro
      expect(find.byKey(const Key('profile_upgrade_pro_btn')), findsNothing);
    });

    testWidgets('3. Tapping edit pencil button opens bottom sheet, validates input, and updates profile name', (WidgetTester tester) async {
      String? updatedName;

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            userName: 'ambaroni',
            userEmail: 'ambaroni@gmail.com',
            hasGroup: true,
            groupName: 'gerup ketat',
            isPro: false,
            restoresLeft: 3,
            onNameChanged: (newName) {
              updatedName = newName;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial name displayed
      expect(find.text('ambaroni'), findsOneWidget);
      expect(find.byKey(const Key('edit_profile_name_btn')), findsOneWidget);

      // Tap edit button to open modal
      await tester.tap(find.byKey(const Key('edit_profile_name_btn')));
      await tester.pumpAndSettle();

      // Verify modal elements matching initial profile name setup
      expect(find.text('Edit your name'), findsOneWidget);
      expect(find.text('ambaroni@gmail.com'), findsOneWidget);
      expect(find.text('Choose a display name for your profile, workout groups, and streaks.'), findsOneWidget);
      expect(find.byKey(const Key('edit_name_text_field')), findsOneWidget);
      expect(find.byKey(const Key('save_profile_name_btn')), findsOneWidget);

      // Test validation: Empty name
      await tester.enterText(find.byKey(const Key('edit_name_text_field')), '');
      await tester.tap(find.byKey(const Key('save_profile_name_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Name cannot be empty'), findsOneWidget);

      // Test validation: Less than 2 characters
      await tester.enterText(find.byKey(const Key('edit_name_text_field')), 'A');
      await tester.tap(find.byKey(const Key('save_profile_name_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Name must be at least 2 characters'), findsOneWidget);

      // Test validation: Reserved name
      await tester.enterText(find.byKey(const Key('edit_name_text_field')), 'admin');
      await tester.tap(find.byKey(const Key('save_profile_name_btn')));
      await tester.pumpAndSettle();
      expect(find.text('This name is reserved by system'), findsOneWidget);

      // Test valid new name
      await tester.enterText(find.byKey(const Key('edit_name_text_field')), 'Amba Master');
      await tester.tap(find.byKey(const Key('save_profile_name_btn')));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify bottom sheet closed, callback called, UI updated, and SnackBar displayed
      expect(updatedName, equals('Amba Master'));
      expect(find.text('Amba Master'), findsOneWidget);
      expect(find.text('Profile name updated'), findsOneWidget);
    });
  });
}
