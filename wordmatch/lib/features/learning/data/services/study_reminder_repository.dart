import 'package:shared_preferences/shared_preferences.dart';

/// 学习提醒设置模型
class StudyReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const StudyReminderSettings({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
  });

  StudyReminderSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return StudyReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  /// 时间格式化为 "HH:mm"
  String get timeLabel => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// 学习提醒设置持久化仓库（shared_preferences）
class StudyReminderRepository {
  static const _kEnabled = 'study_reminder_enabled';
  static const _kHour = 'study_reminder_hour';
  static const _kMinute = 'study_reminder_minute';

  Future<StudyReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return StudyReminderSettings(
      enabled: prefs.getBool(_kEnabled) ?? false,
      hour: prefs.getInt(_kHour) ?? 20,
      minute: prefs.getInt(_kMinute) ?? 0,
    );
  }

  Future<void> save(StudyReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, settings.enabled);
    await prefs.setInt(_kHour, settings.hour);
    await prefs.setInt(_kMinute, settings.minute);
  }
}
