import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordmatch/core/audio/sherpa_tts_engine.dart';
import 'package:wordmatch/core/error/error_handler.dart';
import 'package:wordmatch/core/router/app_router.dart';
import 'package:wordmatch/core/settings/secure_storage_service.dart';
import 'package:wordmatch/core/subscription/subscription_service.dart';
import 'package:wordmatch/core/theme/app_theme.dart';
import 'package:wordmatch/core/theme/card_theme_providers.dart';
import 'package:wordmatch/core/theme/font_scale_provider.dart';
import 'package:wordmatch/core/theme/skin_theme_provider.dart';
import 'package:wordmatch/core/theme/theme_mode_provider.dart';
import 'package:wordmatch/features/ai/data/services/ai_response_cache.dart';
import 'package:wordmatch/features/learning/data/providers/study_reminder_provider.dart';
import 'package:wordmatch/features/learning/data/repositories/progress_storage.dart';
import 'package:wordmatch/features/wordbook/data/services/ai_clean_service.dart';
import 'package:wordmatch/shared/widgets/splash_screen.dart';

void main() {
  ErrorHandler.initialize();
  ErrorHandler.runInZone(_runApp);
}

Future<void> _runApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 预热 AI 缓存（内存层），后续 AI 功能打开即可秒级命中
  unawaited(AiResponseCache.preload());

  // 从本地存储加载 AI 配置（API Key 走系统级加密存储）
  final prefs = await SharedPreferences.getInstance();
  final savedKey = await SecureStorageService.readApiKey();
  final savedUrl = prefs.getString('ai_api_url');
  final savedModel = prefs.getString('ai_model_name');
  if (savedKey.isNotEmpty) {
    AiCleanService.configure(
      savedKey,
      url: savedUrl,
      modelName: savedModel,
    );
  }

  // 检查是否首次启动（未完成引导）
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  // 加载本地学习进度（词书进度 / 错词本 / 打卡 / 每日历史）到内存。
  // 启动时一次性完成，之后各页面可安全地同步读取，不会重复读盘。
  await ProgressStorage.instance.init();

  // 后台预下载离线 TTS 引擎（非阻塞；模型已就绪则立即返回，否则静默下载）
  // 解决国产 ROM（小米/华为等）系统 TTS 缺英文语音包导致发音无声的问题
  unawaited(SherpaTtsEngine.instance.ensureReady());

  runApp(ProviderScope(
    child: WordMatchApp(isFirstLaunch: !onboardingCompleted),
  ));
}

class WordMatchApp extends ConsumerStatefulWidget {
  final bool isFirstLaunch;

  const WordMatchApp({super.key, required this.isFirstLaunch});

  @override
  ConsumerState<WordMatchApp> createState() => _WordMatchAppState();
}

class _WordMatchAppState extends ConsumerState<WordMatchApp>
    with WidgetsBindingObserver {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 初始化通知服务并恢复学习提醒设置（非阻塞）
    unawaited(ref.read(studyReminderProvider.notifier).init());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 应用进入后台时暂停发音，恢复时释放已停的引擎资源，降低后台内存占用
    if (state == AppLifecycleState.paused) {
      SherpaTtsEngine.instance.stop();
      // 退到后台时把合并中的学习进度立即落盘，避免进程被回收导致进度丢失
      unawaited(ProgressStorage.instance.flush());
    } else if (state == AppLifecycleState.detached) {
      // 引擎即将销毁，释放离线 TTS 常驻模型（约 63MB）与购买流订阅
      SherpaTtsEngine.instance.dispose();
      SubscriptionService.dispose();
    }
  }

  void _onSplashComplete() {
    setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    // 监听卡片主题变化，触发全局 rebuild
    ref.watch(cardThemeControllerProvider);
    // 字体缩放系数：注入 MediaQuery.textScaler，全局统一缩放所有 Text 字号
    final fontScale = ref.watch(fontScaleProvider);
    // 夜间模式：跟随系统 / 浅色 / 深色
    final themeMode = ref.watch(themeModeValueProvider);
    // 主题皮肤：持久化 + 全局生效（切换后 MaterialApp 主题重建）
    final skin = ref.watch(skinThemeDataProvider);

    return MaterialApp(
      title: '单词消消乐',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(skin),
      darkTheme: AppTheme.dark(skin),
      themeMode: themeMode,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: widget.isFirstLaunch ? '/onboarding' : '/',
      builder: (context, child) {
        // 启动时显示闪屏，避免重建 Navigator
        final content = _showSplash
            ? SplashScreen(onComplete: _onSplashComplete)
            : (child ?? const SizedBox.shrink());
        // 全局字体缩放：覆盖系统 textScaler，使所有页面字号按统一比例缩放
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(fontScale),
          ),
          child: content,
        );
      },
    );
  }
}
