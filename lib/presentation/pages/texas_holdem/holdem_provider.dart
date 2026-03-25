import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/domain/texas_holdem/entities/holdem_game_state.dart';
import 'package:poke_game/domain/texas_holdem/entities/holdem_player.dart';
import 'package:poke_game/presentation/pages/texas_holdem/holdem_notifier.dart';

/// 默认人机对战配置（1人类 + 3 AI，共4人桌）
final holdemGameProvider =
    StateNotifierProvider.autoDispose<HoldemGameNotifier, HoldemGameState>(
  (ref) => HoldemGameNotifier(
    players: _defaultPlayers(),
    smallBlind: 10,
    bigBlind: 20,
    isAiMode: true,
    humanPlayerId: 'player_human',
  ),
);

/// 自定义参数的 Provider 工厂
AutoDisposeStateNotifierProvider<HoldemGameNotifier, HoldemGameState> holdemGameProviderWith({
  required List<HoldemPlayer> players,
  int smallBlind = 10,
  int bigBlind = 20,
  bool isAiMode = true,
  String? humanPlayerId,
}) {
  return StateNotifierProvider.autoDispose<HoldemGameNotifier, HoldemGameState>(
    (ref) => HoldemGameNotifier(
      players: players,
      smallBlind: smallBlind,
      bigBlind: bigBlind,
      isAiMode: isAiMode,
      humanPlayerId: humanPlayerId,
    ),
  );
}

List<HoldemPlayer> _defaultPlayers() {
  return [
    const HoldemPlayer(id: 'player_human', name: '你', chips: 1000),
    const HoldemPlayer(id: 'player_ai_1', name: 'AI 小明', chips: 1000),
    const HoldemPlayer(id: 'player_ai_2', name: 'AI 小红', chips: 1000),
    const HoldemPlayer(id: 'player_ai_3', name: 'AI 小强', chips: 1000),
  ];
}
