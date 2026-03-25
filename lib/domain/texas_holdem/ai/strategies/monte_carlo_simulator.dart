import 'dart:isolate';
import 'dart:math';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/texas_holdem/validators/hand_evaluator.dart';

/// 蒙特卡洛模拟参数
class _SimParams {
  final List<int> holeCardRanks;
  final List<String> holeCardSuits;
  final List<int> communityRanks;
  final List<String> communitySuits;
  final int playerCount;
  final int iterations;

  const _SimParams({
    required this.holeCardRanks,
    required this.holeCardSuits,
    required this.communityRanks,
    required this.communitySuits,
    required this.playerCount,
    required this.iterations,
  });
}

/// 蒙特卡洛胜率估算器
///
/// 在 Isolate 中运行，避免阻塞 UI 线程。
class MonteCarloSimulator {
  /// 估算给定底牌和公牌情况下的胜率
  ///
  /// [holeCards] 已知底牌（2张）
  /// [communityCards] 已知公牌（0-5张）
  /// [playerCount] 参与玩家数（含自己）
  /// [iterations] 模拟次数
  static Future<double> estimateEquity({
    required List<Card> holeCards,
    required List<Card> communityCards,
    required int playerCount,
    int iterations = 300,
  }) async {
    final params = _SimParams(
      holeCardRanks: holeCards.map((c) => c.rank).toList(),
      holeCardSuits: holeCards.map((c) => c.suit.name).toList(),
      communityRanks: communityCards.map((c) => c.rank).toList(),
      communitySuits: communityCards.map((c) => c.suit.name).toList(),
      playerCount: playerCount,
      iterations: iterations,
    );

    // 在 Isolate 中运行模拟
    final result = await Isolate.run(() => _runSimulation(params));
    return result;
  }

  static double _runSimulation(_SimParams params) {
    final random = Random();
    final known = <Card>[];

    // 重建底牌
    for (var i = 0; i < params.holeCardRanks.length; i++) {
      known.add(Card(
        suit: Suit.values.firstWhere((s) => s.name == params.holeCardSuits[i]),
        rank: params.holeCardRanks[i],
      ));
    }

    // 重建公牌
    final communityKnown = <Card>[];
    for (var i = 0; i < params.communityRanks.length; i++) {
      communityKnown.add(Card(
        suit: Suit.values.firstWhere((s) => s.name == params.communitySuits[i]),
        rank: params.communityRanks[i],
      ));
    }

    final knownAll = [...known, ...communityKnown];
    var wins = 0;
    var ties = 0;

    for (var iter = 0; iter < params.iterations; iter++) {
      // 构建剩余牌堆
      final deck = createHoldemDeck()
          .where((c) => !_containsCard(knownAll, c))
          .toList()
        ..shuffle(random);

      var deckIdx = 0;

      // 补全公牌
      final community = List<Card>.of(communityKnown);
      while (community.length < 5) {
        community.add(deck[deckIdx++]);
      }

      // 我方最优牌
      final myHand = HandEvaluator.evaluate([...known, ...community]);

      // 随机分配对手底牌
      var isBest = true;
      var isTie = false;

      for (var p = 1; p < params.playerCount; p++) {
        final oppHole = [deck[deckIdx++], deck[deckIdx++]];
        final oppHand = HandEvaluator.evaluate([...oppHole, ...community]);
        if (oppHand.score > myHand.score) {
          isBest = false;
          break;
        } else if (oppHand.score == myHand.score) {
          isTie = true;
        }
      }

      if (isBest && !isTie) {
        wins++;
      } else if (isBest && isTie) {
        ties++;
      }
    }

    // Equity = 完胜 + 平局的一半权重
    return (wins + ties * 0.5) / params.iterations;
  }

  static bool _containsCard(List<Card> cards, Card target) {
    return cards.any((c) => c.suit == target.suit && c.rank == target.rank);
  }
}

/// 创建德州扑克牌组（引用自 holdem_game_state.dart）
List<Card> createHoldemDeck() {
  final deck = <Card>[];
  for (final suit in Suit.values) {
    for (var rank = 2; rank <= 14; rank++) {
      deck.add(Card(suit: suit, rank: rank));
    }
  }
  return deck;
}
