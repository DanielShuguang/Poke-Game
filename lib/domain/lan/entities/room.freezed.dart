// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Room _$RoomFromJson(Map<String, dynamic> json) {
  return _Room.fromJson(json);
}

/// @nodoc
mixin _$Room {
  /// 房间ID
  String get roomId => throw _privateConstructorUsedError;

  /// 房间名称
  String get roomName => throw _privateConstructorUsedError;

  /// 游戏类型
  GameType get gameType => throw _privateConstructorUsedError;

  /// 房主玩家ID
  String get hostPlayerId => throw _privateConstructorUsedError;

  /// 玩家列表
  List<PlayerIdentity> get players => throw _privateConstructorUsedError;

  /// 房间状态
  RoomStatus get status => throw _privateConstructorUsedError;

  /// 最大玩家数
  int get maxPlayerCount => throw _privateConstructorUsedError;

  /// 游戏配置
  Map<String, dynamic> get gameConfig => throw _privateConstructorUsedError;

  /// 创建时间
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// 最后更新时间
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// 密码（可选）
  String? get password => throw _privateConstructorUsedError;

  /// 是否允许观战
  bool get allowSpectators => throw _privateConstructorUsedError;

  /// 聊天记录（最近50条）
  List<Map<String, dynamic>> get chatHistory =>
      throw _privateConstructorUsedError;

  /// Serializes this Room to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Room
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoomCopyWith<Room> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomCopyWith<$Res> {
  factory $RoomCopyWith(Room value, $Res Function(Room) then) =
      _$RoomCopyWithImpl<$Res, Room>;
  @useResult
  $Res call(
      {String roomId,
      String roomName,
      GameType gameType,
      String hostPlayerId,
      List<PlayerIdentity> players,
      RoomStatus status,
      int maxPlayerCount,
      Map<String, dynamic> gameConfig,
      DateTime createdAt,
      DateTime? updatedAt,
      String? password,
      bool allowSpectators,
      List<Map<String, dynamic>> chatHistory});
}

/// @nodoc
class _$RoomCopyWithImpl<$Res, $Val extends Room>
    implements $RoomCopyWith<$Res> {
  _$RoomCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Room
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? roomId = null,
    Object? roomName = null,
    Object? gameType = null,
    Object? hostPlayerId = null,
    Object? players = null,
    Object? status = null,
    Object? maxPlayerCount = null,
    Object? gameConfig = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? password = freezed,
    Object? allowSpectators = null,
    Object? chatHistory = null,
  }) {
    return _then(_value.copyWith(
      roomId: null == roomId
          ? _value.roomId
          : roomId // ignore: cast_nullable_to_non_nullable
              as String,
      roomName: null == roomName
          ? _value.roomName
          : roomName // ignore: cast_nullable_to_non_nullable
              as String,
      gameType: null == gameType
          ? _value.gameType
          : gameType // ignore: cast_nullable_to_non_nullable
              as GameType,
      hostPlayerId: null == hostPlayerId
          ? _value.hostPlayerId
          : hostPlayerId // ignore: cast_nullable_to_non_nullable
              as String,
      players: null == players
          ? _value.players
          : players // ignore: cast_nullable_to_non_nullable
              as List<PlayerIdentity>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as RoomStatus,
      maxPlayerCount: null == maxPlayerCount
          ? _value.maxPlayerCount
          : maxPlayerCount // ignore: cast_nullable_to_non_nullable
              as int,
      gameConfig: null == gameConfig
          ? _value.gameConfig
          : gameConfig // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      password: freezed == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String?,
      allowSpectators: null == allowSpectators
          ? _value.allowSpectators
          : allowSpectators // ignore: cast_nullable_to_non_nullable
              as bool,
      chatHistory: null == chatHistory
          ? _value.chatHistory
          : chatHistory // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoomImplCopyWith<$Res> implements $RoomCopyWith<$Res> {
  factory _$$RoomImplCopyWith(
          _$RoomImpl value, $Res Function(_$RoomImpl) then) =
      __$$RoomImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String roomId,
      String roomName,
      GameType gameType,
      String hostPlayerId,
      List<PlayerIdentity> players,
      RoomStatus status,
      int maxPlayerCount,
      Map<String, dynamic> gameConfig,
      DateTime createdAt,
      DateTime? updatedAt,
      String? password,
      bool allowSpectators,
      List<Map<String, dynamic>> chatHistory});
}

/// @nodoc
class __$$RoomImplCopyWithImpl<$Res>
    extends _$RoomCopyWithImpl<$Res, _$RoomImpl>
    implements _$$RoomImplCopyWith<$Res> {
  __$$RoomImplCopyWithImpl(_$RoomImpl _value, $Res Function(_$RoomImpl) _then)
      : super(_value, _then);

  /// Create a copy of Room
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? roomId = null,
    Object? roomName = null,
    Object? gameType = null,
    Object? hostPlayerId = null,
    Object? players = null,
    Object? status = null,
    Object? maxPlayerCount = null,
    Object? gameConfig = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? password = freezed,
    Object? allowSpectators = null,
    Object? chatHistory = null,
  }) {
    return _then(_$RoomImpl(
      roomId: null == roomId
          ? _value.roomId
          : roomId // ignore: cast_nullable_to_non_nullable
              as String,
      roomName: null == roomName
          ? _value.roomName
          : roomName // ignore: cast_nullable_to_non_nullable
              as String,
      gameType: null == gameType
          ? _value.gameType
          : gameType // ignore: cast_nullable_to_non_nullable
              as GameType,
      hostPlayerId: null == hostPlayerId
          ? _value.hostPlayerId
          : hostPlayerId // ignore: cast_nullable_to_non_nullable
              as String,
      players: null == players
          ? _value._players
          : players // ignore: cast_nullable_to_non_nullable
              as List<PlayerIdentity>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as RoomStatus,
      maxPlayerCount: null == maxPlayerCount
          ? _value.maxPlayerCount
          : maxPlayerCount // ignore: cast_nullable_to_non_nullable
              as int,
      gameConfig: null == gameConfig
          ? _value._gameConfig
          : gameConfig // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      password: freezed == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String?,
      allowSpectators: null == allowSpectators
          ? _value.allowSpectators
          : allowSpectators // ignore: cast_nullable_to_non_nullable
              as bool,
      chatHistory: null == chatHistory
          ? _value._chatHistory
          : chatHistory // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RoomImpl implements _Room {
  const _$RoomImpl(
      {required this.roomId,
      required this.roomName,
      required this.gameType,
      required this.hostPlayerId,
      required final List<PlayerIdentity> players,
      required this.status,
      required this.maxPlayerCount,
      required final Map<String, dynamic> gameConfig,
      required this.createdAt,
      this.updatedAt,
      this.password,
      this.allowSpectators = false,
      final List<Map<String, dynamic>> chatHistory = const []})
      : _players = players,
        _gameConfig = gameConfig,
        _chatHistory = chatHistory;

  factory _$RoomImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoomImplFromJson(json);

  /// 房间ID
  @override
  final String roomId;

  /// 房间名称
  @override
  final String roomName;

  /// 游戏类型
  @override
  final GameType gameType;

  /// 房主玩家ID
  @override
  final String hostPlayerId;

  /// 玩家列表
  final List<PlayerIdentity> _players;

  /// 玩家列表
  @override
  List<PlayerIdentity> get players {
    if (_players is EqualUnmodifiableListView) return _players;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_players);
  }

  /// 房间状态
  @override
  final RoomStatus status;

  /// 最大玩家数
  @override
  final int maxPlayerCount;

  /// 游戏配置
  final Map<String, dynamic> _gameConfig;

  /// 游戏配置
  @override
  Map<String, dynamic> get gameConfig {
    if (_gameConfig is EqualUnmodifiableMapView) return _gameConfig;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_gameConfig);
  }

  /// 创建时间
  @override
  final DateTime createdAt;

  /// 最后更新时间
  @override
  final DateTime? updatedAt;

  /// 密码（可选）
  @override
  final String? password;

  /// 是否允许观战
  @override
  @JsonKey()
  final bool allowSpectators;

  /// 聊天记录（最近50条）
  final List<Map<String, dynamic>> _chatHistory;

  /// 聊天记录（最近50条）
  @override
  @JsonKey()
  List<Map<String, dynamic>> get chatHistory {
    if (_chatHistory is EqualUnmodifiableListView) return _chatHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chatHistory);
  }

  @override
  String toString() {
    return 'Room(roomId: $roomId, roomName: $roomName, gameType: $gameType, hostPlayerId: $hostPlayerId, players: $players, status: $status, maxPlayerCount: $maxPlayerCount, gameConfig: $gameConfig, createdAt: $createdAt, updatedAt: $updatedAt, password: $password, allowSpectators: $allowSpectators, chatHistory: $chatHistory)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomImpl &&
            (identical(other.roomId, roomId) || other.roomId == roomId) &&
            (identical(other.roomName, roomName) ||
                other.roomName == roomName) &&
            (identical(other.gameType, gameType) ||
                other.gameType == gameType) &&
            (identical(other.hostPlayerId, hostPlayerId) ||
                other.hostPlayerId == hostPlayerId) &&
            const DeepCollectionEquality().equals(other._players, _players) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.maxPlayerCount, maxPlayerCount) ||
                other.maxPlayerCount == maxPlayerCount) &&
            const DeepCollectionEquality()
                .equals(other._gameConfig, _gameConfig) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.allowSpectators, allowSpectators) ||
                other.allowSpectators == allowSpectators) &&
            const DeepCollectionEquality()
                .equals(other._chatHistory, _chatHistory));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      roomId,
      roomName,
      gameType,
      hostPlayerId,
      const DeepCollectionEquality().hash(_players),
      status,
      maxPlayerCount,
      const DeepCollectionEquality().hash(_gameConfig),
      createdAt,
      updatedAt,
      password,
      allowSpectators,
      const DeepCollectionEquality().hash(_chatHistory));

  /// Create a copy of Room
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomImplCopyWith<_$RoomImpl> get copyWith =>
      __$$RoomImplCopyWithImpl<_$RoomImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoomImplToJson(
      this,
    );
  }
}

abstract class _Room implements Room {
  const factory _Room(
      {required final String roomId,
      required final String roomName,
      required final GameType gameType,
      required final String hostPlayerId,
      required final List<PlayerIdentity> players,
      required final RoomStatus status,
      required final int maxPlayerCount,
      required final Map<String, dynamic> gameConfig,
      required final DateTime createdAt,
      final DateTime? updatedAt,
      final String? password,
      final bool allowSpectators,
      final List<Map<String, dynamic>> chatHistory}) = _$RoomImpl;

  factory _Room.fromJson(Map<String, dynamic> json) = _$RoomImpl.fromJson;

  /// 房间ID
  @override
  String get roomId;

  /// 房间名称
  @override
  String get roomName;

  /// 游戏类型
  @override
  GameType get gameType;

  /// 房主玩家ID
  @override
  String get hostPlayerId;

  /// 玩家列表
  @override
  List<PlayerIdentity> get players;

  /// 房间状态
  @override
  RoomStatus get status;

  /// 最大玩家数
  @override
  int get maxPlayerCount;

  /// 游戏配置
  @override
  Map<String, dynamic> get gameConfig;

  /// 创建时间
  @override
  DateTime get createdAt;

  /// 最后更新时间
  @override
  DateTime? get updatedAt;

  /// 密码（可选）
  @override
  String? get password;

  /// 是否允许观战
  @override
  bool get allowSpectators;

  /// 聊天记录（最近50条）
  @override
  List<Map<String, dynamic>> get chatHistory;

  /// Create a copy of Room
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoomImplCopyWith<_$RoomImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
