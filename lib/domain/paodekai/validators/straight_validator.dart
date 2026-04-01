import '../entities/pdk_card.dart';
import '../entities/pdk_hand_type.dart';

/// 验证顺子（≥5 张连续单张，不含 2 和王）
class StraightValidator {
  const StraightValidator();

  PdkPlayedHand? validate(List<PdkCard> cards) {
    if (cards.length < 5) return null;
    final sorted = List.of(cards)..sort((a, b) => a.rank.index.compareTo(b.rank.index));

    // 不允许含 2 或 Joker
    if (sorted.any((c) => c.rank == PdkRank.two ||
        c.rank == PdkRank.jokerSmall ||
        c.rank == PdkRank.jokerBig)) {
      return null;
    }

    // 每个点数只能出现一次，且点数连续
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].rank.index != sorted[i - 1].rank.index + 1) return null;
      if (sorted[i].rank == sorted[i - 1].rank) return null;
    }

    return PdkPlayedHand(
      type: PdkHandType.straight,
      cards: sorted,
      keyCard: sorted.last, // 最大单张
    );
  }
}
