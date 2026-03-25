import 'package:logger/logger.dart';
import 'package:poke_game/domain/lan/entities/player_identity.dart';
import 'package:poke_game/domain/lan/entities/room.dart';
import 'package:poke_game/domain/lan/entities/room_info.dart';
import 'package:poke_game/domain/lan/repositories/room_repository.dart';
import 'package:uuid/uuid.dart';

/// 创建房间用例
class CreateRoomUseCase {
  final RoomRepository _repository;
  final Logger _logger = Logger();

  CreateRoomUseCase(this._repository);

  Future<Room> call({
    required String roomName,
    required GameType gameType,
    required String hostPlayerId,
    String hostPlayerName = '房主',
    String? password,
    int? maxPlayerCount,
    Map<String, dynamic>? gameConfig,
  }) async {
    _logger.i('创建房间: $roomName, 类型: ${gameType.displayName}');

    // 验证房间名称
    if (roomName.isEmpty) {
      throw ArgumentError('房间名称不能为空');
    }

    // 确定最大玩家数
    final maxCount = maxPlayerCount ?? gameType.fixedPlayerCount ?? gameType.maxPlayerCount;

    // 验证人数限制
    if (gameType.fixedPlayerCount != null && maxCount != gameType.fixedPlayerCount) {
      throw ArgumentError('${gameType.displayName} 固定需要 ${gameType.fixedPlayerCount} 人');
    }

    if (maxCount < gameType.minPlayerCount || maxCount > gameType.maxPlayerCount) {
      throw ArgumentError('人数必须在 ${gameType.minPlayerCount} 到 ${gameType.maxPlayerCount} 之间');
    }

    // 创建房间
    final room = await _repository.createRoom(
      roomName: roomName,
      gameType: gameType,
      hostPlayerId: hostPlayerId,
      password: password,
      maxPlayerCount: maxCount,
      gameConfig: gameConfig ?? {},
    );

    _logger.i('房间已创建: ${room.roomId}');
    return room;
  }
}

/// 加入房间用例
class JoinRoomUseCase {
  final RoomRepository _repository;
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  JoinRoomUseCase(this._repository);

  Future<Room> call({
    required String roomId,
    required String playerName,
    String? password,
  }) async {
    _logger.i('加入房间: $roomId, 玩家: $playerName');

    // 验证玩家名称
    if (playerName.isEmpty) {
      throw ArgumentError('玩家名称不能为空');
    }

    // 生成玩家ID
    final playerId = _uuid.v4();

    // 加入房间
    final room = await _repository.joinRoom(
      roomId: roomId,
      playerId: playerId,
      playerName: playerName,
      password: password,
    );

    _logger.i('已加入房间: ${room.roomName}');
    return room;
  }
}

/// 离开房间用例
class LeaveRoomUseCase {
  final RoomRepository _repository;
  final Logger _logger = Logger();

  LeaveRoomUseCase(this._repository);

  Future<void> call(String playerId) async {
    _logger.i('离开房间: $playerId');
    await _repository.leaveRoom(playerId);
  }
}

/// 踢出玩家用例
class KickPlayerUseCase {
  final RoomRepository _repository;
  final Logger _logger = Logger();

  KickPlayerUseCase(this._repository);

  Future<void> call({
    required String hostPlayerId,
    required String targetPlayerId,
  }) async {
    _logger.i('踢出玩家: $targetPlayerId');
    await _repository.kickPlayer(hostPlayerId, targetPlayerId);
  }
}

/// 更新玩家状态用例
class UpdatePlayerStatusUseCase {
  final RoomRepository _repository;
  final Logger _logger = Logger();

  UpdatePlayerStatusUseCase(this._repository);

  Future<void> call(String playerId, PlayerStatus status) async {
    _logger.i('更新玩家状态: $playerId -> $status');
    await _repository.updatePlayerStatus(playerId, status);
  }
}

/// 开始游戏用例
class StartGameUseCase {
  final RoomRepository _repository;
  final Logger _logger = Logger();

  StartGameUseCase(this._repository);

  Future<void> call() async {
    _logger.i('开始游戏');

    // 检查是否可以开始游戏
    final room = _repository.currentRoom;
    if (room == null) {
      throw Exception('房间不存在');
    }

    if (!room.hasMinimumPlayers) {
      throw Exception('人数不足，无法开始游戏');
    }

    if (!room.allPlayersReady) {
      throw Exception('还有玩家未准备');
    }

    await _repository.startGame();
  }
}

/// 结束游戏用例
class EndGameUseCase {
  final RoomRepository _repository;
  final Logger _logger = Logger();

  EndGameUseCase(this._repository);

  Future<void> call() async {
    _logger.i('结束游戏');
    await _repository.endGame();
  }
}

/// 销毁房间用例
class DestroyRoomUseCase {
  final RoomRepository _repository;
  final Logger _logger = Logger();

  DestroyRoomUseCase(this._repository);

  Future<void> call() async {
    _logger.i('销毁房间');
    await _repository.destroyRoom();
  }
}
