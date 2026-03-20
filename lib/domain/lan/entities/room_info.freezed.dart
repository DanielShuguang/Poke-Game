// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RoomInfo _$RoomInfoFromJson(Map<String, dynamic> json) {
  return _RoomInfo.fromJson(json);
}

/// @nodoc
mixin _$RoomInfo {
  /// 房间ID（UUID）
  String get roomId => throw _privateConstructorUsedError;

  /// 房间名称
  String get roomName => throw _privateConstructorUsedError;

  /// 游戏类型
  GameType get gameType => throw _privateConstructorUsedError;

  /// 当前玩家数量
  int get currentPlayerCount => throw _privateConstructorUsedError;

  /// 最大玩家数量
  int get maxPlayerCount => throw _privateConstructorUsedError;

  /// 房主设备名称
  String get hostDeviceName => throw _privateConstructorUsedError;

  /// 房间状态
  RoomStatus get status => throw _privateConstructorUsedError;

  /// 网络地址（IP:Port）
  String get networkAddress => throw _privateConstructorUsedError;

  /// HTTP端口
  int get httpPort => throw _privateConstructorUsedError;

  /// WebSocket端口
  int get webSocketPort => throw _privateConstructorUsedError;

  /// 是否需要密码
  bool get requiresPassword => throw _privateConstructorUsedError;

  /// 创建时间
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this RoomInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RoomInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoomInfoCopyWith<RoomInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomInfoCopyWith<$Res> {
  factory $RoomInfoCopyWith(RoomInfo value, $Res Function(RoomInfo) then) =
      _$RoomInfoCopyWithImpl<$Res, RoomInfo>;
  @useResult
  $Res call(
      {String roomId,
      String roomName,
      GameType gameType,
      int currentPlayerCount,
      int maxPlayerCount,
      String hostDeviceName,
      RoomStatus status,
      String networkAddress,
      int httpPort,
      int webSocketPort,
      bool requiresPassword,
      DateTime? createdAt});
}

/// @nodoc
class _$RoomInfoCopyWithImpl<$Res, $Val extends RoomInfo>
    implements $RoomInfoCopyWith<$Res> {
  _$RoomInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoomInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? roomId = null,
    Object? roomName = null,
    Object? gameType = null,
    Object? currentPlayerCount = null,
    Object? maxPlayerCount = null,
    Object? hostDeviceName = null,
    Object? status = null,
    Object? networkAddress = null,
    Object? httpPort = null,
    Object? webSocketPort = null,
    Object? requiresPassword = null,
    Object? createdAt = freezed,
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
      currentPlayerCount: null == currentPlayerCount
          ? _value.currentPlayerCount
          : currentPlayerCount // ignore: cast_nullable_to_non_nullable
              as int,
      maxPlayerCount: null == maxPlayerCount
          ? _value.maxPlayerCount
          : maxPlayerCount // ignore: cast_nullable_to_non_nullable
              as int,
      hostDeviceName: null == hostDeviceName
          ? _value.hostDeviceName
          : hostDeviceName // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as RoomStatus,
      networkAddress: null == networkAddress
          ? _value.networkAddress
          : networkAddress // ignore: cast_nullable_to_non_nullable
              as String,
      httpPort: null == httpPort
          ? _value.httpPort
          : httpPort // ignore: cast_nullable_to_non_nullable
              as int,
      webSocketPort: null == webSocketPort
          ? _value.webSocketPort
          : webSocketPort // ignore: cast_nullable_to_non_nullable
              as int,
      requiresPassword: null == requiresPassword
          ? _value.requiresPassword
          : requiresPassword // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoomInfoImplCopyWith<$Res>
    implements $RoomInfoCopyWith<$Res> {
  factory _$$RoomInfoImplCopyWith(
          _$RoomInfoImpl value, $Res Function(_$RoomInfoImpl) then) =
      __$$RoomInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String roomId,
      String roomName,
      GameType gameType,
      int currentPlayerCount,
      int maxPlayerCount,
      String hostDeviceName,
      RoomStatus status,
      String networkAddress,
      int httpPort,
      int webSocketPort,
      bool requiresPassword,
      DateTime? createdAt});
}

/// @nodoc
class __$$RoomInfoImplCopyWithImpl<$Res>
    extends _$RoomInfoCopyWithImpl<$Res, _$RoomInfoImpl>
    implements _$$RoomInfoImplCopyWith<$Res> {
  __$$RoomInfoImplCopyWithImpl(
      _$RoomInfoImpl _value, $Res Function(_$RoomInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of RoomInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? roomId = null,
    Object? roomName = null,
    Object? gameType = null,
    Object? currentPlayerCount = null,
    Object? maxPlayerCount = null,
    Object? hostDeviceName = null,
    Object? status = null,
    Object? networkAddress = null,
    Object? httpPort = null,
    Object? webSocketPort = null,
    Object? requiresPassword = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$RoomInfoImpl(
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
      currentPlayerCount: null == currentPlayerCount
          ? _value.currentPlayerCount
          : currentPlayerCount // ignore: cast_nullable_to_non_nullable
              as int,
      maxPlayerCount: null == maxPlayerCount
          ? _value.maxPlayerCount
          : maxPlayerCount // ignore: cast_nullable_to_non_nullable
              as int,
      hostDeviceName: null == hostDeviceName
          ? _value.hostDeviceName
          : hostDeviceName // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as RoomStatus,
      networkAddress: null == networkAddress
          ? _value.networkAddress
          : networkAddress // ignore: cast_nullable_to_non_nullable
              as String,
      httpPort: null == httpPort
          ? _value.httpPort
          : httpPort // ignore: cast_nullable_to_non_nullable
              as int,
      webSocketPort: null == webSocketPort
          ? _value.webSocketPort
          : webSocketPort // ignore: cast_nullable_to_non_nullable
              as int,
      requiresPassword: null == requiresPassword
          ? _value.requiresPassword
          : requiresPassword // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RoomInfoImpl implements _RoomInfo {
  const _$RoomInfoImpl(
      {required this.roomId,
      required this.roomName,
      required this.gameType,
      required this.currentPlayerCount,
      required this.maxPlayerCount,
      required this.hostDeviceName,
      required this.status,
      required this.networkAddress,
      this.httpPort = 8080,
      this.webSocketPort = 8082,
      this.requiresPassword = false,
      this.createdAt});

  factory _$RoomInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoomInfoImplFromJson(json);

  /// 房间ID（UUID）
  @override
  final String roomId;

  /// 房间名称
  @override
  final String roomName;

  /// 游戏类型
  @override
  final GameType gameType;

  /// 当前玩家数量
  @override
  final int currentPlayerCount;

  /// 最大玩家数量
  @override
  final int maxPlayerCount;

  /// 房主设备名称
  @override
  final String hostDeviceName;

  /// 房间状态
  @override
  final RoomStatus status;

  /// 网络地址（IP:Port）
  @override
  final String networkAddress;

  /// HTTP端口
  @override
  @JsonKey()
  final int httpPort;

  /// WebSocket端口
  @override
  @JsonKey()
  final int webSocketPort;

  /// 是否需要密码
  @override
  @JsonKey()
  final bool requiresPassword;

  /// 创建时间
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'RoomInfo(roomId: $roomId, roomName: $roomName, gameType: $gameType, currentPlayerCount: $currentPlayerCount, maxPlayerCount: $maxPlayerCount, hostDeviceName: $hostDeviceName, status: $status, networkAddress: $networkAddress, httpPort: $httpPort, webSocketPort: $webSocketPort, requiresPassword: $requiresPassword, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomInfoImpl &&
            (identical(other.roomId, roomId) || other.roomId == roomId) &&
            (identical(other.roomName, roomName) ||
                other.roomName == roomName) &&
            (identical(other.gameType, gameType) ||
                other.gameType == gameType) &&
            (identical(other.currentPlayerCount, currentPlayerCount) ||
                other.currentPlayerCount == currentPlayerCount) &&
            (identical(other.maxPlayerCount, maxPlayerCount) ||
                other.maxPlayerCount == maxPlayerCount) &&
            (identical(other.hostDeviceName, hostDeviceName) ||
                other.hostDeviceName == hostDeviceName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.networkAddress, networkAddress) ||
                other.networkAddress == networkAddress) &&
            (identical(other.httpPort, httpPort) ||
                other.httpPort == httpPort) &&
            (identical(other.webSocketPort, webSocketPort) ||
                other.webSocketPort == webSocketPort) &&
            (identical(other.requiresPassword, requiresPassword) ||
                other.requiresPassword == requiresPassword) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      roomId,
      roomName,
      gameType,
      currentPlayerCount,
      maxPlayerCount,
      hostDeviceName,
      status,
      networkAddress,
      httpPort,
      webSocketPort,
      requiresPassword,
      createdAt);

  /// Create a copy of RoomInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomInfoImplCopyWith<_$RoomInfoImpl> get copyWith =>
      __$$RoomInfoImplCopyWithImpl<_$RoomInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoomInfoImplToJson(
      this,
    );
  }
}

abstract class _RoomInfo implements RoomInfo {
  const factory _RoomInfo(
      {required final String roomId,
      required final String roomName,
      required final GameType gameType,
      required final int currentPlayerCount,
      required final int maxPlayerCount,
      required final String hostDeviceName,
      required final RoomStatus status,
      required final String networkAddress,
      final int httpPort,
      final int webSocketPort,
      final bool requiresPassword,
      final DateTime? createdAt}) = _$RoomInfoImpl;

  factory _RoomInfo.fromJson(Map<String, dynamic> json) =
      _$RoomInfoImpl.fromJson;

  /// 房间ID（UUID）
  @override
  String get roomId;

  /// 房间名称
  @override
  String get roomName;

  /// 游戏类型
  @override
  GameType get gameType;

  /// 当前玩家数量
  @override
  int get currentPlayerCount;

  /// 最大玩家数量
  @override
  int get maxPlayerCount;

  /// 房主设备名称
  @override
  String get hostDeviceName;

  /// 房间状态
  @override
  RoomStatus get status;

  /// 网络地址（IP:Port）
  @override
  String get networkAddress;

  /// HTTP端口
  @override
  int get httpPort;

  /// WebSocket端口
  @override
  int get webSocketPort;

  /// 是否需要密码
  @override
  bool get requiresPassword;

  /// 创建时间
  @override
  DateTime? get createdAt;

  /// Create a copy of RoomInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoomInfoImplCopyWith<_$RoomInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
