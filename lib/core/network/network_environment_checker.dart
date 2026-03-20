import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';

/// 网络环境状态
enum NetworkEnvironment {
  /// 已连接 WiFi
  wifiConnected,

  /// 未连接 WiFi
  wifiDisconnected,

  /// 移动数据
  mobileData,

  /// 未知
  unknown,
}

/// 网络环境检测结果
class NetworkCheckResult {
  /// 网络环境
  final NetworkEnvironment environment;

  /// 是否可以运行局域网游戏
  final bool canPlayLanGame;

  /// 提示消息
  final String? message;

  /// 本地 IP 地址
  final String? localIp;

  NetworkCheckResult({
    required this.environment,
    required this.canPlayLanGame,
    this.message,
    this.localIp,
  });
}

/// 网络环境检测服务
class NetworkEnvironmentChecker {
  final Logger _logger = Logger();

  /// 检测网络环境
  Future<NetworkCheckResult> checkEnvironment() async {
    try {
      // 获取网络接口信息
      final interfaces = await NetworkInterface.list();

      // 查找 WiFi 接口
      for (final interface in interfaces) {
        // 检查是否是 WiFi 接口（不同平台名称不同）
        if (_isWifiInterface(interface.name)) {
          // 获取 IPv4 地址
          for (final addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4) {
              final ip = addr.address;

              _logger.i('检测到 WiFi 连接: ${interface.name}, IP: $ip');

              // 检查是否是有效局域网 IP
              if (_isValidLanIp(ip)) {
                return NetworkCheckResult(
                  environment: NetworkEnvironment.wifiConnected,
                  canPlayLanGame: true,
                  localIp: ip,
                  message: 'WiFi 已连接，可以开始局域网游戏',
                );
              }
            }
          }
        }
      }

      // 未检测到 WiFi 连接
      return NetworkCheckResult(
        environment: NetworkEnvironment.wifiDisconnected,
        canPlayLanGame: false,
        message: '未检测到 WiFi 连接，请先连接 WiFi',
      );
    } catch (e) {
      _logger.e('检测网络环境失败: $e');
      return NetworkCheckResult(
        environment: NetworkEnvironment.unknown,
        canPlayLanGame: false,
        message: '无法检测网络环境: $e',
      );
    }
  }

  /// 检测 AP 隔离
  ///
  /// 尝试 ping 网关来检测是否启用了 AP 隔离
  Future<bool> checkApIsolation(String gatewayIp) async {
    try {
      // 尝试 ping 网关
      final result = await Process.run(
        'ping',
        ['-c', '1', '-W', '2', gatewayIp],
      );

      if (result.exitCode == 0) {
        _logger.i('网关可达，AP 隔离未启用');
        return false;
      } else {
        _logger.w('网关不可达，可能启用了 AP 隔离');
        return true;
      }
    } catch (e) {
      _logger.e('检测 AP 隔离失败: $e');
      return false;
    }
  }

  /// 获取网关 IP（简化版，实际需要平台特定实现）
  Future<String?> getGatewayIp() async {
    // 这个方法在不同平台需要不同的实现
    // 简化版：假设网关是 IP 的最后一位改为 1
    final result = await checkEnvironment();
    if (result.localIp != null) {
      final parts = result.localIp!.split('.');
      if (parts.length == 4) {
        parts[3] = '1';
        return parts.join('.');
      }
    }
    return null;
  }

  /// 获取本机 IP 地址列表
  Future<List<String>> getLocalIpAddresses() async {
    final ips = <String>[];

    try {
      final interfaces = await NetworkInterface.list();

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            final ip = addr.address;
            if (_isValidLanIp(ip)) {
              ips.add(ip);
            }
          }
        }
      }
    } catch (e) {
      _logger.e('获取本地 IP 失败: $e');
    }

    return ips;
  }

  /// 判断是否是 WiFi 接口
  bool _isWifiInterface(String name) {
    final lowerName = name.toLowerCase();
    // Android
    if (lowerName.startsWith('wlan') || lowerName.startsWith('wifi')) {
      return true;
    }
    // iOS
    if (lowerName.startsWith('en') && lowerName != 'en0') {
      return true;
    }
    // Windows
    if (lowerName.contains('wireless') || lowerName.contains('wi-fi')) {
      return true;
    }
    // macOS
    if (lowerName == 'en0') {
      return true;
    }
    // Linux
    if (lowerName.startsWith('wlp') || lowerName.startsWith('wlan')) {
      return true;
    }

    return false;
  }

  /// 判断是否是有效的局域网 IP
  bool _isValidLanIp(String ip) {
    // 排除回环地址
    if (ip.startsWith('127.')) return false;

    // 排除链路本地地址
    if (ip.startsWith('169.254.')) return false;

    // 常见局域网 IP 段
    if (ip.startsWith('192.168.')) return true;
    if (ip.startsWith('10.')) return true;
    if (ip.startsWith('172.')) {
      // 172.16.0.0 - 172.31.255.255
      final parts = ip.split('.');
      if (parts.length == 4) {
        final second = int.tryParse(parts[1]) ?? 0;
        if (second >= 16 && second <= 31) return true;
      }
    }

    return false;
  }
}
