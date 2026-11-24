import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/presentation/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String? userEmail;
  final bool hasGroup;
  final String groupName;
  final bool isPro;
  final int restoresLeft;
  final VoidCallback? onUpgradePro;
  final ValueChanged<String>? onNameChanged;

  const ProfileScreen({
    super.key,
    required this.userName,
    this.userEmail,
    this.hasGroup = false,
    this.groupName = 'gerup ketat',
    this.isPro = false,
    this.restoresLeft = 3,
    this.onUpgradePro,
    this.onNameChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _currentName;

  @override
  void initState() {
    super.initState();
    _currentName = widget.userName;
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userName != widget.userName) {
      _currentName = widget.userName;
    }
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            // Profile Hero Card (Integrated with Pro status per UC-03)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: widget.isPro ? const Color(0xFF00D09E).withOpacity(0.4) : const Color(0xFFE6ECE8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isPro ? const Color(0xFF00D09E).withOpacity(0.04) : Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF00D09E),
                    child: Text(
                      _currentName.isNotEmpty ? _currentName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Profile Name with Edit Button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _currentName,
                          key: const Key('profile_name_text'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1D1E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        key: const Key('edit_profile_name_btn'),
                        onTap: () => _showEditProfileNameBottomSheet(context),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7F5),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE6ECE8), width: 1),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Below profile name: (Pro Active) or Upgrade Action
                  if (widget.isPro) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.verified_rounded, size: 14, color: Color(0xFF00A87A)),
                        SizedBox(width: 4),
                        Text(
                          'Pro Active',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00A87A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE6ECE8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.restoresLeft} / 5 Restores',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1E)),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('•', style: TextStyle(color: Color(0xFF9CA3AF))),
                          ),
                          const Text(
                            '10 Members Capacity',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF00A87A)),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    InkWell(
                      key: const Key('profile_upgrade_pro_btn'),
                      onTap: () => _showUpgradeProModal(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8FDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00D09E), width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.workspace_premium_rounded, size: 15, color: Color(0xFF00A87A)),
                            SizedBox(width: 6),
                            Text(
                              'Upgrade to Pro • Rp 29.000',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF00A87A),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF00A87A)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
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
                    icon: Icons.workspace_premium_rounded,
                    label: 'Account Tier',
                    value: widget.isPro ? 'StreakWok Pro' : 'Free Tier',
                    valueColor: widget.isPro ? const Color(0xFF00A87A) : const Color(0xFF6B7280),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F3)),
                  _buildDetailRow(
                    icon: Icons.group_outlined,
                    label: 'Group Membership',
                    value: widget.hasGroup ? widget.groupName : 'No Group Joined',
                    valueColor: const Color(0xFF1A1D1E),
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

  void _showEditProfileNameBottomSheet(BuildContext context) {
    final nameController = TextEditingController(text: _currentName);
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F9F3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: Color(0xFF00D09E),
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit your name',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1D1E),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (widget.userEmail != null && widget.userEmail!.isNotEmpty)
                                  ? widget.userEmail!
                                  : 'Customize your workout display name',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Choose a display name for your profile, workout groups, and streaks.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    key: const Key('edit_name_text_field'),
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1D1E),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      hintText: 'e.g. $_currentName',
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: Color(0xFF00D09E),
                        size: 20,
                      ),
                      errorText: errorText,
                      filled: true,
                      fillColor: const Color(0xFFFAFCFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE6ECE8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE6ECE8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF00D09E), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('save_profile_name_btn'),
                      onPressed: () {
                        final rawInput = nameController.text.trim();
                        if (rawInput.isEmpty) {
                          setModalState(() => errorText = 'Name cannot be empty');
                          return;
                        }
                        if (rawInput.length < 2) {
                          setModalState(() => errorText = 'Name must be at least 2 characters');
                          return;
                        }
                        if (rawInput.length > 25) {
                          setModalState(() => errorText = 'Name cannot exceed 25 characters');
                          return;
                        }
                        if (!RegExp(r"^[a-zA-Z0-9\s.'-]+$").hasMatch(rawInput)) {
                          setModalState(() => errorText = 'Please enter a valid name (letters, numbers, spaces)');
                          return;
                        }
                        const reservedNames = ['admin', 'streakwok', 'system', 'moderator', 'root'];
                        if (reservedNames.contains(rawInput.toLowerCase().trim())) {
                          setModalState(() => errorText = 'This name is reserved by system');
                          return;
                        }

                        final sanitized = rawInput.replaceAll(RegExp(r'\s+'), ' ');
                        Navigator.pop(modalContext);
                        _handleNameUpdated(sanitized);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D09E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleNameUpdated(String newName) {
    setState(() {
      _currentName = newName;
    });
    widget.onNameChanged?.call(newName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Display name updated to "$newName"'),
        backgroundColor: const Color(0xFF00D09E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showUpgradeProModal(BuildContext context) {
    int selectedPlanIndex = 1; // Default yearly

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFFF9800),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'StreakWok Pro',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1D1E),
                          ),
                        ),
                        Text(
                          'Never lose your group streak again',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildProBenefitItem(
                Icons.replay_rounded,
                '5 Streak Restores per Month',
                'Extra chances to keep your group streak alive',
              ),
              _buildProBenefitItem(
                Icons.groups_rounded,
                '10 Members Group Capacity',
                'Workout with your entire squad',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPlanOption(
                      title: 'Monthly',
                      price: 'Rp 29.000',
                      period: '/ month',
                      isSelected: selectedPlanIndex == 0,
                      onTap: () => setModalState(() => selectedPlanIndex = 0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildPlanOption(
                      title: 'Yearly',
                      price: 'Rp 199.000',
                      period: '/ year',
                      badge: 'Save 40%',
                      isSelected: selectedPlanIndex == 1,
                      onTap: () => setModalState(() => selectedPlanIndex = 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  key: const Key('confirm_upgrade_pro_btn'),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    widget.onUpgradePro?.call();
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Upgraded to StreakWok Pro! 5 restores per month & 10-member capacity unlocked.'),
                        duration: Duration(seconds: 3),
                        backgroundColor: Color(0xFF1A1D1E),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D09E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Upgrade to Pro',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProBenefitItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8FDF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF00A87A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D1E),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption({
    required String title,
    required String price,
    required String period,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8FDF5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF00D09E) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? const Color(0xFF00A87A) : const Color(0xFF4B5563),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              price,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1D1E),
              ),
            ),
            Text(
              period,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}
