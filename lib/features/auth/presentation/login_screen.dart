import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../navigation/main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '813546439317-38rvn3s401il3f701q2dl0lfj6b0t1cb.apps.googleusercontent.com',
  );

  // Memanggil POP-UP SISTEM GOOGLE ASLI BAWAAN ANDROID (Google Play Services)
  void _onGoogleSignInTapped() async {
    try {
      setState(() => _isLoading = true);

      // Reset cache akun lama agar sistem Android SELALU menampilkan dialog pemilih akun Google
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // Trigger pop-up asli Android
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // Pengguna menekan tombol back / cancel
        setState(() => _isLoading = false);
        return;
      }

      final chosenName = googleUser.displayName ?? 'User';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_name', chosenName);

      setState(() => _isLoading = false);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainNavigationScreen(userName: chosenName),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In: $e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Logo Mascot Container (Identik 1:1 dengan login_screen.html 140x140)
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D09E), Color(0xFF009E74)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D09E).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: SizedBox(
                    width: 74,
                    height: 74,
                    child: CustomPaint(
                      painter: _MascotFlamePainter(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Brand Title & Subtitle (Identik 1:1 dengan login_screen.html)
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D1E),
                    letterSpacing: -0.5,
                  ),
                  children: [
                    TextSpan(text: 'Streak'),
                    TextSpan(
                      text: 'Wok',
                      style: TextStyle(color: Color(0xFF00D09E)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Build consistent workout habits with your group. Don\'t let your streak flame die!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6C7278),
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Feature Highlights (Identik 1:1 dengan login_screen.html)
              _buildFeatureItem(
                icon: Icons.camera_alt_outlined,
                text: 'Real-Time Camera Validation',
              ),
              const SizedBox(height: 10),
              _buildFeatureItem(
                icon: Icons.group_outlined,
                text: 'Group Workout Streak',
              ),

              const Spacer(flex: 2),

              // Bottom Action Area: Google Sign-in Button
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _onGoogleSignInTapped,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Official Google G Logo SVG Custom Painted
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CustomPaint(painter: _GoogleLogoPainter()),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1D1E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

              const SizedBox(height: 16),

              // Terms of Service & Privacy Policy
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'By continuing, you agree to StreakWok\'s Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8C949D),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEFEA), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F9F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF00D09E)),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF33383F),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter Mascot Flame (Identik 1:1 dengan login_screen.html)
class _MascotFlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final outerPaint = Paint()..color = const Color(0xFFFF7043);
    final innerPaint = Paint()..color = const Color(0xFFFFA726);
    final panPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Outer flame: d="M12 2C9.5 5 7 8 7 11.5C7 14.5 9.2 17 12 17C14.8 17 17 14.5 17 11.5C17 8 14.5 5 12 2Z"
    final outerPath = Path()
      ..moveTo(12, 2)
      ..cubicTo(9.5, 5, 7, 8, 7, 11.5)
      ..cubicTo(7, 14.5, 9.2, 17, 12, 17)
      ..cubicTo(14.8, 17, 17, 14.5, 17, 11.5)
      ..cubicTo(17, 8, 14.5, 5, 12, 2)
      ..close();
    canvas.drawPath(outerPath, outerPaint);

    // Inner flame: d="M12 7C10.5 9 9.5 10.5 9.5 12.5C9.5 14 10.6 15.5 12 15.5C13.4 15.5 14.5 14 14.5 12.5C14.5 10.5 13.5 9 12 7Z"
    final innerPath = Path()
      ..moveTo(12, 7)
      ..cubicTo(10.5, 9, 9.5, 10.5, 9.5, 12.5)
      ..cubicTo(9.5, 14, 10.6, 15.5, 12, 15.5)
      ..cubicTo(13.4, 15.5, 14.5, 14, 14.5, 12.5)
      ..cubicTo(14.5, 10.5, 13.5, 9, 12, 7)
      ..close();
    canvas.drawPath(innerPath, innerPaint);

    // Wok Pan Base: d="M5 21H19M7 19V23M17 19V23"
    canvas.drawLine(const Offset(5, 21), const Offset(19, 21), panPaint);
    canvas.drawLine(const Offset(7, 19), const Offset(7, 23), panPaint);
    canvas.drawLine(const Offset(17, 19), const Offset(17, 23), panPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter Google "G" 4-Color Logo
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final redPaint = Paint()..color = const Color(0xFFEA4335);

    // Blue segment
    final bluePath = Path()
      ..moveTo(23.745, 12.27)
      ..cubicTo(23.745, 11.57, 23.685, 10.87, 23.555, 10.2)
      ..lineTo(12, 10.2)
      ..lineTo(12, 14.71)
      ..lineTo(18.6, 14.71)
      ..cubicTo(18.31, 16.23, 17.46, 17.53, 16.2, 18.39)
      ..lineTo(16.2, 21.44)
      ..lineTo(20.08, 21.44)
      ..cubicTo(22.35, 19.35, 23.745, 16.27, 23.745, 12.27)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green segment
    final greenPath = Path()
      ..moveTo(12, 24)
      ..cubicTo(15.24, 24, 17.95, 22.92, 19.93, 21.09)
      ..lineTo(16.05, 18.04)
      ..cubicTo(14.97, 18.76, 13.6, 19.2, 12, 19.2)
      ..cubicTo(8.88, 19.2, 6.23, 17.1, 5.28, 14.27)
      ..lineTo(1.25, 14.27)
      ..lineTo(1.25, 17.42)
      ..cubicTo(3.26, 21.36, 7.34, 24, 12, 24)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow segment
    final yellowPath = Path()
      ..moveTo(5.28, 14.27)
      ..cubicTo(5.03, 13.55, 4.9, 12.78, 4.9, 12)
      ..cubicTo(4.9, 11.22, 5.03, 10.45, 5.28, 9.73)
      ..lineTo(5.28, 6.58)
      ..lineTo(1.25, 6.58)
      ..cubicTo(0.45, 8.17, 0, 9.97, 0, 12)
      ..cubicTo(0, 14.03, 0.45, 15.83, 1.25, 17.42)
      ..lineTo(5.28, 14.27)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red segment
    final redPath = Path()
      ..moveTo(12, 4.75)
      ..cubicTo(13.77, 4.75, 15.35, 5.36, 16.6, 6.55)
      ..lineTo(20.02, 3.13)
      ..cubicTo(17.95, 1.19, 15.24, 0, 12, 0)
      ..cubicTo(7.34, 0, 3.26, 2.64, 1.25, 6.58)
      ..lineTo(5.28, 9.73)
      ..cubicTo(6.23, 6.9, 8.88, 4.75, 12, 4.75)
      ..close();
    canvas.drawPath(redPath, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
