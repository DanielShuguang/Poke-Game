// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoomInfoImpl _$$RoomInfoImplFromJson(Map<String, dynamic> json) =>
    _$RoomInfoImpl(
      roomId: json['roomId'] as String,
      roomName: json['roomName'] as String,
      gameType: $enumDecode(_$GameTypeEnumMap, json['gameType']),
      currentPlayerCount: (json['currentPlayerCount'] as num).toInt(),
      maxPlayerCount: (json['maxPlayerCount'] as num).toInt(),
      hostDeviceName: json['hostDeviceName'] as String,
      status: $enumDecode(_$RoomStatusEnumMap, json['status']),
      networkAddress: json['networkAddress'] as String,
      httpPort: (json['httpPort'] as num?)?.toInt() ?? 8080,
      webSocketPort: (json['webSocketPort'] as num?)?.toInt() ?? 8082,
      requiresPassword: json['requiresPassword'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$RoomInfoImplToJson(_$RoomInfoImpl instance) =>
    <String, dynamic>{
      'roomId': instance.roomId,
      'roomName': instance.roomName,
      'gameType': _$GameTypeEnumMap[instance.gameType]!,
      'currentPlayerCount': instance.currentPlayerCount,
      'maxPlayerCount': instance.maxPlayerCount,
      'hostDeviceName': instance.hostDeviceName,
      'status': _$RoomStatusEnumMap[instance.status]!,
      'networkAddress': instance.networkAddress,
      'httpPort': instance.httpPort,
      'webSocketPort': instance.webSocketPort,
      'requiresPassword': instance.requiresPassword,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$GameTypeEnumMap = {
  GameType.doudizhu: 'doudizhu',
  GameType.texasHoldem: 'texasHoldem',
  GameType.zhajinhua: 'zhajinhua',
};

const _$RoomStatusEnumMap = {
  RoomStatus.waiting: 'waiting',
  RoomStatus.playing: 'playing',
  RoomStatus.closed: 'closed',
};
