import '../entities/guandan_card.dart';

/// 掼蛋联机行动消息（sealed class，JSON 序列化）
sealed class GuandanNetworkAction {
  const GuandanNetworkAction();

  Map<String, dynamic> toJson();

  static GuandanNetworkAction fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'playCards' => PlayCardsNetworkAction(
          cards: (json['cards'] as List<dynamic>)
              .map((id) => GuandanCard.fromId(id as String))
              .toList(),
        ),
      'pass' => const PassNetworkAction(),
      'tribute' => TributeNetworkAction(
          card: GuandanCard.fromId(json['card'] as String),
          playerId: json['playerId'] as String?,
        ),
      'returnTribute' => ReturnTributeNetworkAction(
          card: GuandanCard.fromId(json['card'] as String),
          playerId: json['playerId'] as String?,
        ),
      _ => throw ArgumentError('Unknown GuandanNetworkAction type: $type'),
    };
  }
}

class PlayCardsNetworkAction extends GuandanNetworkAction {
  final List<GuandanCard> cards;

  const PlayCardsNetworkAction({required this.cards});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'playCards',
        'cards': cards.map((c) => c.toId()).toList(),
      };
}

class PassNetworkAction extends GuandanNetworkAction {
  const PassNetworkAction();

  @override
  Map<String, dynamic> toJson() => {'type': 'pass'};
}

class TributeNetworkAction extends GuandanNetworkAction {
  final GuandanCard card;
  final String? playerId;

  const TributeNetworkAction({required this.card, this.playerId});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tribute',
        'card': card.toId(),
        if (playerId != null) 'playerId': playerId,
      };
}

class ReturnTributeNetworkAction extends GuandanNetworkAction {
  final GuandanCard card;
  final String? playerId;

  const ReturnTributeNetworkAction({required this.card, this.playerId});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'returnTribute',
        'card': card.toId(),
        if (playerId != null) 'playerId': playerId,
      };
}
