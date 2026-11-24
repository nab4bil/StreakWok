import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streakwok/core/services/user_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('New account starts fresh at Day 1 with 0 streak', () async {
    final accountKey = UserProgressService.getAccountKey(userName: 'Newbie User');
    final progress = await UserProgressService.loadProgress(accountKey);

    expect(progress.currentActiveDay, 1);
    expect(progress.streakDays, 0);
    expect(progress.isUserCompleted, false);
    expect(progress.hasGroup, false);
  });

  test('Display name registration supports natural human names and persists', () async {
    final newAccountKey = UserProgressService.getAccountKey(email: 'fresh_user@gmail.com');
    
    // 1. Akun baru: belum punya display name tersimpan
    final nameBefore = await UserProgressService.getSavedUsername(newAccountKey);
    expect(nameBefore, isNull);

    // 2. Akun mendaftar dengan display name natural (non-unique, ada spasi dan huruf besar)
    await UserProgressService.saveUsername(newAccountKey, 'Nabil Fikra');

    // 3. Setelah tersimpan: nama tersimpan persis sesuai pilihan pengguna
    final nameAfter = await UserProgressService.getSavedUsername(newAccountKey);
    expect(nameAfter, 'Nabil Fikra');
  });

  test('Progress is strictly isolated per account', () async {
    final keyUser1 = UserProgressService.getAccountKey(email: 'user1@gmail.com');
    final keyUser2 = UserProgressService.getAccountKey(email: 'user2@gmail.com');

    // User 1 finishes day 1 and advances to day 2 with streak 1
    final progress1 = UserAccountProgress(
      accountKey: keyUser1,
      currentActiveDay: 2,
      streakDays: 1,
      isUserCompleted: false,
      hasGroup: true,
      groupName: 'Keluarga Sehat',
    );
    await UserProgressService.saveProgress(progress1);

    // User 2 logs in for the first time
    final loadedUser2 = await UserProgressService.loadProgress(keyUser2);
    expect(loadedUser2.currentActiveDay, 1);
    expect(loadedUser2.streakDays, 0);
    expect(loadedUser2.hasGroup, false);

    // User 1 logs in again and retains day 2 and streak 1
    final loadedUser1 = await UserProgressService.loadProgress(keyUser1);
    expect(loadedUser1.currentActiveDay, 2);
    expect(loadedUser1.streakDays, 1);
    expect(loadedUser1.hasGroup, true);
    expect(loadedUser1.groupName, 'Keluarga Sehat');
  });

  test('Unregistered account returns null username', () async {
    final key = UserProgressService.getAccountKey(email: 'brand_new_user@gmail.com');
    final username = await UserProgressService.getSavedUsername(key);
    expect(username, isNull);
  });
}
