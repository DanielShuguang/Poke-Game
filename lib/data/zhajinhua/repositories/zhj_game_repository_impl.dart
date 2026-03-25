import 'dart:math';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_config.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_state.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_player.dart';
import 'package:poke_game/domain/zhajinhua/repositories/zhj_game_repository.dart';

class ZhjGameRepositoryImpl implements ZhjGameRepository {
  ZhjGameState? _cachedState;
  final Random _random;

  ZhjGameRepositoryImpl({Random? random}) : _random = random ?? Random();

  @override
  ZhjGameState initGame(ZhjGameConfig config) {
    final players = <ZhjPlayer>[];

    // 第一个玩家为真人
    players.add(ZhjPlayer(
      id: 'human',
      name: '玩家',
      isAi: false,
      chips: config.initialChips,
    ));

    // 其余为 AI，随机分配激进度
    for (int i = 1; i < config.playerCount; i++) {
      players.add(ZhjPlayer(
        id: 'ai_$i',
        name: 'AI $i',
        isAi: true,
        chips: config.initialChips,
        aggression: _random.nextDouble(),
      ));
    }

    return ZhjGameState.initial().copyWith(players: players);
  }

  @override
  void saveState(ZhjGameState state) {
    _cachedState = state;
  }

  @override
  ZhjGameState? loadState() => _cachedState;
}
