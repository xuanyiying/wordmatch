# WordMatch 卡片组件 v2 设计规范

> 目标：把卡片从"简陋"升级为"高吸引感"的多层装饰卡片，同时保持阅读专注度。

## 1. 总体设计原则

| 原则 | 含义 |
|---|---|
| **中央 60% 留白** | 单词/释义是绝对主角，所有装饰都让路 |
| **5 层阴影** | 内顶高光 + 内底投影 + 1px 边缘 + 8px 短投影 + 20px 长投影 |
| **3 套主题差异化** | 学术/森系/太空 一眼可分（颜色 + 装饰元素 + 缎带文字） |
| **强交互反馈** | 选中态 = 持续呼吸 (Option D) · 匹配态 = 灰阶 + 大绿印章 |

## 2. 卡片结构（z-index 从底到顶）

```
Stack (ClipRRect 圆角 22)
├─ 0. 底色渐变（来自 colors.gradient，3 套主题不同色）
├─ 1. 顶部玻璃高光 (40% 高度，6%-94% 宽度，灰白 alpha 0.7)
├─ 2. 3 色径向光斑（左上白 / 右下主题色 / 中央主题 accent，z-index 2）
├─ 3. 散落主题图标群（4-5 个 emoji，11% 透明，z-index 3）
├─ 4. 内双框装饰（dashed + double border，z-index 4）
├─ 5. 4 角 emoji 装饰（9-10px，z-index 5）
├─ 6. 3D 徽章 EN/中（z-index 6）
├─ 7. 3D 缎带（z-index 7）
├─ 8. 闪光 2-3 颗（z-index 8）
├─ 9. 中心文字（z-index 9）
└─ 10. 底部反光带（4px 高，灰白 alpha 0.18，z-index 10）
```

## 3. 三套主题差异化

| 维度 | 学术 | 森系 | 太空 |
|---|---|---|---|
| **typeA 主色** | 晴空蓝 #5B8DEF | 翠叶绿 #4CAF50 | 星云紫 #9C6ADE |
| **typeB 主色** | 珊瑚粉 #F06292 | 蜜糖橙 #FFA726 | 极光青 #26C6DA |
| **typeA 角标** | 📖📚⭐💎 | 🌿🍃☀🌱 | 🪐⭐🌟✨ |
| **typeB 角标** | 📝💡📖✨ | 🍂🌻🌿🌰 | 🌙☄🚀💫 |
| **typeA 缎带** | ★ CET-4 | 🍃 n. | ★ CET-4 |
| **typeB 缎带** | v. 释义 | v. 释义 | v. 释义 |
| **闪光符号** | ✦✧ | ✿❀ | ✦✧ |
| **底纹图标** | 📖✏️🖋️📜 | 🍃🌿☘️🌱 | ✦⭐✧🌟 |
| **内框色** | 金 #FFD66B | 米 #FFF3B0 | 紫 #C8A8F8 |
| **中央光斑 accent** | 金黄 #FFD66B | 米黄 #FFF3B0 | 淡紫 #C8A8F8 |

## 4. 三种状态规格

### 4.1 idle（未选中）
- 闲置微动画：
  - 学术 `paperFlutter` - Y 轴 0.98↔1.0 微缩（3s）
  - 森系 `organicBreathe` - 缩放 0.97↔1.0 + ±0.5° 旋转（4s）
  - 太空 `floatShimmer` - Y 轴 ±1px 漂浮（5s）
- 装饰层（v2 全套）全部启用
- 边框：1.5px 渐变金边

### 4.2 selected（已选中）- Option D
- **持续呼吸 1.6s 循环**：
  - scale 1.10 ↔ 1.13
  - 缎带 brightness 1.0 ↔ 1.3 + drop-shadow 脉动
  - 徽章 brightness 1.0 ↔ 1.3 脉动
  - 整体光晕 60-80px（呼吸同步）
- transform: translateY(-8px) + scale(1.10) + rotate(-3°)
- 边框：3px 金环 + 6px 金色光晕
- 装饰：保留全部 idle 装饰 + 4 颗闪光

### 4.3 matched（已匹配）
- 整体降饱和 85% + 提亮 5%
- 中心覆盖 50px 绿色印章（带 5px 虚线环绕 + -12° 倾斜）
- 文字 2.5px 删除线（#8FB970 绿色）
- 装饰：隐藏图标群 / 闪光 / 角标

## 5. 数据结构扩展

### card_theme.dart 新增

```dart
/// 选中态动画类型
enum SelectedAnimationType {
  /// 持续呼吸：scale + ribbon/badge 亮度脉动（1.6s 循环）
  breathe,
}

/// 闪光元素位置
class SparkleSpec {
  final double topPercent;  // 0-100
  final double leftPercent; // 0-100
  final double fontSize;
  final String char;
  final double opacity; // 0-1
}

/// 背景图标
class BgIconSpec {
  final double topPercent;
  final double leftPercent;
  final double fontSize;
  final String char;
}

/// 缎带/角标/光斑等装饰
class CardDecorations {
  final String ribbonText;       // "★ CET-4" / "v. 释义"
  final List<String> cornerEmojis; // 4 个
  final List<BgIconSpec> bgIcons;  // 4-5 个
  final List<Color> bgBlobColors;  // 3 色 (白 + 主题色 + accent)
  final List<SparkleSpec> sparkles; // 2-3 个
  final String badgeText;        // "EN" / "中"
}

/// 扩展 CardStateColors
class CardStateColors {
  // ... 原字段 ...
  final CardDecorations? decorations;
}
```

## 6. 性能预算

- 每个 CardWidget 至多 14 个子 widget（Stack + 装饰层）
- 持续呼吸动画 1.6s 周期，60 FPS
- 总性能开销：+10-15% 渲染时间（vs 旧版）
- 内存：每个 CardWidget +4 个 Text（图标群）+ 3 个 Container（光斑）

## 7. 实现顺序

1. 扩展 `card_theme.dart` - 新增数据类型
2. 写新装饰组件 `card_decorators.dart` - Badge3D / Ribbon3D / MatchedSeal / 等
3. 重写 `card_widget.dart` - 集成所有装饰 + 实现 Option D 呼吸
4. 更新 `card_theme_registry.dart` - 填充 3 主题 × 2 变体的装饰数据
5. flutter analyze + build apk 验证
6. 截图给你看
