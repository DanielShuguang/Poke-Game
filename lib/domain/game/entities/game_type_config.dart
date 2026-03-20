import 'package:poke_game/domain/lan/entities/room_info.dart';

/// 游戏类型配置
class GameTypeConfig {
  /// 游戏类型
  final GameType gameType;

  /// 显示名称
  final String displayName;

  /// 图标路径
  final String iconPath;

  /// 描述
  final String description;

  /// 是否可用
  final bool isAvailable;

  /// 固定人数（null 表示可配置）
  final int? fixedPlayerCount;

  /// 最小人数
  final int minPlayerCount;

  /// 最大人数
  final int maxPlayerCount;

  /// 预计游戏时长（分钟）
  final int estimatedDuration;

  /// 游戏规则配置项
  final List<GameConfigOption> configOptions;

  const GameTypeConfig({
    required this.gameType,
    required this.displayName,
    required this.iconPath,
    required this.description,
    required this.isAvailable,
    this.fixedPlayerCount,
    required this.minPlayerCount,
    required this.maxPlayerCount,
    required this.estimatedDuration,
    this.configOptions = const [],
  });

  /// 是否支持人数配置
  bool get supportsPlayerCountConfig => fixedPlayerCount == null;

  /// 获取默认配置
  Map<String, dynamic> get defaultConfig {
    final config = <String, dynamic>{};
    for (final option in configOptions) {
      config[option.key] = option.defaultValue;
    }
    return config;
  }
}

/// 游戏配置选项
class GameConfigOption {
  /// 配置键
  final String key;

  /// 显示名称
  final String displayName;

  /// 描述
  final String? description;

  /// 配置类型
  final GameConfigType type;

  /// 默认值
  final dynamic defaultValue;

  /// 可选值（用于枚举类型）
  final List<GameConfigOptionValue>? options;

  /// 最小值（用于数值类型）
  final num? minValue;

  /// 最大值（用于数值类型）
  final num? maxValue;

  const GameConfigOption({
    required this.key,
    required this.displayName,
    this.description,
    required this.type,
    required this.defaultValue,
    this.options,
    this.minValue,
    this.maxValue,
  });
}

/// 游戏配置类型
enum GameConfigType {
  /// 布尔值
  boolean,

  /// 数值
  number,

  /// 枚举选择
  enumeration,

  /// 文本
  text,
}

/// 游戏配置选项值
class GameConfigOptionValue {
  /// 值
  final dynamic value;

  /// 显示名称
  final String displayName;

  /// 描述
  final String? description;

  const GameConfigOptionValue({
    required this.value,
    required this.displayName,
    this.description,
  });
}

/// 游戏类型配置注册表
class GameTypeRegistry {
  /// 所有游戏配置
  static const Map<GameType, GameTypeConfig> configs = {
    GameType.doudizhu: GameTypeConfig(
      gameType: GameType.doudizhu,
      displayName: '斗地主',
      iconPath: 'assets/icons/doudizhu.png',
      description: '经典三人扑克游戏，地主对战两个农民',
      isAvailable: true,
      fixedPlayerCount: 3,
      minPlayerCount: 3,
      maxPlayerCount: 3,
      estimatedDuration: 15,
      configOptions: [
        GameConfigOption(
          key: 'allowMingPai',
          displayName: '允许明牌',
          description: '地主可以选择明牌，增加倍数',
          type: GameConfigType.boolean,
          defaultValue: false,
        ),
        GameConfigOption(
          key: 'baseMultiplier',
          displayName: '底分倍数',
          type: GameConfigType.enumeration,
          defaultValue: 1,
          options: [
            GameConfigOptionValue(value: 1, displayName: '1倍'),
            GameConfigOptionValue(value: 2, displayName: '2倍'),
            GameConfigOptionValue(value: 3, displayName: '3倍'),
          ],
        ),
      ],
    ),
    GameType.texasHoldem: GameTypeConfig(
      gameType: GameType.texasHoldem,
      displayName: '德州扑克',
      iconPath: 'assets/icons/texas_holdem.png',
      description: '流行的公牌扑克游戏',
      isAvailable: false,
      minPlayerCount: 2,
      maxPlayerCount: 9,
      estimatedDuration: 30,
      configOptions: [
        GameConfigOption(
          key: 'initialChips',
          displayName: '初始筹码',
          type: GameConfigType.number,
          defaultValue: 1000,
          minValue: 100,
          maxValue: 10000,
        ),
        GameConfigOption(
          key: 'smallBlind',
          displayName: '小盲注',
          type: GameConfigType.number,
          defaultValue: 10,
          minValue: 1,
          maxValue: 100,
        ),
      ],
    ),
    GameType.zhajinhua: GameTypeConfig(
      gameType: GameType.zhajinhua,
      displayName: '炸金花',
      iconPath: 'assets/icons/zhajinhua.png',
      description: '经典三张牌比大小游戏',
      isAvailable: false,
      minPlayerCount: 2,
      maxPlayerCount: 6,
      estimatedDuration: 20,
      configOptions: [
        GameConfigOption(
          key: 'initialChips',
          displayName: '初始筹码',
          type: GameConfigType.number,
          defaultValue: 500,
          minValue: 100,
          maxValue: 5000,
        ),
      ],
    ),
  };

  /// 获取游戏配置
  static GameTypeConfig? getConfig(GameType gameType) {
    return configs[gameType];
  }

  /// 获取所有可用的游戏类型
  static List<GameTypeConfig> getAvailableGames() {
    return configs.values.where((c) => c.isAvailable).toList();
  }

  /// 获取所有游戏类型（包括未开放的）
  static List<GameTypeConfig> getAllGames() {
    return configs.values.toList();
  }
}
