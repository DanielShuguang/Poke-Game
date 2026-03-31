import 'package:poke_game/domain/shengji/entities/shengji_game_state.dart';
import 'package:poke_game/domain/shengji/entities/shengji_team.dart';

/// 升级结果
enum UpgradeResult {
  /// 大光（防守队 0 分）→ +3 级
  bigLight,

  /// 小光（防守队 1-40 分）→ +2 级
  smallLight,

  /// 成功（防守队 41-80 分）→ +1 级
  success,

  /// 失败（防守队 81-120 分）→ 不升级
  fail,

  /// 下台（防守队 121-160 分）→ 庄家下台
  down,

  /// 大反（防守队 161-200 分）→ 上台 +2 级
  bigReverse,
}

/// 结算用例
class SettleRoundUseCase {
  /// 判定升级结果
  UpgradeResult determineUpgrade(int opponentScore) {
    if (opponentScore == 0) {
      return UpgradeResult.bigLight;
    } else if (opponentScore <= 40) {
      return UpgradeResult.smallLight;
    } else if (opponentScore <= 80) {
      return UpgradeResult.success;
    } else if (opponentScore <= 120) {
      return UpgradeResult.fail;
    } else if (opponentScore <= 160) {
      return UpgradeResult.down;
    } else {
      return UpgradeResult.bigReverse;
    }
  }

  /// 计算升级级别数
  int getUpgradeLevels(UpgradeResult result) {
    switch (result) {
      case UpgradeResult.bigLight:
        return 3;
      case UpgradeResult.smallLight:
        return 2;
      case UpgradeResult.success:
        return 1;
      case UpgradeResult.fail:
      case UpgradeResult.down:
        return 0;
      case UpgradeResult.bigReverse:
        return 2;
    }
  }

  /// 判断是否需要换庄家
  bool shouldChangeDealer(UpgradeResult result) {
    return result == UpgradeResult.down || result == UpgradeResult.bigReverse;
  }

  /// 结算一局游戏
  SettlementResult settle({
    required ShengjiGameState state,
    required int dealerTeamScore,
    required int opponentTeamScore,
  }) {
    final result = determineUpgrade(opponentTeamScore);
    final upgradeLevels = getUpgradeLevels(result);
    final changeDealer = shouldChangeDealer(result);

    // 更新队伍信息
    List<ShengjiTeam> newTeams;
    if (changeDealer) {
      // 庄家下台，对方上台
      newTeams = state.teams.map((team) {
        if (team.isDealer) {
          // 原庄家队下台
          return team.copyWith(isDealer: false, roundScore: dealerTeamScore);
        } else {
          // 防守队上台，可能升级
          final newLevel = upgradeLevels > 0
              ? _advanceLevel(team.currentLevel, upgradeLevels)
              : team.currentLevel;
          return team.copyWith(
            currentLevel: newLevel,
            isDealer: true,
            roundScore: opponentTeamScore,
          );
        }
      }).toList();
    } else {
      // 庄家继续，升级
      newTeams = state.teams.map((team) {
        if (team.isDealer) {
          final newLevel = upgradeLevels > 0
              ? _advanceLevel(team.currentLevel, upgradeLevels)
              : team.currentLevel;
          return team.copyWith(
            currentLevel: newLevel,
            roundScore: dealerTeamScore,
          );
        } else {
          return team.copyWith(roundScore: opponentTeamScore);
        }
      }).toList();
    }

    return SettlementResult(
      result: result,
      upgradeLevels: upgradeLevels,
      changeDealer: changeDealer,
      newTeams: newTeams,
      dealerTeamScore: dealerTeamScore,
      opponentTeamScore: opponentTeamScore,
    );
  }

  /// 升级（2-A 循环）
  int _advanceLevel(int currentLevel, int levels) {
    int newLevel = currentLevel + levels;
    // 超过 A（14）后循环回 2
    while (newLevel > 14) {
      newLevel = newLevel - 13; // 2-14 共 13 级
    }
    return newLevel;
  }
}

/// 结算结果
class SettlementResult {
  final UpgradeResult result;
  final int upgradeLevels;
  final bool changeDealer;
  final List<ShengjiTeam> newTeams;
  final int dealerTeamScore;
  final int opponentTeamScore;

  const SettlementResult({
    required this.result,
    required this.upgradeLevels,
    required this.changeDealer,
    required this.newTeams,
    required this.dealerTeamScore,
    required this.opponentTeamScore,
  });

  /// 结果描述
  String get description {
    switch (result) {
      case UpgradeResult.bigLight:
        return '大光！庄家队升 3 级';
      case UpgradeResult.smallLight:
        return '小光！庄家队升 2 级';
      case UpgradeResult.success:
        return '庄家队成功升级！';
      case UpgradeResult.fail:
        return '庄家队升级失败';
      case UpgradeResult.down:
        return '庄家下台，防守队上台';
      case UpgradeResult.bigReverse:
        return '大反！防守队上台并升 2 级';
    }
  }
}
