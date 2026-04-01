import '../entities/pdk_card.dart';
import '../entities/pdk_game_state.dart';
import '../entities/pdk_hand_type.dart';
import 'hand_type_usecase.dart';
import 'compare_hands_usecase.dart';

class ValidatePlayUseCase {
  const ValidatePlayUseCase();

  static const _handType = HandTypeUseCase();
  static const _compare = CompareHandsUseCase();

  /// 返回合法的 [PdkPlayedHand]，否则 null
  PdkPlayedHand? call({
    required List<PdkCard> selectedCards,
    required PdkGameState state,
  }) {
    final hand = _handType(selectedCards);
    if (hand == null) return null;

    // 首轮必须包含 ♠3
    if (state.isFirstPlay) {
      if (!selectedCards.any((c) => c.isSpadeThree)) return null;
      return hand;
    }

    // 无上家（新轮起手），任何合法牌型均可出
    if (state.lastPlayedHand == null) return hand;

    // 否则必须能压过上家
    if (!_compare(hand, state.lastPlayedHand!)) return null;
    return hand;
  }
}
