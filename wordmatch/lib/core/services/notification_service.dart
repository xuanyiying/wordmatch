import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 本地通知服务：负责学习提醒的初始化、权限申请与每日定时调度。
///
/// 使用 `flutter_local_notifications` + `timezone` 实现每日固定时刻的
/// 本地通知（无需后台服务，本地精确闹钟）。
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// 学习提醒通知 ID
  static const int _studyReminderId = 1001;

  /// 通知渠道 ID（Android）
  static const String _channelId = 'study_reminder';

  bool _initialized = false;

  /// 是否已初始化
  bool get isInitialized => _initialized;

  /// 初始化通知插件（应用启动时调用一次）。
  ///
  /// 幂等：重复调用不会重复初始化。Android 需配置图标/渠道，iOS 需请求权限。
  Future<void> init() async {
    if (_initialized) return;

    // 初始化时区（用于每日定时计算），并设置为系统本地时区
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    } catch (_) {
      // 若本地时区无法解析，忽略并回退到默认（UTC）
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// 请求通知权限。
  ///
  /// Android 13+ 需要在运行时请求 `POST_NOTIFICATIONS`；低版本自动授予。
  /// iOS 请求 alert / sound / badge。
  Future<bool> requestPermissions() async {
    await init();
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        if (granted == null) return true; // 无需授权（低版本）
        return granted;
      }
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        return await iosImpl.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 调度每日学习提醒。
  ///
  /// [hour]、[minute] 为本地时区每日触发时刻。替换旧的提醒（同一通知 ID）。
  Future<bool> scheduleDailyStudyReminder({
    required int hour,
    required int minute,
  }) async {
    await init();
    final ok = await requestPermissions();
    if (!ok) return false;

    final tz.TZDateTime scheduled = _nextInstanceOf(hour, minute);

    try {
      await _plugin.zonedSchedule(
        _studyReminderId,
        '该学习啦 🌱',
        '单词消消乐：今天的新词和复习任务在等你哦～',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            '学习提醒',
            channelDescription: '每天定时提醒你完成今日单词学习',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 取消学习提醒。
  Future<void> cancelStudyReminder() async {
    await init();
    await _plugin.cancel(_studyReminderId);
  }

  /// 计算下一次指定时刻（本地时区）。
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
