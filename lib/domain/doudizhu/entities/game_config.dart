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

  /// 是否为人机对战模式
  /// - 人机模式：玩家选择"不叫"后，最后一个AI必须叫地主
  /// - 非人机模式：所有玩家都可以选择"不叫"，全部不叫时重新发牌
  final bool isHumanVsAi;

  const GameConfig({
    this.playerCount = 3,
    this.landlordCardCount = 3,
    this.initialCardCount = 17,
    this.aiThinkDelayMs = 1500,
    this.isHumanVsAi = true,
  });

  /// 默认配置（人机对战模式）
  static const GameConfig defaultConfig = GameConfig();
}
