// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GameEvent _$GameEventFromJson(Map<String, dynamic> json) {
  return _GameEvent.fromJson(json);
}

/// @nodoc
mixin _$GameEvent {
  /// 事件ID（唯一标识）
  String get eventId => throw _privateConstructorUsedError;

  /// 事件类型
  GameEventType get type => throw _privateConstructorUsedError;

  /// 事件载荷（具体数据）
  Map<String, dynamic> get payload => throw _privateConstructorUsedError;

  /// 事件时间戳
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// 发送者ID
  String? get senderId => throw _privateConstructorUsedError;

  /// 目标玩家ID（可选，用于定向消息）
  String? get targetPlayerId => throw _privateConstructorUsedError;

  /// Serializes this GameEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameEventCopyWith<GameEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameEventCopyWith<$Res> {
  factory $GameEventCopyWith(GameEvent value, $Res Function(GameEvent) then) =
      _$GameEventCopyWithImpl<$Res, GameEvent>;
  @useResult
  $Res call(
      {String eventId,
      GameEventType type,
      Map<String, dynamic> payload,
      DateTime timestamp,
      String? senderId,
      String? targetPlayerId});
}

/// @nodoc
class _$GameEventCopyWithImpl<$Res, $Val extends GameEvent>
    implements $GameEventCopyWith<$Res> {
  _$GameEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventId = null,
    Object? type = null,
    Object? payload = null,
    Object? timestamp = null,
    Object? senderId = freezed,
    Object? targetPlayerId = freezed,
  }) {
    return _then(_value.copyWith(
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as GameEventType,
      payload: null == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      senderId: freezed == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String?,
      targetPlayerId: freezed == targetPlayerId
          ? _value.targetPlayerId
          : targetPlayerId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GameEventImplCopyWith<$Res>
    implements $GameEventCopyWith<$Res> {
  factory _$$GameEventImplCopyWith(
          _$GameEventImpl value, $Res Function(_$GameEventImpl) then) =
      __$$GameEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String eventId,
      GameEventType type,
      Map<String, dynamic> payload,
      DateTime timestamp,
      String? senderId,
      String? targetPlayerId});
}

/// @nodoc
class __$$GameEventImplCopyWithImpl<$Res>
    extends _$GameEventCopyWithImpl<$Res, _$GameEventImpl>
    implements _$$GameEventImplCopyWith<$Res> {
  __$$GameEventImplCopyWithImpl(
      _$GameEventImpl _value, $Res Function(_$GameEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of GameEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventId = null,
    Object? type = null,
    Object? payload = null,
    Object? timestamp = null,
    Object? senderId = freezed,
    Object? targetPlayerId = freezed,
  }) {
    return _then(_$GameEventImpl(
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as GameEventType,
      payload: null == payload
          ? _value._payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      senderId: freezed == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String?,
      targetPlayerId: freezed == targetPlayerId
          ? _value.targetPlayerId
          : targetPlayerId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameEventImpl implements _GameEvent {
  const _$GameEventImpl(
      {required this.eventId,
      required this.type,
      required final Map<String, dynamic> payload,
      required this.timestamp,
      this.senderId,
      this.targetPlayerId})
      : _payload = payload;

  factory _$GameEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameEventImplFromJson(json);

  /// 事件ID（唯一标识）
  @override
  final String eventId;

  /// 事件类型
  @override
  final GameEventType type;

  /// 事件载荷（具体数据）
  final Map<String, dynamic> _payload;

  /// 事件载荷（具体数据）
  @override
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  /// 事件时间戳
  @override
  final DateTime timestamp;

  /// 发送者ID
  @override
  final String? senderId;

  /// 目标玩家ID（可选，用于定向消息）
  @override
  final String? targetPlayerId;

  @override
  String toString() {
    return 'GameEvent(eventId: $eventId, type: $type, payload: $payload, timestamp: $timestamp, senderId: $senderId, targetPlayerId: $targetPlayerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameEventImpl &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.targetPlayerId, targetPlayerId) ||
                other.targetPlayerId == targetPlayerId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      eventId,
      type,
      const DeepCollectionEquality().hash(_payload),
      timestamp,
      senderId,
      targetPlayerId);

  /// Create a copy of GameEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameEventImplCopyWith<_$GameEventImpl> get copyWith =>
      __$$GameEventImplCopyWithImpl<_$GameEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameEventImplToJson(
      this,
    );
  }
}

abstract class _GameEvent implements GameEvent {
  const factory _GameEvent(
      {required final String eventId,
      required final GameEventType type,
      required final Map<String, dynamic> payload,
      required final DateTime timestamp,
      final String? senderId,
      final String? targetPlayerId}) = _$GameEventImpl;

  factory _GameEvent.fromJson(Map<String, dynamic> json) =
      _$GameEventImpl.fromJson;

  /// 事件ID（唯一标识）
  @override
  String get eventId;

  /// 事件类型
  @override
  GameEventType get type;

  /// 事件载荷（具体数据）
  @override
  Map<String, dynamic> get payload;

  /// 事件时间戳
  @override
  DateTime get timestamp;

  /// 发送者ID
  @override
  String? get senderId;

  /// 目标玩家ID（可选，用于定向消息）
  @override
  String? get targetPlayerId;

  /// Create a copy of GameEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameEventImplCopyWith<_$GameEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
