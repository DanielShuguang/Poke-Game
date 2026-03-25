/// 底池（主池或边池）
class Pot {
  /// 底池金额
  final int amount;

  /// 有资格赢得此底池的玩家 ID 列表
  final List<String> eligiblePlayerIds;

  const Pot({
    required this.amount,
    required this.eligiblePlayerIds,
  });

  Pot copyWith({int? amount, List<String>? eligiblePlayerIds}) {
    return Pot(
      amount: amount ?? this.amount,
      eligiblePlayerIds: eligiblePlayerIds ?? this.eligiblePlayerIds,
    );
  }

  @override
  String toString() => 'Pot(amount=$amount, eligible=${eligiblePlayerIds.length} players)';
}
