import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_identity.freezed.dart';
part 'player_identity.g.dart';

/// 玩家状态
enum PlayerStatus {
  /// 在线（等待中）
  online,

  /// 已准备
  ready,

  /// 游戏中
  playing,

  /// 暂时离线（可重连）
  disconnected,

  /// 已离线
  offline,

  /// 被禁言
  muted,
}

/// 玩家角色
enum PlayerRole {
  /// 普通玩家
  player,

  /// 房主
  host,

  /// 地主（游戏中）
  landlord,

  /// 农民（游戏中）
  peasant,
}

/// 玩家身份模型
///
/// 用于局域网内玩家身份识别和状态管理
@freezed
class PlayerIdentity with _$PlayerIdentity {
  const factory PlayerIdentity({
    /// 玩家ID（UUID）
    required String playerId,

    /// 玩家名称
    required String playerName,

    /// 座位号（1开始）
    required int seatNumber,

    /// 玩家状态
    required PlayerStatus status,

    /// 玩家角色
    @Default(PlayerRole.player) PlayerRole role,

    /// 设备名称
    String? deviceName,

    /// 设备IP地址
    String? ipAddress,

    /// 加入时间
    DateTime? joinedAt,

    /// 最后活跃时间
    DateTime? lastActiveAt,

    /// 是否是房主
    @Default(false) bool isHost,

    /// 是否被禁言
    @Default(false) bool isMuted,

    /// 禁言结束时间
    DateTime? muteEndTime,
  }) = _PlayerIdentity;

  factory PlayerIdentity.fromJson(Map<String, dynamic> json) =>
      _$PlayerIdentityFromJson(json);
}

/// 玩家身份扩展方法
extension PlayerIdentityX on PlayerIdentity {
  /// 是否在线
  bool get isOnline => status != PlayerStatus.offline;

  /// 是否可以开始游戏
  bool get canStartGame => status == PlayerStatus.ready || status == PlayerStatus.playing;

  /// 是否可以重连
  bool get canReconnect => status == PlayerStatus.disconnected;

  /// 是否在禁言中
  bool get isInMute {
    if (!isMuted || muteEndTime == null) return false;
    return DateTime.now().isBefore(muteEndTime!);
  }

  /// 获取显示名称（包含座位号）
  String get displayName => '$playerName ($seatNumber号位)';

  /// 获取状态显示文本
  String get statusText {
    switch (status) {
      case PlayerStatus.online:
        return '在线';
      case PlayerStatus.ready:
        return '已准备';
      case PlayerStatus.playing:
        return '游戏中';
      case PlayerStatus.disconnected:
        return '已断线';
      case PlayerStatus.offline:
        return '已离线';
      case PlayerStatus.muted:
        return '被禁言';
    }
  }
}
