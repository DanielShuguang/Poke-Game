import '../entities/guandan_game_state.dart';
import '../entities/guandan_player.dart';

/// 局结算：根据 finishRank 计算升降级档数并返回新状态
class RoundResultUsecase {
  const RoundResultUsecase._();

  /// 计算本局结算结果，更新 state 中的 team0Level / team1Level。
  /// 规则（参见 spec）：
  /// - 己方包揽头游/二游 → 升2级
  /// - 己方头游、对方二游 → 升1级
  /// - 对方头游、己方二游 → 双方不升级
  /// - 对方包揽头游/二游 → 己方降2级（level 最低为2）
  static GuandanGameState calculate(GuandanGameState state) {
    final finishedPlayers = state.players
        .where((p) => p.finishRank != null)
        .toList()
      ..sort((a, b) => a.finishRank!.index.compareTo(b.finishRank!.index));

    if (finishedPlayers.length < 4) {
      // 局未结束，不结算
      return state;
    }

    final first = finishedPlayers[0];
    final second = finishedPlayers[1];

    int team0Delta = 0;
    int team1Delta = 0;

    if (first.teamId == second.teamId) {
      // 同队包揽头二游
      if (first.teamId == 0) {
        team0Delta = 2;
      } else {
        team1Delta = 2;
      }
    } else {
      // 头游所在队升1级
      if (first.teamId == 0) {
        team0Delta = 1;
      } else {
        team1Delta = 1;
      }
    }

    // 输方降级：对方包揽时己方 -2
    if (first.teamId == second.teamId) {
      if (first.teamId == 0) {
        team1Delta = -2;
      } else {
        team0Delta = -2;
      }
    }

    final newTeam0Level =
        (state.team0Level + team0Delta).clamp(2, 14);
    final newTeam1Level =
        (state.team1Level + team1Delta).clamp(2, 14);

    final finishOrder = finishedPlayers.map((p) => p.id).toList();
    final winnerTeamId =
        (team0Delta > 0) ? 0 : (team1Delta > 0 ? 1 : null);

    final result = RoundResult(
      winnerTeamId: winnerTeamId,
      team0LevelDelta: team0Delta,
      team1LevelDelta: team1Delta,
      finishOrder: finishOrder,
    );

    // 检查胜利条件：升到A后继续满足升级条件
    final isTeam0Win = state.team0Level == 14 && team0Delta > 0;
    final isTeam1Win = state.team1Level == 14 && team1Delta > 0;

    final newPhase =
        (isTeam0Win || isTeam1Win) ? GuandanPhase.finished : GuandanPhase.settling;

    return state.copyWith(
      phase: newPhase,
      team0Level: newTeam0Level,
      team1Level: newTeam1Level,
      roundResult: result,
    );
  }

  /// 下局先手座位：本局头游的座位索引
  static int nextLeadSeat(GuandanGameState state) {
    final first = state.players
        .firstWhere((p) => p.finishRank == FinishRank.first);
    return first.seatIndex;
  }

  /// 是否需要贡牌阶段（对方包揽时触发）
  static bool needsTribute(GuandanGameState state) {
    final result = state.roundResult;
    if (result == null) return false;
    // 某队包揽头二游（delta 绝对值 == 2）
    return result.team0LevelDelta.abs() == 2 ||
        result.team1LevelDelta.abs() == 2;
  }
}
