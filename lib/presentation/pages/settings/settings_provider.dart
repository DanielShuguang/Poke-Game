import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式
enum ThemeModeSetting {
  /// 跟随系统
  system,
  /// 浅色模式
  light,
  /// 深色模式
  dark,
}

/// 设置状态
class SettingsState {
  /// 音效开关
  final bool soundEnabled;

  /// 背景音乐开关
  final bool musicEnabled;

  /// 振动反馈开关
  final bool vibrationEnabled;

  /// 主题模式
  final ThemeModeSetting themeMode;

  /// 语言代码
  final String languageCode;

  /// 玩家昵称
  final String playerName;

  /// 玩家头像索引
  final int avatarIndex;

  const SettingsState({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
    this.themeMode = ThemeModeSetting.system,
    this.languageCode = 'zh',
    this.playerName = '玩家',
    this.avatarIndex = 0,
  });

  /// 是否为深色模式（用于 UI 显示）
  bool get isDarkMode => themeMode == ThemeModeSetting.dark;

  /// 是否跟随系统
  bool get isSystemMode => themeMode == ThemeModeSetting.system;

  SettingsState copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? vibrationEnabled,
    ThemeModeSetting? themeMode,
    String? languageCode,
    String? playerName,
    int? avatarIndex,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      playerName: playerName ?? this.playerName,
      avatarIndex: avatarIndex ?? this.avatarIndex,
    );
  }
}

/// 设置状态管理器
class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _keySound = 'settings_sound';
  static const String _keyMusic = 'settings_music';
  static const String _keyVibration = 'settings_vibration';
  static const String _keyThemeMode = 'settings_theme_mode';
  static const String _keyLanguage = 'settings_language';
  static const String _keyPlayerName = 'settings_player_name';
  static const String _keyAvatarIndex = 'settings_avatar_index';

  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs) : super(const SettingsState()) {
    _loadSettings();
  }

  /// 从本地存储加载设置
  void _loadSettings() {
    final themeModeString = _prefs.getString(_keyThemeMode) ?? 'system';
    final themeMode = ThemeModeSetting.values.firstWhere(
      (e) => e.name == themeModeString,
      orElse: () => ThemeModeSetting.system,
    );

    state = SettingsState(
      soundEnabled: _prefs.getBool(_keySound) ?? true,
      musicEnabled: _prefs.getBool(_keyMusic) ?? true,
      vibrationEnabled: _prefs.getBool(_keyVibration) ?? true,
      themeMode: themeMode,
      languageCode: _prefs.getString(_keyLanguage) ?? 'zh',
      playerName: _prefs.getString(_keyPlayerName) ?? '玩家',
      avatarIndex: _prefs.getInt(_keyAvatarIndex) ?? 0,
    );
  }

  /// 切换音效
  Future<void> toggleSound() async {
    final newValue = !state.soundEnabled;
    await _prefs.setBool(_keySound, newValue);
    state = state.copyWith(soundEnabled: newValue);
  }

  /// 切换背景音乐
  Future<void> toggleMusic() async {
    final newValue = !state.musicEnabled;
    await _prefs.setBool(_keyMusic, newValue);
    state = state.copyWith(musicEnabled: newValue);
  }

  /// 切换振动反馈
  Future<void> toggleVibration() async {
    final newValue = !state.vibrationEnabled;
    await _prefs.setBool(_keyVibration, newValue);
    state = state.copyWith(vibrationEnabled: newValue);
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeModeSetting mode) async {
    await _prefs.setString(_keyThemeMode, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  /// 设置语言
  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(_keyLanguage, languageCode);
    state = state.copyWith(languageCode: languageCode);
  }

  /// 设置玩家昵称
  Future<void> setPlayerName(String name) async {
    await _prefs.setString(_keyPlayerName, name);
    state = state.copyWith(playerName: name);
  }

  /// 设置头像索引
  Future<void> setAvatarIndex(int index) async {
    await _prefs.setInt(_keyAvatarIndex, index);
    state = state.copyWith(avatarIndex: index);
  }

  /// 重置所有设置
  Future<void> resetSettings() async {
    await _prefs.clear();
    state = const SettingsState();
  }
}

/// SharedPreferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// 设置 Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
