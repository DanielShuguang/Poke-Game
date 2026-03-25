import 'dart:math';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/texas_holdem/entities/holdem_game_state.dart';
import 'package:poke_game/domain/texas_holdem/entities/holdem_player.dart';
import 'package:poke_game/domain/texas_holdem/entities/pot.dart';
import 'package:poke_game/domain/texas_holdem/usecases/pot_calculator.dart';
import 'package:poke_game/domain/texas_holdem/validators/hand_evaluator.dart';

/// 发牌用例：洗牌、发底牌、设置盲注位、扣除盲注
class DealCardsUsecase {
  final Random _random;

  DealCardsUsecase({Random? random}) : _random = random ?? Random();

  HoldemGameState execute(HoldemGameState state) {
    // 洗牌
    final deck = createHoldemDeck()..shuffle(_random);

    // 发2张底牌给每位玩家
    var deckIndex = 0;
    final players = state.players.map((p) {
      final hole = [deck[deckIndex++], deck[deckIndex++]];
      return p.copyWith(
        holeCards: hole,
        currentBet: 0,
        isFolded: false,
        isAllIn: false,
      );
    }).toList();

    // 剩余牌堆
    final remainingDeck = deck.sublist(deckIndex);

    // 盲注位
    final sbIndex = (state.dealerIndex + 1) % players.length;
    final bbIndex = (state.dealerIndex + 2) % players.length;

    // 自动扣除盲注
    final sb = players[sbIndex];
    final bb = players[bbIndex];

    final sbBet = min(state.smallBlind, sb.chips);
    final bbBet = min(state.bigBlind, bb.chips);

    players[sbIndex] = sb.copyWith(
      chips: sb.chips - sbBet,
      currentBet: sbBet,
      isAllIn: sb.chips <= state.smallBlind,
    );
    players[bbIndex] = bb.copyWith(
      chips: bb.chips - bbBet,
      currentBet: bbBet,
      isAllIn: bb.chips <= state.bigBlind,
    );

    // 首轮行动从大盲注下一位开始
    final firstActIndex = (bbIndex + 1) % players.length;

    return state.copyWith(
      players: players,
      deck: remainingDeck,
      communityCards: [],
      pots: [],
      phase: GamePhase.preflop,
      currentBet: bbBet,
      minRaise: state.bigBlind,
      currentPlayerIndex: firstActIndex,
    );
  }
}

/// 投注动作
sealed class BettingAction {
  const BettingAction();
}

class FoldAction extends BettingAction {
  const FoldAction();
}

class CheckAction extends BettingAction {
  const CheckAction();
}

class CallAction extends BettingAction {
  const CallAction();
}

class RaiseAction extends BettingAction {
  final int totalBet; // 本轮总投注额（含之前已投）
  const RaiseAction(this.totalBet);
}

class AllInAction extends BettingAction {
  const AllInAction();
}

/// 投注轮用例：处理单个玩家的投注动作
class BettingRoundUsecase {
  /// 执行投注动作，返回更新后的游戏状态
  HoldemGameState execute(HoldemGameState state, BettingAction action) {
    final playerIndex = state.currentPlayerIndex;
    final player = state.players[playerIndex];

    if (!player.canAct) {
      throw StateError('玩家 ${player.name} 无法行动');
    }

    final players = List<HoldemPlayer>.of(state.players);
    int currentBet = state.currentBet;
    int minRaise = state.minRaise;

    switch (action) {
      case FoldAction():
        players[playerIndex] = player.copyWith(isFolded: true);

      case CheckAction():
        if (player.currentBet < state.currentBet) {
          throw StateError('无法 Check：存在未跟注的投注');
        }

      case CallAction():
        final callAmount = min(state.currentBet - player.currentBet, player.chips);
        players[playerIndex] = player.copyWith(
          chips: player.chips - callAmount,
          currentBet: player.currentBet + callAmount,
          isAllIn: player.chips <= callAmount,
        );

      case RaiseAction(:final totalBet):
        _validateRaise(state, player, totalBet);
        final raiseIncrement = totalBet - player.currentBet;
        final actualBet = min(raiseIncrement, player.chips);
        final newTotal = player.currentBet + actualBet;
        minRaise = max(newTotal - currentBet, state.bigBlind);
        currentBet = newTotal;
        players[playerIndex] = player.copyWith(
          chips: player.chips - actualBet,
          currentBet: newTotal,
          isAllIn: player.chips <= raiseIncrement,
        );

      case AllInAction():
        final allInBet = player.currentBet + player.chips;
        if (allInBet > currentBet) {
          minRaise = max(allInBet - currentBet, state.bigBlind);
          currentBet = allInBet;
        }
        players[playerIndex] = player.copyWith(
          chips: 0,
          currentBet: allInBet,
          isAllIn: true,
        );
    }

    // 找下一个可行动玩家
    final nextIndex = _nextActablePlayerIndex(players, playerIndex);

    return state.copyWith(
      players: players,
      currentBet: currentBet,
      minRaise: minRaise,
      currentPlayerIndex: nextIndex,
    );
  }

  void _validateRaise(HoldemGameState state, HoldemPlayer player, int totalBet) {
    final increment = totalBet - state.currentBet;
    if (increment < state.minRaise) {
      throw ArgumentError(
          '加注增量 $increment 不得低于最小加注额 ${state.minRaise}');
    }
  }

  int _nextActablePlayerIndex(List<HoldemPlayer> players, int current) {
    final count = players.length;
    for (var i = 1; i < count; i++) {
      final idx = (current + i) % count;
      if (players[idx].canAct) return idx;
    }
    return -1;
  }

  /// 判断本轮投注是否结束
  static bool isRoundComplete(HoldemGameState state) {
    final active = state.activePlayers;
    if (active.length <= 1) return true;
    final actable = state.actablePlayers;
    if (actable.isEmpty) return true;
    return actable.every((p) => p.currentBet == state.currentBet);
  }
}

/// 轮次推进用例：投注轮结束后翻公牌或进入摊牌
class PhaseAdvanceUsecase {
  HoldemGameState advance(HoldemGameState state) {
    final newPots = _collectBets(state);

    final players = state.players
        .map((p) => p.copyWith(currentBet: 0))
        .toList();

    final nextPhase = _nextPhase(state.phase);

    var deck = List<Card>.of(state.deck);
    var communityCards = List<Card>.of(state.communityCards);

    switch (nextPhase) {
      case GamePhase.flop:
        communityCards.addAll(deck.take(3));
        deck = deck.sublist(3);
      case GamePhase.turn:
      case GamePhase.river:
        communityCards.add(deck.first);
        deck = deck.sublist(1);
      default:
        break;
    }

    final firstActIndex = _findFirstActor(players, state.smallBlindIndex);

    return state.copyWith(
      players: players,
      communityCards: communityCards,
      pots: newPots,
      phase: nextPhase,
      deck: deck,
      currentBet: 0,
      minRaise: state.bigBlind,
      currentPlayerIndex: firstActIndex,
    );
  }

  List<Pot> _collectBets(HoldemGameState state) {
    final allPots = List<Pot>.of(state.pots);
    final totalThisRound =
        state.players.fold(0, (sum, p) => sum + p.currentBet);
    if (totalThisRound == 0) return allPots;

    final eligible = state.players
        .where((p) => p.isActive)
        .map((p) => p.id)
        .toList();
    allPots.add(Pot(amount: totalThisRound, eligiblePlayerIds: eligible));
    return allPots;
  }

  GamePhase _nextPhase(GamePhase current) {
    switch (current) {
      case GamePhase.preflop:
        return GamePhase.flop;
      case GamePhase.flop:
        return GamePhase.turn;
      case GamePhase.turn:
        return GamePhase.river;
      case GamePhase.river:
        return GamePhase.showdown;
      default:
        return GamePhase.finished;
    }
  }

  int _findFirstActor(List<HoldemPlayer> players, int startIndex) {
    final count = players.length;
    for (var i = 0; i < count; i++) {
      final idx = (startIndex + i) % count;
      if (players[idx].canAct) return idx;
    }
    return 0;
  }
}

/// 摊牌用例：评估牌型、分配底池
class ShowdownUsecase {
  HoldemGameState execute(HoldemGameState state) {
    // 收集剩余投注
    final advancer = PhaseAdvanceUsecase();
    var newState = advancer.advance(state);

    // 提前结束（仅剩1名活跃玩家）
    final active = newState.activePlayers;
    if (active.length == 1) {
      return _awardToSingleWinner(newState, active.first);
    }

    // 评估所有活跃玩家牌型
    final allCards = <String, List<Card>>{};
    for (final player in active) {
      allCards[player.id] = [
        ...player.holeCards,
        ...newState.communityCards,
      ];
    }

    // 为每个底池确定获胜者
    final winnerIdsByPot = newState.pots.map((pot) {
      final eligible = active
          .where((p) => pot.eligiblePlayerIds.contains(p.id))
          .toList();
      return _findWinners(eligible, allCards);
    }).toList();

    // 分配筹码
    final sbPlayerId =
        newState.players[newState.smallBlindIndex].id;
    final awards = PotCalculator.distribute(
      newState.pots,
      winnerIdsByPot,
      smallBlindPlayerId: sbPlayerId,
    );

    final players = newState.players.map((p) {
      final bonus = awards[p.id] ?? 0;
      return p.copyWith(chips: p.chips + bonus);
    }).toList();

    return newState.copyWith(
      players: players,
      phase: GamePhase.finished,
    );
  }

  HoldemGameState _awardToSingleWinner(
      HoldemGameState state, HoldemPlayer winner) {
    final total = state.totalPot;
    final players = state.players.map((p) {
      if (p.id == winner.id) {
        return p.copyWith(chips: p.chips + total);
      }
      return p;
    }).toList();
    return state.copyWith(players: players, phase: GamePhase.finished);
  }

  List<String> _findWinners(
    List<HoldemPlayer> candidates,
    Map<String, List<Card>> allCards,
  ) {
    if (candidates.isEmpty) return [];
    if (candidates.length == 1) return [candidates.first.id];

    // 评估每位玩家的最优手牌
    final scores = <String, int>{};
    for (final p in candidates) {
      final cards = allCards[p.id]!;
      final result = HandEvaluator.evaluate(cards);
      scores[p.id] = result.score;
    }

    final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
    return scores.entries
        .where((e) => e.value == maxScore)
        .map((e) => e.key)
        .toList();
  }
}

/// Dealer Button 轮转用例
class AdvanceDealerUsecase {
  HoldemGameState execute(HoldemGameState state) {
    final count = state.players.length;
    var next = (state.dealerIndex + 1) % count;
    // 跳过筹码为0或已离开的玩家（此处简化：跳过筹码=0）
    var attempts = 0;
    while (state.players[next].chips == 0 && attempts < count) {
      next = (next + 1) % count;
      attempts++;
    }
    return state.copyWith(dealerIndex: next);
  }
}
