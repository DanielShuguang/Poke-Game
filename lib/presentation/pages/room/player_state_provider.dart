import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:poke_game/domain/lan/entities/player_identity.dart';
import 'package:poke_game/domain/lan/repositories/player_repository.dart';
import 'package:uuid/uuid.dart';

/// 玩家状态管理 Notifier
class PlayerStateNotifier extends StateNotifier<List<PlayerIdentity>> implements PlayerRepository {
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  PlayerIdentity? _currentPlayer;
  final StreamController<PlayerIdentity?> _currentPlayerController =
      StreamController<PlayerIdentity?>.broadcast();
  final StreamController<List<PlayerIdentity>> _playersController =
      StreamController<List<PlayerIdentity>>.broadcast();

  PlayerStateNotifier() : super([]);

  @override
  PlayerIdentity? get currentPlayer => _currentPlayer;

  @override
  Stream<PlayerIdentity?> get currentPlayerStream => _currentPlayerController.stream;

  @override
  List<PlayerIdentity> get players => state;

  @override
  Stream<List<PlayerIdentity>> get playersStream => _playersController.stream;

  @override
  Future<PlayerIdentity> createPlayer({
    required String playerName,
    String? deviceName,
    String? ipAddress,
  }) async {
    final playerId = _uuid.v4();
    final seatNumber = await assignSeat(playerId);

    final player = PlayerIdentity(
      playerId: playerId,
      playerName: playerName,
      seatNumber: seatNumber,
      status: PlayerStatus.online,
      deviceName: deviceName,
      ipAddress: ipAddress,
      joinedAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );

    state = [...state, player];
    _currentPlayer = player;

    _currentPlayerController.add(player);
    _playersController.add(state);

    _logger.i('玩家已创建: $playerName ($playerId)');
    return player;
  }

  @override
  Future<void> updateStatus(String playerId, PlayerStatus status) async {
    final index = state.indexWhere((p) => p.playerId == playerId);
    if (index == -1) {
      _logger.w('找不到玩家: $playerId');
      return;
    }

    state = [
      ...state.sublist(0, index),
      state[index].copyWith(status: status, lastActiveAt: DateTime.now()),
      ...state.sublist(index + 1),
    ];

    if (_currentPlayer?.playerId == playerId) {
      _currentPlayer = state[index];
      _currentPlayerController.add(_currentPlayer);
    }

    _playersController.add(state);
    _logger.d('玩家状态已更新: $playerId -> $status');
  }

  @override
  Future<void> updateName(String playerId, String newName) async {
    final index = state.indexWhere((p) => p.playerId == playerId);
    if (index == -1) {
      _logger.w('找不到玩家: $playerId');
      return;
    }

    state = [
      ...state.sublist(0, index),
      state[index].copyWith(playerName: newName),
      ...state.sublist(index + 1),
    ];

    if (_currentPlayer?.playerId == playerId) {
      _currentPlayer = state[index];
      _currentPlayerController.add(_currentPlayer);
    }

    _playersController.add(state);
    _logger.i('玩家名称已更新: $playerId -> $newName');
  }

  @override
  Future<int> assignSeat(String playerId) async {
    // 找到最小的可用座位号
    final usedSeats = state.map((p) => p.seatNumber).toSet();
    int seatNumber = 1;
    while (usedSeats.contains(seatNumber)) {
      seatNumber++;
    }

    _logger.d('分配座位: $playerId -> 座位 $seatNumber');
    return seatNumber;
  }

  @override
  Future<void> removePlayer(String playerId) async {
    final removedPlayer = getPlayer(playerId);
    if (removedPlayer == null) {
      _logger.w('找不到玩家: $playerId');
      return;
    }

    state = state.where((p) => p.playerId != playerId).toList();

    if (_currentPlayer?.playerId == playerId) {
      _currentPlayer = null;
      _currentPlayerController.add(null);
    }

    _playersController.add(state);
    _logger.i('玩家已移除: ${removedPlayer.playerName}');
  }

  @override
  PlayerIdentity? getPlayer(String playerId) {
    try {
      return state.firstWhere((p) => p.playerId == playerId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setHost(String playerId) async {
    final index = state.indexWhere((p) => p.playerId == playerId);
    if (index == -1) {
      _logger.w('找不到玩家: $playerId');
      return;
    }

    // 移除其他玩家的房主标记
    state = state.map((p) {
      if (p.playerId == playerId) {
        return p.copyWith(isHost: true, role: PlayerRole.host);
      } else {
        return p.copyWith(isHost: false, role: PlayerRole.player);
      }
    }).toList();

    _playersController.add(state);
    _logger.i('房主已设置: $playerId');
  }

  @override
  Future<void> mutePlayer(String playerId, {Duration duration = const Duration(minutes: 5)}) async {
    final index = state.indexWhere((p) => p.playerId == playerId);
    if (index == -1) {
      _logger.w('找不到玩家: $playerId');
      return;
    }

    final muteEndTime = DateTime.now().add(duration);

    state = [
      ...state.sublist(0, index),
      state[index].copyWith(
        isMuted: true,
        muteEndTime: muteEndTime,
        status: PlayerStatus.muted,
      ),
      ...state.sublist(index + 1),
    ];

    _playersController.add(state);
    _logger.i('玩家已被禁言: $playerId, 结束时间: $muteEndTime');
  }

  @override
  Future<void> unmutePlayer(String playerId) async {
    final index = state.indexWhere((p) => p.playerId == playerId);
    if (index == -1) {
      _logger.w('找不到玩家: $playerId');
      return;
    }

    state = [
      ...state.sublist(0, index),
      state[index].copyWith(
        isMuted: false,
        muteEndTime: null,
        status: PlayerStatus.online,
      ),
      ...state.sublist(index + 1),
    ];

    _playersController.add(state);
    _logger.i('玩家已解除禁言: $playerId');
  }

  @override
  bool isPlayerMuted(String playerId) {
    final player = getPlayer(playerId);
    if (player == null) return false;

    if (!player.isMuted || player.muteEndTime == null) return false;

    return DateTime.now().isBefore(player.muteEndTime!);
  }

  /// 更新最后活跃时间
  void updateLastActiveTime(String playerId) {
    final index = state.indexWhere((p) => p.playerId == playerId);
    if (index == -1) return;

    state = [
      ...state.sublist(0, index),
      state[index].copyWith(lastActiveAt: DateTime.now()),
      ...state.sublist(index + 1),
    ];

    _playersController.add(state);
  }

  /// 清空所有玩家
  void clearAll() {
    state = [];
    _currentPlayer = null;
    _currentPlayerController.add(null);
    _playersController.add(state);
    _logger.i('所有玩家已清空');
  }

  @override
  void dispose() {
    _currentPlayerController.close();
    _playersController.close();
    super.dispose();
  }
}

/// 玩家状态 Provider
final playerStateProvider =
    StateNotifierProvider<PlayerStateNotifier, List<PlayerIdentity>>((ref) {
  return PlayerStateNotifier();
});
