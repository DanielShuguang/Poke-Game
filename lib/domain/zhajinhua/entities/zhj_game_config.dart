/// 炸金花游戏配置
class ZhjGameConfig {
  /// 玩家数量（含人类，2-5）
  final int playerCount;

  /// 每人初始筹码
  final int initialChips;

  /// 底注（每局开始每人缴纳）
  final int baseBet;

  /// 看牌后跟注倍率（默认2，即看牌玩家跟注金额 = 当前底注 × blindBetMultiplier）
  final int blindBetMultiplier;

  /// AI 思考延迟范围（毫秒）
  final int aiMinDelayMs;
  final int aiMaxDelayMs;

  const ZhjGameConfig({
    this.playerCount = 4,
    this.initialChips = 1000,
    this.baseBet = 10,
    this.blindBetMultiplier = 2,
    this.aiMinDelayMs = 500,
    this.aiMaxDelayMs = 1200,
  });

  static const ZhjGameConfig defaultConfig = ZhjGameConfig();

  ZhjGameConfig copyWith({
    int? playerCount,
    int? initialChips,
    int? baseBet,
    int? blindBetMultiplier,
    int? aiMinDelayMs,
    int? aiMaxDelayMs,
  }) {
    return ZhjGameConfig(
      playerCount: playerCount ?? this.playerCount,
      initialChips: initialChips ?? this.initialChips,
      baseBet: baseBet ?? this.baseBet,
      blindBetMultiplier: blindBetMultiplier ?? this.blindBetMultiplier,
      aiMinDelayMs: aiMinDelayMs ?? this.aiMinDelayMs,
      aiMaxDelayMs: aiMaxDelayMs ?? this.aiMaxDelayMs,
    );
  }
}
