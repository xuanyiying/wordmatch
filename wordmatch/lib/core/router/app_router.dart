import 'package:flutter/material.dart';
import 'package:wordmatch/core/settings/ai_settings_screen.dart';
import 'package:wordmatch/core/settings/privacy_policy_screen.dart';
import 'package:wordmatch/core/settings/settings_screen.dart';
import 'package:wordmatch/core/settings/user_agreement_screen.dart';
import 'package:wordmatch/core/theme/card_theme_select_screen.dart';
import 'package:wordmatch/core/theme/skin_theme_settings_screen.dart';
import 'package:wordmatch/features/game/presentation/screens/game_screen.dart';
import 'package:wordmatch/features/learning/domain/services/plan_service.dart';
import 'package:wordmatch/features/learning/presentation/screens/dialogue_practice_screen.dart';
import 'package:wordmatch/features/learning/presentation/screens/new_word_screen.dart';
import 'package:wordmatch/features/learning/presentation/screens/report_screen.dart';
import 'package:wordmatch/features/learning/presentation/screens/stats_screen.dart';
import 'package:wordmatch/features/learning/presentation/screens/word_chain_story_screen.dart';
import 'package:wordmatch/features/learning/presentation/screens/word_network_screen.dart';
import 'package:wordmatch/features/learning/presentation/screens/word_stream_screen.dart';
import 'package:wordmatch/features/learning/presentation/screens/wrong_word_screen.dart';
import 'package:wordmatch/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:wordmatch/features/shell/presentation/screens/main_shell.dart';
import 'package:wordmatch/features/wordbook/data/models/word.dart';
import 'package:wordmatch/features/wordbook/presentation/screens/import_wordbook_screen.dart';
import 'package:wordmatch/features/wordbook/presentation/screens/wordbook_select_screen.dart';

/// 应用路由配置
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _buildRoute(const MainShell(), settings);
      case '/onboarding':
        return _buildRoute(const OnboardingScreen(), settings);
      case '/game':
        final args = settings.arguments as GameScreenArgs?;
        return _buildRoute(
          GameScreen(args: args ?? GameScreenArgs.defaultArgs()),
          settings,
        );
      case '/new_word':
        final args = settings.arguments as NewWordArgs?;
        if (args != null) {
          return _buildRoute(
            NewWordScreen(
              words: args.words,
              onComplete: args.onComplete,
              onRecognitionComplete: args.onRecognitionComplete,
              browseMode: args.browseMode,
            ),
            settings,
          );
        }
        return _buildRoute(const MainShell(), settings);
      case '/report':
        final args = settings.arguments as DailyTask?;
        if (args != null) {
          return _buildRoute(ReportScreen(dailyTask: args), settings);
        }
        return _buildRoute(const MainShell(), settings);
      case '/wordbook_select':
        return _buildRoute(const WordbookSelectScreen(), settings);
      case '/import_wordbook':
        return _buildRoute(const ImportWordbookScreen(), settings);
      case '/card_theme_select':
        return _buildRoute(const CardThemeSelectScreen(), settings);
      case '/theme_settings':
        return _buildRoute(const ThemeSettingsScreen(), settings);
      case '/wrong_word':
        return _buildRoute(const WrongWordScreen(), settings);
      case '/word_network':
        final args = settings.arguments as WordNetworkArgs?;
        if (args != null) {
          return _buildRoute(WordNetworkScreen(args: args), settings);
        }
        return _buildRoute(const MainShell(), settings);
      case '/dialogue_practice':
        final args = settings.arguments as DialoguePracticeArgs?;
        if (args != null) {
          return _buildRoute(DialoguePracticeScreen(args: args), settings);
        }
        return _buildRoute(const MainShell(), settings);
      case '/word_chain_story':
        final args = settings.arguments as WordChainStoryArgs?;
        if (args != null) {
          return _buildRoute(WordChainStoryScreen(args: args), settings);
        }
        return _buildRoute(const MainShell(), settings);
      case '/word_stream':
        final args = settings.arguments as WordStreamArgs?;
        return _buildRoute(WordStreamScreen(args: args), settings);
      case '/stats':
        return _buildRoute(const StatsScreen(), settings);
      case '/settings':
        return _buildRoute(const SettingsScreen(), settings);
      case '/ai_settings':
        return _buildRoute(const AiSettingsScreen(), settings);
      case '/privacy_policy':
        return _buildRoute(const PrivacyPolicyScreen(), settings);
      case '/user_agreement':
        return _buildRoute(const UserAgreementScreen(), settings);
      default:
        return _buildRoute(const MainShell(), settings);
    }
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }

  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String game = '/game';
  static const String newWord = '/new_word';
  static const String report = '/report';
  static const String wordbookSelect = '/wordbook_select';
  static const String importWordbook = '/import_wordbook';
  static const String cardThemeSelect = '/card_theme_select';
  static const String themeSettings = '/theme_settings';
  static const String wrongWord = '/wrong_word';
  static const String wordNetwork = '/word_network';
  static const String dialoguePractice = '/dialogue_practice';
  static const String wordChainStory = '/word_chain_story';
  static const String wordStream = '/word_stream';
  static const String stats = '/stats';
  static const String settings = '/settings';
  static const String aiSettings = '/ai_settings';
  static const String privacyPolicy = '/privacy_policy';
  static const String userAgreement = '/user_agreement';
}

/// 新词学习页面参数
class NewWordArgs {
  final List<Word> words;
  final VoidCallback onComplete;

  /// 学习完成后，传入每个词的"认识"结果列表，保存初始 SM-2 进度
  final void Function(List<bool> recognizedList)? onRecognitionComplete;

  /// 浏览模式：用于同反义词网络 chip 跳转。
  /// true 时强制展开详情、隐藏进度点与认识/不认识操作按钮，
  /// 仅展示单词卡片本身，标题改为「单词详情」。
  final bool browseMode;

  const NewWordArgs({
    required this.words,
    required this.onComplete,
    this.onRecognitionComplete,
    this.browseMode = false,
  });
}

/// 单词流页面参数
class WordStreamArgs {
  final List<Word> words;
  final String mode;

  const WordStreamArgs({
    this.words = const [],
    this.mode = 'today',
  });
}

/// 词串烧页面参数
class WordChainStoryArgs {
  final List<Word> todaysWords;
  final String bookName;

  const WordChainStoryArgs({
    required this.todaysWords,
    required this.bookName,
  });
}
