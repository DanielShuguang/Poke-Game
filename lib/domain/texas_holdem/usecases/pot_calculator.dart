import 'package:poke_game/domain/texas_holdem/entities/holdem_player.dart';
import 'package:poke_game/domain/texas_holdem/entities/pot.dart';

/// 边池计算器
///
/// 处理 All-in 场景下的主池和边池分层计算。
class PotCalculator {
  /// 根据玩家投注状态计算底池列表。
  ///
  /// [players] 当前所有玩家（含已弃牌、All-in）。
  /// [smallBlindPlayerIndex] 小盲位索引，用于奇数筹码归属。
  ///
  /// 返回底池列表，索引0为主池，后续为边池。
  static List<Pot> calculate(
    List<HoldemPlayer> players, {
    int smallBlindPlayerIndex = 0,
  }) {
    // 只考虑本轮已投注的玩家（currentBet > 0 或 已弃牌但有投注）
    final contributors = players
        .where((p) => p.currentBet > 0)
        .toList();

    if (contributors.isEmpty) return [];

    // 按投注额升序排列，确定分层
    final sorted = [...contributors]
      ..sort((a, b) => a.currentBet.compareTo(b.currentBet));

    final pots = <Pot>[];
    var processedBet = 0;

    for (var i = 0; i < sorted.length; i++) {
      final level = sorted[i].currentBet;
      if (level <= processedBet) continue;

      final increment = level - processedBet;
      final eligible = players
          .where((p) => p.currentBet >= level && !p.isFolded)
          .map((p) => p.id)
          .toList();

      // 计算该层底池金额：所有投注额 >= level 的玩家贡献 increment
      final contributors2 = players.where((p) => p.currentBet >= level).length;
      final potAmount = increment * contributors2;

      if (potAmount > 0) {
        pots.add(Pot(amount: potAmount, eligiblePlayerIds: eligible));
      }

      processedBet = level;
    }

    return pots;
  }

  /// 将奖金分配给各底池的获胜者。
  ///
  /// [pots] 底池列表。
  /// [winnerIdsByPot] 每个底池的获胜玩家 ID 列表（可多人平局）。
  /// [smallBlindPlayerId] 小盲玩家 ID，奇数筹码余数归此玩家。
  ///
  /// 返回每个玩家获得的筹码数 Map<playerId, amount>。
  static Map<String, int> distribute(
    List<Pot> pots,
    List<List<String>> winnerIdsByPot, {
    String? smallBlindPlayerId,
  }) {
    assert(pots.length == winnerIdsByPot.length,
        'pots 和 winnerIdsByPot 长度不匹配');

    final result = <String, int>{};

    for (var i = 0; i < pots.length; i++) {
      final pot = pots[i];
      final winners = winnerIdsByPot[i];
      if (winners.isEmpty) continue;

      final share = pot.amount ~/ winners.length;
      final remainder = pot.amount % winners.length;

      for (final winnerId in winners) {
        result[winnerId] = (result[winnerId] ?? 0) + share;
      }

      // 奇数筹码归小盲位（若小盲在获胜者中），否则归第一个获胜者
      if (remainder > 0) {
        final extraRecipient =
            (smallBlindPlayerId != null && winners.contains(smallBlindPlayerId))
                ? smallBlindPlayerId
                : winners.first;
        result[extraRecipient] = (result[extraRecipient] ?? 0) + remainder;
      }
    }

    return result;
  }
}
