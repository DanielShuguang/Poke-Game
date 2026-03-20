import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/domain/game/entities/game_type_config.dart';
import 'package:poke_game/domain/lan/entities/room_info.dart';

/// 游戏选择状态
class GameSelectionState {
  /// 当前选中的游戏类型
  final GameType? selectedGameType;

  /// 游戏配置
  final Map<String, dynamic> gameConfig;

  /// 人数配置（仅在支持自定义人数时使用）
  final int? playerCount;

  /// 验证错误信息
  final String? errorMessage;

  const GameSelectionState({
    this.selectedGameType,
    this.gameConfig = const {},
    this.playerCount,
    this.errorMessage,
  });

  /// 获取游戏配置
  GameTypeConfig? get gameTypeConfig {
    if (selectedGameType == null) return null;
    return GameTypeRegistry.getConfig(selectedGameType!);
  }

  /// 是否有效
  bool get isValid => errorMessage == null && selectedGameType != null;

  /// 获取实际玩家数
  int get actualPlayerCount {
    final config = gameTypeConfig;
    if (config == null) return 0;

    if (config.fixedPlayerCount != null) {
      return config.fixedPlayerCount!;
    }

    return playerCount ?? config.minPlayerCount;
  }

  GameSelectionState copyWith({
    GameType? selectedGameType,
    Map<String, dynamic>? gameConfig,
    int? playerCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GameSelectionState(
      selectedGameType: selectedGameType ?? this.selectedGameType,
      gameConfig: gameConfig ?? this.gameConfig,
      playerCount: playerCount ?? this.playerCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 游戏选择 Notifier
class GameSelectionNotifier extends StateNotifier<GameSelectionState> {
  GameSelectionNotifier() : super(const GameSelectionState());

  /// 选择游戏类型
  void selectGameType(GameType gameType) {
    final config = GameTypeRegistry.getConfig(gameType);
    if (config == null) {
      state = state.copyWith(
        errorMessage: '游戏类型不存在',
        clearError: false,
      );
      return;
    }

    if (!config.isAvailable) {
      state = state.copyWith(
        errorMessage: '${config.displayName}暂未开放，敬请期待',
        clearError: false,
      );
      return;
    }

    // 更新状态
    state = GameSelectionState(
      selectedGameType: gameType,
      gameConfig: config.defaultConfig,
      playerCount: config.fixedPlayerCount ?? config.minPlayerCount,
    );
  }

  /// 更新游戏配置
  void updateConfig(String key, dynamic value) {
    if (state.selectedGameType == null) return;

    final newConfig = Map<String, dynamic>.from(state.gameConfig);
    newConfig[key] = value;

    state = state.copyWith(gameConfig: newConfig);
  }

  /// 更新玩家数（仅当游戏支持自定义人数时）
  void updatePlayerCount(int count) {
    final config = state.gameTypeConfig;
    if (config == null || config.fixedPlayerCount != null) return;

    // 验证人数范围
    if (count < config.minPlayerCount || count > config.maxPlayerCount) {
      state = state.copyWith(
        errorMessage: '人数必须在 ${config.minPlayerCount} 到 ${config.maxPlayerCount} 之间',
      );
      return;
    }

    state = state.copyWith(
      playerCount: count,
      clearError: true,
    );
  }

  /// 验证当前选择
  bool validate() {
    if (state.selectedGameType == null) {
      state = state.copyWith(errorMessage: '请选择游戏类型');
      return false;
    }

    final config = state.gameTypeConfig;
    if (config == null) {
      state = state.copyWith(errorMessage: '游戏配置无效');
      return false;
    }

    if (!config.isAvailable) {
      state = state.copyWith(errorMessage: '该游戏暂未开放');
      return false;
    }

    // 验证人数
    final playerCount = state.actualPlayerCount;
    if (playerCount < config.minPlayerCount || playerCount > config.maxPlayerCount) {
      state = state.copyWith(errorMessage: '人数配置无效');
      return false;
    }

    state = state.copyWith(clearError: true);
    return true;
  }

  /// 重置选择
  void reset() {
    state = const GameSelectionState();
  }
}

/// 游戏选择 Provider
final gameSelectionProvider =
    StateNotifierProvider<GameSelectionNotifier, GameSelectionState>((ref) {
  return GameSelectionNotifier();
});

/// 可用游戏列表 Provider
final availableGamesProvider = Provider<List<GameTypeConfig>>((ref) {
  return GameTypeRegistry.getAvailableGames();
});

/// 所有游戏列表 Provider
final allGamesProvider = Provider<List<GameTypeConfig>>((ref) {
  return GameTypeRegistry.getAllGames();
});
