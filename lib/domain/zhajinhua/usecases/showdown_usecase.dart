import 'package:poke_game/domain/zhajinhua/entities/zhj_game_state.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_player.dart';
import 'package:poke_game/domain/zhajinhua/validators/zhj_card_validator.dart';

/// 比牌用例：两玩家直接翻牌比较，输者淘汰
class ShowdownUsecase {
  /// [challengerIndex] 发起比牌的玩家，[targetIndex] 被比牌的玩家
  ZhjGameState execute(
    ZhjGameState state,
    int challengerIndex,
    int targetIndex,
  ) {
    final players = List<ZhjPlayer>.from(state.players);
    final challenger = players[challengerIndex];
    final target = players[targetIndex];

    // 双方都强制看牌（翻牌）
    players[challengerIndex] = challenger.copyWith(hasPeeked: true);
    players[targetIndex] = target.copyWith(hasPeeked: true);

    final cmp = ZhjCardValidator.compare(challenger.cards, target.cards);

    // cmp > 0：challenger 更大，target 淘汰；cmp <= 0：challenger 淘汰（先手劣势平局也输）
    if (cmp > 0) {
      players[targetIndex] = players[targetIndex].copyWith(isFolded: true);
    } else {
      players[challengerIndex] = players[challengerIndex].copyWith(isFolded: true);
    }

    return state.copyWith(players: players);
  }
}
