/// 斗牛网络行动类型
enum NiuniuActionType {
  /// 下注
  bet,
}

/// 斗牛网络行动
class NiuniuNetworkAction {
  final NiuniuActionType action;
  final String playerId;

  /// 下注金额（action==bet 时使用）
  final int amount;

  const NiuniuNetworkAction({
    required this.action,
    required this.playerId,
    this.amount = 0,
  });

  Map<String, dynamic> toJson() => {
        'action': action.name,
        'playerId': playerId,
        'amount': amount,
      };

  static NiuniuNetworkAction fromJson(Map<String, dynamic> json) {
    final actionStr = json['action'] as String? ?? 'bet';
    return NiuniuNetworkAction(
      action: NiuniuActionType.values.firstWhere(
        (e) => e.name == actionStr,
        orElse: () => NiuniuActionType.bet,
      ),
      playerId: json['playerId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }
}
