import 'dart:async';
import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:poke_game/domain/lan/entities/chat_message.dart';
import 'package:uuid/uuid.dart';

/// 敏感词过滤器
class SensitiveWordFilter {
  final Set<String> _sensitiveWords;
  final Logger _logger = Logger();

  SensitiveWordFilter({Set<String>? sensitiveWords})
      : _sensitiveWords = sensitiveWords ?? _defaultSensitiveWords;

  /// 默认敏感词列表（示例）
  static final Set<String> _defaultSensitiveWords = {
    // 这里应该放实际的敏感词，示例中省略
  };

  /// 添加敏感词
  void addWord(String word) {
    _sensitiveWords.add(word);
  }

  /// 移除敏感词
  void removeWord(String word) {
    _sensitiveWords.remove(word);
  }

  /// 检查是否包含敏感词
  bool containsSensitiveWord(String text) {
    final lowerText = text.toLowerCase();
    for (final word in _sensitiveWords) {
      if (lowerText.contains(word.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /// 过滤敏感词
  String filter(String text) {
    var result = text;
    for (final word in _sensitiveWords) {
      if (result.toLowerCase().contains(word.toLowerCase())) {
        result = result.replaceAll(
          RegExp(word, caseSensitive: false),
          '***',
        );
      }
    }
    return result;
  }
}

/// 聊天服务
class ChatService {
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  /// 最大消息数量
  final int maxMessages;

  /// 敏感词过滤器
  final SensitiveWordFilter _filter;

  /// 消息历史
  final Queue<ChatMessage> _messages = Queue<ChatMessage>();

  /// 消息流控制器
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();

  /// 消息流
  Stream<ChatMessage> get messageStream => _messageController.stream;

  /// 禁言玩家列表
  final Map<String, DateTime> _mutedPlayers = {};

  /// 发送频率限制
  final Map<String, List<DateTime>> _sendHistory = {};

  /// 频率限制窗口（秒）
  final int rateLimitWindow;

  /// 频率限制最大次数
  final int rateLimitMax;

  ChatService({
    this.maxMessages = 50,
    SensitiveWordFilter? filter,
    this.rateLimitWindow = 10,
    this.rateLimitMax = 5,
  }) : _filter = filter ?? SensitiveWordFilter();

  /// 发送文字消息
  ChatMessage? sendTextMessage({
    required String senderId,
    required String senderName,
    required String content,
  }) {
    // 检查是否被禁言
    if (isPlayerMuted(senderId)) {
      _logger.w('玩家 $senderId 已被禁言，无法发送消息');
      return null;
    }

    // 检查频率限制
    if (!_checkRateLimit(senderId)) {
      _logger.w('玩家 $senderId 发送过于频繁');
      return null;
    }

    // 检查消息长度
    if (content.isEmpty || content.length > 100) {
      _logger.w('消息长度无效');
      return null;
    }

    // 过滤敏感词
    final filteredContent = _filter.filter(content);
    final isFiltered = filteredContent != content;

    final message = ChatMessage(
      messageId: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      type: ChatMessageType.text,
      content: filteredContent,
      timestamp: DateTime.now(),
      isFiltered: isFiltered,
    );

    _addMessage(message);
    return message;
  }

  /// 发送表情
  ChatMessage? sendEmoji({
    required String senderId,
    required String senderName,
    required String emojiId,
  }) {
    // 检查是否被禁言
    if (isPlayerMuted(senderId)) {
      return null;
    }

    // 检查频率限制
    if (!_checkRateLimit(senderId)) {
      return null;
    }

    // 查找表情
    final emoji = PresetEmoji.defaultEmojis.firstWhere(
      (e) => e.id == emojiId,
      orElse: () => PresetEmoji.defaultEmojis.first,
    );

    final message = ChatMessage(
      messageId: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      type: ChatMessageType.emoji,
      content: emoji.emoji,
      timestamp: DateTime.now(),
    );

    _addMessage(message);
    return message;
  }

  /// 发送系统消息
  void sendSystemMessage(String content) {
    final message = ChatMessage(
      messageId: _uuid.v4(),
      senderId: 'system',
      senderName: '系统',
      type: ChatMessageType.system,
      content: content,
      timestamp: DateTime.now(),
    );

    _addMessage(message);
  }

  /// 添加消息到历史
  void _addMessage(ChatMessage message) {
    _messages.add(message);

    // 限制消息数量
    while (_messages.length > maxMessages) {
      _messages.removeFirst();
    }

    _messageController.add(message);
    _logger.d('聊天消息已添加: ${message.messageId}');
  }

  /// 禁言玩家
  void mutePlayer(String playerId, {Duration duration = const Duration(minutes: 5)}) {
    _mutedPlayers[playerId] = DateTime.now().add(duration);
    _logger.i('玩家 $playerId 已被禁言，持续 ${duration.inMinutes} 分钟');
  }

  /// 解除禁言
  void unmutePlayer(String playerId) {
    _mutedPlayers.remove(playerId);
    _logger.i('玩家 $playerId 已解除禁言');
  }

  /// 检查玩家是否被禁言
  bool isPlayerMuted(String playerId) {
    final muteEndTime = _mutedPlayers[playerId];
    if (muteEndTime == null) return false;

    if (DateTime.now().isAfter(muteEndTime)) {
      _mutedPlayers.remove(playerId);
      return false;
    }

    return true;
  }

  /// 获取禁言剩余时间
  Duration? getMuteRemainingTime(String playerId) {
    final muteEndTime = _mutedPlayers[playerId];
    if (muteEndTime == null) return null;

    final remaining = muteEndTime.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// 检查频率限制
  bool _checkRateLimit(String playerId) {
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(seconds: rateLimitWindow));

    // 获取发送历史
    final history = _sendHistory[playerId] ?? [];

    // 过滤过期的记录
    final recentHistory = history.where((t) => t.isAfter(windowStart)).toList();

    // 检查是否超过限制
    if (recentHistory.length >= rateLimitMax) {
      return false;
    }

    // 更新历史
    recentHistory.add(now);
    _sendHistory[playerId] = recentHistory;

    return true;
  }

  /// 获取消息历史
  List<ChatMessage> getMessageHistory() {
    return _messages.toList();
  }

  /// 清空消息历史
  void clearHistory() {
    _messages.clear();
    _logger.i('聊天消息历史已清空');
  }

  /// 释放资源
  void dispose() {
    _messageController.close();
  }
}
