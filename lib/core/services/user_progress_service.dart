import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Model satu entri riwayat latihan harian (UC-02)
class WorkoutHistoryEntry {
  final int dayNumber;
  final String category;
  final List<String> exerciseNames;
  final DateTime completedAt;
  final int durationSeconds;
  final int totalReps;
  final bool isRestDay;

  const WorkoutHistoryEntry({
    required this.dayNumber,
    required this.category,
    required this.exerciseNames,
    required this.completedAt,
    required this.durationSeconds,
    this.totalReps = 0,
    this.isRestDay = false,
  });

  String get formattedTitle => isRestDay
      ? 'Day $dayNumber | Rest & Recovery'
      : 'Day $dayNumber | ${exerciseNames.join(' • ')}';

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'category': category,
        'exerciseNames': exerciseNames,
        'completedAt': completedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'totalReps': totalReps,
        'isRestDay': isRestDay,
      };

  factory WorkoutHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutHistoryEntry(
      dayNumber: (json['dayNumber'] as num?)?.toInt() ?? 1,
      category: (json['category'] as String?) ?? 'Workout',
      exerciseNames: (json['exerciseNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      completedAt: DateTime.tryParse((json['completedAt'] as String?) ?? '') ??
          DateTime.now(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      totalReps: (json['totalReps'] as num?)?.toInt() ?? 0,
      isRestDay: (json['isRestDay'] as bool?) ?? false,
    );
  }
}

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
  final DateTime? cooldownUntil;
  final List<WorkoutHistoryEntry> workoutHistory;

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
    this.cooldownUntil,
    this.workoutHistory = const [],
  });

  /// Mengembalikan true apabila user masih dalam masa penalti cooldown keluar grup (UC-06 / UC-07).
  bool isOnCooldown({DateTime? now}) {
    final until = cooldownUntil;
    if (until == null) return false;
    return until.isAfter(now ?? DateTime.now());
  }

  /// Menghitung sisa hari cooldown dibulatkan ke atas (1..7) atau 0 jika bebas cooldown.
  int remainingCooldownDays({DateTime? now}) {
    final ref = now ?? DateTime.now();
    final until = cooldownUntil;
    if (until == null || !until.isAfter(ref)) return 0;
    final diffSeconds = until.difference(ref).inSeconds;
    if (diffSeconds <= 0) return 0;
    return (diffSeconds / Duration.secondsPerDay).ceil().clamp(1, 7);
  }

  int get totalWorkoutsCount =>
      workoutHistory.where((entry) => !entry.isRestDay).length;

  int get totalWorkoutSeconds =>
      workoutHistory.fold<int>(0, (sum, entry) => sum + entry.durationSeconds);

  int get totalWorkoutMinutes => totalWorkoutSeconds ~/ 60;

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
    DateTime? cooldownUntil,
    bool clearCooldown = false,
    List<WorkoutHistoryEntry>? workoutHistory,
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
      cooldownUntil: clearCooldown ? null : (cooldownUntil ?? this.cooldownUntil),
      workoutHistory: workoutHistory ?? this.workoutHistory,
    );
  }
}

/// Service untuk menyimpan dan memuat progres akun secara terisolasi (per-account persistence)
class UserProgressService {
  static final Map<String, UserAccountProgress> _memoryCache = {};

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasData = prefs.containsKey('progress_${accountKey}_current_day');

      if (!hasData) {
        final fresh = UserAccountProgress(
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
        _memoryCache[accountKey] = fresh;
        return fresh;
      }

      final isPro = prefs.getBool('progress_${accountKey}_is_pro') ?? false;
      final defaultRestores = isPro ? 5 : 3;
      final defaultMaxMembers = isPro ? 10 : 4;

      final cooldownRaw = prefs.getString('progress_${accountKey}_cooldown_until');
      final cooldownUntil =
          cooldownRaw != null ? DateTime.tryParse(cooldownRaw) : null;

      final historyJson = prefs.getString('progress_${accountKey}_workout_history');
      final List<WorkoutHistoryEntry> history = _decodeHistory(historyJson);

      final loaded = UserAccountProgress(
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
        cooldownUntil: cooldownUntil,
        workoutHistory: history,
      );
      _memoryCache[accountKey] = loaded;
      return loaded;
    } catch (_) {
      return _memoryCache[accountKey] ?? UserAccountProgress(accountKey: accountKey);
    }
  }

  static List<WorkoutHistoryEntry> _decodeHistory(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => WorkoutHistoryEntry.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveProgress(UserAccountProgress progress) async {
    _memoryCache[progress.accountKey] = progress;
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

    if (progress.cooldownUntil != null) {
      await prefs.setString(
        'progress_${key}_cooldown_until',
        progress.cooldownUntil!.toIso8601String(),
      );
    } else {
      await prefs.remove('progress_${key}_cooldown_until');
    }

    await prefs.setString(
      'progress_${key}_workout_history',
      jsonEncode(progress.workoutHistory.map((e) => e.toJson()).toList()),
    );
  }
}
