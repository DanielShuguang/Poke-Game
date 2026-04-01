import '../entities/pdk_card.dart';
import '../entities/pdk_hand_type.dart';

/// 验证连对（≥3 对连续）和飞机（≥2 组连续三张）
class ConsecutiveValidator {
  const ConsecutiveValidator();

  PdkPlayedHand? validate(List<PdkCard> cards) {
    if (cards.isEmpty) return null;

    final result = _validateConsecutivePairs(cards);
    if (result != null) return result;

    return _validateAirplane(cards);
  }

  PdkPlayedHand? _validateConsecutivePairs(List<PdkCard> cards) {
    if (cards.length < 6 || cards.length % 2 != 0) return null;
    final sorted = List.of(cards)..sort((a, b) => a.rank.index.compareTo(b.rank.index));

    if (sorted.any((c) => _isForbidden(c))) return null;

    // 每个点数恰好 2 张
    final groups = _groupByRank(sorted);
    if (groups.any((g) => g.length != 2)) return null;

    // 点数连续
    for (int i = 1; i < groups.length; i++) {
      if (groups[i][0].rank.index != groups[i - 1][0].rank.index + 1) {
        return null;
      }
    }

    if (groups.length < 3) return null;

    return PdkPlayedHand(
      type: PdkHandType.consecutivePairs,
      cards: sorted,
      keyCard: groups.last.reduce((a, b) => a.compareTo(b) > 0 ? a : b),
    );
  }

  PdkPlayedHand? _validateAirplane(List<PdkCard> cards) {
    if (cards.length < 6 || cards.length % 3 != 0) return null;
    final sorted = List.of(cards)..sort((a, b) => a.rank.index.compareTo(b.rank.index));

    if (sorted.any((c) => _isForbidden(c))) return null;

    final groups = _groupByRank(sorted);
    if (groups.any((g) => g.length != 3)) return null;

    for (int i = 1; i < groups.length; i++) {
      if (groups[i][0].rank.index != groups[i - 1][0].rank.index + 1) {
        return null;
      }
    }

    if (groups.length < 2) return null;

    return PdkPlayedHand(
      type: PdkHandType.airplane,
      cards: sorted,
      keyCard: groups.last.reduce((a, b) => a.compareTo(b) > 0 ? a : b),
    );
  }

  bool _isForbidden(PdkCard c) =>
      c.rank == PdkRank.two ||
      c.rank == PdkRank.jokerSmall ||
      c.rank == PdkRank.jokerBig;

  List<List<PdkCard>> _groupByRank(List<PdkCard> sorted) {
    final groups = <List<PdkCard>>[];
    for (final c in sorted) {
      if (groups.isEmpty || groups.last[0].rank != c.rank) {
        groups.add([c]);
      } else {
        groups.last.add(c);
      }
    }
    return groups;
  }
}
