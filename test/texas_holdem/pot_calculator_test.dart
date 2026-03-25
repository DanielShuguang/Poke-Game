import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/texas_holdem/entities/holdem_player.dart';
import 'package:poke_game/domain/texas_holdem/entities/pot.dart';
import 'package:poke_game/domain/texas_holdem/usecases/pot_calculator.dart';

HoldemPlayer _player(String id, int chips, int bet, {bool isFolded = false, bool isAllIn = false}) {
  return HoldemPlayer(
    id: id,
    name: id,
    chips: chips,
    currentBet: bet,
    isFolded: isFolded,
    isAllIn: isAllIn,
  );
}

void main() {
  group('PotCalculator', () {
    group('calculate', () {
      test('无 All-in：3人各投注100', () {
        final players = [
          _player('A', 900, 100),
          _player('B', 900, 100),
          _player('C', 900, 100),
        ];
        final pots = PotCalculator.calculate(players);
        expect(pots.length, 1);
        expect(pots[0].amount, 300);
        expect(pots[0].eligiblePlayerIds, containsAll(['A', 'B', 'C']));
      });

      test('单人 All-in：A=50 all-in, B=100, C=100', () {
        final players = [
          _player('A', 0, 50, isAllIn: true),
          _player('B', 950, 100),
          _player('C', 950, 100),
        ];
        final pots = PotCalculator.calculate(players);
        // 主池：50*3=150，边池：50*2=100
        expect(pots.length, 2);
        expect(pots[0].amount, 150); // 主池
        expect(pots[0].eligiblePlayerIds, containsAll(['A', 'B', 'C']));
        expect(pots[1].amount, 100); // 边池（A 不参与）
        expect(pots[1].eligiblePlayerIds, containsAll(['B', 'C']));
        expect(pots[1].eligiblePlayerIds, isNot(contains('A')));
      });

      test('多人不同金额 All-in：A=30, B=80, C=100', () {
        final players = [
          _player('A', 0, 30, isAllIn: true),
          _player('B', 0, 80, isAllIn: true),
          _player('C', 900, 100),
        ];
        final pots = PotCalculator.calculate(players);
        // 层级1：0-30，每人贡献30，共3人，主池=90
        // 层级2：31-80，每人贡献50，B+C参与，池=100
        // 层级3：81-100，每人贡献20，仅C参与，池=20
        expect(pots.length, 3);
        expect(pots[0].amount, 90);
        expect(pots[0].eligiblePlayerIds, containsAll(['A', 'B', 'C']));
        expect(pots[1].amount, 100);
        expect(pots[1].eligiblePlayerIds, containsAll(['B', 'C']));
        expect(pots[1].eligiblePlayerIds, isNot(contains('A')));
        expect(pots[2].amount, 20);
        expect(pots[2].eligiblePlayerIds, contains('C'));
        expect(pots[2].eligiblePlayerIds.length, 1);
      });

      test('已弃牌玩家不在 eligible 列表中', () {
        final players = [
          _player('A', 900, 100),
          _player('B', 900, 100, isFolded: true),
          _player('C', 900, 100),
        ];
        final pots = PotCalculator.calculate(players);
        expect(pots[0].eligiblePlayerIds, containsAll(['A', 'C']));
        expect(pots[0].eligiblePlayerIds, isNot(contains('B')));
      });
    });

    group('distribute', () {
      test('单底池，单赢家', () {
        final pots = [const Pot(amount: 300, eligiblePlayerIds: ['A', 'B', 'C'])];
        final result = PotCalculator.distribute(pots, [['A']]);
        expect(result['A'], 300);
        expect(result['B'], isNull);
      });

      test('平局均分，无余数', () {
        final pots = [const Pot(amount: 200, eligiblePlayerIds: ['A', 'B'])];
        final result = PotCalculator.distribute(pots, [['A', 'B']]);
        expect(result['A'], 100);
        expect(result['B'], 100);
      });

      test('平局均分，奇数筹码余数归小盲', () {
        final pots = [const Pot(amount: 101, eligiblePlayerIds: ['A', 'B'])];
        final result = PotCalculator.distribute(pots, [['A', 'B']], smallBlindPlayerId: 'B');
        // 101 / 2 = 50 余 1，余数归小盲 B
        expect(result['A'], 50);
        expect(result['B'], 51);
      });

      test('奇数筹码余数归第一个获胜者（小盲不在获胜者中）', () {
        final pots = [const Pot(amount: 101, eligiblePlayerIds: ['A', 'B'])];
        final result = PotCalculator.distribute(pots, [['A', 'B']], smallBlindPlayerId: 'C');
        expect(result['A'], 51); // 第一个获胜者
        expect(result['B'], 50);
      });
    });

    group('筹码守恒', () {
      test('无 All-in 场景筹码总量守恒', () {
        final players = [
          _player('A', 900, 100),
          _player('B', 900, 100),
          _player('C', 900, 100),
        ];
        final pots = PotCalculator.calculate(players);
        final totalBets = players.fold(0, (sum, p) => sum + p.currentBet);
        final totalPots = pots.fold(0, (sum, p) => sum + p.amount);
        expect(totalPots, equals(totalBets));
      });

      test('多人 All-in 场景筹码总量守恒', () {
        final players = [
          _player('A', 0, 30, isAllIn: true),
          _player('B', 0, 80, isAllIn: true),
          _player('C', 900, 100),
          _player('D', 900, 100),
        ];
        final pots = PotCalculator.calculate(players);
        final totalBets = players.fold(0, (sum, p) => sum + p.currentBet);
        final totalPots = pots.fold(0, (sum, p) => sum + p.amount);
        expect(totalPots, equals(totalBets));
      });

      test('分配后筹码总量守恒', () {
        final pots = [
          const Pot(amount: 150, eligiblePlayerIds: ['A', 'B', 'C']),
          const Pot(amount: 100, eligiblePlayerIds: ['B', 'C']),
        ];
        final result = PotCalculator.distribute(pots, [['A'], ['B']]);
        final totalOut = result.values.fold(0, (sum, v) => sum + v);
        expect(totalOut, equals(250));
      });
    });
  });
}
