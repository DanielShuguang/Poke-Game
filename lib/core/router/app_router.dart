import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:poke_game/presentation/pages/home/home_page.dart';
import 'package:poke_game/presentation/pages/doudizhu/doudizhu_game_page.dart';
import 'package:poke_game/presentation/pages/settings/settings_page.dart';
import 'package:poke_game/presentation/pages/room/room_scan_page.dart';
import 'package:poke_game/presentation/pages/room/create_room_page.dart';
import 'package:poke_game/presentation/pages/room/room_lobby_page.dart';
import 'package:poke_game/presentation/pages/texas_holdem/holdem_lobby_page.dart';
import 'package:poke_game/presentation/pages/texas_holdem/holdem_game_page.dart';
import 'package:poke_game/presentation/pages/zhajinhua/zhajinhua_page.dart';
import 'package:poke_game/presentation/pages/blackjack/blackjack_page.dart';

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
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (BuildContext context, GoRouterState state) =>
          const SettingsPage(),
    ),
    // 局域网多人游戏路由
    GoRoute(
      path: '/room/scan',
      name: 'room-scan',
      builder: (BuildContext context, GoRouterState state) {
        final gameTypeStr = state.uri.queryParameters['gameType'];
        return RoomScanPage(filterGameType: gameTypeStr);
      },
    ),
    GoRoute(
      path: '/room/create',
      name: 'room-create',
      builder: (BuildContext context, GoRouterState state) =>
          const CreateRoomPage(),
    ),
    GoRoute(
      path: '/room/lobby',
      name: 'room-lobby',
      builder: (BuildContext context, GoRouterState state) =>
          const RoomLobbyPage(),
    ),
    // 预留其他游戏路由
    GoRoute(
      path: '/texas-holdem',
      name: 'texas-holdem',
      builder: (BuildContext context, GoRouterState state) =>
          const HoldemLobbyPage(),
    ),
    GoRoute(
      path: '/texas-holdem/game',
      name: 'texas-holdem-game',
      builder: (BuildContext context, GoRouterState state) =>
          const HoldemGamePage(),
    ),
    GoRoute(
      path: '/zhajinhua',
      name: 'zhajinhua',
      builder: (BuildContext context, GoRouterState state) =>
          const ZhajinhuaPage(),
    ),
    GoRoute(
      path: '/blackjack',
      name: 'blackjack',
      builder: (BuildContext context, GoRouterState state) =>
          const BlackjackPage(),
    ),
  ],
  errorBuilder: (BuildContext context, GoRouterState state) =>
      Scaffold(body: Center(child: Text('页面未找到: ${state.uri}'))),
);
