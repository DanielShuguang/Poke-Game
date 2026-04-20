import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poke_game/core/network/blackjack_network_adapter.dart';
import 'package:poke_game/core/network/guandan_network_adapter.dart';
import 'package:poke_game/core/network/holdem_network_adapter.dart';
import 'package:poke_game/core/network/niuniu_network_adapter.dart';
import 'package:poke_game/core/network/pdk_network_adapter.dart';
import 'package:poke_game/core/network/shengji_network_adapter.dart';
import 'package:poke_game/core/network/zhj_network_adapter.dart';
import 'package:poke_game/domain/lan/entities/room_info.dart';
import 'package:poke_game/presentation/pages/guandan/providers/guandan_game_notifier.dart';
import 'package:poke_game/presentation/pages/paodekai/providers/pdk_notifier.dart';
import 'package:poke_game/presentation/pages/shengji/providers/shengji_notifier.dart';
import 'package:poke_game/presentation/pages/blackjack/blackjack_page.dart';
import 'package:poke_game/presentation/pages/blackjack/providers/blackjack_game_notifier.dart';
import 'package:poke_game/presentation/pages/guandan/guandan_game_page.dart';
import 'package:poke_game/presentation/pages/niuniu/niuniu_page.dart';
import 'package:poke_game/presentation/pages/niuniu/providers/niuniu_game_notifier.dart';
import 'package:poke_game/presentation/pages/paodekai/paodekai_page.dart';
import 'package:poke_game/presentation/pages/shengji/shengji_page.dart';
import 'package:poke_game/presentation/pages/texas_holdem/holdem_game_page.dart';
import 'package:poke_game/presentation/pages/texas_holdem/holdem_provider.dart';
import 'package:poke_game/presentation/pages/zhajinhua/providers/zhj_game_provider.dart';
import 'package:poke_game/presentation/pages/zhajinhua/zhajinhua_page.dart';

import 'lobby_notifier.dart';

/// 根据游戏类型路由至对应游戏页面并初始化 NetworkAdapter
void navigateToGame(
    BuildContext context, WidgetRef ref, LobbyState lobbyState) {
  final room = lobbyState.room;
  if (room == null) return;
  final lobbyNotifier = ref.read(lobbyProvider.notifier);
  final isHost = lobbyState.isHost;
  final localPlayerId = lobbyState.currentPlayerId ?? 'player1';

  final incomingStream = isHost
      ? lobbyNotifier.hostGameStream
      : lobbyNotifier.clientGameStream;

  final turnTimeLimit =
      (room.gameConfig['turnTimeLimit'] as int?) ?? 35;

  void broadcastFn(Map<String, dynamic> msg) {
    if (isHost) {
      lobbyNotifier.broadcastGameMessage(msg);
    } else {
      lobbyNotifier.sendGameMessage(msg);
    }
  }

  switch (room.gameType) {
    case GameType.texasHoldem:
      final holdemNotifier = ref.read(holdemGameProvider.notifier);
      final adapter = HoldemNetworkAdapter(
        incomingStream: incomingStream,
        broadcastFn: broadcastFn,
        notifier: holdemNotifier,
        isHost: isHost,
        localPlayerId: localPlayerId,
        turnTimeLimit: turnTimeLimit,
      );
      adapter.start();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            HoldemGamePage(isOnline: true, networkAdapter: adapter, turnTimeLimit: turnTimeLimit),
      ));
    case GameType.zhajinhua:
      final zhjNotifier = ref.read(zhjGameProvider.notifier);
      final adapter = ZhjNetworkAdapter(
        incomingStream: incomingStream,
        broadcastFn: broadcastFn,
        notifier: zhjNotifier,
        isHost: isHost,
        localPlayerId: localPlayerId,
        turnTimeLimit: turnTimeLimit,
      );
      adapter.start();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            ZhajinhuaPage(isOnline: true, networkAdapter: adapter, turnTimeLimit: turnTimeLimit),
      ));
    case GameType.blackjack:
      final bjNotifier = ref.read(blackjackGameProvider.notifier);
      final adapter = BlackjackNetworkAdapter(
        incomingStream: incomingStream,
        broadcastFn: broadcastFn,
        notifier: bjNotifier,
        isHost: isHost,
        localPlayerId: localPlayerId,
        turnTimeLimit: turnTimeLimit,
      );
      adapter.start();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            BlackjackPage(isOnline: true, networkAdapter: adapter, turnTimeLimit: turnTimeLimit),
      ));
    case GameType.niuniu:
      final nnNotifier = ref.read(niuniuGameProvider.notifier);
      final adapter = NiuniuNetworkAdapter(
        incomingStream: incomingStream,
        broadcastFn: broadcastFn,
        notifier: nnNotifier,
        isHost: isHost,
        localPlayerId: localPlayerId,
        turnTimeLimit: turnTimeLimit,
      );
      adapter.start();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => NiuniuPage(isOnline: true, networkAdapter: adapter, turnTimeLimit: turnTimeLimit),
      ));
    case GameType.doudizhu:
      context.push('/doudizhu');
    case GameType.shengji:
      final shengjiNotifier = ref.read(shengjiNotifierProvider.notifier);
      final adapter = ShengjiNetworkAdapter(
        incomingStream: incomingStream,
        broadcastFn: broadcastFn,
        notifier: shengjiNotifier,
        isHost: isHost,
        localPlayerId: localPlayerId,
        turnTimeLimit: turnTimeLimit,
      );
      adapter.start();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            ShengjiPage(isOnline: true, networkAdapter: adapter, turnTimeLimit: turnTimeLimit),
      ));
    case GameType.paodekai:
      final pdkNotifier = ref.read(pdkGameProvider.notifier);
      final adapter = PdkNetworkAdapter(
        incomingStream: incomingStream,
        broadcastFn: broadcastFn,
        notifier: pdkNotifier,
        isHost: isHost,
        localPlayerId: localPlayerId,
        turnTimeLimit: turnTimeLimit,
      );
      adapter.start();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            PaodekaiPage(isOnline: true, networkAdapter: adapter, turnTimeLimit: turnTimeLimit),
      ));
    case GameType.guandan:
      final guandanNotifier = ref.read(guandanGameProvider.notifier);
      final guandanAdapter = GuandanNetworkAdapter(
        incomingStream: incomingStream,
        broadcastFn: broadcastFn,
        notifier: guandanNotifier,
        isHost: isHost,
        localPlayerId: localPlayerId,
        turnTimeLimit: turnTimeLimit,
      );
      guandanAdapter.start();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => GuandanGamePage(
          isOnline: true,
          networkAdapter: guandanAdapter,
          turnTimeLimit: turnTimeLimit,
        ),
      ));
  }
}
