import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:poke_game/domain/lan/entities/player_identity.dart';
import 'package:poke_game/domain/lan/entities/room_info.dart';

part 'room.freezed.dart';
part 'room.g.dart';

/// 房间实体
///
/// 管理房间的完整状态和生命周期
@freezed
class Room with _$Room {
  const factory Room({
    /// 房间ID
    required String roomId,

    /// 房间名称
    required String roomName,

    /// 游戏类型
    required GameType gameType,

    /// 房主玩家ID
    required String hostPlayerId,

    /// 玩家列表
    required List<PlayerIdentity> players,

    /// 房间状态
    required RoomStatus status,

    /// 最大玩家数
    required int maxPlayerCount,

    /// 游戏配置
    required Map<String, dynamic> gameConfig,

    /// 创建时间
    required DateTime createdAt,

    /// 最后更新时间
    DateTime? updatedAt,

    /// 密码（可选）
    String? password,

    /// 是否允许观战
    @Default(false) bool allowSpectators,

    /// 聊天记录（最近50条）
    @Default([]) List<Map<String, dynamic>> chatHistory,
  }) = _Room;

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
}

/// 房间扩展方法
extension RoomX on Room {
  /// 当前玩家数
  int get currentPlayerCount => players.length;

  /// 是否已满
  bool get isFull => currentPlayerCount >= maxPlayerCount;

  /// 是否可以加入
  bool get canJoin => status == RoomStatus.waiting && !isFull;

  /// 是否所有玩家都已准备
  bool get allPlayersReady {
    if (players.isEmpty) return false;
    return players.every((p) => p.status == PlayerStatus.ready);
  }

  /// 是否达到最低人数要求
  bool get hasMinimumPlayers {
    return currentPlayerCount >= gameType.minPlayerCount;
  }

  /// 获取玩家座位
  int? getPlayerSeat(String playerId) {
    final player = players.firstWhere(
      (p) => p.playerId == playerId,
      orElse: () => throw Exception('Player not found'),
    );
    return player.seatNumber;
  }

  /// 获取指定座位的玩家
  PlayerIdentity? getPlayerBySeat(int seatNumber) {
    try {
      return players.firstWhere((p) => p.seatNumber == seatNumber);
    } catch (_) {
      return null;
    }
  }

  /// 转换为房间信息（用于广播）
  RoomInfo toRoomInfo({required String hostDeviceName, required String networkAddress}) {
    return RoomInfo(
      roomId: roomId,
      roomName: roomName,
      gameType: gameType,
      currentPlayerCount: currentPlayerCount,
      maxPlayerCount: maxPlayerCount,
      hostDeviceName: hostDeviceName,
      status: status,
      networkAddress: networkAddress,
      requiresPassword: password != null && password!.isNotEmpty,
      createdAt: createdAt,
    );
  }
}
