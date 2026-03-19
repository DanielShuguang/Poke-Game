import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/domain/doudizhu/entities/game_config.dart';
import 'package:poke_game/domain/doudizhu/usecases/call_landlord_usecase.dart';
import 'package:poke_game/domain/doudizhu/usecases/check_winner_usecase.dart';
import 'package:poke_game/domain/doudizhu/usecases/deal_cards_usecase.dart';
import 'package:poke_game/domain/doudizhu/usecases/play_cards_usecase.dart';
import 'package:poke_game/domain/doudizhu/validators/card_validator.dart';
import 'package:poke_game/presentation/pages/doudizhu/doudizhu_notifier.dart';
import 'package:poke_game/presentation/pages/doudizhu/doudizhu_state.dart';

/// 斗地主 Provider
final doudizhuProvider =
    StateNotifierProvider.autoDispose<DoudizhuNotifier, DoudizhuUiState>(
  (ref) => DoudizhuNotifier(
    dealCardsUseCase: DealCardsUseCase(),
    callLandlordUseCase: CallLandlordUseCase(),
    playCardsUseCase: PlayCardsUseCase(),
    checkWinnerUseCase: CheckWinnerUseCase(),
    validator: const CardValidator(),
    config: GameConfig.defaultConfig,
  ),
);
