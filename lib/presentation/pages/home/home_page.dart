import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poke_game/domain/game/entities/game_info.dart';
import 'package:poke_game/presentation/pages/home/home_provider.dart';
import 'package:poke_game/presentation/pages/home/widgets/game_card_widget.dart';

/// 游戏首页
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(gamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('扑克游戏合集'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: 设置页面
            },
          ),
        ],
      ),
      body: gamesAsync.when(
        data: (games) => _buildGameList(context, ref, games),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(gamesProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameList(
    BuildContext context,
    WidgetRef ref,
    List<GameInfo> games,
  ) {
    // 按分类分组
    final cardGames = games.where((g) => g.category == GameCategory.cardGames).toList();
    final boardGames = games.where((g) => g.category == GameCategory.boardGames).toList();
    final otherGames = games.where((g) => g.category == GameCategory.other).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(gamesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (cardGames.isNotEmpty) ...[
            _buildSectionHeader(context, '扑克牌类'),
            const SizedBox(height: 8),
            ...cardGames.map((game) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GameCardWidget(
                game: game,
                onTap: () => _handleGameTap(context, game),
              ),
            )),
            const SizedBox(height: 16),
          ],
          if (boardGames.isNotEmpty) ...[
            _buildSectionHeader(context, '棋类'),
            const SizedBox(height: 8),
            ...boardGames.map((game) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GameCardWidget(
                game: game,
                onTap: () => _handleGameTap(context, game),
              ),
            )),
            const SizedBox(height: 16),
          ],
          if (otherGames.isNotEmpty) ...[
            _buildSectionHeader(context, '其他'),
            const SizedBox(height: 8),
            ...otherGames.map((game) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GameCardWidget(
                game: game,
                onTap: () => _handleGameTap(context, game),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  void _handleGameTap(BuildContext context, GameInfo game) {
    if (game.status == GameStatus.available) {
      context.push(game.route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${game.name} 暂未开放，敬请期待！'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
