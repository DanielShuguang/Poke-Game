/// 21点联机行动类型
enum BlackjackActionType { hit, stand, doubleDown, split, surrender }

/// 21点联机网络行动（Client → Host）
class BlackjackNetworkAction {
  final BlackjackActionType action;
  final String playerId;

  /// Split 后有多手时指定操作哪手（0=第一手）
  final int handIndex;

  const BlackjackNetworkAction({
    required this.action,
    required this.playerId,
    this.handIndex = 0,
  });

  Map<String, dynamic> toJson() => {
        'type': 'blackjack_action',
        'action': action.name,
        'playerId': playerId,
        'handIndex': handIndex,
      };

  static BlackjackNetworkAction fromJson(Map<String, dynamic> json) {
    final actionName = json['action'] as String? ?? 'stand';
    final actionType = BlackjackActionType.values.firstWhere(
      (e) => e.name == actionName,
      orElse: () => BlackjackActionType.stand,
    );
    return BlackjackNetworkAction(
      action: actionType,
      playerId: json['playerId'] as String? ?? '',
      handIndex: (json['handIndex'] as num?)?.toInt() ?? 0,
    );
  }
}
