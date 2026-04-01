import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/domain/game/entities/game_info.dart';

/// 游戏列表 Provider
final gamesProvider = FutureProvider<List<GameInfo>>((ref) async {
  // 模拟网络延迟
  await Future.delayed(const Duration(milliseconds: 500));

  // 返回游戏列表数据
  return _getMockGames();
});

/// 获取模拟游戏数据
List<GameInfo> _getMockGames() {
  return [
    // 扑克牌类 - 已上线
    const GameInfo(
      id: 'doudizhu',
      name: '斗地主',
      description: '经典斗地主游戏，支持人机对战',
      icon: '🎴',
      status: GameStatus.available,
      category: GameCategory.cardGames,
      route: '/doudizhu',
    ),
    // 扑克牌类 - 开发中
    const GameInfo(
      id: 'texas-holdem',
      name: '德州扑克',
      description: '现金局·支持人机对战与局域网多人',
      icon: '🃏',
      status: GameStatus.available,
      category: GameCategory.cardGames,
      route: '/texas-holdem',
    ),
    const GameInfo(
      id: 'blackjack',
      name: '21点',
      description: '经典21点扑克游戏',
      icon: '🂡',
      status: GameStatus.available,
      category: GameCategory.cardGames,
      route: '/blackjack',
    ),
    const GameInfo(
      id: 'zhajinhua',
      name: '炸金花',
      description: '三张牌博弈，支持人机对战',
      icon: '💰',
      status: GameStatus.available,
      category: GameCategory.cardGames,
      route: '/zhajinhua',
    ),
    const GameInfo(
      id: 'niuniu',
      name: '斗牛',
      description: '比牌博弈，支持人机对战',
      icon: '🐂',
      status: GameStatus.available,
      category: GameCategory.cardGames,
      route: '/niuniu',
    ),
    const GameInfo(
      id: 'shengji',
      name: '升级',
      description: '四人组队对抗，支持人机对战',
      icon: '🎯',
      status: GameStatus.available,
      category: GameCategory.cardGames,
      route: '/shengji',
    ),
    const GameInfo(
      id: 'paodekai',
      name: '跑得快',
      description: '3人竞速，先出完手牌获胜',
      icon: '🏃',
      status: GameStatus.available,
      category: GameCategory.cardGames,
      route: '/paodekai',
    ),
  ];
}
