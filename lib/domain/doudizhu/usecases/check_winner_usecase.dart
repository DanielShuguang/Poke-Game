import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';

/// 判断胜负用例
class CheckWinnerUseCase {
  /// 检查是否有玩家获胜
  List<String>? call(GameState state) {
    for (final player in state.players) {
      if (player.handCards.isEmpty) {
        // 找到获胜者
        if (player.role == PlayerRole.landlord) {
          // 地主赢
          return [player.id];
        } else {
          // 农民赢（两个农民都算赢）
          return state.players
              .where((p) => p.role == PlayerRole.peasant)
              .map((p) => p.id)
              .toList();
        }
      }
    }
    return null;
  }
}
