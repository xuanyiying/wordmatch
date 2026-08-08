import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/features/today/data/daily_content_service.dart';
import 'package:wordmatch/features/today/domain/models/daily_word.dart';
import 'package:wordmatch/features/today/domain/models/daily_quote.dart';

/// 每日一词 Provider
final dailyWordProvider = FutureProvider<DailyWord>((ref) async {
  return DailyContentService.getWordOfDay();
});

/// 每日一词手动覆盖 Notifier（「换一个」时设置，null 时用日期默认词）
class DailyWordOverrideNotifier extends Notifier<DailyWord?> {
  @override
  DailyWord? build() => null;

  void set(DailyWord? word) {
    state = word;
  }
}

/// 每日一词手动覆盖 Provider
final dailyWordOverrideProvider =
    NotifierProvider<DailyWordOverrideNotifier, DailyWord?>(
        DailyWordOverrideNotifier.new);

/// 每日一句 Provider
final dailyQuoteProvider = FutureProvider<DailyQuote>((ref) async {
  return DailyContentService.getQuoteOfDay();
});
