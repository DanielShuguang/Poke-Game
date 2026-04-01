import 'pdk_card.dart';

enum PdkActionType { playCards, pass, forcePlayCards, forcePass }

class PdkNetworkAction {
  final PdkActionType action;
  final String playerId;
  final List<PdkCard> cards;

  const PdkNetworkAction({
    required this.action,
    required this.playerId,
    this.cards = const [],
  });

  Map<String, dynamic> toJson() => {
        'action': action.name,
        'playerId': playerId,
        'cards': cards.map((c) => c.toJson()).toList(),
      };

  static PdkNetworkAction fromJson(Map<String, dynamic> json) {
    final action = PdkActionType.values.firstWhere(
      (e) => e.name == json['action'],
      orElse: () => PdkActionType.pass,
    );
    return PdkNetworkAction(
      action: action,
      playerId: json['playerId'] as String? ?? '',
      cards: (json['cards'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(PdkCard.fromJson)
          .toList(),
    );
  }
}
