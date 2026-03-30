import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/domain/blackjack/ai/blackjack_dealer_ai.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_game_config.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_game_state.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_hand.dart';
import 'package:poke_game/domain/blackjack/entities/blackjack_player.dart';
import 'package:poke_game/domain/blackjack/usecases/deal_cards_usecase.dart';
import 'package:poke_game/domain/blackjack/usecases/player_action_usecase.dart';
import 'package:poke_game/domain/blackjack/usecases/settle_usecase.dart';

final blackjackGameProvider =
    StateNotifierProvider<BlackjackGameNotifier, BlackjackGameState>(
  (ref) => BlackjackGameNotifier(),
);

class BlackjackGameNotifier extends StateNotifier<BlackjackGameState> {
  BlackjackGameNotifier() : super(BlackjackGameState.initial());

  BlackjackGameConfig _config = BlackjackGameConfig.defaultConfig;
  late PlayerActionUseCase _actionUseCase;
  static const _settle = SettleUseCase();

  // ── 初始化 ────────────────────────────────────────────────────────────────

  void init({
    required List<BlackjackPlayer> players,
    BlackjackGameConfig? config,
  }) {
    _config = config ?? BlackjackGameConfig.defaultConfig;
    _actionUseCase = PlayerActionUseCase(config: _config);
    state = BlackjackGameState(
      deck: DealCardsUseCase.buildShuffledDeck(_config),
      dealer: const BlackjackPlayer(
        id: 'dealer',
        name: '庄家',
        isAi: true,
        isDealer: true,
        chips: 0,
      ),
      players: players,
      phase: BlackjackPhase.betting,
    );
  }

  // ── 下注 ──────────────────────────────────────────────────────────────────

  void bet(String playerId, int amount) {
    if (state.phase != BlackjackPhase.betting) return;
    final idx = state.players.indexWhere((p) => p.id == playerId);
    if (idx == -1) return;
    final player = state.players[idx];
    if (player.chips < amount) return;

    final betHand = BlackjackHand(cards: const [], bet: amount);
    final updated = player.copyWith(
      chips: player.chips - amount,
      hands: [betHand],
    );
    final newPlayers = List.of(state.players)..[idx] = updated;
    state = state.copyWith(players: newPlayers);
  }

  // ── 开始（发牌）──────────────────────────────────────────────────────────

  void startGame() {
    if (state.phase != BlackjackPhase.betting) return;
    if (state.players.any((p) => p.hands.isEmpty || p.hands[0].bet == 0)) {
      state = state.copyWith(message: '请先完成下注');
      return;
    }
    _actionUseCase = PlayerActionUseCase(config: _config);
    state = DealCardsUseCase().call(state);
  }

  // ── 玩家操作 ───────────────────────────────────────────────────────────────

  void hit() {
    if (state.phase != BlackjackPhase.playerTurn) return;
    final newState = _actionUseCase.hit(state);
    state = newState;
    _checkDealerTurn(newState);
  }

  void stand() {
    if (state.phase != BlackjackPhase.playerTurn) return;
    final newState = _actionUseCase.stand(state);
    state = newState;
    _checkDealerTurn(newState);
  }

  void doubleDown() {
    if (state.phase != BlackjackPhase.playerTurn) return;
    final newState = _actionUseCase.doubleDown(state);
    state = newState;
    _checkDealerTurn(newState);
  }

  void split() {
    if (state.phase != BlackjackPhase.playerTurn) return;
    state = _actionUseCase.split(state);
  }

  void surrender() {
    if (state.phase != BlackjackPhase.playerTurn) return;
    final newState = _actionUseCase.surrender(state);
    state = newState;
    _checkDealerTurn(newState);
  }

  // ── 庄家行动 ───────────────────────────────────────────────────────────────

  void _checkDealerTurn(BlackjackGameState newState) {
    if (newState.phase == BlackjackPhase.dealerTurn) {
      _runDealerAi();
    }
  }

  void _runDealerAi() async {
    final ai = BlackjackDealerAi(config: _config);
    final afterDealer = await ai.runAsync(state);
    state = afterDealer;
    state = _settle(state);
  }

  // ── 重置 ──────────────────────────────────────────────────────────────────

  void resetForNextRound() {
    // 保留筹码，重置手牌和阶段
    final resetPlayers = state.players.map((p) => p.copyWith(hands: [])).toList();
    state = BlackjackGameState(
      deck: DealCardsUseCase.buildShuffledDeck(_config),
      dealer: BlackjackGameState.initial().dealer,
      players: resetPlayers,
      phase: BlackjackPhase.betting,
    );
  }

  // ── 网络接口（联机适配器使用）─────────────────────────────────────────────

  BlackjackGameState get currentState => state;

  void applyNetworkState(BlackjackGameState newState) {
    state = newState;
  }

  void networkHit(String playerId) {
    if (state.currentPlayer?.id != playerId) return;
    final newState = _actionUseCase.hit(state);
    state = newState;
  }

  void networkStand(String playerId) {
    if (state.currentPlayer?.id != playerId) return;
    final newState = _actionUseCase.stand(state);
    state = newState;
  }

  void networkDoubleDown(String playerId) {
    if (state.currentPlayer?.id != playerId) return;
    final newState = _actionUseCase.doubleDown(state);
    state = newState;
  }

  void networkSplit(String playerId) {
    if (state.currentPlayer?.id != playerId) return;
    state = _actionUseCase.split(state);
  }

  void networkSurrender(String playerId) {
    if (state.currentPlayer?.id != playerId) return;
    final newState = _actionUseCase.surrender(state);
    state = newState;
  }

  void forcePlayerStand(String playerId) {
    if (state.currentPlayer?.id != playerId) return;
    final newState = _actionUseCase.stand(state);
    state = newState;
  }
}
