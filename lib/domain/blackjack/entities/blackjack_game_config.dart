/// 21点游戏配置
class BlackjackGameConfig {
  /// 牌堆副数（标准使用6副）
  final int deckCount;

  /// 初始筹码
  final int initialChips;

  /// 是否启用五小龙（5张不爆自动赢）
  final bool fiveCardCharlie;

  /// 庄家 Soft 17 是否摸牌（true=摸，false=停）
  final bool dealerHitSoft17;

  /// AI 庄家摸牌间隔（毫秒，用于 UI 动画）
  final int dealerDelayMs;

  const BlackjackGameConfig({
    this.deckCount = 6,
    this.initialChips = 1000,
    this.fiveCardCharlie = false,
    this.dealerHitSoft17 = false,
    this.dealerDelayMs = 600,
  });

  static const BlackjackGameConfig defaultConfig = BlackjackGameConfig();

  BlackjackGameConfig copyWith({
    int? deckCount,
    int? initialChips,
    bool? fiveCardCharlie,
    bool? dealerHitSoft17,
    int? dealerDelayMs,
  }) {
    return BlackjackGameConfig(
      deckCount: deckCount ?? this.deckCount,
      initialChips: initialChips ?? this.initialChips,
      fiveCardCharlie: fiveCardCharlie ?? this.fiveCardCharlie,
      dealerHitSoft17: dealerHitSoft17 ?? this.dealerHitSoft17,
      dealerDelayMs: dealerDelayMs ?? this.dealerDelayMs,
    );
  }
}
