import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/presentation/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userName;
  final bool hasGroup;
  final String groupName;

  const ProfileScreen({
    super.key,
    required this.userName,
    this.hasGroup = false,
    this.groupName = 'gerup ketat',
  });

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Logout',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1D1E)),
        ),
        content: const Text(
          'Are you sure you want to sign out of your StreakWok session?',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog

              // 1. Reset Google Play Services cache so the account picker always opens on next sign-in
              try {
                await GoogleSignIn().signOut();
              } catch (_) {}

              // 2. Clear login session state
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_logged_in', false);
              await prefs.setBool('has_group', false);

              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Top Header (Identical style to prototype)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                'Me',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1D1E),
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Profile Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFFE8F9F3),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF00A87A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1D1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00D09E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Google Account Connected',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SECTION: ACCOUNT DETAILS
            const Text(
              'Account Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1D1E),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Display Name',
                    value: userName,
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F3)),
                  _buildDetailRow(
                    icon: Icons.group_outlined,
                    label: 'Group Membership',
                    value: hasGroup ? groupName : 'No Group Joined',
                    valueColor: hasGroup ? const Color(0xFF00A87A) : const Color(0xFF9CA3AF),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F3)),
                  _buildDetailRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Authentication',
                    value: 'Google Sign-In',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SECTION: APP PREFERENCES
            const Text(
              'Preferences & Engine',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1D1E),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.camera_alt_outlined,
                    label: 'Pose Estimation',
                    value: 'MediaPipe Native Engine',
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F3)),
                  _buildDetailRow(
                    icon: Icons.cloud_done_outlined,
                    label: 'Cloud Sync',
                    value: 'Real-time Firebase',
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F3)),
                  _buildDetailRow(
                    icon: Icons.info_outline_rounded,
                    label: 'App Version',
                    value: '1.0.0 (IPPL Milestone)',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // LOGOUT BUTTON (Solid red button matching Leave Group design)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.white),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = const Color(0xFF1A1D1E),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF6B7280)),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
