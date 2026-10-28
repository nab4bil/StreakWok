import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import 'group_history_screen.dart';

class GroupScreen extends StatefulWidget {
  final String userName;
  final bool isUserCompleted;
  final bool hasGroup;
  final String groupName;
  final bool isLeader;
  final String inviteCode;
  final int memberCount;
  final int maxMembers;
  final VoidCallback? onBackPressed;
  final VoidCallback? onHistoryTap;
  final ValueChanged<String>? onJoinGroup;
  final Function(String name, String difficulty, int capacity)? onCreateGroup;
  final VoidCallback? onLeaveGroup;

  const GroupScreen({
    super.key,
    required this.userName,
    this.isUserCompleted = false,
    this.hasGroup = true,
    this.groupName = 'gerup ketat',
    this.isLeader = false,
    this.inviteCode = 'WOK-882',
    this.memberCount = 3,
    this.maxMembers = 4,
    this.onBackPressed,
    this.onHistoryTap,
    this.onJoinGroup,
    this.onCreateGroup,
    this.onLeaveGroup,
  });

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  String _selectedPlan = 'Intermediate';

  // State untuk Join/Create Tab (saat hasGroup == false)
  int _noGroupTab = 0; // 0 = Join Group, 1 = Create Group
  final TextEditingController _joinCodeController = TextEditingController(text: 'WOK-882');
  final TextEditingController _createNameController = TextEditingController(text: 'gerup ketat');
  String _createDifficulty = 'Intermediate';
  int _createCapacity = 4;
  String? _joinFeedback;
  bool _isJoinError = false;

  @override
  void dispose() {
    _joinCodeController.dispose();
    _createNameController.dispose();
    super.dispose();
  }

  void _copyInviteCode() {
    Clipboard.setData(ClipboardData(text: widget.inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Invite code ${widget.inviteCode} copied to clipboard!',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1D1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToGroupHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupHistoryScreen(
          groupName: widget.groupName,
          isLeader: widget.isLeader,
          userName: widget.userName,
          isUserCompleted: widget.isUserCompleted,
        ),
      ),
    );
  }

  // MODAL / BOTTOM SHEET: WORKOUT PLAN SETTINGS (Identik 1:1 dengan group_screen.html #settingsModal)
  void _showWorkoutPlanModal() {
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Workout Plan Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1D1E),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Personal difficulty for your daily routines',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close, size: 16, color: Color(0xFF6B7280)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildDiffOption('Beginner', 'Squat • Knee Push-up • Wall Sit', setModalState),
                  const SizedBox(height: 10),
                  _buildDiffOption('Intermediate', 'Squat • Push-up • Calisthenics Routine', setModalState),
                  const SizedBox(height: 10),
                  _buildDiffOption('Advanced', 'Pistol Squat • Diamond Push-up • Handstand', setModalState),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D09E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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

  Widget _buildDiffOption(String title, String subtitle, StateSetter setModalState) {
    final isSelected = _selectedPlan == title;

    return GestureDetector(
      onTap: () => setModalState(() => _selectedPlan = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D1E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF00D09E) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFF00D09E) : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.circle, size: 8, color: Colors.white),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Leave Group?',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1D1E)),
        ),
        content: Text(
          'Per SDD specifications, leaving "${widget.groupName}" triggers a 7-day cooldown before you can join another group.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.onLeaveGroup != null) {
                widget.onLeaveGroup!();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Leave', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _handleJoinSubmit() {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code == 'FULL99') {
      setState(() {
        _isJoinError = true;
        _joinFeedback = 'Group FULL99 has reached max capacity (4/4 members).';
      });
      return;
    }
    if (code == 'WAIT07') {
      setState(() {
        _isJoinError = true;
        _joinFeedback = 'You are currently on a 7-day cooldown period.';
      });
      return;
    }
    if (code.isEmpty) {
      setState(() {
        _isJoinError = true;
        _joinFeedback = 'Please enter a valid group invite code.';
      });
      return;
    }

    setState(() {
      _isJoinError = false;
      _joinFeedback = 'Successfully joined group streak';
    });

    if (widget.onJoinGroup != null) {
      widget.onJoinGroup!(code);
    }
  }

  void _handleCreateSubmit() {
    final name = _createNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (widget.onCreateGroup != null) {
      widget.onCreateGroup!(name, _createDifficulty, _createCapacity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streakDays = widget.isLeader
        ? (widget.isUserCompleted ? 1 : 0)
        : (widget.isUserCompleted ? 15 : 14);
    final isDone = widget.isUserCompleted;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFB),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Header (Identik 1:1 dengan group_screen.html / join_create_group.html)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFCFB),
                border: Border(bottom: BorderSide(color: Color(0xFFEEF2F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: widget.onBackPressed,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.centerLeft,
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 26,
                        color: Color(0xFF1A1D1E),
                      ),
                    ),
                  ),
                  Text(
                    widget.hasGroup ? 'Group Details' : 'Workout Group',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1D1E),
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (widget.hasGroup)
                    GestureDetector(
                      onTap: _showWorkoutPlanModal,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.centerRight,
                        child: const Icon(
                          Icons.tune_rounded,
                          size: 22,
                          color: Color(0xFF1A1D1E),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 32),
                ],
              ),
            ),

            // Body Content Area
            Expanded(
              child: widget.hasGroup
                  ? ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      children: [
                        // CARD 1: GROUP HERO & STREAK BANNER (group-hero-card)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.groupName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1A1D1E),
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.isLeader ? 'Started Today' : 'Started Oct 4, 2026',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF8C949D),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: CustomPaint(
                                      painter: _TikTokFlamePainter(isLit: isDone),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$streakDays',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: isDone ? const Color(0xFFFF5722) : const Color(0xFF9CA3AF),
                                      letterSpacing: -0.5,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // CARD 2: INVITE CODE CARD (invite-card)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF8F3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD6EFE5), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'INVITE CODE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF009E74),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.inviteCode,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A1D1E),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _copyInviteCode,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00D09E),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: const [
                                      Text(
                                        'Copy',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Icon(Icons.copy_rounded, size: 13, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // STATS GRID (2 COLUMNS FLAT) (stats-grid)
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard('Capacity', '${widget.memberCount} / ${widget.maxMembers}'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard('Restores Left', '3 / 3'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // CARD 4: THIS WEEK PROGRESS CARD (week-card)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'This Week',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A1D1E),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _navigateToGroupHistory,
                                    child: Row(
                                      children: const [
                                        Text(
                                          'History',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF00D09E),
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 16,
                                          color: Color(0xFF00D09E),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Days grid row (S, M, T, W, T, F, S)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _DayCircle(dayName: 'S', dateNum: '18', isActive: widget.isLeader ? isDone : true),
                                  const _DayCircle(dayName: 'M', dateNum: '19'),
                                  const _DayCircle(dayName: 'T', dateNum: '20'),
                                  const _DayCircle(dayName: 'W', dateNum: '21'),
                                  const _DayCircle(dayName: 'T', dateNum: '22'),
                                  const _DayCircle(dayName: 'F', dateNum: '23'),
                                  const _DayCircle(dayName: 'S', dateNum: '24'),
                                ],
                              ),

                              const SizedBox(height: 14),
                              const Divider(height: 1, color: Color(0xFFF1F5F3)),
                              const SizedBox(height: 12),

                              // Week streak footer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CustomPaint(
                                          painter: _TikTokFlamePainter(isLit: isDone),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF1A1D1E)),
                                          children: [
                                            TextSpan(
                                              text: '$streakDays ',
                                              style: const TextStyle(fontWeight: FontWeight.w800),
                                            ),
                                            const TextSpan(text: 'Day Streak'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    widget.isLeader ? 'Group Best: $streakDays' : 'Group Best: 14',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF8C949D),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // CARD 5: MEMBERS DETAIL LIST (members-card)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Group Members',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1D1E),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 14),

                              if (widget.isLeader) ...[
                                _buildMemberRow(
                                  initials: _getInitials(widget.userName),
                                  name: widget.userName.toLowerCase(),
                                  role: 'Leader',
                                  isLeader: true,
                                  isDone: isDone,
                                  isPending: !isDone,
                                ),
                                const Divider(height: 20, color: Color(0xFFF1F5F3)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAFCFB),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE6ECE8)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.person_add_outlined,
                                          size: 20,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Waiting for members...',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Share code ${widget.inviteCode} to invite',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                _buildMemberRow(
                                  initials: 'TH',
                                  name: 'tono hardija',
                                  role: 'Leader',
                                  isLeader: true,
                                  isDone: true,
                                ),
                                const Divider(height: 20, color: Color(0xFFF1F5F3)),

                                _buildMemberRow(
                                  initials: _getInitials(widget.userName),
                                  name: widget.userName.toLowerCase(),
                                  role: 'Member',
                                  isLeader: false,
                                  isDone: isDone,
                                  isPending: !isDone,
                                ),
                                const Divider(height: 20, color: Color(0xFFF1F5F3)),

                                _buildMemberRow(
                                  initials: 'MB',
                                  name: 'mahmud buah',
                                  role: 'Member',
                                  isLeader: false,
                                  isDone: true,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // DANGER ZONE (LEAVE GROUP BUTTON)
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _showLeaveGroupDialog,
                                icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.white),
                                label: const Text(
                                  'Leave Group',
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
                            const SizedBox(height: 6),
                            const Text(
                              'Leaving triggers a 7-day cooldown penalty.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8C949D),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),
                      ],
                    )
                  // TAMPILAN KETIKA BELUM ADA GRUP (Identik 1:1 dengan join_create_group.html)
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      children: [
                        // Hero Header
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F9F3),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(Icons.group_outlined, color: Color(0xFF00A87A), size: 28),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Start Streaking Together',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1D1E),
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'Join your friends\' team or create your own group to build healthy fitness habits.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF8C949D),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Segmented Control (Toggle Join vs Create)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _noGroupTab = 0),
                                  child: Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: _noGroupTab == 0 ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _noGroupTab == 0
                                          ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Join Group',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _noGroupTab == 0 ? const Color(0xFF1A1D1E) : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _noGroupTab = 1),
                                  child: Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: _noGroupTab == 1 ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _noGroupTab == 1
                                          ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Create Group',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _noGroupTab == 1 ? const Color(0xFF1A1D1E) : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // TAB 1: JOIN GROUP
                        if (_noGroupTab == 0) ...[
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Group Invite Code',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1E)),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _joinCodeController,
                                  textCapitalization: TextCapitalization.characters,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.0,
                                    color: Color(0xFF1A1D1E),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'WOK-882',
                                    filled: true,
                                    fillColor: const Color(0xFFFAFCFB),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE6ECE8)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFF00D09E), width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Quick Simulation Presets
                                const Text(
                                  'SIMULATION QUICK PRESETS:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _buildSimPill('WOK-882', 'WOK-882 (Valid: gerup ketat)'),
                                    _buildSimPill('FULL99', 'FULL99 (Group Full)'),
                                    _buildSimPill('WAIT07', 'WAIT07 (On Cooldown)'),
                                  ],
                                ),

                                if (_joinFeedback != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _isJoinError ? const Color(0xFFFEF2F2) : const Color(0xFFE8F9F3),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _isJoinError ? const Color(0xFFFCA5A5) : const Color(0xFFA7F3D0),
                                      ),
                                    ),
                                    child: Text(
                                      _joinFeedback!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _isJoinError ? const Color(0xFFDC2626) : const Color(0xFF00A87A),
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 16),

                                // Rules card
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAF9),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE6ECE8)),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildRuleItem('Instant synchronization to group\'s active day'),
                                      const SizedBox(height: 8),
                                      _buildRuleItem('Max 4 members per workout group'),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),

                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _handleJoinSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00D09E),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: const Text(
                                      'Join Group',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                        // TAB 2: CREATE GROUP
                        else ...[
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Group Name',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1E)),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _createNameController,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1E)),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. gerup ketat',
                                    filled: true,
                                    fillColor: const Color(0xFFFAFCFB),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE6ECE8)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFF00D09E), width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                const Text(
                                  'Target Difficulty',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1E)),
                                ),
                                const SizedBox(height: 8),
                                _buildCreateDiffOption('Beginner', '3 sets • 8–10 reps • 45s rest (Light)'),
                                const SizedBox(height: 8),
                                _buildCreateDiffOption('Intermediate', '3 sets • 15 reps • 30s rest (Moderate)'),
                                const SizedBox(height: 8),
                                _buildCreateDiffOption('Advanced', '4 sets • 20 reps • 20s rest (Intense)'),
                                const SizedBox(height: 16),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Group Capacity',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1E)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F9F3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Free Tier: 2–4 Members',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF00A87A)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Stepper Container
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAFCFB),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        onPressed: _createCapacity > 2
                                            ? () => setState(() => _createCapacity--)
                                            : null,
                                        icon: const Icon(Icons.remove, size: 18),
                                      ),
                                      Column(
                                        children: [
                                          Text(
                                            '$_createCapacity',
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1D1E)),
                                          ),
                                          const Text(
                                            'MEMBERS',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF8C949D)),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        onPressed: _createCapacity < 4
                                            ? () => setState(() => _createCapacity++)
                                            : null,
                                        icon: const Icon(Icons.add, size: 18),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Rules card
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAF9),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE6ECE8)),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildRuleItem('You will automatically become the Group Leader'),
                                      const SizedBox(height: 8),
                                      _buildRuleItem('Unique invite code generated automatically (e.g. WOK-882)'),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),

                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _handleCreateSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00D09E),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: const Text(
                                      'Create Group',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 30),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimPill(String code, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _joinCodeController.text = code;
          _joinFeedback = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check, size: 14, color: Color(0xFF00A87A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateDiffOption(String title, String subtitle) {
    final isSelected = _createDifficulty == title;

    return GestureDetector(
      onTap: () => setState(() => _createDifficulty = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F9F3) : const Color(0xFFFAFCFB),
          borderRadius: BorderRadius.circular(14),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
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

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6ECE8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D1E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D1E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow({
    required String initials,
    required String name,
    required String role,
    required bool isLeader,
    bool isDone = false,
    bool isPending = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPending ? const Color(0xFFF3F4F6) : const Color(0xFFE8F9F3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isPending ? const Color(0xFF6B7280) : const Color(0xFF00A87A),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D1E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isLeader ? const Color(0xFF00A87A) : const Color(0xFF8C949D),
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFFFEECEB) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            isDone ? 'Done' : 'Pending',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDone ? const Color(0xFFFF5722) : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayCircle extends StatelessWidget {
  final String dayName;
  final String dateNum;
  final bool isActive;

  const _DayCircle({
    required this.dayName,
    required this.dateNum,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          dayName,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8C949D)),
        ),
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1A1D1E) : const Color(0xFFF4F7F5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              dateNum,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                color: isActive ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Painter untuk TikTok Flame Identik dengan Path SVG di HTML
class _TikTokFlamePainter extends CustomPainter {
  final bool isLit;

  _TikTokFlamePainter({required this.isLit});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final outerPaint = Paint()
      ..color = isLit ? const Color(0xFFFF5722) : const Color(0xFF9CA3AF);
    final innerPaint = Paint()
      ..color = isLit ? const Color(0xFFFFA000) : const Color(0xFFD1D5DB);

    final outerPath = Path()
      ..moveTo(12, 2)
      ..cubicTo(9.5, 5.2, 6.5, 8.5, 6.5, 13)
      ..cubicTo(6.5, 16.9, 9, 20, 12, 20)
      ..cubicTo(15, 20, 17.5, 16.9, 17.5, 13)
      ..cubicTo(17.5, 8.5, 14.5, 5.2, 12, 2)
      ..close();
    canvas.drawPath(outerPath, outerPaint);

    final innerPath = Path()
      ..moveTo(12, 8)
      ..cubicTo(10.8, 10, 9.5, 11.8, 9.5, 14)
      ..cubicTo(9.5, 15.8, 10.6, 17.5, 12, 17.5)
      ..cubicTo(13.4, 17.5, 14.5, 15.8, 14.5, 14)
      ..cubicTo(14.5, 11.8, 13.2, 10, 12, 8)
      ..close();
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _TikTokFlamePainter oldDelegate) =>
      oldDelegate.isLit != isLit;
}
