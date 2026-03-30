import 'package:flutter_test/flutter_test.dart';
import 'package:poke_game/domain/niuniu/ai/niuniu_ai.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_game_config.dart';

void main() {
  group('NiuniuAi.decideBet', () {
    final ai = NiuniuAi(config: NiuniuGameConfig.defaultConfig);

    test('下注范围在 [50, 200] 之间', () {
      for (int i = 0; i < 100; i++) {
        final bet = ai.decideBet(1000);
        expect(bet, greaterThanOrEqualTo(50));
        expect(bet, lessThanOrEqualTo(200));
      }
    });

    test('筹码为 100 时不超过 100', () {
      for (int i = 0; i < 100; i++) {
        final bet = ai.decideBet(100);
        expect(bet, greaterThanOrEqualTo(50));
        expect(bet, lessThanOrEqualTo(100));
      }
    });

    test('筹码为 30 时押全部（不超筹码）', () {
      final bet = ai.decideBet(30);
      expect(bet, lessThanOrEqualTo(30));
      expect(bet, greaterThan(0));
    });

    test('筹码为 0 时返回 0', () {
      expect(ai.decideBet(0), 0);
    });
  });
}
