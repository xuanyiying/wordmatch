import 'package:flutter/material.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/features/learning/presentation/screens/home_screen.dart';
import 'package:wordmatch/features/profile/presentation/screens/profile_screen.dart';
import 'package:wordmatch/features/today/presentation/screens/today_screen.dart';

/// 应用主框架：底部导航三 Tab（学习 / 今日 / 我的）
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// 三个 Tab 页面（保持常驻，IndexedStack 保留状态）
  final List<Widget> _screens = const [
    LearnTab(),
    TodayScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.card,
          border: Border(
            top: BorderSide(color: colors.border),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _navItem(0, Icons.menu_book_outlined, Icons.menu_book, '学习'),
                _navItem(1, Icons.star_outline, Icons.star, '今日'),
                _navItem(2, Icons.person_outline, Icons.person, '我的'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData inactive, IconData active, String label) {
    final selected = _index == i;
    final colors = context.appColors;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = i),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: selected
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.mintLight, colors.mintDeep],
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    )
                  : null,
              child: Icon(
                selected ? active : inactive,
                color: selected ? colors.ink : colors.inkFaint,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? colors.ink : colors.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
