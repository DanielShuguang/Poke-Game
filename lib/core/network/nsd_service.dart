import 'dart:async';

import 'package:logger/logger.dart';
import 'package:nsd/nsd.dart' as nsd;

/// mDNS 服务类型
const String kServiceType = '_pokegame._tcp';

/// 服务信息
class NsdServiceInfo {
  final String name;
  final String host;
  final int port;

  NsdServiceInfo({
    required this.name,
    required this.host,
    required this.port,
  });
}

/// NSD 服务管理器
///
/// 用于 iOS/macOS 平台的服务发现
class NsdService {
  final Logger _logger = Logger();

  /// 服务名称
  final String serviceName;

  /// 服务端口
  final int port;

  nsd.Registration? _registration;
  nsd.Discovery? _discovery;

  NsdService({
    required this.serviceName,
    this.port = 8080,
  });

  /// 注册服务（房主使用）
  ///
  /// 让其他设备可以发现此设备提供的房间服务
  Future<void> registerService() async {
    try {
      final service = nsd.Service(
        name: serviceName,
        type: kServiceType,
        port: port,
      );

      _registration = await nsd.register(service);
      _logger.i('NSD 服务已注册: $serviceName, 端口: $port');
    } catch (e) {
      _logger.e('注册 NSD 服务失败: $e');
      rethrow;
    }
  }

  /// 取消注册服务
  Future<void> unregisterService() async {
    if (_registration != null) {
      try {
        await nsd.unregister(_registration!);
        _logger.i('NSD 服务已取消注册');
      } catch (e) {
        _logger.e('取消注册 NSD 服务失败: $e');
      } finally {
        _registration = null;
      }
    }
  }

  /// 发现服务（客户端使用）
  ///
  /// [onServiceFound] 发现服务时的回调
  Future<void> discoverServices(
    Function(NsdServiceInfo serviceInfo) onServiceFound,
  ) async {
    try {
      _discovery = await nsd.startDiscovery(kServiceType);

      // 添加服务监听器
      _discovery!.addServiceListener((nsd.Service service, nsd.ServiceStatus status) {
        if (status == nsd.ServiceStatus.found) {
          _logger.d('发现服务: ${service.name}');

          if (service.host != null && service.port != null) {
            onServiceFound(NsdServiceInfo(
              name: service.name ?? 'Unknown',
              host: service.host!,
              port: service.port!,
            ));
          }
        } else if (status == nsd.ServiceStatus.lost) {
          _logger.d('服务丢失: ${service.name}');
        }
      });

      _logger.i('开始发现 NSD 服务: $kServiceType');
    } catch (e) {
      _logger.e('发现 NSD 服务失败: $e');
      rethrow;
    }
  }

  /// 停止发现服务
  Future<void> stopNsdDiscovery() async {
    if (_discovery != null) {
      try {
        await nsd.stopDiscovery(_discovery!);
        _logger.i('停止发现 NSD 服务');
      } catch (e) {
        _logger.e('停止发现失败: $e');
      } finally {
        _discovery = null;
      }
    }
  }

  /// 解析服务地址
  ///
  /// 获取服务的具体 IP 和端口信息
  Future<NsdServiceInfo?> resolveService(nsd.Service service) async {
    try {
      final result = await nsd.resolve(service);

      _logger.i('解析服务成功: ${result.name}, 地址: ${result.host}, 端口: ${result.port}');

      return NsdServiceInfo(
        name: result.name ?? service.name ?? 'Unknown',
        host: result.host ?? '',
        port: result.port ?? port,
      );
    } catch (e) {
      _logger.e('解析服务失败: $e');
      return null;
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await unregisterService();
    await stopNsdDiscovery();
  }
}
