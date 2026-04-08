import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poke_game/presentation/pages/settings/settings_provider.dart';

void main() {
  group('SettingsNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<SettingsNotifier> makeNotifier([Map<String, Object>? initial]) async {
      if (initial != null) {
        SharedPreferences.setMockInitialValues(initial);
      }
      final prefs = await SharedPreferences.getInstance();
      return SettingsNotifier(prefs);
    }

    // ── 默认值 ─────────────────────────────────────────────────────────────────

    test('默认玩家昵称为 "玩家"', () async {
      final notifier = await makeNotifier();
      expect(notifier.state.playerName, '玩家');
    });

    test('默认头像索引为 0', () async {
      final notifier = await makeNotifier();
      expect(notifier.state.avatarIndex, 0);
    });

    // ── setPlayerName ──────────────────────────────────────────────────────────

    test('setPlayerName 更新 state.playerName', () async {
      final notifier = await makeNotifier();
      await notifier.setPlayerName('Alice');
      expect(notifier.state.playerName, 'Alice');
    });

    test('setPlayerName 将昵称持久化到 SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = SettingsNotifier(prefs);
      await notifier.setPlayerName('Bob');

      // 读取同一个 prefs 实例验证持久化
      expect(prefs.getString('settings_player_name'), 'Bob');
    });

    test('setPlayerName 不影响其他设置', () async {
      final notifier = await makeNotifier();
      await notifier.setAvatarIndex(2);
      await notifier.setPlayerName('Charlie');
      expect(notifier.state.avatarIndex, 2);
    });

    // ── setAvatarIndex ─────────────────────────────────────────────────────────

    test('setAvatarIndex 更新 state.avatarIndex', () async {
      final notifier = await makeNotifier();
      await notifier.setAvatarIndex(3);
      expect(notifier.state.avatarIndex, 3);
    });

    test('setAvatarIndex 将索引持久化到 SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = SettingsNotifier(prefs);
      await notifier.setAvatarIndex(5);

      expect(prefs.getInt('settings_avatar_index'), 5);
    });

    test('setAvatarIndex 不影响其他设置', () async {
      final notifier = await makeNotifier();
      await notifier.setPlayerName('Dave');
      await notifier.setAvatarIndex(4);
      expect(notifier.state.playerName, 'Dave');
    });

    // ── 从 SharedPreferences 加载 ──────────────────────────────────────────────

    test('已有持久化昵称时构造时自动加载', () async {
      final notifier = await makeNotifier({
        'settings_player_name': 'Eve',
      });
      expect(notifier.state.playerName, 'Eve');
    });

    test('已有持久化头像索引时构造时自动加载', () async {
      final notifier = await makeNotifier({
        'settings_avatar_index': 7,
      });
      expect(notifier.state.avatarIndex, 7);
    });

    test('同时持久化昵称和头像索引时均可正确加载', () async {
      final notifier = await makeNotifier({
        'settings_player_name': 'Frank',
        'settings_avatar_index': 2,
      });
      expect(notifier.state.playerName, 'Frank');
      expect(notifier.state.avatarIndex, 2);
    });

    // ── resetSettings ──────────────────────────────────────────────────────────

    test('resetSettings 恢复昵称为默认值', () async {
      final notifier = await makeNotifier();
      await notifier.setPlayerName('Grace');
      await notifier.resetSettings();
      expect(notifier.state.playerName, '玩家');
    });

    test('resetSettings 恢复头像索引为默认值', () async {
      final notifier = await makeNotifier();
      await notifier.setAvatarIndex(6);
      await notifier.resetSettings();
      expect(notifier.state.avatarIndex, 0);
    });

    test('resetSettings 清除 SharedPreferences 中的昵称', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = SettingsNotifier(prefs);
      await notifier.setPlayerName('Henry');
      await notifier.resetSettings();
      expect(prefs.getString('settings_player_name'), isNull);
    });
  });
}
