import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase initialization placeholder for Phase 2/3 (Milestone 70% & 100%)
  // await Firebase.initializeApp();
  runApp(const StreakWokApp());
}

class StreakWokApp extends StatelessWidget {
  const StreakWokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreakWok',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
