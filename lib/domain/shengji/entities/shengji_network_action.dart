/// 升级网络行动类型
enum ShengjiActionType {
  /// 叫牌
  callTrump,

  /// 跳过叫牌
  passCall,

  /// 出牌
  playCards,
}

/// 升级网络行动
class ShengjiNetworkAction {
  final ShengjiActionType action;
  final String playerId;

  /// 叫牌内容（action==callTrump 时使用）
  final Map<String, dynamic>? callData;

  /// 出牌数据（action==playCards 时使用）
  final List<Map<String, dynamic>>? cards;

  const ShengjiNetworkAction({
    required this.action,
    required this.playerId,
    this.callData,
    this.cards,
  });

  Map<String, dynamic> toJson() => {
        'action': action.name,
        'playerId': playerId,
        'callData': callData,
        'cards': cards,
      };

  static ShengjiNetworkAction fromJson(Map<String, dynamic> json) {
    final actionStr = json['action'] as String? ?? 'playCards';
    return ShengjiNetworkAction(
      action: ShengjiActionType.values.firstWhere(
        (e) => e.name == actionStr,
        orElse: () => ShengjiActionType.playCards,
      ),
      playerId: json['playerId'] as String? ?? '',
      callData: json['callData'] as Map<String, dynamic>?,
      cards: (json['cards'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
}
