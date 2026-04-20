import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 所有扑克游戏页面的横屏锁定 Mixin。
///
/// 在 initState 中锁定横屏，在 dispose 中恢复。
/// 使用方式：
/// ```dart
/// class SomeGamePage extends ConsumerState<SomeGamePage>
///     with GameOrientationMixin {
///   // ...
/// }
/// ```
mixin GameOrientationMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }
}
