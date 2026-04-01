class CalculateScoreUseCase {
  const CalculateScoreUseCase();

  /// 返回 playerId → 积分变化 的 Map
  /// rankings 按出完顺序排列（第 0 名为头游）
  Map<String, int> call(List<String> rankings) {
    assert(rankings.length == 3);
    return {
      rankings[0]: 2,  // 头游 +2
      rankings[1]: 0,  // 二游 +0
      rankings[2]: -2, // 末游 -2
    };
  }
}
