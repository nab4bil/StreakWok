import 'package:flutter_test/flutter_test.dart';
import 'package:streakwok/features/auth/presentation/login_screen.dart';
import 'package:streakwok/main.dart';

void main() {
  testWidgets('StreakWok app initial screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StreakWokApp(
      isLoggedIn: false,
      initialUserName: 'Test User',
    ));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
