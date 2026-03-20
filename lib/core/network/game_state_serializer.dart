import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';

/// 游戏状态序列化器
///
/// 用于将游戏状态序列化/反序列化以进行网络传输
class GameStateSerializer {
  final Logger _logger = Logger();

  /// 序列化卡牌
  Map<String, dynamic> serializeCard(Card card) {
    return {
      'suit': card.suit.index,
      'rank': card.rank,
    };
  }

  /// 反序列化卡牌
  Card deserializeCard(Map<String, dynamic> json) {
    return Card(
      suit: Suit.values[json['suit'] as int],
      rank: json['rank'] as int,
    );
  }

  /// 序列化卡牌列表
  List<Map<String, dynamic>> serializeCards(List<Card> cards) {
    return cards.map(serializeCard).toList();
  }

  /// 反序列化卡牌列表
  List<Card> deserializeCards(List<dynamic> jsonList) {
    return jsonList
        .map((json) => deserializeCard(json as Map<String, dynamic>))
        .toList();
  }

  /// 序列化玩家（仅公开信息，不包含手牌）
  Map<String, dynamic> serializePlayerPublic(Player player) {
    return {
      'id': player.id,
      'name': player.name,
      'role': player.role?.index,
      'handCardCount': player.handCards.length,
    };
  }

  /// 序列化玩家（包含手牌，用于发送给该玩家自己）
  Map<String, dynamic> serializePlayerPrivate(Player player) {
    return {
      'id': player.id,
      'name': player.name,
      'role': player.role?.index,
      'handCards': serializeCards(player.handCards),
    };
  }

  /// 序列化游戏状态（公开信息）
  Map<String, dynamic> serializeGameStatePublic(GameState state, {String? excludePlayerId}) {
    return {
      'phase': state.phase.index,
      'players': state.players.map((p) {
        // 如果指定了排除玩家，则该玩家的手牌不显示
        if (excludePlayerId != null && p.id == excludePlayerId) {
          return serializePlayerPublic(p);
        }
        return serializePlayerPublic(p);
      }).toList(),
      'currentPlayerIndex': state.currentPlayerIndex,
      'landlordCards': state.landlordCards.isEmpty
          ? []
          : serializeCards(state.landlordCards), // 底牌在叫地主后公开
      'lastPlayedCards': state.lastPlayedCards != null
          ? serializeCards(state.lastPlayedCards!)
          : null,
      'lastPlayerIndex': state.lastPlayerIndex,
      'landlordIndex': state.landlordIndex,
      'callingPlayerIndex': state.callingPlayerIndex,
      'callCount': state.callCount,
    };
  }

  /// 序列化游戏状态（包含指定玩家的手牌）
  Map<String, dynamic> serializeGameStateForPlayer(GameState state, String playerId) {
    return {
      'phase': state.phase.index,
      'players': state.players.map((p) {
        if (p.id == playerId) {
          return serializePlayerPrivate(p);
        }
        return serializePlayerPublic(p);
      }).toList(),
      'currentPlayerIndex': state.currentPlayerIndex,
      'landlordCards': state.phase == GamePhase.calling
          ? [] // 叫地主阶段底牌不公开
          : serializeCards(state.landlordCards),
      'lastPlayedCards': state.lastPlayedCards != null
          ? serializeCards(state.lastPlayedCards!)
          : null,
      'lastPlayerIndex': state.lastPlayerIndex,
      'landlordIndex': state.landlordIndex,
      'callingPlayerIndex': state.callingPlayerIndex,
      'callCount': state.callCount,
    };
  }

  /// 序列化为 JSON 字符串
  String toJsonString(Map<String, dynamic> json) {
    return jsonEncode(json);
  }

  /// 从 JSON 字符串反序列化
  Map<String, dynamic> fromJsonString(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// 压缩消息（大于 1KB 时）
  Future<String> compressIfNeeded(String message) async {
    if (message.length > 1024) {
      // 使用 gzip 压缩
      final bytes = utf8.encode(message);
      final compressed = gzip.encode(bytes);
      final base64 = base64Encode(compressed);
      _logger.d('消息已压缩: ${message.length} -> $base64.length');
      return 'GZIP:$base64';
    }
    return message;
  }

  /// 解压消息（如果需要）
  Future<String> decompressIfNeeded(String message) async {
    if (message.startsWith('GZIP:')) {
      final base64 = message.substring(5);
      final compressed = base64Decode(base64);
      final bytes = gzip.decode(compressed);
      final decompressed = utf8.decode(bytes);
      _logger.d('消息已解压: ${message.length} -> ${decompressed.length}');
      return decompressed;
    }
    return message;
  }
}

/// 发牌数据
class DealData {
  final String playerId;
  final List<Card> cards;

  DealData({required this.playerId, required this.cards});

  Map<String, dynamic> toJson() {
    final serializer = GameStateSerializer();
    return {
      'playerId': playerId,
      'cards': serializer.serializeCards(cards),
    };
  }

  factory DealData.fromJson(Map<String, dynamic> json) {
    final serializer = GameStateSerializer();
    return DealData(
      playerId: json['playerId'] as String,
      cards: serializer.deserializeCards(json['cards'] as List<dynamic>),
    );
  }
}

/// 出牌数据
class PlayCardsData {
  final String playerId;
  final List<Card> cards;

  PlayCardsData({required this.playerId, required this.cards});

  Map<String, dynamic> toJson() {
    final serializer = GameStateSerializer();
    return {
      'playerId': playerId,
      'cards': serializer.serializeCards(cards),
    };
  }

  factory PlayCardsData.fromJson(Map<String, dynamic> json) {
    final serializer = GameStateSerializer();
    return PlayCardsData(
      playerId: json['playerId'] as String,
      cards: serializer.deserializeCards(json['cards'] as List<dynamic>),
    );
  }
}

/// 叫地主数据
class CallLandlordData {
  final String playerId;
  final bool call;

  CallLandlordData({required this.playerId, required this.call});

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'call': call,
    };
  }

  factory CallLandlordData.fromJson(Map<String, dynamic> json) {
    return CallLandlordData(
      playerId: json['playerId'] as String,
      call: json['call'] as bool,
    );
  }
}
