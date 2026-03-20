import 'package:poke_game/domain/lan/entities/player_identity.dart';
import 'package:poke_game/domain/lan/entities/room.dart';
import 'package:poke_game/domain/lan/entities/room_info.dart';

/// 房间仓库接口
abstract class RoomRepository {
  /// 获取当前房间
  Room? get currentRoom;

  /// 房间状态流
  Stream<Room?> get roomStream;

  /// 创建房间
  Future<Room> createRoom({
    required String roomName,
    required GameType gameType,
    required String hostPlayerId,
    String? password,
    int? maxPlayerCount,
    Map<String, dynamic>? gameConfig,
  });

  /// 加入房间
  Future<Room> joinRoom({
    required String roomId,
    required String playerId,
    required String playerName,
    String? password,
  });

  /// 离开房间
  Future<void> leaveRoom(String playerId);

  /// 踢出玩家
  Future<void> kickPlayer(String hostPlayerId, String targetPlayerId);

  /// 更新玩家状态
  Future<void> updatePlayerStatus(String playerId, PlayerStatus status);

  /// 更新玩家名称
  Future<void> updatePlayerName(String playerId, String newName);

  /// 开始游戏
  Future<void> startGame();

  /// 结束游戏
  Future<void> endGame();

  /// 销毁房间
  Future<void> destroyRoom();

  /// 获取房间信息（用于广播）
  Future<RoomInfo> getRoomInfo();

  /// 发现的房间列表流
  Stream<List<RoomInfo>> get discoveredRoomsStream;

  /// 开始扫描房间
  Future<void> startScanning();

  /// 停止扫描房间
  void stopScanning();
}
