import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/navigation/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cek Session Persistence (Auto-Login): Apakah user sudah pernah login sebelumnya?
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  final String savedName = prefs.getString('user_name') ?? 'Nabil';

  runApp(StreakWokApp(
    isLoggedIn: isLoggedIn,
    initialUserName: savedName,
  ));
}

class StreakWokApp extends StatelessWidget {
  final bool isLoggedIn;
  final String initialUserName;

  const StreakWokApp({
    super.key,
    required this.isLoggedIn,
    required this.initialUserName,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreakWok',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        fontFamily: 'sans-serif',
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: AppColors.textMain,
          displayColor: AppColors.textMain,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        useMaterial3: true,
      ),
      // Jika sudah login, langsung ke Dashboard. Jika belum / sudah logout, buka LoginScreen!
      home: isLoggedIn
          ? MainNavigationScreen(userName: initialUserName)
          : const LoginScreen(),
    );
  }
}
