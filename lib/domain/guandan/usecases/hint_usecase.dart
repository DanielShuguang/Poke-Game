import '../entities/guandan_card.dart';
import '../entities/guandan_hand.dart';
import 'validate_hand_usecase.dart';

/// 出牌提示：返回玩家手牌中所有能压制场上牌型的最小合法组合
class HintUsecase {
  const HintUsecase._();

  /// [hand] 玩家手牌，[lastPlayed] 场上最后一手牌（null 表示首出），[level] 当前级牌
  /// 返回所有合法可出的牌组列表（按"消耗成本"从小到大排列）
  static List<List<GuandanCard>> hint(
    List<GuandanCard> hand,
    GuandanHand? lastPlayed,
    int level,
  ) {
    final all = _enumerateCombinations(hand, level);

    if (lastPlayed == null) {
      all.sort((a, b) => a.rank.compareTo(b.rank));
      return all.map((h) => h.cards).toList();
    }

    final valid = all.where((h) => h.beats(lastPlayed, level)).toList();
    valid.sort((a, b) {
      final ap = a.bombPriority(level);
      final bp = b.bombPriority(level);
      if (ap != bp) return ap.compareTo(bp);
      return a.rank.compareTo(b.rank);
    });
    return valid.map((h) => h.cards).toList();
  }

  // ────────────────────────────────────────────────────────────────
  // 按牌型枚举（O(n²)，不做全子集枚举）
  // ────────────────────────────────────────────────────────────────

  static List<GuandanHand> _enumerateCombinations(
      List<GuandanCard> hand, int level) {
    if (hand.isEmpty) return [];

    final results = <GuandanHand>[];

    final bigJokers = hand.where((c) => c.isBigJoker).toList();
    final smallJokers = hand.where((c) => c.isSmallJoker).toList();
    final wilds = hand.where((c) => !c.isJoker && c.rank == level).toList();
    final normals = hand.where((c) => !c.isJoker && c.rank != level).toList();

    final byRank = <int, List<GuandanCard>>{};
    for (final card in normals) {
      byRank.putIfAbsent(card.rank!, () => []).add(card);
    }
    final sortedRanks = byRank.keys.toList()..sort();
    final wildCount = wilds.length;

    void tryAdd(List<GuandanCard> cards) {
      final h = ValidateHandUsecase.validate(cards, level);
      if (h != null) results.add(h);
    }

    // 天王炸
    if (bigJokers.length >= 2) tryAdd([bigJokers[0], bigJokers[1]]);

    // 单张
    for (final card in hand) {
      tryAdd([card]);
    }

    // 小王对
    if (smallJokers.length >= 2) tryAdd([smallJokers[0], smallJokers[1]]);

    // 对子（同点数 / 一正一野）
    for (final rank in sortedRanks) {
      final cards = byRank[rank]!;
      if (cards.length >= 2) tryAdd([cards[0], cards[1]]);
      if (cards.isNotEmpty && wildCount >= 1) tryAdd([cards[0], wilds[0]]);
    }

    // 三张
    for (final rank in sortedRanks) {
      final cards = byRank[rank]!;
      final available = cards.length.clamp(0, 3);
      final needed = 3 - available;
      if (needed <= wildCount) {
        tryAdd([...cards.sublist(0, available), ...wilds.sublist(0, needed)]);
      }
    }

    // 炸弹（4张及以上同点数，无大小王）
    for (final rank in sortedRanks) {
      final cards = byRank[rank]!;
      for (int size = 4; size <= cards.length; size++) {
        tryAdd(cards.sublist(0, size));
      }
    }

    // 级牌炸（4张及以上级牌）
    for (int size = 4; size <= wildCount; size++) {
      tryAdd(wilds.sublist(0, size));
    }

    // 三带二
    _addTriplePairs(tryAdd, sortedRanks, byRank, smallJokers, wilds, wildCount);

    // 顺子（5张及以上连续点数）
    _addStraights(tryAdd, sortedRanks, byRank, wilds, wildCount);

    // 连对（6张及以上连续对子）
    _addConsecutivePairs(tryAdd, sortedRanks, byRank, wilds, wildCount);

    // 钢板（6张及以上连续三张）
    _addSteelPlates(tryAdd, sortedRanks, byRank, wilds, wildCount);

    // 同花顺炸弹
    _addStraightFlushBombs(tryAdd, hand);

    return results;
  }

  // ────────────────────────────────────────────────────────────────
  // 三带二
  // ────────────────────────────────────────────────────────────────

  static void _addTriplePairs(
    void Function(List<GuandanCard>) tryAdd,
    List<int> sortedRanks,
    Map<int, List<GuandanCard>> byRank,
    List<GuandanCard> smallJokers,
    List<GuandanCard> wilds,
    int wildCount,
  ) {
    for (final tripleRank in sortedRanks) {
      final tc = byRank[tripleRank]!;
      final tAvail = tc.length.clamp(0, 3);
      final tNeeded = 3 - tAvail;
      if (tNeeded > wildCount) continue;

      final tripleCombo = [...tc.sublist(0, tAvail), ...wilds.sublist(0, tNeeded)];
      final remainWilds = wilds.sublist(tNeeded);

      // 正常对子
      for (final pairRank in sortedRanks) {
        if (pairRank == tripleRank) continue;
        final pc = byRank[pairRank]!;
        if (pc.length >= 2) tryAdd([...tripleCombo, pc[0], pc[1]]);
        if (pc.isNotEmpty && remainWilds.isNotEmpty) {
          tryAdd([...tripleCombo, pc[0], remainWilds[0]]);
        }
      }
      // 小王对
      if (smallJokers.length >= 2) {
        tryAdd([...tripleCombo, smallJokers[0], smallJokers[1]]);
      }
      // 纯级牌对
      if (remainWilds.length >= 2) {
        tryAdd([...tripleCombo, remainWilds[0], remainWilds[1]]);
      }
    }
  }

  // ────────────────────────────────────────────────────────────────
  // 顺子（A=14 不参与）
  // ────────────────────────────────────────────────────────────────

  static void _addStraights(
    void Function(List<GuandanCard>) tryAdd,
    List<int> sortedRanks,
    Map<int, List<GuandanCard>> byRank,
    List<GuandanCard> wilds,
    int wildCount,
  ) {
    final rankSet = sortedRanks.where((r) => r != 14).toSet();
    final rankList = rankSet.toList()..sort();
    if (rankList.length < 2) return;

    for (int si = 0; si < rankList.length; si++) {
      final start = rankList[si];
      for (int ei = si + 1; ei < rankList.length; ei++) {
        final end = rankList[ei];
        final len = end - start + 1;
        if (len < 5) continue;

        // 统计内部缺口（非端点缺少的点数）
        int gaps = 0;
        for (int r = start + 1; r < end; r++) {
          if (!rankSet.contains(r)) gaps++;
        }
        if (gaps > wildCount) continue;

        final combo = <GuandanCard>[];
        int wildsUsed = 0;
        bool ok = true;
        for (int r = start; r <= end; r++) {
          if (rankSet.contains(r)) {
            combo.add(byRank[r]![0]);
          } else {
            if (wildsUsed >= wildCount) { ok = false; break; }
            combo.add(wilds[wildsUsed++]);
          }
        }
        if (ok) tryAdd(combo);
      }
    }
  }

  // ────────────────────────────────────────────────────────────────
  // 连对（A=14 不参与）
  // ────────────────────────────────────────────────────────────────

  static void _addConsecutivePairs(
    void Function(List<GuandanCard>) tryAdd,
    List<int> sortedRanks,
    Map<int, List<GuandanCard>> byRank,
    List<GuandanCard> wilds,
    int wildCount,
  ) {
    final rankSet = sortedRanks.where((r) => r != 14).toSet();
    final rankList = rankSet.toList()..sort();
    if (rankList.length < 3) return;

    for (int si = 0; si < rankList.length; si++) {
      final start = rankList[si];
      for (int ei = si + 2; ei < rankList.length; ei++) {
        final end = rankList[ei];
        final combo = <GuandanCard>[];
        int wildsUsed = 0;
        bool ok = true;

        for (int r = start; r <= end; r++) {
          final rc = byRank[r];
          if (rc == null || rc.isEmpty) {
            if (wildsUsed + 2 > wildCount) { ok = false; break; }
            combo.add(wilds[wildsUsed++]);
            combo.add(wilds[wildsUsed++]);
          } else if (rc.length == 1) {
            if (wildsUsed + 1 > wildCount) { ok = false; break; }
            combo.add(rc[0]);
            combo.add(wilds[wildsUsed++]);
          } else {
            combo.add(rc[0]);
            combo.add(rc[1]);
          }
        }
        if (ok) tryAdd(combo);
      }
    }
  }

  // ────────────────────────────────────────────────────────────────
  // 钢板（A=14 不参与）
  // ────────────────────────────────────────────────────────────────

  static void _addSteelPlates(
    void Function(List<GuandanCard>) tryAdd,
    List<int> sortedRanks,
    Map<int, List<GuandanCard>> byRank,
    List<GuandanCard> wilds,
    int wildCount,
  ) {
    final rankSet = sortedRanks.where((r) => r != 14).toSet();
    final rankList = rankSet.toList()..sort();
    if (rankList.length < 2) return;

    for (int si = 0; si < rankList.length; si++) {
      final start = rankList[si];
      for (int ei = si + 1; ei < rankList.length; ei++) {
        final end = rankList[ei];
        final combo = <GuandanCard>[];
        int wildsUsed = 0;
        bool ok = true;

        for (int r = start; r <= end; r++) {
          final rc = byRank[r];
          final available = (rc?.length ?? 0).clamp(0, 3);
          final needed = 3 - available;
          if (wildsUsed + needed > wildCount) { ok = false; break; }
          if (rc != null) combo.addAll(rc.sublist(0, available));
          combo.addAll(wilds.sublist(wildsUsed, wildsUsed + needed));
          wildsUsed += needed;
        }
        if (ok) tryAdd(combo);
      }
    }
  }

  // ────────────────────────────────────────────────────────────────
  // 同花顺炸弹（含级牌的自然点数）
  // ────────────────────────────────────────────────────────────────

  static void _addStraightFlushBombs(
    void Function(List<GuandanCard>) tryAdd,
    List<GuandanCard> hand,
  ) {
    final bySuit = <Object, List<GuandanCard>>{};
    for (final card in hand) {
      if (card.isJoker || card.suit == null) continue;
      bySuit.putIfAbsent(card.suit!, () => []).add(card);
    }

    for (final suitCards in bySuit.values) {
      suitCards.sort((a, b) => a.rank!.compareTo(b.rank!));
      for (int i = 0; i < suitCards.length; i++) {
        for (int j = i + 4; j < suitCards.length; j++) {
          bool consecutive = true;
          for (int k = i + 1; k <= j; k++) {
            if (suitCards[k].rank! != suitCards[k - 1].rank! + 1) {
              consecutive = false;
              break;
            }
          }
          if (consecutive) tryAdd(suitCards.sublist(i, j + 1));
        }
      }
    }
  }
}
