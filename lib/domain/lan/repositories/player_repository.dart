import 'package:poke_game/domain/lan/entities/player_identity.dart';

/// 玩家仓库接口
abstract class PlayerRepository {
  /// 获取当前玩家
  PlayerIdentity? get currentPlayer;

  /// 当前玩家流
  Stream<PlayerIdentity?> get currentPlayerStream;

  /// 获取所有玩家
  List<PlayerIdentity> get players;

  /// 玩家列表流
  Stream<List<PlayerIdentity>> get playersStream;

  /// 创建玩家
  Future<PlayerIdentity> createPlayer({
    required String playerName,
    String? deviceName,
    String? ipAddress,
  });

  /// 更新玩家状态
  Future<void> updateStatus(String playerId, PlayerStatus status);

  /// 更新玩家名称
  Future<void> updateName(String playerId, String newName);

  /// 分配座位
  Future<int> assignSeat(String playerId);

  /// 移除玩家
  Future<void> removePlayer(String playerId);

  /// 获取玩家
  PlayerIdentity? getPlayer(String playerId);

  /// 设置房主
  Future<void> setHost(String playerId);

  /// 禁言玩家
  Future<void> mutePlayer(String playerId, {Duration duration = const Duration(minutes: 5)});

  /// 解除禁言
  Future<void> unmutePlayer(String playerId);

  /// 检查是否被禁言
  bool isPlayerMuted(String playerId);
}
