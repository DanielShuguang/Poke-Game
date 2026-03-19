import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:poke_game/presentation/pages/home/home_page.dart';
import 'package:poke_game/presentation/pages/doudizhu/doudizhu_game_page.dart';

/// 应用路由配置
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) => const HomePage(),
    ),
    GoRoute(
      path: '/doudizhu',
      name: 'doudizhu',
      builder: (BuildContext context, GoRouterState state) =>
          const DoudizhuGamePage(),
    ),
    // 预留其他游戏路由
    // GoRoute(
    //   path: '/texas-holdem',
    //   name: 'texas-holdem',
    //   builder: (BuildContext context, GoRouterState state) =>
    //       const TexasHoldemPage(),
    // ),
  ],
  errorBuilder: (BuildContext context, GoRouterState state) =>
      Scaffold(body: Center(child: Text('页面未找到: ${state.uri}'))),
);
