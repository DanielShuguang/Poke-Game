import 'package:poke_game/domain/zhajinhua/entities/zhj_game_state.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_player.dart';

/// 看牌用例：设置 hasPeeked=true，不可撤销
class PeekCardUsecase {
  ZhjGameState execute(ZhjGameState state) {
    final players = List<ZhjPlayer>.from(state.players);
    final player = players[state.currentPlayerIndex];

    if (player.hasPeeked) return state; // 已看牌，无效操作

    players[state.currentPlayerIndex] = player.copyWith(hasPeeked: true);
    return state.copyWith(players: players);
  }
}
