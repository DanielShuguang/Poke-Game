// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_identity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PlayerIdentity _$PlayerIdentityFromJson(Map<String, dynamic> json) {
  return _PlayerIdentity.fromJson(json);
}

/// @nodoc
mixin _$PlayerIdentity {
  /// 玩家ID（UUID）
  String get playerId => throw _privateConstructorUsedError;

  /// 玩家名称
  String get playerName => throw _privateConstructorUsedError;

  /// 座位号（1开始）
  int get seatNumber => throw _privateConstructorUsedError;

  /// 玩家状态
  PlayerStatus get status => throw _privateConstructorUsedError;

  /// 玩家角色
  PlayerRole get role => throw _privateConstructorUsedError;

  /// 设备名称
  String? get deviceName => throw _privateConstructorUsedError;

  /// 设备IP地址
  String? get ipAddress => throw _privateConstructorUsedError;

  /// 加入时间
  DateTime? get joinedAt => throw _privateConstructorUsedError;

  /// 最后活跃时间
  DateTime? get lastActiveAt => throw _privateConstructorUsedError;

  /// 是否是房主
  bool get isHost => throw _privateConstructorUsedError;

  /// 是否被禁言
  bool get isMuted => throw _privateConstructorUsedError;

  /// 禁言结束时间
  DateTime? get muteEndTime => throw _privateConstructorUsedError;

  /// Serializes this PlayerIdentity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerIdentity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerIdentityCopyWith<PlayerIdentity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerIdentityCopyWith<$Res> {
  factory $PlayerIdentityCopyWith(
          PlayerIdentity value, $Res Function(PlayerIdentity) then) =
      _$PlayerIdentityCopyWithImpl<$Res, PlayerIdentity>;
  @useResult
  $Res call(
      {String playerId,
      String playerName,
      int seatNumber,
      PlayerStatus status,
      PlayerRole role,
      String? deviceName,
      String? ipAddress,
      DateTime? joinedAt,
      DateTime? lastActiveAt,
      bool isHost,
      bool isMuted,
      DateTime? muteEndTime});
}

/// @nodoc
class _$PlayerIdentityCopyWithImpl<$Res, $Val extends PlayerIdentity>
    implements $PlayerIdentityCopyWith<$Res> {
  _$PlayerIdentityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerIdentity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? playerName = null,
    Object? seatNumber = null,
    Object? status = null,
    Object? role = null,
    Object? deviceName = freezed,
    Object? ipAddress = freezed,
    Object? joinedAt = freezed,
    Object? lastActiveAt = freezed,
    Object? isHost = null,
    Object? isMuted = null,
    Object? muteEndTime = freezed,
  }) {
    return _then(_value.copyWith(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      playerName: null == playerName
          ? _value.playerName
          : playerName // ignore: cast_nullable_to_non_nullable
              as String,
      seatNumber: null == seatNumber
          ? _value.seatNumber
          : seatNumber // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as PlayerStatus,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as PlayerRole,
      deviceName: freezed == deviceName
          ? _value.deviceName
          : deviceName // ignore: cast_nullable_to_non_nullable
              as String?,
      ipAddress: freezed == ipAddress
          ? _value.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      joinedAt: freezed == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastActiveAt: freezed == lastActiveAt
          ? _value.lastActiveAt
          : lastActiveAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isHost: null == isHost
          ? _value.isHost
          : isHost // ignore: cast_nullable_to_non_nullable
              as bool,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      muteEndTime: freezed == muteEndTime
          ? _value.muteEndTime
          : muteEndTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerIdentityImplCopyWith<$Res>
    implements $PlayerIdentityCopyWith<$Res> {
  factory _$$PlayerIdentityImplCopyWith(_$PlayerIdentityImpl value,
          $Res Function(_$PlayerIdentityImpl) then) =
      __$$PlayerIdentityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String playerId,
      String playerName,
      int seatNumber,
      PlayerStatus status,
      PlayerRole role,
      String? deviceName,
      String? ipAddress,
      DateTime? joinedAt,
      DateTime? lastActiveAt,
      bool isHost,
      bool isMuted,
      DateTime? muteEndTime});
}

/// @nodoc
class __$$PlayerIdentityImplCopyWithImpl<$Res>
    extends _$PlayerIdentityCopyWithImpl<$Res, _$PlayerIdentityImpl>
    implements _$$PlayerIdentityImplCopyWith<$Res> {
  __$$PlayerIdentityImplCopyWithImpl(
      _$PlayerIdentityImpl _value, $Res Function(_$PlayerIdentityImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlayerIdentity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? playerName = null,
    Object? seatNumber = null,
    Object? status = null,
    Object? role = null,
    Object? deviceName = freezed,
    Object? ipAddress = freezed,
    Object? joinedAt = freezed,
    Object? lastActiveAt = freezed,
    Object? isHost = null,
    Object? isMuted = null,
    Object? muteEndTime = freezed,
  }) {
    return _then(_$PlayerIdentityImpl(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      playerName: null == playerName
          ? _value.playerName
          : playerName // ignore: cast_nullable_to_non_nullable
              as String,
      seatNumber: null == seatNumber
          ? _value.seatNumber
          : seatNumber // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as PlayerStatus,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as PlayerRole,
      deviceName: freezed == deviceName
          ? _value.deviceName
          : deviceName // ignore: cast_nullable_to_non_nullable
              as String?,
      ipAddress: freezed == ipAddress
          ? _value.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      joinedAt: freezed == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastActiveAt: freezed == lastActiveAt
          ? _value.lastActiveAt
          : lastActiveAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isHost: null == isHost
          ? _value.isHost
          : isHost // ignore: cast_nullable_to_non_nullable
              as bool,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      muteEndTime: freezed == muteEndTime
          ? _value.muteEndTime
          : muteEndTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerIdentityImpl implements _PlayerIdentity {
  const _$PlayerIdentityImpl(
      {required this.playerId,
      required this.playerName,
      required this.seatNumber,
      required this.status,
      this.role = PlayerRole.player,
      this.deviceName,
      this.ipAddress,
      this.joinedAt,
      this.lastActiveAt,
      this.isHost = false,
      this.isMuted = false,
      this.muteEndTime});

  factory _$PlayerIdentityImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerIdentityImplFromJson(json);

  /// 玩家ID（UUID）
  @override
  final String playerId;

  /// 玩家名称
  @override
  final String playerName;

  /// 座位号（1开始）
  @override
  final int seatNumber;

  /// 玩家状态
  @override
  final PlayerStatus status;

  /// 玩家角色
  @override
  @JsonKey()
  final PlayerRole role;

  /// 设备名称
  @override
  final String? deviceName;

  /// 设备IP地址
  @override
  final String? ipAddress;

  /// 加入时间
  @override
  final DateTime? joinedAt;

  /// 最后活跃时间
  @override
  final DateTime? lastActiveAt;

  /// 是否是房主
  @override
  @JsonKey()
  final bool isHost;

  /// 是否被禁言
  @override
  @JsonKey()
  final bool isMuted;

  /// 禁言结束时间
  @override
  final DateTime? muteEndTime;

  @override
  String toString() {
    return 'PlayerIdentity(playerId: $playerId, playerName: $playerName, seatNumber: $seatNumber, status: $status, role: $role, deviceName: $deviceName, ipAddress: $ipAddress, joinedAt: $joinedAt, lastActiveAt: $lastActiveAt, isHost: $isHost, isMuted: $isMuted, muteEndTime: $muteEndTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerIdentityImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.playerName, playerName) ||
                other.playerName == playerName) &&
            (identical(other.seatNumber, seatNumber) ||
                other.seatNumber == seatNumber) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.deviceName, deviceName) ||
                other.deviceName == deviceName) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.lastActiveAt, lastActiveAt) ||
                other.lastActiveAt == lastActiveAt) &&
            (identical(other.isHost, isHost) || other.isHost == isHost) &&
            (identical(other.isMuted, isMuted) || other.isMuted == isMuted) &&
            (identical(other.muteEndTime, muteEndTime) ||
                other.muteEndTime == muteEndTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      playerId,
      playerName,
      seatNumber,
      status,
      role,
      deviceName,
      ipAddress,
      joinedAt,
      lastActiveAt,
      isHost,
      isMuted,
      muteEndTime);

  /// Create a copy of PlayerIdentity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerIdentityImplCopyWith<_$PlayerIdentityImpl> get copyWith =>
      __$$PlayerIdentityImplCopyWithImpl<_$PlayerIdentityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerIdentityImplToJson(
      this,
    );
  }
}

abstract class _PlayerIdentity implements PlayerIdentity {
  const factory _PlayerIdentity(
      {required final String playerId,
      required final String playerName,
      required final int seatNumber,
      required final PlayerStatus status,
      final PlayerRole role,
      final String? deviceName,
      final String? ipAddress,
      final DateTime? joinedAt,
      final DateTime? lastActiveAt,
      final bool isHost,
      final bool isMuted,
      final DateTime? muteEndTime}) = _$PlayerIdentityImpl;

  factory _PlayerIdentity.fromJson(Map<String, dynamic> json) =
      _$PlayerIdentityImpl.fromJson;

  /// 玩家ID（UUID）
  @override
  String get playerId;

  /// 玩家名称
  @override
  String get playerName;

  /// 座位号（1开始）
  @override
  int get seatNumber;

  /// 玩家状态
  @override
  PlayerStatus get status;

  /// 玩家角色
  @override
  PlayerRole get role;

  /// 设备名称
  @override
  String? get deviceName;

  /// 设备IP地址
  @override
  String? get ipAddress;

  /// 加入时间
  @override
  DateTime? get joinedAt;

  /// 最后活跃时间
  @override
  DateTime? get lastActiveAt;

  /// 是否是房主
  @override
  bool get isHost;

  /// 是否被禁言
  @override
  bool get isMuted;

  /// 禁言结束时间
  @override
  DateTime? get muteEndTime;

  /// Create a copy of PlayerIdentity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerIdentityImplCopyWith<_$PlayerIdentityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
