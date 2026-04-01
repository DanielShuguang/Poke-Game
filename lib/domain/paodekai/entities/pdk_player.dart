import 'pdk_card.dart';

class PdkPlayer {
  final String id;
  final String name;
  final List<PdkCard> hand;
  final bool isAi;

  const PdkPlayer({
    required this.id,
    required this.name,
    required this.hand,
    required this.isAi,
  });

  PdkPlayer copyWith({List<PdkCard>? hand}) {
    return PdkPlayer(
      id: id,
      name: name,
      hand: hand ?? List.of(this.hand),
      isAi: isAi,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isAi': isAi,
        'hand': hand.map((c) => c.toJson()).toList(),
      };

  static PdkPlayer fromJson(Map<String, dynamic> json) {
    return PdkPlayer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isAi: json['isAi'] as bool? ?? false,
      hand: (json['hand'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(PdkCard.fromJson)
          .toList(),
    );
  }
}
