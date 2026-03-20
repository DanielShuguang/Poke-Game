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
            onPressed: () => context.push('/settings'),
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
          // 局域网对战入口
          _buildLanModeCard(context),
          const SizedBox(height: 24),
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

  /// 局域网对战入口卡片
  Widget _buildLanModeCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.push('/room/scan'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '局域网对战',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '与同一 WiFi 下的好友一起游戏',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
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
