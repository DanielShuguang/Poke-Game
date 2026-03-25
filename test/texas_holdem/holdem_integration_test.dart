import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/texas_holdem/entities/holdem_game_state.dart';
import 'package:poke_game/domain/texas_holdem/entities/holdem_player.dart';
import 'package:poke_game/domain/texas_holdem/usecases/betting_usecases.dart';

void main() {
  group('德州扑克流程集成测试', () {
    late List<HoldemPlayer> players;
    late HoldemGameState initialState;
    late DealCardsUsecase dealCards;
    late BettingRoundUsecase betting;
    late PhaseAdvanceUsecase advance;
    late ShowdownUsecase showdown;

    setUp(() {
      players = [
        const HoldemPlayer(id: 'p1', name: '玩家1', chips: 1000),
        const HoldemPlayer(id: 'p2', name: '玩家2', chips: 1000),
        const HoldemPlayer(id: 'p3', name: '玩家3', chips: 1000),
      ];
      initialState = HoldemGameState.initial(
        players: players,
        smallBlind: 10,
        bigBlind: 20,
      );
      dealCards = DealCardsUsecase();
      betting = BettingRoundUsecase();
      advance = PhaseAdvanceUsecase();
      showdown = ShowdownUsecase();
    });

    test('发牌阶段：每人2张底牌，盲注正确扣除', () {
      final state = dealCards.execute(initialState);

      expect(state.phase, GamePhase.preflop);
      for (final p in state.players) {
        expect(p.holeCards.length, 2);
      }
      // SB 扣10，BB 扣20
      final sb = state.players[state.smallBlindIndex];
      final bb = state.players[state.bigBlindIndex];
      expect(sb.currentBet, 10);
      expect(bb.currentBet, 20);
      expect(sb.chips, 990);
      expect(bb.chips, 980);
    });

    test('全局筹码守恒：发牌后所有筹码总量不变', () {
      final state = dealCards.execute(initialState);
      final totalChips = state.players.fold(0, (sum, p) => sum + p.chips + p.currentBet);
      expect(totalChips, 3000); // 3人各1000
    });

    test('投注轮：Call 后筹码正确', () {
      var state = dealCards.execute(initialState);
      // 当前行动者是大盲注下一位（p1如果是dealer则从p3开始，按位置确定）
      final actorIndex = state.currentPlayerIndex;
      final actor = state.players[actorIndex];
      final callAmount = state.currentBet - actor.currentBet;

      state = betting.execute(state, const CallAction());

      final updatedActor = state.players[actorIndex];
      expect(updatedActor.chips, actor.chips - callAmount);
      expect(updatedActor.currentBet, state.currentBet);
    });

    test('弃牌后仅剩活跃玩家', () {
      var state = dealCards.execute(initialState);
      // 全部人弃牌直到剩1人
      var foldCount = 0;
      while (state.activePlayers.length > 1 && foldCount < 10) {
        if (state.currentPlayer?.canAct == true) {
          state = betting.execute(state, const FoldAction());
          foldCount++;
        } else {
          break;
        }
      }
      expect(state.activePlayers.length, lessThanOrEqualTo(2));
    });

    test('完整一局：发牌→全部跟注→推进阶段→结算，筹码守恒', () {
      var state = dealCards.execute(initialState);

      // 所有玩家跟注
      for (var i = 0; i < state.players.length * 2; i++) {
        if (BettingRoundUsecase.isRoundComplete(state)) break;
        final current = state.currentPlayer;
        if (current == null || !current.canAct) break;
        if (current.currentBet < state.currentBet) {
          state = betting.execute(state, const CallAction());
        } else {
          state = betting.execute(state, const CheckAction());
        }
      }

      // 推进到 Flop
      state = advance.advance(state);
      expect(state.phase, GamePhase.flop);
      expect(state.communityCards.length, 3);

      // 过牌到 Turn
      for (var i = 0; i < state.players.length; i++) {
        if (BettingRoundUsecase.isRoundComplete(state)) break;
        final current = state.currentPlayer;
        if (current?.canAct == true) {
          state = betting.execute(state, const CheckAction());
        }
      }
      state = advance.advance(state);
      expect(state.phase, GamePhase.turn);
      expect(state.communityCards.length, 4);

      // 过牌到 River
      for (var i = 0; i < state.players.length; i++) {
        if (BettingRoundUsecase.isRoundComplete(state)) break;
        final current = state.currentPlayer;
        if (current?.canAct == true) {
          state = betting.execute(state, const CheckAction());
        }
      }
      state = advance.advance(state);
      expect(state.phase, GamePhase.river);
      expect(state.communityCards.length, 5);

      // 结算
      for (var i = 0; i < state.players.length; i++) {
        if (BettingRoundUsecase.isRoundComplete(state)) break;
        final current = state.currentPlayer;
        if (current?.canAct == true) {
          state = betting.execute(state, const CheckAction());
        }
      }
      state = showdown.execute(state);

      expect(state.phase, GamePhase.finished);

      // 验证筹码守恒
      final totalChipsAfter = state.players.fold(
          0, (sum, p) => sum + p.chips + p.currentBet);
      expect(totalChipsAfter, 3000);
    });
  });
}
