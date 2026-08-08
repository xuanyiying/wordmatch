/// 应用尺寸常量
class AppSizes {
  AppSizes._();

  /// 卡牌圆角
  static const double cardRadius = 12.0;

  /// 卡牌内边距
  static const double cardPadding = 8.0;

  /// 网格间距
  static const double gridSpacing = 10.0;

  /// 4x4 网格卡牌尺寸
  static const double cardSizeSmall = 90.0;

  /// 6x6 网格卡牌尺寸
  static const double cardSizeLarge = 68.0;

  /// 页面水平边距
  static const double pagePaddingH = 16.0;

  /// 页面垂直边距
  static const double pagePaddingV = 16.0;

  /// 标题字号
  static const double titleSize = 24.0;

  /// 正文字号
  static const double bodySize = 16.0;

  /// 卡牌 typeA 文本字号（如英文单词、上句、元素符号）
  static const double cardWordSize = 16.0;

  /// 卡牌 typeB 文本字号（如中文释义、下句、元素名称）
  static const double cardMeaningSize = 15.0;

  /// Combo 指示器字号
  static const double comboSize = 32.0;

  /// 动画时长（毫秒）
  static const int flipDurationMs = 400;
  static const int shakeDurationMs = 400;
  static const int eliminateDurationMs = 600;
  static const int comboDisplayMs = 1500;

  /// 匹配超时阈值（秒）
  static const int matchTimeoutSeconds = 3;
}
