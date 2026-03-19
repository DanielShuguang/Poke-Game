import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/doudizhu/repositories/game_repository.dart';

/// 游戏仓库本地实现
/// 当前仅实现本地存储，局域网对战功能待扩展
class GameRepositoryImpl implements GameRepository {
  // TODO: 注入本地存储依赖（如 SharedPreferences、Hive）

  @override
  Future<void> saveGameState(GameState state) async {
    // TODO: 实现本地存储
    // 用于断线重连功能
  }

  @override
  Future<GameState?> loadGameState() async {
    // TODO: 实现本地加载
    return null;
  }

  @override
  Future<void> clearGameState() async {
    // TODO: 实现清除本地存储
  }

  @override
  Future<void> syncGameState(GameState state) async {
    // TODO: 局域网对战时实现
    throw UnimplementedError('局域网对战功能待实现');
  }

  @override
  Stream<GameState> watchRemoteState() {
    // TODO: 局域网对战时实现
    throw UnimplementedError('局域网对战功能待实现');
  }

  @override
  Future<void> sendPlayAction(String playerId, List<Card> cards) async {
    // TODO: 局域网对战时实现
    throw UnimplementedError('局域网对战功能待实现');
  }

  @override
  Future<void> sendPassAction(String playerId) async {
    // TODO: 局域网对战时实现
    throw UnimplementedError('局域网对战功能待实现');
  }

  @override
  Future<void> sendCallAction(String playerId, bool call) async {
    // TODO: 局域网对战时实现
    throw UnimplementedError('局域网对战功能待实现');
  }
}
