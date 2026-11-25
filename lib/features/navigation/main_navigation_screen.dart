import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/user_progress_service.dart';
import '../dashboard/domain/workout_plan_model.dart';
import '../dashboard/presentation/dashboard_screen.dart';
import '../group/presentation/group_screen.dart';
import '../history/presentation/history_screen.dart';
import '../profile/presentation/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String userName;
  final String? userEmail;
  final String? userId;

  const MainNavigationScreen({
    super.key,
    required this.userName,
    this.userEmail,
    this.userId,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  late UserAccountProgress _userProgress;
  late String _activeUserName;

  String get _accountKey => UserProgressService.getAccountKey(
        email: widget.userEmail,
        userId: widget.userId,
        userName: widget.userName,
      );

  @override
  void initState() {
    super.initState();
    _activeUserName = widget.userName;
    _pageController = PageController(initialPage: _currentIndex);
    _userProgress = UserAccountProgress(accountKey: _accountKey);
    _loadUserProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  Future<void> _loadUserProgress() async {
    final loaded = await UserProgressService.loadProgress(_accountKey);
    final progress = loaded.syncForDate(DateTime.now());
    if (progress != loaded) {
      await UserProgressService.saveProgress(progress);
    }
    final savedName = await UserProgressService.getSavedUsername(_accountKey);
    if (!mounted) return;
    setState(() {
      _userProgress = progress;
      if (savedName != null && savedName.isNotEmpty) {
        _activeUserName = savedName;
      }
    });
  }

  Future<void> _handleNameChanged(String newName) async {
    setState(() {
      _activeUserName = newName;
    });
    await UserProgressService.saveUsername(_accountKey, newName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newName);
  }

  Future<void> _updateUserProgress(UserAccountProgress updated) async {
    setState(() {
      _userProgress = updated;
    });
    await UserProgressService.saveProgress(updated);
  }

  void _onToggleWorkout() async {
    final newCompleted = !_userProgress.isUserCompleted;
    int newStreak = _userProgress.streakDays;
    if (newCompleted) {
      newStreak += 1;
    } else {
      newStreak = (newStreak > 0) ? newStreak - 1 : 0;
    }

    final updated = _userProgress.copyWith(
      isUserCompleted: newCompleted,
      streakDays: newStreak,
    );
    await _updateUserProgress(updated);
  }

  Future<void> _recordCompletedWorkoutSession(
    WorkoutDayPlan plan,
    int durationSeconds,
    int totalReps,
  ) async {
    final newStreak = _userProgress.isUserCompleted
        ? _userProgress.streakDays
        : _userProgress.streakDays + 1;

    final entry = WorkoutHistoryEntry(
      dayNumber: plan.dayNumber,
      category: plan.category,
      exerciseNames: plan.exerciseNames,
      completedAt: DateTime.now(),
      durationSeconds: durationSeconds,
      totalReps: totalReps,
      isRestDay: plan.isRestDay,
    );

    final updated = _userProgress.copyWith(
      isUserCompleted: true,
      streakDays: newStreak,
      workoutHistory: [..._userProgress.workoutHistory, entry],
    );
    await _updateUserProgress(updated);
  }

  void _onAdvanceDay() async {
    if (_userProgress.currentActiveDay >= 30) return;
    final updated = _userProgress.copyWith(
      currentActiveDay: _userProgress.currentActiveDay + 1,
      isUserCompleted: false,
    );
    await _updateUserProgress(updated);
  }

  void _switchToGroupTab() {
    _navigateToTab(1);
  }

  void _onWorkoutCompletedSession() {
    if (_userProgress.hasGroup) {
      _navigateToTab(1); // Group tab
    } else {
      _navigateToTab(2); // Reports / History tab
    }
  }

  void _onToggleGroupDemo() async {
    final updated = _userProgress.copyWith(
      hasGroup: !_userProgress.hasGroup,
    );
    await _updateUserProgress(updated);
  }

  // MODAL 1: JOIN GROUP MODAL (Identik 1:1 dengan dashboard_screen.html #joinGroupModal)
  void _showJoinGroupModal(BuildContext context) {
    if (_userProgress.hasGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda sudah memiliki grup workout'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

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

                  if (kDebugMode) ...[
                    // Quick simulation presets (debug/demo only)
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
                  ] else
                    const SizedBox(height: 12),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () async {
                        final remainingCooldown =
                            _userProgress.remainingCooldownDays();
                        if (remainingCooldown > 0) {
                          setModalState(
                            () => errorText =
                                'Anda belum bisa bergabung grup selama $remainingCooldown hari',
                          );
                          return;
                        }

                        final inputCode = codeController.text.trim().toUpperCase();
                        if (inputCode.isEmpty) {
                          setModalState(() => errorText = 'Invite code cannot be empty');
                          return;
                        }

                        if (inputCode == 'FULL99') {
                          setModalState(() => errorText = 'Grup sudah penuh (Max 4 members reached)');
                          return;
                        }

                        if (inputCode == 'WAIT07') {
                          setModalState(
                            () => errorText =
                                'Anda belum bisa bergabung grup selama 7 hari',
                          );
                          return;
                        }

                        if (inputCode == 'WOK-882' || inputCode.startsWith('WOK-')) {
                          final updated = _userProgress.copyWith(
                            hasGroup: true,
                            groupName: 'gerup ketat',
                            isLeader: false,
                            inviteCode: inputCode,
                            memberCount: 3,
                            maxMembers: 4,
                            clearCooldown: true,
                            groupCreatedAt:
                                _userProgress.groupCreatedAt ?? DateTime.now(),
                          );
                          await _updateUserProgress(updated);
                          setState(() {
                            _currentIndex = 1; // Langsung beralih ke Dashboard Grup!
                          });

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          if (_pageController.hasClients) {
                            _pageController.jumpToPage(1);
                          }
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
    if (_userProgress.hasGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda sudah memiliki grup workout'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final nameController = TextEditingController(text: 'gerup ketat');
    String selectedDifficulty = _userProgress.workoutDifficulty;
    final int maxCap = _userProgress.isPro ? 10 : 4;
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
                        children: [
                          const Text(
                            'Create Group',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1D1E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userProgress.isPro
                                ? 'Pro tier • 2 to 10 members'
                                : 'Free tier • 2 to 4 members',
                            style: const TextStyle(
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
                          color: const Color(0xFF00D09E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _userProgress.isPro
                              ? 'Pro Tier: 2–10 Members'
                              : 'Free Tier: 2–4 Members',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
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
                          color: capacity < maxCap ? const Color(0xFF1A1D1E) : Colors.grey.shade400,
                          onPressed: capacity < maxCap ? () => setModalState(() => capacity++) : null,
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
                        final updated = _userProgress.copyWith(
                          hasGroup: true,
                          groupName: gName,
                          isLeader: true,
                          inviteCode: randomCode,
                          memberCount: 1,
                          maxMembers: capacity,
                          workoutDifficulty: selectedDifficulty,
                          groupCreatedAt: DateTime.now(),
                          clearCooldown: true,
                        );
                        await _updateUserProgress(updated);
                        setState(() {
                          _currentIndex = 1; // Langsung beralih ke Dashboard Grup!
                        });

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        if (_pageController.hasClients) {
                          _pageController.jumpToPage(1);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Group "$gName" created! Invite code: $randomCode'),
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
          color: isSelected ? Colors.white : const Color(0xFFFAFCFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00D09E) : const Color(0xFFE6ECE8),
            width: isSelected ? 2.0 : 1.5,
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

  // Handler: Keluar dari Grup (UC-06: menetapkan cooldown 7 hari di database lokal)
  void _handleLeaveGroup() async {
    final cooldownEnd = DateTime.now().add(const Duration(days: 7));
    final updated = _userProgress.copyWith(
      hasGroup: false,
      isLeader: false,
      cooldownUntil: cooldownEnd,
      workoutDifficulty: 'Intermediate',
      clearGroupCreatedAt: true,
    );
    await _updateUserProgress(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have left the group (7-day cooldown active).'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _handleJoinGroupFromScreen(String code) async {
    if (_userProgress.hasGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda sudah memiliki grup workout'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_userProgress.isOnCooldown()) return;
    final updated = _userProgress.copyWith(
      hasGroup: true,
      isLeader: false,
      groupName: 'gerup ketat',
      inviteCode: code,
      memberCount: 3,
      clearCooldown: true,
      groupCreatedAt: _userProgress.groupCreatedAt ?? DateTime.now(),
    );
    await _updateUserProgress(updated);
    if (!mounted) return;
    setState(() {
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
    if (_userProgress.hasGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda sudah memiliki grup workout'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    final generatedCode = 'WOK-${Random().nextInt(900) + 100}';
    final updated = _userProgress.copyWith(
      hasGroup: true,
      isLeader: true,
      groupName: name,
      inviteCode: generatedCode,
      memberCount: 1,
      maxMembers: capacity,
      workoutDifficulty: difficulty,
      groupCreatedAt: DateTime.now(),
      clearCooldown: true,
    );
    await _updateUserProgress(updated);
    if (!mounted) return;
    setState(() {
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

  Future<void> _handleDifficultyChanged(String difficulty) async {
    final updated = _userProgress.copyWith(workoutDifficulty: difficulty);
    await _updateUserProgress(updated);
  }

  Future<void> _handleUpgradePro() async {
    final updated = _userProgress.copyWith(
      isPro: true,
      maxMembers: 10,
      restoresLeft: 5,
    );
    await _updateUserProgress(updated);
  }

  Future<void> _handleRestoreQuotaChanged(int newQuota) async {
    final updated = _userProgress.copyWith(
      restoresLeft: newQuota,
    );
    await _updateUserProgress(updated);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(
        userName: _activeUserName,
        currentActiveDay: _userProgress.currentActiveDay,
        streakDays: _userProgress.streakDays,
        isUserCompleted: _userProgress.isUserCompleted,
        hasGroup: _userProgress.hasGroup,
        groupName: _userProgress.groupName,
        isLeader: _userProgress.isLeader,
        workoutDifficulty: _userProgress.hasGroup
            ? _userProgress.workoutDifficulty
            : 'Intermediate',
        onToggleWorkout: _onToggleWorkout,
        onAdvanceDay: _onAdvanceDay,
        onViewGroup: _switchToGroupTab,
        onJoinGroupTap: () => _showJoinGroupModal(context),
        onCreateGroupTap: () => _showCreateGroupModal(context),
        onToggleGroupState: _onToggleGroupDemo,
        onWorkoutCompletedSession: _onWorkoutCompletedSession,
        onRecordWorkoutSession: _recordCompletedWorkoutSession,
      ),
      GroupScreen(
        userName: _activeUserName,
        currentActiveDay: _userProgress.currentActiveDay,
        streakDays: _userProgress.streakDays,
        isUserCompleted: _userProgress.isUserCompleted,
        hasGroup: _userProgress.hasGroup,
        groupName: _userProgress.groupName,
        isLeader: _userProgress.isLeader,
        inviteCode: _userProgress.inviteCode,
        memberCount: _userProgress.memberCount,
        maxMembers: _userProgress.maxMembers,
        isPro: _userProgress.isPro,
        initialRestoresLeft: _userProgress.restoresLeft,
        cooldownUntil: _userProgress.cooldownUntil,
        groupCreatedAt: _userProgress.groupCreatedAt,
        workoutDifficulty: _userProgress.workoutDifficulty,
        workoutHistory: _userProgress.workoutHistory,
        onUpgradePro: _handleUpgradePro,
        onRestoreQuotaChanged: _handleRestoreQuotaChanged,
        onDifficultyChanged: _handleDifficultyChanged,
        onBackPressed: () => _navigateToTab(0),
        onHistoryTap: () => _navigateToTab(2),
        onJoinGroup: _handleJoinGroupFromScreen,
        onCreateGroup: _handleCreateGroupFromScreen,
        onLeaveGroup: _handleLeaveGroup,
        onKickMember: (memberName, remainingCount) async {
          final updated = _userProgress.copyWith(
            memberCount: remainingCount,
          );
          await _updateUserProgress(updated);
        },
      ),
      HistoryScreen(
        onBackPressed: () => _navigateToTab(0),
        historyEntries: _userProgress.workoutHistory,
        currentStreakDays: _userProgress.streakDays,
      ),
      ProfileScreen(
        userName: _activeUserName,
        userEmail: widget.userEmail,
        hasGroup: _userProgress.hasGroup,
        groupName: _userProgress.groupName,
        isPro: _userProgress.isPro,
        restoresLeft: _userProgress.restoresLeft,
        onUpgradePro: _handleUpgradePro,
        onNameChanged: _handleNameChanged,
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
      onTap: () => _navigateToTab(index),
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

/// Helper wrapper to retain page state and scroll positions during PageView transitions.
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({super.key, required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
