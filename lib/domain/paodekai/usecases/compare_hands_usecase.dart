import '../entities/pdk_hand_type.dart';

class CompareHandsUseCase {
  const CompareHandsUseCase();

  /// 返回 [challenger] 是否能压过 [current]
  bool call(PdkPlayedHand challenger, PdkPlayedHand current) {
    return challenger.beats(current);
  }
}
