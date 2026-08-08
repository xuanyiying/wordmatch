import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'package:wordmatch/shared/widgets/app_logo.dart';

/// 引导页（Phase 1 完整实现）
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildLogoPage(),
                  _buildIntroPage(
                    icon: Icons.psychology,
                    title: '科学记忆',
                    subtitle: 'SM-2 间隔重复算法\n在你快要遗忘时精准复习',
                  ),
                  _buildIntroPage(
                    icon: Icons.rocket_launch,
                    title: '开始学习',
                    subtitle: '选择你的目标词库\n开启高效背词之旅',
                  ),
                ],
              ),
            ),
            // 指示器与按钮
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 页面指示器
                  ...List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? colors.mintDeep
                            : const Color(0xFFC5D1BC),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < 2) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _completeOnboarding();
                    }
                  },
                  child: Text(_currentPage < 2 ? '下一步' : '开始使用'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPage() {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo 动画
          const AppLogo(size: 160, animate: true),
          const SizedBox(height: 32),
          Text(
            '单词消消乐',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '翻开卡牌，英汉匹配\n消除成功即记住',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colors.inkSoft,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroPage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: context.appColors.mintDeep.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: context.appColors.mintDeep),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.appColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: context.appColors.inkSoft,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
