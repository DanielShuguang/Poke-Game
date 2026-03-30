/// 斗牛游戏配置
class NiuniuGameConfig {
  /// 使用几副标准牌
  final int deckCount;

  /// 初始筹码
  final int initialChips;

  /// AI 行动延迟（毫秒）
  final int aiDelayMs;

  const NiuniuGameConfig({
    this.deckCount = 6,
    this.initialChips = 1000,
    this.aiDelayMs = 400,
  });

  static const NiuniuGameConfig defaultConfig = NiuniuGameConfig();
}
