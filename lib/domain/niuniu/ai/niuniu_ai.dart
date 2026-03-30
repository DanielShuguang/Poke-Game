import 'dart:math';

import 'package:poke_game/domain/niuniu/entities/niuniu_game_config.dart';
import 'package:poke_game/domain/niuniu/entities/niuniu_player.dart';

/// 斗牛 AI
///
/// 负责单机模式下闲家的自动下注。
class NiuniuAi {
  final NiuniuGameConfig config;
  final _random = Random();

  NiuniuAi({required this.config});

  /// 决定下注额：在 [50, min(200, chips)] 范围内随机
  int decideBet(int chips) {
    if (chips <= 0) return 0;
    final min = 50;
    final max = chips < 200 ? chips : 200;
    if (min > max) return max; // 筹码不足50时押全部
    return min + _random.nextInt(max - min + 1);
  }

  /// 异步运行（带 aiDelayMs 延迟），为每位 AI 闲家执行下注
  Future<void> runAsync({
    required List<NiuniuPlayer> aiPunters,
    required Future<void> Function(String playerId, int amount) betAction,
  }) async {
    for (final player in aiPunters) {
      if (player.chips <= 0) continue;
      await Future.delayed(Duration(milliseconds: config.aiDelayMs));
      final amount = decideBet(player.chips);
      await betAction(player.id, amount);
    }
  }
}
