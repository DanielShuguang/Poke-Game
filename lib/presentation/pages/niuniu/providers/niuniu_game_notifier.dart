import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/domain/niuniu/ai/niuniu_ai.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_game_config.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_game_state.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_player.dart';
import 'package:poke_game/domain/niuniu/usecases/deal_niuniu_usecase.dart';
import 'package:poke_game/domain/niuniu/usecases/settle_niuniu_usecase.dart';

final niuniuGameProvider =
    StateNotifierProvider<NiuniuGameNotifier, NiuniuGameState>(
  (ref) => NiuniuGameNotifier(),
);

class NiuniuGameNotifier extends StateNotifier<NiuniuGameState> {
  NiuniuGameNotifier() : super(NiuniuGameState.initial());

  NiuniuGameConfig _config = NiuniuGameConfig.defaultConfig;
  static const _settle = SettleNiuniuUseCase();

  // ── 初始化 ────────────────────────────────────────────────────────────────

  void init({
    required List<NiuniuPlayer> players,
    NiuniuGameConfig? config,
  }) {
    _config = config ?? NiuniuGameConfig.defaultConfig;
    final bankerId = players.firstWhere((p) => p.isBanker).id;
    state = NiuniuGameState(
      deck: DealNiuniuUseCase.buildShuffledDeck(_config),
      bankerId: bankerId,
      players: players,
      phase: NiuniuPhase.betting,
    );
  }

  // ── 下注 ──────────────────────────────────────────────────────────────────

  void bet(String playerId, int amount) {
    if (state.phase != NiuniuPhase.betting) return;
    final idx = state.players.indexWhere((p) => p.id == playerId);
    if (idx == -1) return;
    final player = state.players[idx];
    if (player.chips < amount || amount <= 0) return;

    final updated = player.copyWith(
      chips: player.chips - amount,
      betAmount: amount,
      status: NiuniuPlayerStatus.bet,
    );
    final newPlayers = List.of(state.players)..[idx] = updated;
    state = state.copyWith(players: newPlayers);

    // 庄家是 AI 时自动发牌；庄家是人类时等待其点击"开始发牌"
    if (state.allPuntersBet && (state.banker?.isAi == true)) {
      startGame();
    }
  }

  // ── 开始（发牌）──────────────────────────────────────────────────────────

  void startGame() {
    if (state.phase != NiuniuPhase.betting) return;
    state = DealNiuniuUseCase().call(state);
  }

  // ── 结算 ──────────────────────────────────────────────────────────────────

  void settle() {
    if (state.phase != NiuniuPhase.showdown) return;
    state = _settle(state);
  }

  // ── 重置 ──────────────────────────────────────────────────────────────────

  void resetForNextRound() {
    final resetPlayers = state.players.map((p) => p.copyWith(
          betAmount: 0,
          clearHand: true,
          status: p.chips > 0
              ? NiuniuPlayerStatus.waiting
              : NiuniuPlayerStatus.broke,
        )).toList();
    state = NiuniuGameState(
      deck: DealNiuniuUseCase.buildShuffledDeck(_config),
      bankerId: state.bankerId,
      players: resetPlayers,
      phase: NiuniuPhase.betting,
    );
  }

  // ── AI 下注 ───────────────────────────────────────────────────────────────

  Future<void> runAiBets() async {
    final ai = NiuniuAi(config: _config);
    final aiPunters =
        state.players.where((p) => p.isPunter && p.isAi && p.chips > 0).toList();
    await ai.runAsync(
      aiPunters: aiPunters,
      betAction: (playerId, amount) async {
        bet(playerId, amount);
      },
    );
  }

  // ── 网络接口 ───────────────────────────────────────────────────────────────

  NiuniuGameState get currentState => state;

  void applyNetworkState(NiuniuGameState newState) {
    state = newState;
  }

  void networkBet(String playerId, int amount) {
    bet(playerId, amount);
  }

  /// 超时托管：以最小面额（10）代为下注
  void forceMinBet(String playerId) {
    final player =
        state.players.where((p) => p.id == playerId).firstOrNull;
    if (player == null || player.status != NiuniuPlayerStatus.waiting) return;
    final amount = player.chips >= 10 ? 10 : player.chips;
    if (amount > 0) bet(playerId, amount);
  }
}
