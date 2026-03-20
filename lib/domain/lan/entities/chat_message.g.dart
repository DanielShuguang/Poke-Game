// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      messageId: json['messageId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      type: $enumDecode(_$ChatMessageTypeEnumMap, json['type']),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFiltered: json['isFiltered'] as bool? ?? false,
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'type': _$ChatMessageTypeEnumMap[instance.type]!,
      'content': instance.content,
      'timestamp': instance.timestamp.toIso8601String(),
      'isFiltered': instance.isFiltered,
    };

const _$ChatMessageTypeEnumMap = {
  ChatMessageType.text: 'text',
  ChatMessageType.emoji: 'emoji',
  ChatMessageType.system: 'system',
};
