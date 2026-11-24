import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streakwok/features/group/presentation/group_screen.dart';

void main() {
  group('UC-13: Mengeluarkan Anggota Grup (Kick Member) - Option 2', () {
    testWidgets('Main screen has no role badge and no kick buttons, only vertical more button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: GroupScreen(
            userName: 'ambaroni',
            hasGroup: true,
            isLeader: false,
            groupName: 'gerup ketat',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expect to see Group Members header
      expect(find.text('Group Members'), findsOneWidget);

      // No role badge in header
      expect(find.text('Role: Member'), findsNothing);
      expect(find.text('Role: Leader'), findsNothing);

      // No Kick button directly on main screen card
      expect(find.text('Kick'), findsNothing);

      // Expect vertical three-dots more button in header
      expect(find.byKey(const Key('group_members_more_btn')), findsOneWidget);
    });

    testWidgets('Manage Members sheet shows "You" for current user, no Done/Undone text, and sheet stays open on cancel', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: GroupScreen(
            userName: 'tono hardija',
            hasGroup: true,
            isLeader: true,
            groupName: 'gerup ketat',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap vertical more button
      final moreBtn = find.byKey(const Key('group_members_more_btn'));
      await tester.ensureVisible(moreBtn);
      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      // Expect bottom sheet with Manage Members
      expect(find.text('Manage Members'), findsOneWidget);
      expect(find.text('Leader Mode'), findsOneWidget);

      // Current user is displayed as "You"
      expect(find.text('You'), findsOneWidget);

      // No Done / Undone text inside Manage Members sheet
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('Done')), findsNothing);
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('Undone')), findsNothing);

      // Leader sees Remove button for members
      final removeMahmud = find.byKey(const Key('sheet_kick_mahmud buah'));
      expect(removeMahmud, findsOneWidget);

      // Tap Remove button -> confirmation dialog appears
      await tester.tap(removeMahmud);
      await tester.pumpAndSettle();

      expect(find.text('Remove mahmud buah?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel -> dialog closes, but Manage Members sheet STAYS OPEN!
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Remove mahmud buah?'), findsNothing);
      expect(find.text('Manage Members'), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('mahmud buah')), findsOneWidget);
    });

    testWidgets('Main flow: Confirming kick removes member, sheet updates and stays open', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? kickedName;
      int? remainingCount;

      await tester.pumpWidget(
        MaterialApp(
          home: GroupScreen(
            userName: 'tono hardija',
            hasGroup: true,
            isLeader: true,
            groupName: 'gerup ketat',
            onKickMember: (name, count) {
              kickedName = name;
              remainingCount = count;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open manage sheet
      final moreBtn = find.byKey(const Key('group_members_more_btn'));
      await tester.ensureVisible(moreBtn);
      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      // Tap Remove button for mahmud buah
      final removeMahmud = find.byKey(const Key('sheet_kick_mahmud buah'));
      await tester.tap(removeMahmud);
      await tester.pumpAndSettle();

      // Tap 'Kick Member' inside dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Kick Member'));
      await tester.pumpAndSettle();

      // Dialog is gone, Manage Members sheet STAYS OPEN!
      expect(find.text('Manage Members'), findsOneWidget);

      // Member should be removed from sheet immediately
      expect(find.text('mahmud buah'), findsNothing);
      expect(kickedName, 'mahmud buah');
      expect(remainingCount, 2);

      // Dismiss the bottom sheet
      tester.binding.handlePointerEvent(const PointerDownEvent(position: Offset(100, 100)));
      tester.binding.handlePointerEvent(const PointerUpEvent(position: Offset(100, 100)));
      await tester.pumpAndSettle();

      // Capacity updates to 2 / 4 on main screen
      expect(find.text('Capacity'), findsOneWidget);
      expect(find.text('2 / 4'), findsOneWidget);
    });
  });
}
