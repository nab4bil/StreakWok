import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../dashboard/presentation/dashboard_screen.dart';
import '../group/presentation/group_screen.dart';
import '../history/presentation/history_screen.dart';
import '../profile/presentation/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String userName;

  const MainNavigationScreen({super.key, required this.userName});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isUserCompleted = false;

  // Status Siklus Grup Pengguna (SDD StreakWok)
  bool _hasGroup = false;
  String _groupName = 'gerup ketat';
  bool _isLeader = false;
  String _inviteCode = 'WOK-882';
  int _memberCount = 3;
  int _maxMembers = 4;

  @override
  void initState() {
    super.initState();
    _loadGroupState();
  }

  Future<void> _loadGroupState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hasGroup = prefs.getBool('has_group') ?? false;
      _groupName = prefs.getString('group_name') ?? 'gerup ketat';
      _isLeader = prefs.getBool('is_leader') ?? false;
      _inviteCode = prefs.getString('invite_code') ?? 'WOK-882';
      _memberCount = prefs.getInt('member_count') ?? 3;
      _maxMembers = prefs.getInt('max_members') ?? 4;
    });
  }

  void _onToggleWorkout() {
    setState(() {
      _isUserCompleted = !_isUserCompleted;
    });
  }

  void _switchToGroupTab() {
    setState(() => _currentIndex = 1);
  }

  void _onToggleGroupDemo() async {
    final newStatus = !_hasGroup;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_group', newStatus);

    setState(() {
      _hasGroup = newStatus;
    });
  }

  // MODAL 1: JOIN GROUP MODAL (Identik 1:1 dengan dashboard_screen.html #joinGroupModal)
  void _showJoinGroupModal(BuildContext context) {
    final codeController = TextEditingController(text: 'WOK-882');
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sheet Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Sheet Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Join Group',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1D1E),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Enter a 6-character group invite code',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8C949D),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close, size: 16, color: Color(0xFF6B7280)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Form Group
                  const Text(
                    'Invite Code',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1E)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: codeController,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      color: Color(0xFF1A1D1E),
                    ),
                    decoration: InputDecoration(
                      hintText: 'WOK-882',
                      errorText: errorText,
                      filled: true,
                      fillColor: const Color(0xFFFAFCFB),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE6ECE8), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00D09E), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick simulation presets (Identik dengan modal-presets di HTML)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text(
                          'Presets: ',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8C949D)),
                        ),
                        const SizedBox(width: 4),
                        _buildPresetPill('WOK-882 (Valid)', () {
                          setModalState(() {
                            codeController.text = 'WOK-882';
                            errorText = null;
                          });
                        }),
                        const SizedBox(width: 4),
                        _buildPresetPill('FULL99 (Full)', () {
                          setModalState(() {
                            codeController.text = 'FULL99';
                            errorText = null;
                          });
                        }),
                        const SizedBox(width: 4),
                        _buildPresetPill('WAIT07 (Cooldown)', () {
                          setModalState(() {
                            codeController.text = 'WAIT07';
                            errorText = null;
                          });
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () async {
                        final inputCode = codeController.text.trim().toUpperCase();
                        if (inputCode.isEmpty) {
                          setModalState(() => errorText = 'Invite code cannot be empty');
                          return;
                        }

                        if (inputCode == 'FULL99') {
                          setModalState(() => errorText = 'Group is full (Max 4 members reached)');
                          return;
                        }

                        if (inputCode == 'WAIT07') {
                          setModalState(() => errorText = 'You are on a 7-day cooldown penalty');
                          return;
                        }

                        if (inputCode == 'WOK-882' || inputCode.startsWith('WOK-')) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('has_group', true);
                          await prefs.setString('group_name', 'gerup ketat');
                          await prefs.setBool('is_leader', false);
                          await prefs.setString('invite_code', inputCode);
                          await prefs.setInt('member_count', 3);
                          await prefs.setInt('max_members', 4);

                          setState(() {
                            _hasGroup = true;
                            _groupName = 'gerup ketat';
                            _isLeader = false;
                            _inviteCode = inputCode;
                            _memberCount = 3;
                            _maxMembers = 4;
                            _currentIndex = 1; // Langsung beralih ke Dashboard Grup!
                          });

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Successfully joined group streak'),
                              backgroundColor: const Color(0xFF1A1D1E),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          setModalState(() => errorText = 'Invalid code. Try preset: WOK-882');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D09E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Join Group', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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

  // MODAL 2: CREATE GROUP MODAL (Identik 1:1 dengan dashboard_screen.html #createGroupModal)
  void _showCreateGroupModal(BuildContext context) {
    final nameController = TextEditingController(text: 'gerup ketat');
    String selectedDifficulty = 'Intermediate';
    int capacity = 2;
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sheet Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Sheet Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Create Group',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1D1E),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Free tier • 2 to 4 members',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8C949D),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close, size: 16, color: Color(0xFF6B7280)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 1. Group Name
                  const Text(
                    'Group Name',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1E)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1D1E),
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. gerup ketat',
                      errorText: errorText,
                      filled: true,
                      fillColor: const Color(0xFFFAFCFB),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE6ECE8), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00D09E), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Target Difficulty
                  const Text(
                    'Target Difficulty',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1E)),
                  ),
                  const SizedBox(height: 6),
                  _buildDifficultyOption(
                    title: 'Beginner',
                    desc: '3 sets • 8–10 reps • 45s rest (Light)',
                    isSelected: selectedDifficulty == 'Beginner',
                    onTap: () => setModalState(() => selectedDifficulty = 'Beginner'),
                  ),
                  const SizedBox(height: 6),
                  _buildDifficultyOption(
                    title: 'Intermediate',
                    desc: '3 sets • 15 reps • 30s rest (Moderate)',
                    isSelected: selectedDifficulty == 'Intermediate',
                    onTap: () => setModalState(() => selectedDifficulty = 'Intermediate'),
                  ),
                  const SizedBox(height: 6),
                  _buildDifficultyOption(
                    title: 'Advanced',
                    desc: '4 sets • 20 reps • 20s rest (Intense)',
                    isSelected: selectedDifficulty == 'Advanced',
                    onTap: () => setModalState(() => selectedDifficulty = 'Advanced'),
                  ),
                  const SizedBox(height: 14),

                  // 3. Group Capacity Stepper
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Group Capacity',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1E)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F9F3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Free Tier: 2–4 Members',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF00A87A)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFCFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          color: capacity > 2 ? const Color(0xFF1A1D1E) : Colors.grey.shade400,
                          onPressed: capacity > 2 ? () => setModalState(() => capacity--) : null,
                        ),
                        Text(
                          '$capacity Members',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1D1E),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          color: capacity < 4 ? const Color(0xFF1A1D1E) : Colors.grey.shade400,
                          onPressed: capacity < 4 ? () => setModalState(() => capacity++) : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () async {
                        final gName = nameController.text.trim();
                        if (gName.isEmpty) {
                          setModalState(() => errorText = 'Group name cannot be empty');
                          return;
                        }

                        final randomCode = 'WOK-${100 + Random().nextInt(900)}';
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('has_group', true);
                        await prefs.setString('group_name', gName);
                        await prefs.setBool('is_leader', true);
                        await prefs.setString('invite_code', randomCode);
                        await prefs.setInt('member_count', 1);
                        await prefs.setInt('max_members', capacity);

                        setState(() {
                          _hasGroup = true;
                          _groupName = gName;
                          _isLeader = true;
                          _inviteCode = randomCode;
                          _memberCount = 1;
                          _maxMembers = capacity;
                          _currentIndex = 1; // Langsung beralih ke Dashboard Grup!
                        });

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Group "$gName" created! Invite code: $randomCode 🎉'),
                            backgroundColor: AppColors.primaryDark,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D09E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Create Group', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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

  Widget _buildDifficultyOption({
    required String title,
    required String desc,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F9F3) : const Color(0xFFFAFCFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00D09E) : const Color(0xFFE6ECE8),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1E)),
                ),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF00D09E) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFF00D09E) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(child: Icon(Icons.circle, size: 6, color: Colors.white))
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetPill(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDCE7E1)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
        ),
      ),
    );
  }

  // Handler: Keluar dari Grup
  void _handleLeaveGroup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_group', false);
    await prefs.remove('group_name');
    await prefs.remove('is_leader');
    await prefs.remove('invite_code');

    setState(() {
      _hasGroup = false;
      _isLeader = false;
      _groupName = 'gerup ketat';
      _inviteCode = 'WOK-882';
      _memberCount = 3;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have left the group (7-day cooldown active).'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _handleJoinGroupFromScreen(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_group', true);
    await prefs.setString('group_name', 'gerup ketat');
    await prefs.setBool('is_leader', false);
    await prefs.setString('invite_code', code);
    await prefs.setInt('member_count', 3);

    if (!mounted) return;
    setState(() {
      _hasGroup = true;
      _isLeader = false;
      _groupName = 'gerup ketat';
      _inviteCode = code;
      _memberCount = 3;
      _currentIndex = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Successfully joined group streak'),
        backgroundColor: const Color(0xFF1A1D1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleCreateGroupFromScreen(String name, String difficulty, int capacity) async {
    final generatedCode = 'WOK-${Random().nextInt(900) + 100}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_group', true);
    await prefs.setString('group_name', name);
    await prefs.setBool('is_leader', true);
    await prefs.setString('invite_code', generatedCode);
    await prefs.setInt('member_count', 1);
    await prefs.setInt('max_members', capacity);

    if (!mounted) return;
    setState(() {
      _hasGroup = true;
      _isLeader = true;
      _groupName = name;
      _inviteCode = generatedCode;
      _memberCount = 1;
      _maxMembers = capacity;
      _currentIndex = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Group "$name" created! Invite Code: $generatedCode'),
        backgroundColor: const Color(0xFF1A1D1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(
        userName: widget.userName,
        isUserCompleted: _isUserCompleted,
        hasGroup: _hasGroup,
        groupName: _groupName,
        isLeader: _isLeader,
        onToggleWorkout: _onToggleWorkout,
        onViewGroup: _switchToGroupTab,
        onJoinGroupTap: () => _showJoinGroupModal(context),
        onCreateGroupTap: () => _showCreateGroupModal(context),
        onToggleGroupState: _onToggleGroupDemo,
      ),
      GroupScreen(
        userName: widget.userName,
        isUserCompleted: _isUserCompleted,
        hasGroup: _hasGroup,
        groupName: _groupName,
        isLeader: _isLeader,
        inviteCode: _inviteCode,
        memberCount: _memberCount,
        maxMembers: _maxMembers,
        onBackPressed: () => setState(() => _currentIndex = 0),
        onHistoryTap: () => setState(() => _currentIndex = 2),
        onJoinGroup: _handleJoinGroupFromScreen,
        onCreateGroup: _handleCreateGroupFromScreen,
        onLeaveGroup: _handleLeaveGroup,
      ),
      HistoryScreen(
        onBackPressed: () => setState(() => _currentIndex = 0),
      ),
      ProfileScreen(
        userName: widget.userName,
        hasGroup: _hasGroup,
        groupName: _groupName,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      // Bottom Navigation Bar Responsif (Bebas Overflow di Semua Layar & Identik dengan bottom-nav HTML)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFEEF2F0), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.calendar_today_rounded, 'Plan'),
                _buildNavItem(1, Icons.group_rounded, 'Group'),
                _buildNavItem(2, Icons.bar_chart_rounded, 'Reports'),
                _buildNavItem(3, Icons.person_rounded, 'Me'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFF00D09E) : const Color(0xFF9CA3AF);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
