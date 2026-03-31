import 'package:poke_game/domain/shengji/entities/shengji_card.dart';

/// 计分用例
class CalculateScoreUseCase {
  /// 分值牌得分
  static const int _score5 = 5;
  static const int _score10 = 10;
  static const int _scoreK = 10;

  /// 计算一组牌的总分
  int calculateScore(List<ShengjiCard> cards) {
    int score = 0;
    for (final card in cards) {
      if (card.rank == 5) score += _score5;
      if (card.rank == 10) score += _score10;
      if (card.rank == 13) score += _scoreK; // K
    }
    return score;
  }

  /// 计算一轮出牌的得分
  int calculateRoundScore(Map<int, List<ShengjiCard>> plays) {
    int score = 0;
    for (final cards in plays.values) {
      score += calculateScore(cards);
    }
    return score;
  }

  /// 获取总分（两副牌共 200 分）
  int get totalScore => 200;
}
