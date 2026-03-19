/// 游戏配置
class GameConfig {
  /// 玩家数量
  final int playerCount;

  /// 底牌数量
  final int landlordCardCount;

  /// 每人初始手牌数量
  final int initialCardCount;

  /// AI 思考延迟（毫秒）
  final int aiThinkDelayMs;

  const GameConfig({
    this.playerCount = 3,
    this.landlordCardCount = 3,
    this.initialCardCount = 17,
    this.aiThinkDelayMs = 1500,
  });

  /// 默认配置
  static const GameConfig defaultConfig = GameConfig();
}
