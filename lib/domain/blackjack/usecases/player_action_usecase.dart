import 'package:poke_game/domain/blackjack/entities/blackjack_card.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_game_config.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_game_state.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_hand.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_player.dart';

/// 玩家行动 Use Case：Hit / Stand / Double / Split / Surrender
class PlayerActionUseCase {
  final BlackjackGameConfig config;

  const PlayerActionUseCase({required this.config});

  // ── Hit ──────────────────────────────────────────────────────────────────

  BlackjackGameState hit(BlackjackGameState state) {
    final player = state.currentPlayer;
    if (player == null) return state;
    final handIdx = player.activeHandIndex;
    final hand = player.hands[handIdx];

    final newCard = _drawCard(state);
    final updatedCards = [...hand.cards, newCard];
    final updatedHand = hand.copyWith(cards: updatedCards);

    // 检查爆牌 / 五小龙
    BlackjackHandStatus? newStatus;
    if (updatedHand.isBust) {
      newStatus = BlackjackHandStatus.bust;
    } else if (config.fiveCardCharlie && updatedCards.length >= 5) {
      newStatus = BlackjackHandStatus.fiveCardCharlie;
    }

    final finalHand = newStatus != null
        ? updatedHand.copyWith(status: newStatus)
        : updatedHand;

    final updatedPlayer = _updateHand(player, handIdx, finalHand);
    final newState = _replacePlayer(state, updatedPlayer);

    // 若该手已完成，推进轮次
    if (finalHand.isDone) {
      return _advance(newState);
    }
    return newState;
  }

  // ── Stand ─────────────────────────────────────────────────────────────────

  BlackjackGameState stand(BlackjackGameState state) {
    final player = state.currentPlayer;
    if (player == null) return state;
    final handIdx = player.activeHandIndex;
    final hand = player.hands[handIdx];

    final stoodHand = hand.copyWith(status: BlackjackHandStatus.stood);
    final updatedPlayer = _updateHand(player, handIdx, stoodHand);
    final newState = _replacePlayer(state, updatedPlayer);
    return _advance(newState);
  }

  // ── Double ────────────────────────────────────────────────────────────────

  BlackjackGameState doubleDown(BlackjackGameState state) {
    final player = state.currentPlayer;
    if (player == null) return state;
    final handIdx = player.activeHandIndex;
    final hand = player.hands[handIdx];
    if (hand.cards.length != 2) return state; // 只有两张时可以 Double

    final newCard = _drawCard(state);
    final doubled = hand.copyWith(
      cards: [...hand.cards, newCard],
      bet: hand.bet * 2,
    );

    BlackjackHandStatus newStatus;
    if (doubled.isBust) {
      newStatus = BlackjackHandStatus.bust;
    } else if (config.fiveCardCharlie && doubled.cards.length >= 5) {
      newStatus = BlackjackHandStatus.fiveCardCharlie;
    } else {
      newStatus = BlackjackHandStatus.stood; // Double 后自动 Stand
    }

    final finalHand = doubled.copyWith(status: newStatus);
    final updatedPlayer = _updateHand(player, handIdx, finalHand)
        .copyWith(chips: player.chips - hand.bet); // 额外扣除等额筹码
    final newState = _replacePlayer(state, updatedPlayer);
    return _advance(newState);
  }

  // ── Split ─────────────────────────────────────────────────────────────────

  BlackjackGameState split(BlackjackGameState state) {
    final player = state.currentPlayer;
    if (player == null) return state;
    final handIdx = player.activeHandIndex;
    final hand = player.hands[handIdx];
    if (!hand.canSplit) return state;

    // 各取一张，再补一张
    var deck = List.of(state.deck);
    BlackjackCard drawFromDeck() => deck.removeAt(0);

    final card1 = hand.cards[0];
    final card2 = hand.cards[1];
    final hand1 = BlackjackHand(
      cards: [card1, drawFromDeck()],
      bet: hand.bet,
    );
    final hand2 = BlackjackHand(
      cards: [card2, drawFromDeck()],
      bet: hand.bet,
    );

    // 检查 Blackjack（Split 后的 Blackjack 通常按普通 21 点处理，不按 1.5x 赔率）
    final h1 = hand1.value == 21
        ? hand1.copyWith(status: BlackjackHandStatus.stood)
        : hand1;
    final h2 = hand2.value == 21
        ? hand2.copyWith(status: BlackjackHandStatus.stood)
        : hand2;

    final newHands = List<BlackjackHand>.of(player.hands)
      ..replaceRange(handIdx, handIdx + 1, [h1, h2]);

    final updatedPlayer = player.copyWith(
      hands: newHands,
      chips: player.chips - hand.bet, // 额外扣除一份下注
      activeHandIndex: handIdx,
    );
    return _replacePlayer(state, updatedPlayer).copyWith(deck: deck);
  }

  // ── Surrender ─────────────────────────────────────────────────────────────

  BlackjackGameState surrender(BlackjackGameState state) {
    final player = state.currentPlayer;
    if (player == null) return state;
    final handIdx = player.activeHandIndex;
    final hand = player.hands[handIdx];
    if (hand.cards.length != 2) return state;

    final surrendered = hand.copyWith(status: BlackjackHandStatus.surrendered);
    // 返还一半下注
    final refund = hand.bet ~/ 2;
    final updatedPlayer = _updateHand(player, handIdx, surrendered)
        .copyWith(chips: player.chips + refund);
    final newState = _replacePlayer(state, updatedPlayer);
    return _advance(newState);
  }

  // ── 内部辅助 ──────────────────────────────────────────────────────────────

  BlackjackGameState _replacePlayer(
      BlackjackGameState state, BlackjackPlayer player) {
    final newPlayers = List.of(state.players);
    newPlayers[state.currentPlayerIndex] = player;
    return state.copyWith(players: newPlayers);
  }

  BlackjackPlayer _updateHand(
      BlackjackPlayer player, int handIdx, BlackjackHand hand) {
    final newHands = List<BlackjackHand>.of(player.hands);
    newHands[handIdx] = hand;
    return player.copyWith(hands: newHands);
  }

  BlackjackCard _drawCard(BlackjackGameState state) {
    if (state.deck.isEmpty) throw StateError('牌堆已空');
    return state.deck.first;
  }

  /// 推进轮次：找下一个未完成的手牌 / 玩家；若全部完成则进入庄家阶段
  BlackjackGameState _advance(BlackjackGameState state) {
    // 先检查当前玩家是否还有未完成的手牌（Split 场景）
    final currentPlayer = state.players[state.currentPlayerIndex];
    final nextHandIdx = currentPlayer.hands
        .indexWhere((h) => !h.isDone, currentPlayer.activeHandIndex + 1);
    if (nextHandIdx != -1) {
      final updated =
          currentPlayer.copyWith(activeHandIndex: nextHandIdx);
      final newPlayers = List.of(state.players);
      newPlayers[state.currentPlayerIndex] = updated;
      return state.copyWith(players: newPlayers);
    }

    // 找下一位玩家
    final nextPlayerIdx = _findNextPlayerIndex(state);
    if (nextPlayerIdx != -1) {
      return state.copyWith(currentPlayerIndex: nextPlayerIdx);
    }

    // 所有玩家完成，进入庄家阶段
    return state.copyWith(phase: BlackjackPhase.dealerTurn);
  }

  int _findNextPlayerIndex(BlackjackGameState state) {
    for (int i = state.currentPlayerIndex + 1;
        i < state.players.length;
        i++) {
      if (!state.players[i].allHandsDone) return i;
    }
    return -1;
  }
}
