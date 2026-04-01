import 'dart:math';

import 'package:poke_game/domain/paodekai/entities/pdk_card.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_game_state.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_hand_type.dart';
import 'package:poke_game/domain/paodekai/usecases/compare_hands_usecase.dart';
import 'package:poke_game/domain/paodekai/usecases/hand_type_usecase.dart';

class PdkAiStrategy {
  const PdkAiStrategy();

  static const _handType = HandTypeUseCase();
  static const _compare = CompareHandsUseCase();

  /// 决策出牌，null 表示 pass
  Future<List<PdkCard>?> decidePlay(
    PdkGameState state,
    String playerId,
  ) async {
    final delay = 800 + Random().nextInt(700); // 800–1500ms
    await Future.delayed(Duration(milliseconds: delay));

    final pidx = state.players.indexWhere((p) => p.id == playerId);
    if (pidx == -1) return null;
    final hand = state.players[pidx].hand;
    if (hand.isEmpty) return null;

    // 首轮必须含 ♠3，直接出 ♠3 单张（避免 ♠3 在对子中时被跳过而死循环）
    if (state.isFirstPlay) {
      final spadeThree = hand.firstWhere(
        (c) => c.isSpadeThree,
        orElse: () => hand.first,
      );
      return [spadeThree];
    }

    final opponents = state.players.where((p) => p.id != playerId).toList();
    final opponentInDanger = opponents.any((p) => p.hand.length <= 3);

    // 起手方（新轮）
    if (state.lastPlayedHand == null) {
      return _decideOpen(hand, opponentInDanger);
    }

    // 跟牌方
    return _decideFollow(hand, state.lastPlayedHand!, opponentInDanger);
  }

  List<PdkCard>? _decideOpen(List<PdkCard> hand, bool danger) {
    final sorted = List.of(hand)..sort((a, b) => a.compareTo(b));

    // 危险时考虑炸弹
    if (danger) {
      final bomb = _findBomb(sorted);
      if (bomb != null) return bomb;
    }

    // 优先最小单张（非炸弹/王）
    final singles = _candidateSingles(sorted);
    if (singles.isNotEmpty) return [singles.first];

    // 最小对子
    final pair = _findSmallestPair(sorted);
    if (pair != null) return pair;

    // 最小三张
    final triple = _findSmallestTriple(sorted);
    if (triple != null) return triple;

    // 最小顺子
    final straight = _findSmallestStraight(sorted);
    if (straight != null) return straight;

    // 最后只剩炸弹
    final bomb = _findBomb(sorted);
    if (bomb != null) return bomb;

    // 王炸
    return _findRocket(sorted);
  }

  List<PdkCard>? _decideFollow(
    List<PdkCard> hand,
    PdkPlayedHand last,
    bool danger,
  ) {
    final sorted = List.of(hand)..sort((a, b) => a.compareTo(b));

    // 对手危险时先考虑炸弹/王炸
    if (danger) {
      final rocket = _findRocket(sorted);
      if (rocket != null) {
        final rh = _handType(rocket);
        if (rh != null && _compare(rh, last)) return rocket;
      }
      final bomb = _findBomb(sorted);
      if (bomb != null) {
        final bh = _handType(bomb);
        if (bh != null && _compare(bh, last)) return bomb;
      }
    }

    // 同型最小合法跟牌
    final candidate = _findSmallestBeating(sorted, last);
    if (candidate != null) return candidate;

    // 炸弹压制（非危险时也可用）
    final bomb = _findBomb(sorted);
    if (bomb != null) {
      final bh = _handType(bomb);
      if (bh != null && _compare(bh, last)) return bomb;
    }

    final rocket = _findRocket(sorted);
    if (rocket != null) return rocket;

    return null; // pass
  }

  // ── 辅助方法 ────────────────────────────────────────────────────────────

  List<PdkCard>? _findSmallestBeating(
    List<PdkCard> sorted,
    PdkPlayedHand last,
  ) {
    final n = last.length;
    final type = last.type;

    if (type == PdkHandType.single) {
      for (final c in sorted) {
        final h = _handType([c]);
        if (h != null && _compare(h, last)) return [c];
      }
    } else if (type == PdkHandType.pair) {
      return _findSmallestSameTypeBeating(sorted, last, 2);
    } else if (type == PdkHandType.triple) {
      return _findSmallestSameTypeBeating(sorted, last, 3);
    } else if (type == PdkHandType.straight) {
      return _findSmallestStraightBeating(sorted, last, n);
    } else if (type == PdkHandType.consecutivePairs) {
      return _findSmallestSameTypeBeating(sorted, last, n);
    } else if (type == PdkHandType.airplane) {
      return _findSmallestSameTypeBeating(sorted, last, n);
    }
    return null;
  }

  List<PdkCard>? _findSmallestSameTypeBeating(
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
    // 枚举所有可能的 n 张顺子
    for (int i = 0; i <= sorted.length - n; i++) {
      final candidate = sorted.sublist(i, i + n);
      final h = _handType(candidate);
      if (h != null && h.type == PdkHandType.straight && _compare(h, last)) {
        return candidate;
      }
    }
    return null;
  }

  List<PdkCard> _candidateSingles(List<PdkCard> sorted) {
    // 排除组成对子/三张/炸弹所需的牌，优先出孤立单张
    final groups = _groupByRank(sorted);
    final singles = <PdkCard>[];
    for (final g in groups) {
      if (g.length == 1 &&
          g[0].rank != PdkRank.jokerSmall &&
          g[0].rank != PdkRank.jokerBig) {
        singles.add(g[0]);
      }
    }
    return singles;
  }

  List<PdkCard>? _findSmallestPair(List<PdkCard> sorted) {
    final groups = _groupByRank(sorted);
    for (final g in groups) {
      if (g.length >= 2) return g.sublist(0, 2);
    }
    return null;
  }

  List<PdkCard>? _findSmallestTriple(List<PdkCard> sorted) {
    final groups = _groupByRank(sorted);
    for (final g in groups) {
      if (g.length >= 3) return g.sublist(0, 3);
    }
    return null;
  }

  List<PdkCard>? _findSmallestStraight(List<PdkCard> sorted) {
    if (sorted.length < 5) return null;
    for (int start = 0; start <= sorted.length - 5; start++) {
      final candidate = sorted.sublist(start, start + 5);
      final h = _handType(candidate);
      if (h != null && h.type == PdkHandType.straight) return candidate;
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
