import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/game_state.dart';

/// 游戏仓库抽象接口
/// 预留给局域网对战使用
abstract class GameRepository {
  /// 保存游戏状态（用于断线重连）
  Future<void> saveGameState(GameState state);

  /// 加载游戏状态
  Future<GameState?> loadGameState();

  /// 清除游戏状态
  Future<void> clearGameState();

  /// 同步游戏状态到服务器（局域网对战）
  Future<void> syncGameState(GameState state);

  /// 监听远程玩家的出牌（局域网对战）
  Stream<GameState> watchRemoteState();

  /// 发送出牌动作到服务器（局域网对战）
  Future<void> sendPlayAction(String playerId, List<Card> cards);

  /// 发送过牌动作到服务器（局域网对战）
  Future<void> sendPassAction(String playerId);

  /// 发送叫地主动作到服务器（局域网对战）
  Future<void> sendCallAction(String playerId, bool call);
}
