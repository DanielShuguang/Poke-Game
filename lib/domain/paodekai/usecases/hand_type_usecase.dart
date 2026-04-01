import '../entities/pdk_card.dart';
import '../entities/pdk_hand_type.dart';
import '../validators/card_validator.dart';
import '../validators/consecutive_validator.dart';
import '../validators/straight_validator.dart';

class HandTypeUseCase {
  const HandTypeUseCase();

  static const _card = CardValidator();
  static const _straight = StraightValidator();
  static const _consecutive = ConsecutiveValidator();

  /// 返回合法牌型，不合法返回 null
  PdkPlayedHand? call(List<PdkCard> cards) {
    if (cards.isEmpty) return null;
    return _card.validate(cards) ??
        _straight.validate(cards) ??
        _consecutive.validate(cards);
  }
}
