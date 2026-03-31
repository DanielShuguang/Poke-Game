import 'package:flutter/material.dart';
import 'package:poke_game/domain/game/entities/game_type_config.dart';
import 'package:poke_game/domain/lan/entities/room_info.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';

/// 游戏规则页面
class GameRulesPage extends StatelessWidget {
  final GameType gameType;
  final Map<String, dynamic>? currentConfig;

  const GameRulesPage({
    super.key,
    required this.gameType,
    this.currentConfig,
  });

  @override
  Widget build(BuildContext context) {
    final config = GameTypeRegistry.getConfig(gameType);
    if (config == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('游戏规则')),
        body: const Center(child: Text('游戏类型不存在')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${config.displayName}规则'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGameOverview(context, config),
            const SizedBox(height: 24),
            _buildPlayerCountInfo(context, config),
            const SizedBox(height: 24),
            if (config.configOptions.isNotEmpty) ...[
              _buildConfigOptions(context, config),
              const SizedBox(height: 24),
            ],
            _buildRulesDetail(context, gameType),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverview(BuildContext context, GameTypeConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              config.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: context.gameColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '预计 ${config.estimatedDuration} 分钟',
                  style: TextStyle(color: context.gameColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCountInfo(BuildContext context, GameTypeConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '人数配置',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (config.fixedPlayerCount != null)
              Row(
                children: [
                  const Icon(Icons.people, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '固定 ${config.fixedPlayerCount} 人',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${config.minPlayerCount} - ${config.maxPlayerCount} 人',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigOptions(BuildContext context, GameTypeConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '游戏设置',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...config.configOptions.map((option) => _buildOptionItem(context, option)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(BuildContext context, GameConfigOption option) {
    String valueText;
    if (option.type == GameConfigType.boolean) {
      valueText = option.defaultValue == true ? '是' : '否';
    } else if (option.type == GameConfigType.enumeration && option.options != null) {
      final opt = option.options!.firstWhere(
        (o) => o.value == option.defaultValue,
        orElse: () => GameConfigOptionValue(value: option.defaultValue, displayName: '${option.defaultValue}'),
      );
      valueText = opt.displayName;
    } else {
      valueText = '${option.defaultValue}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(option.displayName),
              if (option.description != null)
                Text(
                  option.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.gameColors.textSecondary,
                      ),
                ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              valueText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesDetail(BuildContext context, GameType gameType) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '游戏规则',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _getRulesContent(gameType),
          ],
        ),
      ),
    );
  }

  Widget _getRulesContent(GameType gameType) {
    switch (gameType) {
      case GameType.doudizhu:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. 发牌：每人17张，留3张底牌给地主'),
            SizedBox(height: 8),
            Text('2. 叫地主：玩家轮流叫地主，叫地主者获得3张底牌'),
            SizedBox(height: 8),
            Text('3. 出牌：地主先出，顺时针轮流出牌'),
            SizedBox(height: 8),
            Text('4. 牌型：单张、对子、三张、三带一、三带二、顺子、连对、飞机、炸弹、火箭等'),
            SizedBox(height: 8),
            Text('5. 胜负：地主先出完牌则地主胜，任一农民先出完则农民胜'),
          ],
        );
      case GameType.texasHoldem:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. 发牌：每人2张底牌'),
            SizedBox(height: 8),
            Text('2. 翻牌：发出3张公共牌'),
            SizedBox(height: 8),
            Text('3. 转牌：发出第4张公共牌'),
            SizedBox(height: 8),
            Text('4. 河牌：发出第5张公共牌'),
            SizedBox(height: 8),
            Text('5. 比牌：用5张最佳牌型比较大小'),
          ],
        );
      case GameType.zhajinhua:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. 发牌：每人3张牌，牌面朝下'),
            SizedBox(height: 8),
            Text('2. 下注：玩家可以选择看牌、跟注、加注或弃牌'),
            SizedBox(height: 8),
            Text('3. 比牌：最后剩下的玩家开牌比大小'),
            SizedBox(height: 8),
            Text('4. 牌型：豹子 > 同花顺 > 同花 > 顺子 > 对子 > 散牌'),
          ],
        );
      case GameType.blackjack:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. 目标：手牌点数尽量接近21点但不超过'),
            SizedBox(height: 8),
            Text('2. 点数：A=1或11，J/Q/K=10，其余按面值'),
            SizedBox(height: 8),
            Text('3. 操作：Hit摸牌、Stand停牌、Double加倍、Split分牌、Surrender投降'),
            SizedBox(height: 8),
            Text('4. 庄家：点数≤16必须摸牌，≥17停牌（Hard 17规则）'),
            SizedBox(height: 8),
            Text('5. 赔率：Blackjack赔1.5倍，普通胜赔1倍，平局返还'),
          ],
        );
      case GameType.niuniu:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. 发牌：每人5张牌'),
            SizedBox(height: 8),
            Text('2. 判牛：从5张中找3张之和为10的倍数，余2张之和 mod 10 为牛X（0=牛牛）'),
            SizedBox(height: 8),
            Text('3. 特殊牌型：炸弹（4张同点）> 五小牛（5张全≤5且之和≤10）'),
            SizedBox(height: 8),
            Text('4. 倍率：无牛/牛1-6=×1，牛7-9=×2，牛牛=×3，五小牛/炸弹=×5'),
            SizedBox(height: 8),
            Text('5. 结算：庄家与每位闲家单独比较，按闲家倍率结算筹码（平局庄家优先）'),
          ],
        );
      case GameType.shengji:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. 发牌：4人游戏，每人25张，留8张底牌给庄家'),
            SizedBox(height: 8),
            Text('2. 叫牌：亮出对子/拖拉机确定庄家和将牌花色'),
            SizedBox(height: 8),
            Text('3. 组队：对家为队友，两队对抗'),
            SizedBox(height: 8),
            Text('4. 出牌：必须跟同花色，无则可垫牌或杀牌（出将牌）'),
            SizedBox(height: 8),
            Text('5. 计分：5=5分，10/K=10分，共200分'),
            SizedBox(height: 8),
            Text('6. 升级：防守队0分大光+3级，≤40分小光+2级，≤80分成功+1级'),
          ],
        );
    }
  }
}

/// 游戏规则对话框
class GameRulesDialog extends StatelessWidget {
  final GameType gameType;
  final Map<String, dynamic>? currentConfig;

  const GameRulesDialog({
    super.key,
    required this.gameType,
    this.currentConfig,
  });

  static void show(BuildContext context, GameType gameType, {Map<String, dynamic>? currentConfig}) {
    showDialog(
      context: context,
      builder: (context) => GameRulesDialog(
        gameType: gameType,
        currentConfig: currentConfig,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = GameTypeRegistry.getConfig(gameType);
    if (config == null) {
      return AlertDialog(
        title: const Text('游戏规则'),
        content: const Text('游戏类型不存在'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(config.displayName),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(config.description),
            const SizedBox(height: 16),
            Text('人数: ${config.fixedPlayerCount ?? "${config.minPlayerCount}-${config.maxPlayerCount}"} 人'),
            const SizedBox(height: 16),
            if (currentConfig != null && currentConfig!.isNotEmpty) ...[
              const Text('当前配置:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...currentConfig!.entries.map((e) => Text('• ${e.key}: ${e.value}')),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
