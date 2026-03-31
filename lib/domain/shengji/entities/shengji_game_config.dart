/// AI 难度
enum AiDifficulty {
  /// 简单（随机出牌）
  easy,

  /// 普通（基本策略）
  normal,
}

/// 升级游戏配置
class ShengjiGameConfig {
  /// 初始级别（默认 2）
  final int initialLevel;

  /// AI 难度
  final AiDifficulty aiDifficulty;

  /// 是否启用超时托管
  final bool enableTimeout;

  /// 超时秒数
  final int timeoutSeconds;

  const ShengjiGameConfig({
    this.initialLevel = 2,
    this.aiDifficulty = AiDifficulty.normal,
    this.enableTimeout = true,
    this.timeoutSeconds = 35,
  });

  /// 默认配置
  static const ShengjiGameConfig defaultConfig = ShengjiGameConfig();

  /// 单机模式配置（3 个 AI）
  static const ShengjiGameConfig singlePlayer = ShengjiGameConfig(
    aiDifficulty: AiDifficulty.normal,
  );

  /// 复制并修改
  ShengjiGameConfig copyWith({
    int? initialLevel,
    AiDifficulty? aiDifficulty,
    bool? enableTimeout,
    int? timeoutSeconds,
  }) {
    return ShengjiGameConfig(
      initialLevel: initialLevel ?? this.initialLevel,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      enableTimeout: enableTimeout ?? this.enableTimeout,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    );
  }
}
