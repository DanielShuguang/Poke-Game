import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_config.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_state.dart';
import 'package:poke_game/presentation/pages/zhajinhua/providers/zhj_game_notifier.dart';

final zhjGameProvider =
    StateNotifierProvider.autoDispose<ZhjGameNotifier, ZhjGameState>(
  (ref) => ZhjGameNotifier(config: ZhjGameConfig.defaultConfig),
);
