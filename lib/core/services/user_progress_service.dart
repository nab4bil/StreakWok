import 'package:shared_preferences/shared_preferences.dart';

/// Model progres harian & streak spesifik per akun pengguna
class UserAccountProgress {
  final String accountKey;
  final int currentActiveDay;
  final int streakDays;
  final bool isUserCompleted;
  final bool hasGroup;
  final String groupName;
  final bool isLeader;
  final String inviteCode;
  final int memberCount;
  final int maxMembers;
  final bool isPro;
  final int restoresLeft;

  const UserAccountProgress({
    required this.accountKey,
    this.currentActiveDay = 1,
    this.streakDays = 0,
    this.isUserCompleted = false,
    this.hasGroup = false,
    this.groupName = 'gerup ketat',
    this.isLeader = false,
    this.inviteCode = 'WOK-882',
    this.memberCount = 3,
    this.maxMembers = 4,
    this.isPro = false,
    this.restoresLeft = 3,
  });

  UserAccountProgress copyWith({
    String? accountKey,
    int? currentActiveDay,
    int? streakDays,
    bool? isUserCompleted,
    bool? hasGroup,
    String? groupName,
    bool? isLeader,
    String? inviteCode,
    int? memberCount,
    int? maxMembers,
    bool? isPro,
    int? restoresLeft,
  }) {
    return UserAccountProgress(
      accountKey: accountKey ?? this.accountKey,
      currentActiveDay: currentActiveDay ?? this.currentActiveDay,
      streakDays: streakDays ?? this.streakDays,
      isUserCompleted: isUserCompleted ?? this.isUserCompleted,
      hasGroup: hasGroup ?? this.hasGroup,
      groupName: groupName ?? this.groupName,
      isLeader: isLeader ?? this.isLeader,
      inviteCode: inviteCode ?? this.inviteCode,
      memberCount: memberCount ?? this.memberCount,
      maxMembers: maxMembers ?? this.maxMembers,
      isPro: isPro ?? this.isPro,
      restoresLeft: restoresLeft ?? this.restoresLeft,
    );
  }
}

/// Service untuk menyimpan dan memuat progres akun secara terisolasi (per-account persistence)
class UserProgressService {
  static String getAccountKey({String? email, String? userId, String? userName}) {
    final raw = (email != null && email.trim().isNotEmpty)
        ? email.trim()
        : (userId != null && userId.trim().isNotEmpty)
            ? userId.trim()
            : (userName != null && userName.trim().isNotEmpty ? userName.trim() : 'default_user');
    return raw.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  /// Mengambil username yang sudah tersimpan untuk akun ini.
  /// Mengembalikan null jika akun baru dan belum pernah mendaftar/membuat username.
  static Future<String?> getSavedUsername(String accountKey) async {
    final prefs = await SharedPreferences.getInstance();
    final customName = prefs.getString('account_${accountKey}_username');
    if (customName != null && customName.trim().isNotEmpty) {
      return customName.trim();
    }
    return null;
  }

  /// Menyimpan username untuk akun baru
  static Future<void> saveUsername(String accountKey, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('account_${accountKey}_username', username.trim());
  }

  static Future<UserAccountProgress> loadProgress(String accountKey) async {
    final prefs = await SharedPreferences.getInstance();
    final hasData = prefs.containsKey('progress_${accountKey}_current_day');

    if (!hasData) {
      // User baru: Selalu mulai dari Day 1, Streak 0, Belum selesai hari ini
      return UserAccountProgress(
        accountKey: accountKey,
        currentActiveDay: 1,
        streakDays: 0,
        isUserCompleted: false,
        hasGroup: false,
        groupName: 'gerup ketat',
        isLeader: false,
        isPro: false,
        restoresLeft: 3,
      );
    }

    final isPro = prefs.getBool('progress_${accountKey}_is_pro') ?? false;
    final defaultRestores = isPro ? 5 : 3;
    final defaultMaxMembers = isPro ? 10 : 4;

    return UserAccountProgress(
      accountKey: accountKey,
      currentActiveDay: prefs.getInt('progress_${accountKey}_current_day') ?? 1,
      streakDays: prefs.getInt('progress_${accountKey}_streak_days') ?? 0,
      isUserCompleted: prefs.getBool('progress_${accountKey}_is_completed') ?? false,
      hasGroup: prefs.getBool('progress_${accountKey}_has_group') ?? false,
      groupName: prefs.getString('progress_${accountKey}_group_name') ?? 'gerup ketat',
      isLeader: prefs.getBool('progress_${accountKey}_is_leader') ?? false,
      inviteCode: prefs.getString('progress_${accountKey}_invite_code') ?? 'WOK-882',
      memberCount: prefs.getInt('progress_${accountKey}_member_count') ?? 3,
      maxMembers: prefs.getInt('progress_${accountKey}_max_members') ?? defaultMaxMembers,
      isPro: isPro,
      restoresLeft: prefs.getInt('progress_${accountKey}_restores_left') ?? defaultRestores,
    );
  }

  static Future<void> saveProgress(UserAccountProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final key = progress.accountKey;
    await prefs.setInt('progress_${key}_current_day', progress.currentActiveDay);
    await prefs.setInt('progress_${key}_streak_days', progress.streakDays);
    await prefs.setBool('progress_${key}_is_completed', progress.isUserCompleted);
    await prefs.setBool('progress_${key}_has_group', progress.hasGroup);
    await prefs.setString('progress_${key}_group_name', progress.groupName);
    await prefs.setBool('progress_${key}_is_leader', progress.isLeader);
    await prefs.setString('progress_${key}_invite_code', progress.inviteCode);
    await prefs.setInt('progress_${key}_member_count', progress.memberCount);
    await prefs.setInt('progress_${key}_max_members', progress.maxMembers);
    await prefs.setBool('progress_${key}_is_pro', progress.isPro);
    await prefs.setInt('progress_${key}_restores_left', progress.restoresLeft);
  }
}
