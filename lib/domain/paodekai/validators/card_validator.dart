import '../entities/pdk_card.dart';
import '../entities/pdk_hand_type.dart';

/// 验证简单牌型：单/对/三/炸/王炸
class CardValidator {
  const CardValidator();

  PdkPlayedHand? validate(List<PdkCard> cards) {
    if (cards.isEmpty) return null;
    final sorted = List.of(cards)..sort((a, b) => a.compareTo(b));
    final n = sorted.length;

    // 王炸
    if (n == 2 &&
        sorted[0].rank == PdkRank.jokerSmall &&
        sorted[1].rank == PdkRank.jokerBig) {
      return PdkPlayedHand(
        type: PdkHandType.rocket,
        cards: sorted,
        keyCard: sorted[1],
      );
    }

    // 炸弹
    if (n == 4 && _allSameRank(sorted)) {
      return PdkPlayedHand(
        type: PdkHandType.bomb,
        cards: sorted,
        keyCard: sorted.reduce((a, b) => a.compareTo(b) > 0 ? a : b),
      );
    }

    // 单张
    if (n == 1) {
      return PdkPlayedHand(
        type: PdkHandType.single,
        cards: sorted,
        keyCard: sorted[0],
      );
    }

    // 对子
    if (n == 2 && _allSameRank(sorted)) {
      return PdkPlayedHand(
        type: PdkHandType.pair,
        cards: sorted,
        keyCard: sorted.reduce((a, b) => a.compareTo(b) > 0 ? a : b),
      );
    }

    // 三张
    if (n == 3 && _allSameRank(sorted)) {
      return PdkPlayedHand(
        type: PdkHandType.triple,
        cards: sorted,
        keyCard: sorted.reduce((a, b) => a.compareTo(b) > 0 ? a : b),
      );
    }

    return null;
  }

  bool _allSameRank(List<PdkCard> cards) {
    final r = cards[0].rank;
    return cards.every((c) => c.rank == r);
  }
}
