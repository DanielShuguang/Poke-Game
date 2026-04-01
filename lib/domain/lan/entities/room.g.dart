// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoomImpl _$$RoomImplFromJson(Map<String, dynamic> json) => _$RoomImpl(
      roomId: json['roomId'] as String,
      roomName: json['roomName'] as String,
      gameType: $enumDecode(_$GameTypeEnumMap, json['gameType']),
      hostPlayerId: json['hostPlayerId'] as String,
      players: (json['players'] as List<dynamic>)
          .map((e) => PlayerIdentity.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: $enumDecode(_$RoomStatusEnumMap, json['status']),
      maxPlayerCount: (json['maxPlayerCount'] as num).toInt(),
      gameConfig: json['gameConfig'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      password: json['password'] as String?,
      allowSpectators: json['allowSpectators'] as bool? ?? false,
      chatHistory: (json['chatHistory'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$RoomImplToJson(_$RoomImpl instance) =>
    <String, dynamic>{
      'roomId': instance.roomId,
      'roomName': instance.roomName,
      'gameType': _$GameTypeEnumMap[instance.gameType]!,
      'hostPlayerId': instance.hostPlayerId,
      'players': instance.players,
      'status': _$RoomStatusEnumMap[instance.status]!,
      'maxPlayerCount': instance.maxPlayerCount,
      'gameConfig': instance.gameConfig,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'password': instance.password,
      'allowSpectators': instance.allowSpectators,
      'chatHistory': instance.chatHistory,
    };

const _$GameTypeEnumMap = {
  GameType.doudizhu: 'doudizhu',
  GameType.texasHoldem: 'texasHoldem',
  GameType.zhajinhua: 'zhajinhua',
  GameType.blackjack: 'blackjack',
  GameType.niuniu: 'niuniu',
  GameType.shengji: 'shengji',
  GameType.paodekai: 'paodekai',
};

const _$RoomStatusEnumMap = {
  RoomStatus.waiting: 'waiting',
  RoomStatus.playing: 'playing',
  RoomStatus.closed: 'closed',
};
