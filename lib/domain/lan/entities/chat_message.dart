import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

/// 聊天消息类型
enum ChatMessageType {
  /// 文字消息
  text,

  /// 预设表情
  emoji,

  /// 系统消息
  system,
}

/// 聊天消息实体
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    /// 消息ID
    required String messageId,

    /// 发送者ID
    required String senderId,

    /// 发送者名称
    required String senderName,

    /// 消息类型
    required ChatMessageType type,

    /// 消息内容
    required String content,

    /// 发送时间
    required DateTime timestamp,

    /// 是否被过滤（敏感词）
    @Default(false) bool isFiltered,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}

/// 预设表情
class PresetEmoji {
  final String id;
  final String name;
  final String emoji;
  final String? assetPath;

  const PresetEmoji({
    required this.id,
    required this.name,
    required this.emoji,
    this.assetPath,
  });

  static const List<PresetEmoji> defaultEmojis = [
    PresetEmoji(id: 'thumb_up', name: '点赞', emoji: '👍'),
    PresetEmoji(id: 'smile', name: '微笑', emoji: '😊'),
    PresetEmoji(id: 'laugh', name: '大笑', emoji: '😂'),
    PresetEmoji(id: 'cry', name: '哭泣', emoji: '😢'),
    PresetEmoji(id: 'angry', name: '生气', emoji: '😠'),
    PresetEmoji(id: 'surprise', name: '惊讶', emoji: '😲'),
    PresetEmoji(id: 'think', name: '思考', emoji: '🤔'),
    PresetEmoji(id: 'ok', name: '好的', emoji: '👌'),
    PresetEmoji(id: 'clap', name: '鼓掌', emoji: '👏'),
    PresetEmoji(id: 'rocket', name: '火箭', emoji: '🚀'),
  ];
}

/// 聊天消息扩展
extension ChatMessageX on ChatMessage {
  /// 是否是系统消息
  bool get isSystemMessage => type == ChatMessageType.system;

  /// 获取显示内容
  String get displayContent => isFiltered ? '***' : content;
}
