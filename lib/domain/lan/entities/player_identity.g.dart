// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_identity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerIdentityImpl _$$PlayerIdentityImplFromJson(Map<String, dynamic> json) =>
    _$PlayerIdentityImpl(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      seatNumber: (json['seatNumber'] as num).toInt(),
      status: $enumDecode(_$PlayerStatusEnumMap, json['status']),
      role: $enumDecodeNullable(_$PlayerRoleEnumMap, json['role']) ??
          PlayerRole.player,
      deviceName: json['deviceName'] as String?,
      ipAddress: json['ipAddress'] as String?,
      joinedAt: json['joinedAt'] == null
          ? null
          : DateTime.parse(json['joinedAt'] as String),
      lastActiveAt: json['lastActiveAt'] == null
          ? null
          : DateTime.parse(json['lastActiveAt'] as String),
      isHost: json['isHost'] as bool? ?? false,
      isMuted: json['isMuted'] as bool? ?? false,
      muteEndTime: json['muteEndTime'] == null
          ? null
          : DateTime.parse(json['muteEndTime'] as String),
    );

Map<String, dynamic> _$$PlayerIdentityImplToJson(
        _$PlayerIdentityImpl instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'playerName': instance.playerName,
      'seatNumber': instance.seatNumber,
      'status': _$PlayerStatusEnumMap[instance.status]!,
      'role': _$PlayerRoleEnumMap[instance.role]!,
      'deviceName': instance.deviceName,
      'ipAddress': instance.ipAddress,
      'joinedAt': instance.joinedAt?.toIso8601String(),
      'lastActiveAt': instance.lastActiveAt?.toIso8601String(),
      'isHost': instance.isHost,
      'isMuted': instance.isMuted,
      'muteEndTime': instance.muteEndTime?.toIso8601String(),
    };

const _$PlayerStatusEnumMap = {
  PlayerStatus.online: 'online',
  PlayerStatus.ready: 'ready',
  PlayerStatus.playing: 'playing',
  PlayerStatus.disconnected: 'disconnected',
  PlayerStatus.offline: 'offline',
  PlayerStatus.muted: 'muted',
};

const _$PlayerRoleEnumMap = {
  PlayerRole.player: 'player',
  PlayerRole.host: 'host',
  PlayerRole.landlord: 'landlord',
  PlayerRole.peasant: 'peasant',
};
