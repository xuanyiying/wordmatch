import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordmatch/core/router/app_router.dart';
import 'package:wordmatch/features/shell/presentation/screens/main_shell.dart';
import 'package:wordmatch/features/wordbook/presentation/screens/wordbook_select_screen.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.dir);
  final String dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
}

class _LogObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('PUSH => ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('POP => ${route.settings.name}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('从我的页进入词库管理（runAsync）', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final dir = Directory.systemTemp.createTempSync('wb_nav_');
    PathProviderPlatform.instance = _FakePathProvider(dir.path);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: '/',
            navigatorObservers: [_LogObserver()],
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await tester.pump();

      await tester.tap(find.text('我的').first);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pump();

      final entry = find.text('词库管理');
      debugPrint('入口 => ${entry.evaluate().length}');
      final ink = find.ancestor(of: entry, matching: find.byType(InkWell));
      debugPrint('InkWell => ${ink.evaluate().length}');
      debugPrint('MainShell => ${find.byType(MainShell).evaluate().length}');

      await tester.tap(entry.first, warnIfMissed: true);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    debugPrint('异常 => ${tester.takeException()}');
    debugPrint('WordbookSelect => ${find.byType(WordbookSelectScreen).evaluate().length}');
    debugPrint('选择词库 => ${find.text('选择词库').evaluate().length}');
    debugPrint('MainShell => ${find.byType(MainShell).evaluate().length}');
  });
}
