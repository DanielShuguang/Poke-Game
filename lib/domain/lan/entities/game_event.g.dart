// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameEventImpl _$$GameEventImplFromJson(Map<String, dynamic> json) =>
    _$GameEventImpl(
      eventId: json['eventId'] as String,
      type: $enumDecode(_$GameEventTypeEnumMap, json['type']),
      payload: json['payload'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      senderId: json['senderId'] as String?,
      targetPlayerId: json['targetPlayerId'] as String?,
    );

Map<String, dynamic> _$$GameEventImplToJson(_$GameEventImpl instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'type': _$GameEventTypeEnumMap[instance.type]!,
      'payload': instance.payload,
      'timestamp': instance.timestamp.toIso8601String(),
      'senderId': instance.senderId,
      'targetPlayerId': instance.targetPlayerId,
    };

const _$GameEventTypeEnumMap = {
  GameEventType.deal: 'deal',
  GameEventType.callLandlord: 'callLandlord',
  GameEventType.playCards: 'playCards',
  GameEventType.pass: 'pass',
  GameEventType.gameStart: 'gameStart',
  GameEventType.gameEnd: 'gameEnd',
  GameEventType.playerJoin: 'playerJoin',
  GameEventType.playerLeave: 'playerLeave',
  GameEventType.heartbeat: 'heartbeat',
  GameEventType.roomStateSync: 'roomStateSync',
  GameEventType.chatMessage: 'chatMessage',
};
