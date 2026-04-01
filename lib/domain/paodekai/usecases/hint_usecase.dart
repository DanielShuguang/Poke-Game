import '../entities/pdk_card.dart';
import '../entities/pdk_hand_type.dart';
import 'hand_type_usecase.dart';
import 'compare_hands_usecase.dart';

/// 找当前手牌中最小合法出法，null 表示无解
class HintUseCase {
  const HintUseCase();

  static const _handType = HandTypeUseCase();
  static const _compare = CompareHandsUseCase();

  /// [hand] 玩家当前手牌，[lastPlayedHand] 上家出的牌（null 表示新一轮起手）
  /// 返回推荐的最小合法出牌组合，无解时返回 null
  List<PdkCard>? call({
    required List<PdkCard> hand,
    required PdkPlayedHand? lastPlayedHand,
  }) {
    if (hand.isEmpty) return null;
    final sorted = List.of(hand)..sort((a, b) => a.compareTo(b));

    if (lastPlayedHand == null) {
      return _findOpen(sorted);
    }
    return _findFollow(sorted, lastPlayedHand);
  }

  // ── 起手方：优先孤立单张，再考虑炸弹/王炸 ──────────────────────────────────

  List<PdkCard>? _findOpen(List<PdkCard> sorted) {
    final groups = _groupByRank(sorted);

    // 孤立单张（不是对子/三张/炸弹的一部分，且不是王）
    for (final g in groups) {
      if (g.length == 1 &&
          g[0].rank != PdkRank.jokerSmall &&
          g[0].rank != PdkRank.jokerBig) {
        return [g[0]];
      }
    }

    // 最小对子
    for (final g in groups) {
      if (g.length == 2) return g.sublist(0, 2);
    }

    // 最小三张
    for (final g in groups) {
      if (g.length == 3) return g.sublist(0, 3);
    }

    // 炸弹
    final bomb = _findBomb(sorted);
    if (bomb != null) return bomb;

    // 王炸
    return _findRocket(sorted);
  }

  // ── 跟牌方 ────────────────────────────────────────────────────────────────

  List<PdkCard>? _findFollow(List<PdkCard> sorted, PdkPlayedHand last) {
    // 先找同型最小能压过的组合
    final candidate = _findSmallestBeating(sorted, last);
    if (candidate != null) return candidate;

    // 炸弹压制
    final bomb = _findBomb(sorted);
    if (bomb != null) {
      final bh = _handType(bomb);
      if (bh != null && _compare(bh, last)) return bomb;
    }

    // 王炸
    final rocket = _findRocket(sorted);
    if (rocket != null) {
      final rh = _handType(rocket);
      if (rh != null && _compare(rh, last)) return rocket;
    }

    return null;
  }

  List<PdkCard>? _findSmallestBeating(List<PdkCard> sorted, PdkPlayedHand last) {
    final n = last.length;
    final type = last.type;

    if (type == PdkHandType.single) {
      for (final c in sorted) {
        final h = _handType([c]);
        if (h != null && _compare(h, last)) return [c];
      }
    } else if (type == PdkHandType.pair) {
      return _findSmallestGroupBeating(sorted, last, 2);
    } else if (type == PdkHandType.triple) {
      return _findSmallestGroupBeating(sorted, last, 3);
    } else if (type == PdkHandType.straight) {
      return _findSmallestStraightBeating(sorted, last, n);
    } else if (type == PdkHandType.consecutivePairs) {
      return _findSmallestGroupBeating(sorted, last, n);
    } else if (type == PdkHandType.airplane) {
      return _findSmallestGroupBeating(sorted, last, n);
    }
    return null;
  }

  List<PdkCard>? _findSmallestGroupBeating(
    List<PdkCard> sorted,
    PdkPlayedHand last,
    int count,
  ) {
    final groups = _groupByRank(sorted);
    for (final g in groups) {
      if (g.length == count) {
        final h = _handType(g);
        if (h != null && _compare(h, last)) return g;
      }
    }
    return null;
  }

  List<PdkCard>? _findSmallestStraightBeating(
    List<PdkCard> sorted,
    PdkPlayedHand last,
    int n,
  ) {
    for (int i = 0; i <= sorted.length - n; i++) {
      final candidate = sorted.sublist(i, i + n);
      final h = _handType(candidate);
      if (h != null && h.type == PdkHandType.straight && _compare(h, last)) {
        return candidate;
      }
    }
    return null;
  }

  List<PdkCard>? _findBomb(List<PdkCard> sorted) {
    final groups = _groupByRank(sorted);
    for (final g in groups) {
      if (g.length == 4) return g;
    }
    return null;
  }

  List<PdkCard>? _findRocket(List<PdkCard> sorted) {
    final hasSmall = sorted.any((c) => c.rank == PdkRank.jokerSmall);
    final hasBig = sorted.any((c) => c.rank == PdkRank.jokerBig);
    if (!hasSmall || !hasBig) return null;
    return [
      sorted.firstWhere((c) => c.rank == PdkRank.jokerSmall),
      sorted.firstWhere((c) => c.rank == PdkRank.jokerBig),
    ];
  }

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
