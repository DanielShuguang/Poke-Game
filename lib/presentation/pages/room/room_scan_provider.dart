import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:poke_game/core/network/network_environment_checker.dart';
import 'package:poke_game/core/network/udp_broadcaster.dart';
import 'package:poke_game/domain/lan/entities/room_info.dart';

/// 扫描状态
enum ScanStatus {
  /// 空闲
  idle,

  /// 扫描中
  scanning,

  /// 已停止
  stopped,

  /// 错误
  error,
}

/// 扫描状态
class RoomScanState {
  /// 扫描状态
  final ScanStatus status;

  /// 发现的房间列表
  final List<RoomInfo> rooms;

  /// 错误消息
  final String? errorMessage;

  /// 网络检测结果
  final NetworkCheckResult? networkCheck;

  const RoomScanState({
    this.status = ScanStatus.idle,
    this.rooms = const [],
    this.errorMessage,
    this.networkCheck,
  });

  RoomScanState copyWith({
    ScanStatus? status,
    List<RoomInfo>? rooms,
    String? errorMessage,
    NetworkCheckResult? networkCheck,
  }) {
    return RoomScanState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      errorMessage: errorMessage,
      networkCheck: networkCheck ?? this.networkCheck,
    );
  }
}

/// 房间扫描 Notifier
class RoomScanNotifier extends StateNotifier<RoomScanState> {
  final Logger _logger = Logger();
  final UdpListener _udpListener = UdpListener();
  final NetworkEnvironmentChecker _networkChecker = NetworkEnvironmentChecker();

  Timer? _scanTimeoutTimer;

  RoomScanNotifier() : super(const RoomScanState());

  /// 检查网络环境
  Future<void> checkNetwork() async {
    final result = await _networkChecker.checkEnvironment();
    state = state.copyWith(networkCheck: result);
  }

  /// 开始扫描房间
  Future<void> startScan() async {
    if (state.status == ScanStatus.scanning) {
      _logger.w('已经在扫描中');
      return;
    }

    // 先检查网络
    if (state.networkCheck == null) {
      await checkNetwork();
    }

    if (state.networkCheck?.canPlayLanGame != true) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: state.networkCheck?.message ?? '网络不可用',
      );
      return;
    }

    state = state.copyWith(
      status: ScanStatus.scanning,
      rooms: [],
      errorMessage: null,
    );

    try {
      await _udpListener.startListening(_onRoomFound);

      // 设置扫描超时（10秒）
      _scanTimeoutTimer = Timer(const Duration(seconds: 10), () {
        if (state.status == ScanStatus.scanning) {
          stopScan();
          if (state.rooms.isEmpty) {
            state = state.copyWith(
              errorMessage: '未发现房间，请确保设备在同一 WiFi 下',
            );
          }
        }
      });

      _logger.i('开始扫描房间');
    } catch (e) {
      _logger.e('启动扫描失败: $e');
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: '启动扫描失败: $e',
      );
    }
  }

  /// 停止扫描
  void stopScan() {
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;
    _udpListener.stopListening();

    if (state.status == ScanStatus.scanning) {
      state = state.copyWith(status: ScanStatus.stopped);
      _logger.i('停止扫描房间');
    }
  }

  /// 发现房间回调
  void _onRoomFound(String roomInfoJson) {
    try {
      final json = jsonDecode(roomInfoJson) as Map<String, dynamic>;
      final roomInfo = RoomInfo.fromJson(json);

      // 检查是否已存在
      final existingIndex = state.rooms.indexWhere((r) => r.roomId == roomInfo.roomId);

      if (existingIndex >= 0) {
        // 更新已存在的房间
        final updatedRooms = List<RoomInfo>.from(state.rooms);
        updatedRooms[existingIndex] = roomInfo;
        state = state.copyWith(rooms: updatedRooms);
      } else {
        // 添加新房间
        state = state.copyWith(rooms: [...state.rooms, roomInfo]);
      }

      _logger.d('发现房间: ${roomInfo.roomName}');
    } catch (e) {
      _logger.e('解析房间信息失败: $e');
    }
  }

  /// 清空房间列表
  void clearRooms() {
    state = state.copyWith(rooms: []);
  }

  /// 手动添加房间（通过 IP）
  Future<bool> addRoomByIp(String ipAddress, int port) async {
    _logger.i('手动添加房间: $ipAddress:$port');

    try {
      final dio = Dio();

      // 尝试获取房间信息
      final response = await dio.get(
        'http://$ipAddress:$port/room/info',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final roomInfoJson = response.data as Map<String, dynamic>;

        // 添加网络地址信息
        roomInfoJson['networkAddress'] = ipAddress;

        final roomInfo = RoomInfo.fromJson(roomInfoJson);

        // 检查是否已存在
        final existingIndex = state.rooms.indexWhere((r) => r.roomId == roomInfo.roomId);

        if (existingIndex >= 0) {
          // 更新已存在的房间
          final updatedRooms = List<RoomInfo>.from(state.rooms);
          updatedRooms[existingIndex] = roomInfo;
          state = state.copyWith(rooms: updatedRooms);
        } else {
          // 添加新房间
          state = state.copyWith(rooms: [...state.rooms, roomInfo]);
        }

        _logger.i('成功添加房间: ${roomInfo.roomName}');
        return true;
      }
    } on DioException catch (e) {
      _logger.e('连接房间失败: ${e.message}');
    } catch (e) {
      _logger.e('添加房间失败: $e');
    }

    return false;
  }

  @override
  void dispose() {
    stopScan();
    super.dispose();
  }
}

/// 房间扫描 Provider
final roomScanProvider =
    StateNotifierProvider<RoomScanNotifier, RoomScanState>((ref) {
  return RoomScanNotifier();
});
