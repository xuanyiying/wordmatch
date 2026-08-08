import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

/// 全局错误处理
///
/// 负责捕获：
/// 1. Flutter framework 层异常（build/layout/paint 等）
/// 2. Zone 内未捕获的异步异常
class ErrorHandler {
  ErrorHandler._();

  /// 初始化全局错误捕获
  static void initialize() {
    // 1. Flutter framework 异常
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _report(details.exception, details.stack, source: 'flutter');
    };

    // 2. 平台/异步异常（ Futures、isolate 等）
    PlatformDispatcher.instance.onError = (error, stack) {
      _report(error, stack, source: 'platform');
      return true;
    };
  }

  /// 在受保护的 Zone 中运行 app，捕获 Zone 内所有未处理异常
  static void runInZone(void Function() app) {
    runZonedGuarded(app, (error, stack) {
      _report(error, stack, source: 'zone');
    });
  }

  static void _report(Object error, StackTrace? stack, {required String source}) {
    // 开发环境直接打印；生产环境可替换为 Firebase Crashlytics / Sentry
    if (kDebugMode) {
      log('[$source] $error', stackTrace: stack, name: 'ErrorHandler');
    }
  }
}
