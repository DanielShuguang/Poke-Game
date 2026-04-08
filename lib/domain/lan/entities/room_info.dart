import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_info.freezed.dart';
part 'room_info.g.dart';

/// 房间状态
enum RoomStatus {
  /// 等待中（等待玩家加入/准备）
  waiting,

  /// 游戏中
  playing,

  /// 已关闭
  closed,
}

/// 游戏类型
enum GameType {
  /// 斗地主
  doudizhu,

  /// 德州扑克（预留）
  texasHoldem,

  /// 炸金花（预留）
  zhajinhua,

  /// 21点
  blackjack,

  /// 斗牛
  niuniu,

  /// 升级
  shengji,

  /// 跑得快
  paodekai,

  /// 掼蛋
  guandan,
}

/// 游戏类型扩展
extension GameTypeX on GameType {
  /// 获取游戏显示名称
  String get displayName {
    switch (this) {
      case GameType.doudizhu:
        return '斗地主';
      case GameType.texasHoldem:
        return '德州扑克';
      case GameType.zhajinhua:
        return '炸金花';
      case GameType.blackjack:
        return '21点';
      case GameType.niuniu:
        return '斗牛';
      case GameType.shengji:
        return '升级';
      case GameType.paodekai:
        return '跑得快';
      case GameType.guandan:
        return '掼蛋';
    }
  }

  /// 获取固定人数（某些游戏有固定人数要求）
  int? get fixedPlayerCount {
    switch (this) {
      case GameType.doudizhu:
        return 3;
      case GameType.shengji:
        return 4;
      case GameType.paodekai:
        return 3;
      case GameType.guandan:
        return 4;
      case GameType.texasHoldem:
      case GameType.zhajinhua:
      case GameType.blackjack:
      case GameType.niuniu:
        return null; // 可变人数
    }
  }

  /// 获取最小人数
  int get minPlayerCount {
    switch (this) {
      case GameType.doudizhu:
        return 3;
      case GameType.shengji:
        return 4;
      case GameType.texasHoldem:
        return 2;
      case GameType.zhajinhua:
        return 2;
      case GameType.blackjack:
        return 2;
      case GameType.niuniu:
        return 2;
      case GameType.paodekai:
        return 3;
      case GameType.guandan:
        return 4;
    }
  }

  /// 获取最大人数
  int get maxPlayerCount {
    switch (this) {
      case GameType.doudizhu:
        return 3;
      case GameType.shengji:
        return 4;
      case GameType.texasHoldem:
        return 9;
      case GameType.zhajinhua:
        return 6;
      case GameType.blackjack:
        return 7;
      case GameType.niuniu:
        return 6;
      case GameType.paodekai:
        return 3;
      case GameType.guandan:
        return 4;
    }
  }

  /// 是否支持人数配置
  bool get supportsPlayerCountConfig => fixedPlayerCount == null;
}

/// 房间信息模型
///
/// 用于局域网广播和房间列表展示
@freezed
class RoomInfo with _$RoomInfo {
  const factory RoomInfo({
    /// 房间ID（UUID）
    required String roomId,

    /// 房间名称
    required String roomName,

    /// 游戏类型
    required GameType gameType,

    /// 当前玩家数量
    required int currentPlayerCount,

    /// 最大玩家数量
    required int maxPlayerCount,

    /// 房主设备名称
    required String hostDeviceName,

    /// 房间状态
    required RoomStatus status,

    /// 网络地址（IP:Port）
    required String networkAddress,

    /// HTTP端口
    @Default(8080) int httpPort,

    /// WebSocket端口
    @Default(8082) int webSocketPort,

    /// 是否需要密码
    @Default(false) bool requiresPassword,

    /// 创建时间
    DateTime? createdAt,
  }) = _RoomInfo;

  factory RoomInfo.fromJson(Map<String, dynamic> json) =>
      _$RoomInfoFromJson(json);
}

/// 房间信息扩展方法
extension RoomInfoX on RoomInfo {
  /// 是否已满员
  bool get isFull => currentPlayerCount >= maxPlayerCount;

  /// 是否可以加入
  bool get canJoin => status == RoomStatus.waiting && !isFull;

  /// 获取显示地址
  String get displayAddress {
    return '$networkAddress:$httpPort';
  }
}
