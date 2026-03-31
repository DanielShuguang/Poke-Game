import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/shengji/entities/shengji_game_state.dart';
import 'package:poke_game/domain/shengji/entities/shengji_player.dart';
import 'package:poke_game/domain/shengji/entities/shengji_team.dart';
import 'package:poke_game/domain/shengji/usecases/settle_round_usecase.dart';

void main() {
  group('SettleRoundUseCase - 升级结果判定', () {
    final useCase = SettleRoundUseCase();

    test('大光 - 防守队 0 分', () {
      final result = useCase.determineUpgrade(0);
      expect(result, UpgradeResult.bigLight);
    });

    test('小光 - 防守队 40 分及以下', () {
      expect(useCase.determineUpgrade(40), UpgradeResult.smallLight);
      expect(useCase.determineUpgrade(35), UpgradeResult.smallLight);
      expect(useCase.determineUpgrade(1), UpgradeResult.smallLight);
    });

    test('成功 - 防守队 41-80 分', () {
      expect(useCase.determineUpgrade(80), UpgradeResult.success);
      expect(useCase.determineUpgrade(60), UpgradeResult.success);
      expect(useCase.determineUpgrade(41), UpgradeResult.success);
    });

    test('失败 - 防守队 81-120 分', () {
      expect(useCase.determineUpgrade(120), UpgradeResult.fail);
      expect(useCase.determineUpgrade(100), UpgradeResult.fail);
      expect(useCase.determineUpgrade(81), UpgradeResult.fail);
    });

    test('下台 - 防守队 121-160 分', () {
      expect(useCase.determineUpgrade(160), UpgradeResult.down);
      expect(useCase.determineUpgrade(140), UpgradeResult.down);
      expect(useCase.determineUpgrade(121), UpgradeResult.down);
    });

    test('大反 - 防守队 161-200 分', () {
      expect(useCase.determineUpgrade(200), UpgradeResult.bigReverse);
      expect(useCase.determineUpgrade(180), UpgradeResult.bigReverse);
      expect(useCase.determineUpgrade(161), UpgradeResult.bigReverse);
    });
  });

  group('SettleRoundUseCase - 升级级别数', () {
    final useCase = SettleRoundUseCase();

    test('大光升级 3 级', () {
      expect(useCase.getUpgradeLevels(UpgradeResult.bigLight), 3);
    });

    test('小光升级 2 级', () {
      expect(useCase.getUpgradeLevels(UpgradeResult.smallLight), 2);
    });

    test('成功升级 1 级', () {
      expect(useCase.getUpgradeLevels(UpgradeResult.success), 1);
    });

    test('失败不升级', () {
      expect(useCase.getUpgradeLevels(UpgradeResult.fail), 0);
    });

    test('下台不升级', () {
      expect(useCase.getUpgradeLevels(UpgradeResult.down), 0);
    });

    test('大反升级 2 级', () {
      expect(useCase.getUpgradeLevels(UpgradeResult.bigReverse), 2);
    });
  });

  group('SettleRoundUseCase - 换庄判定', () {
    final useCase = SettleRoundUseCase();

    test('大光不换庄', () {
      expect(useCase.shouldChangeDealer(UpgradeResult.bigLight), isFalse);
    });

    test('小光不换庄', () {
      expect(useCase.shouldChangeDealer(UpgradeResult.smallLight), isFalse);
    });

    test('成功不换庄', () {
      expect(useCase.shouldChangeDealer(UpgradeResult.success), isFalse);
    });

    test('失败不换庄', () {
      expect(useCase.shouldChangeDealer(UpgradeResult.fail), isFalse);
    });

    test('下台换庄', () {
      expect(useCase.shouldChangeDealer(UpgradeResult.down), isTrue);
    });

    test('大反换庄', () {
      expect(useCase.shouldChangeDealer(UpgradeResult.bigReverse), isTrue);
    });
  });

  group('SettleRoundUseCase - 结算描述', () {
    test('各结果有描述', () {
      final results = [
        (UpgradeResult.bigLight, '大光'),
        (UpgradeResult.smallLight, '小光'),
        (UpgradeResult.success, '成功'),
        (UpgradeResult.fail, '失败'),
        (UpgradeResult.down, '下台'),
        (UpgradeResult.bigReverse, '大反'),
      ];

      for (final (result, keyword) in results) {
        final settlement = SettlementResult(
          result: result,
          upgradeLevels: 0,
          changeDealer: false,
          newTeams: [],
          dealerTeamScore: 0,
          opponentTeamScore: 0,
        );
        expect(settlement.description, contains(keyword));
      }
    });
  });
}
