/// 炸金花联机行动类型
enum ZhjActionType {
  peek,
  call,
  raise,
  fold,
  showdown,
}

/// 炸金花网络消息类型常量
class ZhjMessageType {
  static const String action = 'zhj_action';
  static const String stateSync = 'zhj_state_sync';

  ZhjMessageType._();
}

/// 炸金花联机行动（客户端 → Host）
class ZhjNetworkAction {
  final String playerId;
  final ZhjActionType actionType;

  /// 比牌时目标玩家索引（仅 showdown 时有值）
  final int? targetPlayerIndex;

  final DateTime timestamp;

  ZhjNetworkAction({
    required this.playerId,
    required this.actionType,
    this.targetPlayerIndex,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'actionType': actionType.name,
        'targetPlayerIndex': targetPlayerIndex,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ZhjNetworkAction.fromJson(Map<String, dynamic> json) {
    return ZhjNetworkAction(
      playerId: json['playerId'] as String? ?? '',
      actionType: ZhjActionType.values.firstWhere(
        (e) => e.name == json['actionType'],
        orElse: () => ZhjActionType.fold,
      ),
      targetPlayerIndex: json['targetPlayerIndex'] as int?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
