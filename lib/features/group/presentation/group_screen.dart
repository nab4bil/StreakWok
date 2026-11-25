import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/user_progress_service.dart';
import '../../dashboard/domain/workout_plan_model.dart';
import '../../profile/presentation/upgrade_pro_sheet.dart';
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
  final Function(String memberName, int remainingCount)? onKickMember;

  final int currentActiveDay;
  final int streakDays;
  final int? initialRestoresLeft;
  final bool? isPastDeadline;
  final bool? isRestoreDeadlineExpired;
  final bool isPro;
  final DateTime? cooldownUntil;
  final DateTime? groupCreatedAt;
  final String workoutDifficulty;
  final List<WorkoutHistoryEntry> workoutHistory;
  final VoidCallback? onUpgradePro;
  final Future<bool> Function(String planLabel)? onProcessUpgradePayment;
  final ValueChanged<int>? onRestoreQuotaChanged;
  final ValueChanged<String>? onDifficultyChanged;

  const GroupScreen({
    super.key,
    required this.userName,
    this.isUserCompleted = false,
    this.hasGroup = true,
    this.groupName = 'gerup ketat',
    this.isLeader = false,
    this.currentActiveDay = 1,
    this.streakDays = 0,
    this.inviteCode = 'WOK-882',
    this.memberCount = 3,
    this.maxMembers = 4,
    this.initialRestoresLeft,
    this.isPastDeadline,
    this.isRestoreDeadlineExpired,
    this.isPro = false,
    this.cooldownUntil,
    this.groupCreatedAt,
    this.workoutDifficulty = 'Intermediate',
    this.workoutHistory = const [],
    this.onUpgradePro,
    this.onProcessUpgradePayment,
    this.onRestoreQuotaChanged,
    this.onDifficultyChanged,
    this.onBackPressed,
    this.onHistoryTap,
    this.onJoinGroup,
    this.onCreateGroup,
    this.onLeaveGroup,
    this.onKickMember,
  });

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class GroupMemberItem {
  final String id;
  final String initials;
  final String name;
  final String role;
  final bool isLeader;
  final bool isDone;
  final bool isCurrentUser;

  GroupMemberItem({
    required this.id,
    required this.initials,
    required this.name,
    required this.role,
    required this.isLeader,
    required this.isDone,
    this.isCurrentUser = false,
  });
}

class _GroupScreenState extends State<GroupScreen>
    with SingleTickerProviderStateMixin {
  // State untuk Join/Create Tab (saat hasGroup == false)
  int _noGroupTab = 0; // 0 = Join Group, 1 = Create Group
  final TextEditingController _joinCodeController =
      TextEditingController(text: 'WOK-882');
  final TextEditingController _createNameController =
      TextEditingController(text: 'gerup ketat');
  String _createDifficulty = 'Intermediate';
  int _createCapacity = 4;
  String? _joinFeedback;
  bool _isJoinError = false;

  late bool _isLeaderMode;
  late List<GroupMemberItem> _members;
  late int _restoresLeft;
  late String _currentDifficulty;
  bool _isStreakRestored = false;
  bool _isPro = false;

  late AnimationController _jiggleController;
  late Animation<double> _jiggleAnimation;

  @override
  void initState() {
    super.initState();
    _isLeaderMode = widget.isLeader;
    _isPro = widget.isPro;
    _currentDifficulty = widget.workoutDifficulty;
    _restoresLeft = widget.initialRestoresLeft ?? (_isPro ? 5 : 3);
    _initMembers();

    _jiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _jiggleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: -0.15)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 15),
      TweenSequenceItem(
          tween: Tween<double>(begin: -0.15, end: 0.15)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 25),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.15, end: -0.10)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 25),
      TweenSequenceItem(
          tween: Tween<double>(begin: -0.10, end: 0.08)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.08, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 15),
    ]).animate(_jiggleController);
  }

  @override
  void didUpdateWidget(covariant GroupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLeader != widget.isLeader ||
        oldWidget.isUserCompleted != widget.isUserCompleted ||
        oldWidget.userName != widget.userName) {
      _isLeaderMode = widget.isLeader;
      _initMembers();
    }
    if (oldWidget.isPro != widget.isPro) {
      setState(() {
        _isPro = widget.isPro;
        if (_isPro && _restoresLeft < 5) {
          _restoresLeft = 5;
        }
      });
    }
    if (oldWidget.initialRestoresLeft != widget.initialRestoresLeft &&
        widget.initialRestoresLeft != null) {
      setState(() {
        _restoresLeft = widget.initialRestoresLeft!;
      });
    }
    if (oldWidget.workoutDifficulty != widget.workoutDifficulty) {
      setState(() {
        _currentDifficulty = widget.workoutDifficulty;
      });
    }
  }

  void _showGroupDifficultySheet() {
    if (!_isLeaderMode) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content:
                const Text('Only your group leader can change the difficulty.'),
            backgroundColor: const Color(0xFF1A1D1E),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 2),
          ),
        );
      return;
    }

    String selected = WorkoutDifficultySpec.fromLabel(_currentDifficulty).label;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (modalContext, setModalState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                const Text(
                  'Workout Difficulty',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D1E),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sets, target reps, and rest duration for your group routines.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                for (final spec in WorkoutDifficultySpec.all) ...[
                  GestureDetector(
                    onTap: () => setModalState(() => selected = spec.label),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected == spec.label
                            ? const Color(0xFFE8F9F3)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected == spec.label
                              ? const Color(0xFF00D09E)
                              : const Color(0xFFE6ECE8),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  spec.label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1D1E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  spec.summaryLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            selected == spec.label
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: selected == spec.label
                                ? const Color(0xFF00D09E)
                                : const Color(0xFFCBD5E1),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      setState(() {
                        _currentDifficulty = selected;
                      });
                      widget.onDifficultyChanged?.call(selected);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D09E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Apply Difficulty',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _initMembers() {
    final currentName = widget.userName.trim().toLowerCase();
    if (_isLeaderMode) {
      _members = [
        GroupMemberItem(
          id: 'leader_me',
          initials: _getInitials(widget.userName),
          name: currentName,
          role: 'Leader',
          isLeader: true,
          isCurrentUser: true,
          isDone: widget.isUserCompleted,
        ),
        GroupMemberItem(
          id: 'm1',
          initials: currentName == 'tono hardija' ? 'AM' : 'TH',
          name: currentName == 'tono hardija' ? 'ambaroni' : 'tono hardija',
          role: 'Member',
          isLeader: false,
          isDone: true,
        ),
        GroupMemberItem(
          id: 'm2',
          initials: 'MB',
          name: 'mahmud buah',
          role: 'Member',
          isLeader: false,
          isDone: false, // Member belum latihan -> streak padam
        ),
      ];
    } else {
      _members = [
        GroupMemberItem(
          id: 'm_leader',
          initials: currentName == 'tono hardija' ? 'AM' : 'TH',
          name: currentName == 'tono hardija' ? 'ambaroni' : 'tono hardija',
          role: 'Leader',
          isLeader: true,
          isDone: true,
        ),
        GroupMemberItem(
          id: 'user_me',
          initials: _getInitials(widget.userName),
          name: currentName,
          role: 'Member',
          isLeader: false,
          isCurrentUser: true,
          isDone: widget.isUserCompleted,
        ),
        GroupMemberItem(
          id: 'm_other',
          initials: 'MB',
          name: 'mahmud buah',
          role: 'Member',
          isLeader: false,
          isDone: false, // Member belum latihan -> streak butuh restore
        ),
      ];
    }
  }

  void _showKickMemberDialog(GroupMemberItem member, {VoidCallback? onKicked}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove ${member.name}?',
          style: const TextStyle(
              fontWeight: FontWeight.w800, color: Color(0xFF1A1D1E)),
        ),
        content: Text(
          'Are you sure you want to remove ${member.name} from ${widget.groupName}?\n\nIf all remaining members have completed today\'s workout, the group streak will immediately reignite.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(
                    color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _executeKickMember(member);
              if (onKicked != null) {
                onKicked();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Kick Member',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _executeKickMember(GroupMemberItem member) {
    setState(() {
      _members.removeWhere((m) => m.id == member.id);
    });

    final allRemainingDone =
        _members.isNotEmpty && _members.every((m) => m.isDone);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          allRemainingDone
              ? '${member.name} removed. Group streak reignited!'
              : '${member.name} removed from group.',
        ),
        backgroundColor: const Color(0xFF1A1D1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );

    if (widget.onKickMember != null) {
      widget.onKickMember!(member.name, _members.length);
    }
  }

  void _showManageMembersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Manage Members',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1D1E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLeaderMode
                          ? 'Select a member to remove from this streak group.'
                          : 'You are currently a Member. Only leaders can remove members.',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 16),
                    ..._members.map((member) {
                      final canKick = _isLeaderMode && !member.isCurrentUser;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFF00D09E),
                                    child: Text(
                                      member.initials,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member.isCurrentUser
                                              ? 'You'
                                              : member.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1A1D1E),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          member.role,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: member.isLeader
                                                ? const Color(0xFF00D09E)
                                                : const Color(0xFF8C949D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (canKick)
                              ElevatedButton(
                                key: Key('sheet_kick_${member.name}'),
                                onPressed: () {
                                  _showKickMemberDialog(
                                    member,
                                    onKicked: () {
                                      setSheetState(() {});
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEF2F2),
                                  foregroundColor: const Color(0xFFDC2626),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(
                                        color: Color(0xFFFCA5A5)),
                                  ),
                                ),
                                child: const Text(
                                  'Remove',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _jiggleController.dispose();
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
          historyEntries: widget.workoutHistory,
          memberNames: _members.map((m) => m.name).toList(),
        ),
      ),
    );
  }

  void _onRestoreStreakTapped() {
    if (widget.isRestoreDeadlineExpired == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Waktu habis: batas restore grup jam 13.00 telah terlewati.'),
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_restoresLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kuota restore bulan ini tidak cukup.'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF1A1D1E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _showUpgradeProModal();
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Restore Group Streak?',
          style:
              TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1D1E)),
        ),
        content: Text(
          'Use 1 monthly restore quota ($_restoresLeft left this month) to restore ${widget.groupName}\'s streak today?',
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
        ),
        actions: [
          TextButton(
            key: const Key('cancel_restore_streak_btn'),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(
                  color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            key: const Key('confirm_restore_streak_btn'),
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _restoresLeft--;
                _isStreakRestored = true;
              });
              widget.onRestoreQuotaChanged?.call(_restoresLeft);
              HapticFeedback.mediumImpact();
              _jiggleController.forward(from: 0.0);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Streak restored! $_restoresLeft restores left this month.'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF1A1D1E),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D09E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Restore',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showUpgradeProModal() {
    showUpgradeProBottomSheet(
      context: context,
      onUpgradeConfirmed: () {
        setState(() {
          _isPro = true;
          _restoresLeft = 5;
          _isStreakRestored = true;
        });
        widget.onUpgradePro?.call();
        widget.onRestoreQuotaChanged?.call(5);
        _jiggleController.forward(from: 0.0);
      },
      onProcessPayment: widget.onProcessUpgradePayment,
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Leave Group?',
          style:
              TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1D1E)),
        ),
        content: Text(
          'Per SDD specifications, leaving "${widget.groupName}" triggers a 7-day cooldown before you can join another group.',
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Leave',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  int get _remainingCooldownDays {
    final until = widget.cooldownUntil;
    final now = DateTime.now();
    if (until == null || !until.isAfter(now)) return 0;
    final diffSeconds = until.difference(now).inSeconds;
    if (diffSeconds <= 0) return 0;
    return (diffSeconds / Duration.secondsPerDay).ceil().clamp(1, 7);
  }

  void _handleJoinSubmit() {
    if (widget.hasGroup) {
      setState(() {
        _isJoinError = true;
        _joinFeedback = 'Anda sudah memiliki grup workout';
      });
      return;
    }

    final remainingCooldown = _remainingCooldownDays;
    if (remainingCooldown > 0) {
      setState(() {
        _isJoinError = true;
        _joinFeedback =
            'Anda belum bisa bergabung grup selama $remainingCooldown hari';
      });
      return;
    }

    final code = _joinCodeController.text.trim().toUpperCase();
    if (code == 'FULL99') {
      setState(() {
        _isJoinError = true;
        _joinFeedback = 'Grup sudah penuh (4/4 members).';
      });
      return;
    }
    if (code == 'WAIT07') {
      setState(() {
        _isJoinError = true;
        _joinFeedback = 'Anda belum bisa bergabung grup selama 7 hari';
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
    if (widget.hasGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda sudah memiliki grup workout'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

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
    final streakDays = widget.streakDays;
    final isDone = widget.isUserCompleted;
    final bool allDone = _members.isNotEmpty && _members.every((m) => m.isDone);
    final bool isPast13 = widget.isPastDeadline ?? (DateTime.now().hour >= 13);
    final bool isStreakBroken = !allDone && isPast13 && !_isStreakRestored;
    final bool isStreakLit = allDone || _isStreakRestored;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFB),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFCFB),
                border: Border(bottom: BorderSide(color: Color(0xFFEEF2F0))),
              ),
              child: Row(
                children: [
                  if (widget.onBackPressed != null) ...[
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
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.hasGroup ? 'Group Details' : 'Workout Group',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1D1E),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Body Content Area
            Expanded(
              child: widget.hasGroup
                  ? ListView(
                      key: const ValueKey('group_active_list'),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      children: [
                        // CARD 1: GROUP HERO & STREAK BANNER (group-hero-card)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFE6ECE8), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          widget.groupCreatedAt != null
                                              ? '${widget.isLeader ? 'Leader' : 'Member'} • Day ${widget.currentActiveDay} of 30 • Started ${DateFormat('MMM d').format(widget.groupCreatedAt!)}'
                                              : (widget.isLeader
                                                  ? 'Leader • Day ${widget.currentActiveDay} of 30'
                                                  : 'Member • Day ${widget.currentActiveDay} of 30'),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF8C949D),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        GestureDetector(
                                          key:
                                              const Key('group_difficulty_btn'),
                                          onTap: _showGroupDifficultySheet,
                                          child: Builder(
                                            builder: (context) {
                                              final spec = WorkoutDifficultySpec
                                                  .fromLabel(
                                                _currentDifficulty,
                                              );
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFE8F9F3),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color:
                                                        const Color(0xFFBCEBDC),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        '${spec.label} • ${spec.sets} sets',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              Color(0xFF007A58),
                                                        ),
                                                      ),
                                                    ),
                                                    if (_isLeaderMode) ...[
                                                      const SizedBox(width: 3),
                                                      const Icon(
                                                        Icons
                                                            .keyboard_arrow_down_rounded,
                                                        size: 14,
                                                        color:
                                                            Color(0xFF007A58),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() {
                                        _isStreakRestored = !_isStreakRestored;
                                      });
                                    },
                                    child: Column(
                                      children: [
                                        AnimatedBuilder(
                                          animation: _jiggleAnimation,
                                          builder: (context, child) {
                                            final scale = 1.0 +
                                                (_jiggleController.value > 0
                                                    ? (0.28 *
                                                        (1.0 -
                                                            ((_jiggleController
                                                                            .value -
                                                                        0.5)
                                                                    .abs() *
                                                                2)))
                                                    : 0.0);
                                            return Transform.scale(
                                              scale: scale,
                                              child: Transform.rotate(
                                                angle: _jiggleAnimation.value,
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: SizedBox(
                                            width: 52,
                                            height: 52,
                                            child: CustomPaint(
                                              painter: _TikTokFlamePainter(
                                                  isLit: isStreakLit),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$streakDays',
                                          style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w900,
                                            color: isStreakLit
                                                ? const Color(0xFFFF5722)
                                                : const Color(0xFF9CA3AF),
                                            letterSpacing: -0.5,
                                            height: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (isStreakBroken) ...[
                                const SizedBox(height: 12),
                                const Divider(
                                    height: 1, color: Color(0xFFF1F5F3)),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  key: const Key('restore_streak_btn'),
                                  onTap: _onRestoreStreakTapped,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00D09E),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.local_fire_department_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Restore Streak',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

                        // CARD 2: INVITE CODE CARD (invite-card)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFE6ECE8), width: 1.5),
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
                                      color: Color(0xFF00D09E),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
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
                                      Icon(Icons.copy_rounded,
                                          size: 13, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

                        // STATS GRID (2 SEPARATE CARDS, TIGHT GAP)
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard('Capacity',
                                  '${_members.length} / ${_isPro ? 10 : widget.maxMembers}'),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (isStreakBroken) {
                                    _onRestoreStreakTapped();
                                  } else if (_restoresLeft == 0) {
                                    _showUpgradeProModal();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(_isPro
                                            ? 'StreakWok Pro: $_restoresLeft / 5 streak restores left this month.'
                                            : 'You have $_restoresLeft / 3 streak restores left this month.'),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor:
                                            const Color(0xFF1A1D1E),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    );
                                  }
                                },
                                child: _buildStatCard(
                                  'Restores Left',
                                  '$_restoresLeft / ${_isPro ? 5 : 3}',
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // CARD 4: THIS WEEK PROGRESS CARD (week-card)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFE6ECE8), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                              const SizedBox(height: 10),

                              // Dynamic Days grid row (S, M, T, W, T, F, S)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: _buildThisWeekCircles(isDone),
                              ),

                              const SizedBox(height: 10),
                              const Divider(
                                  height: 1, color: Color(0xFFF1F5F3)),
                              const SizedBox(height: 8),

                              // Week streak footer
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CustomPaint(
                                          painter: _TikTokFlamePainter(
                                              isLit: isStreakLit),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF1A1D1E)),
                                          children: [
                                            TextSpan(
                                              text: '$streakDays ',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800),
                                            ),
                                            const TextSpan(text: 'Day Streak'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    widget.isLeader
                                        ? 'Group Best: $streakDays'
                                        : 'Group Best: 14',
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

                        const SizedBox(height: 6),

                        // CARD 5: MEMBERS DETAIL LIST (members-card)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFE6ECE8), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                  InkWell(
                                    key: const Key('group_members_more_btn'),
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _showManageMembersSheet,
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.more_vert_rounded,
                                        size: 20,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              for (int i = 0; i < _members.length; i++) ...[
                                if (i > 0)
                                  const Divider(
                                      height: 12, color: Color(0xFFF1F5F3)),
                                _buildMemberRow(
                                  initials: _members[i].initials,
                                  name: _members[i].name,
                                  role: _members[i].role,
                                  isLeader: _members[i].isLeader,
                                  isDone: _members[i].isDone,
                                  isPending: !_members[i].isDone,
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
                                icon: const Icon(Icons.logout_rounded,
                                    size: 16, color: Colors.white),
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
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
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
                      key: const ValueKey('group_empty_list'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      children: [
                        // Hero Header
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00D09E),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(Icons.group_outlined,
                                    color: Colors.white, size: 28),
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
                            border: Border.all(
                                color: const Color(0xFFE6ECE8), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _noGroupTab = 0),
                                  child: Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: _noGroupTab == 0
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _noGroupTab == 0
                                          ? [
                                              BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.04),
                                                  blurRadius: 4)
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Join Group',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _noGroupTab == 0
                                              ? const Color(0xFF1A1D1E)
                                              : const Color(0xFF6B7280),
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
                                      color: _noGroupTab == 1
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _noGroupTab == 1
                                          ? [
                                              BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.04),
                                                  blurRadius: 4)
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Create Group',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _noGroupTab == 1
                                              ? const Color(0xFF1A1D1E)
                                              : const Color(0xFF6B7280),
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
                              border: Border.all(
                                  color: const Color(0xFFE6ECE8), width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_remainingCooldownDays > 0) ...[
                                  Container(
                                    key: const Key('group_cooldown_banner'),
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFFCA5A5),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.timer_off_outlined,
                                          size: 18,
                                          color: Color(0xFFDC2626),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Anda belum bisa bergabung grup selama $_remainingCooldownDays hari',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFDC2626),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const Text(
                                  'Group Invite Code',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1D1E)),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _joinCodeController,
                                  textCapitalization:
                                      TextCapitalization.characters,
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
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE6ECE8)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF00D09E), width: 2),
                                    ),
                                  ),
                                ),
                                if (kDebugMode) ...[
                                  const SizedBox(height: 14),
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
                                      _buildSimPill('WOK-882',
                                          'WOK-882 (Valid: gerup ketat)'),
                                      _buildSimPill(
                                          'FULL99', 'FULL99 (Group Full)'),
                                      _buildSimPill(
                                          'WAIT07', 'WAIT07 (On Cooldown)'),
                                    ],
                                  ),
                                ],

                                if (_joinFeedback != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _isJoinError
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF00D09E),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _joinFeedback!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
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
                                    border: Border.all(
                                        color: const Color(0xFFE6ECE8)),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildRuleItem(
                                          'Instant synchronization to group\'s active day'),
                                      const SizedBox(height: 8),
                                      _buildRuleItem(
                                          'Max 4 members per workout group'),
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
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                    ),
                                    child: const Text(
                                      'Join Group',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700),
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
                              border: Border.all(
                                  color: const Color(0xFFE6ECE8), width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Group Name',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1D1E)),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _createNameController,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1D1E)),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. gerup ketat',
                                    filled: true,
                                    fillColor: const Color(0xFFFAFCFB),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE6ECE8)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF00D09E), width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                const Text(
                                  'Target Difficulty',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1D1E)),
                                ),
                                const SizedBox(height: 8),
                                _buildCreateDiffOption('Beginner',
                                    '3 sets • 8–10 reps • 45s rest (Light)'),
                                const SizedBox(height: 8),
                                _buildCreateDiffOption('Intermediate',
                                    '3 sets • 15 reps • 30s rest (Moderate)'),
                                const SizedBox(height: 8),
                                _buildCreateDiffOption('Advanced',
                                    '4 sets • 20 reps • 20s rest (Intense)'),
                                const SizedBox(height: 16),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Group Capacity',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1A1D1E)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00D09E),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _isPro
                                            ? 'Pro Tier: 2–10 Members'
                                            : 'Free Tier: 2–4 Members',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Stepper Container
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAFCFB),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: const Color(0xFFE6ECE8),
                                        width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        onPressed: _createCapacity > 2
                                            ? () => setState(
                                                () => _createCapacity--)
                                            : null,
                                        icon:
                                            const Icon(Icons.remove, size: 18),
                                      ),
                                      Column(
                                        children: [
                                          Text(
                                            '$_createCapacity',
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF1A1D1E)),
                                          ),
                                          const Text(
                                            'MEMBERS',
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF8C949D)),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        onPressed:
                                            _createCapacity < (_isPro ? 10 : 4)
                                                ? () => setState(
                                                    () => _createCapacity++)
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
                                    border: Border.all(
                                        color: const Color(0xFFE6ECE8)),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildRuleItem(
                                          'You will automatically become the Group Leader'),
                                      const SizedBox(height: 8),
                                      _buildRuleItem(
                                          'Unique invite code generated automatically (e.g. WOK-882)'),
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
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                    ),
                                    child: const Text(
                                      'Create Group',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700),
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
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569)),
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
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563)),
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
          color: isSelected ? Colors.white : const Color(0xFFFAFCFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF00D09E) : const Color(0xFFE6ECE8),
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
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D1E)),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280)),
                ),
              ],
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? const Color(0xFF00D09E) : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00D09E)
                      : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.circle, size: 6, color: Colors.white))
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildThisWeekCircles(bool isDoneToday) {
    const dayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final now = DateTime.now();
    final sunday = now.subtract(Duration(days: now.weekday % 7));
    return List.generate(7, (index) {
      final date = sunday.add(Duration(days: index));
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      final hasHistoryForDate = widget.workoutHistory.any(
        (entry) =>
            entry.completedAt.year == date.year &&
            entry.completedAt.month == date.month &&
            entry.completedAt.day == date.day,
      );
      return _DayCircle(
        dayName: dayLetters[index],
        dateNum: '${date.day}',
        isActive: hasHistoryForDate || (isToday && isDoneToday),
      );
    });
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
    VoidCallback? onKick,
  }) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFF3F4F6)
                      : const Color(0xFF00D09E),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isPending ? const Color(0xFF6B7280) : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D1E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isLeader
                            ? const Color(0xFF00D09E)
                            : const Color(0xFF8C949D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isDone ? const Color(0xFFFF5722) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isDone ? 'Done' : 'Undone',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDone ? Colors.white : const Color(0xFF8C949D),
                ),
              ),
            ),
            if (onKick != null) ...[
              const SizedBox(width: 6),
              InkWell(
                key: Key('kick_button_$name'),
                borderRadius: BorderRadius.circular(8),
                onTap: onKick,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0xFFFCA5A5), width: 1),
                  ),
                  child: const Text(
                    'Kick',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
            ],
          ],
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
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8C949D)),
        ),
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF00D09E) : const Color(0xFFF4F7F5),
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
