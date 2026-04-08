/// 掼蛋牌型枚举
enum HandType {
  /// 单张
  single,

  /// 对子（两张同点数）
  pair,

  /// 三张（三张同点数）
  triple,

  /// 三带二（三张同点数 + 一对）
  triplePair,

  /// 顺子（5张及以上连续点数，A不延伸）
  straight,

  /// 连对（3对及以上连续点数的对子）
  consecutivePairs,

  /// 钢板（3组及以上连续点数的三张）
  steelPlate,

  /// 普通炸弹（4张及以上同点数，非级牌炸）
  bomb,

  /// 同花顺炸弹（5张及以上同花色连续点数）
  straightFlushBomb,

  /// 天王炸（两张大王）
  kingBomb,
}
