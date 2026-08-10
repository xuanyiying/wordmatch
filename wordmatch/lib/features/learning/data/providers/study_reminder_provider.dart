import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/core/services/notification_service.dart';
import 'package:wordmatch/features/learning/data/services/study_reminder_repository.dart';

/// 学习提醒状态管理
///
/// 负责读取/保存设置，并在状态变更时同步调度或取消本地每日提醒通知。
class StudyReminderNotifier extends Notifier<StudyReminderSettings> {
  late final StudyReminderRepository _repo;

  @override
  StudyReminderSettings build() {
    _repo = StudyReminderRepository();
    return const StudyReminderSettings();
  }

  /// 初始化：读取持久化设置，并根据开关状态恢复/清理通知。
  Future<void> init() async {
    final settings = await _repo.load();
    state = settings;
    if (settings.enabled) {
      await NotificationService.instance.scheduleDailyStudyReminder(
        hour: settings.hour,
        minute: settings.minute,
      );
    }
  }

  /// 切换开关
  Future<bool> toggle(bool enabled) async {
    final next = state.copyWith(enabled: enabled);
    await _apply(next);
    return true;
  }

  /// 设置提醒时间
  Future<void> setTime({required int hour, required int minute}) async {
    final next = state.copyWith(hour: hour, minute: minute);
    await _apply(next);
  }

  /// 应用新设置：持久化 + 调度/取消通知。
  Future<void> _apply(StudyReminderSettings next) async {
    state = next;
    await _repo.save(next);
    if (next.enabled) {
      await NotificationService.instance.scheduleDailyStudyReminder(
        hour: next.hour,
        minute: next.minute,
      );
    } else {
      await NotificationService.instance.cancelStudyReminder();
    }
  }
}

/// 学习提醒 Provider
final studyReminderProvider =
    NotifierProvider<StudyReminderNotifier, StudyReminderSettings>(
        StudyReminderNotifier.new);
