import 'package:flutter/material.dart';
import 'package:wordmatch/core/theme/card_theme.dart';

/// 3 套卡片主题注册表 v2
/// 核心原则：高吸引感多层装饰，3 主题差异化，typeA/typeB 强对比
class CardThemeRegistry {
  CardThemeRegistry._();

  /// 全部主题（顺序固定）
  static final List<CardVisualTheme> all = [
    academic,
    forest,
    space,
  ];

  /// 根据 type 获取
  static CardVisualTheme get(CardThemeType type) {
    return all.firstWhere((t) => t.type == type);
  }

  // ============ 装饰工厂：3 主题差异化数据 ============

  /// 学术 typeA 装饰
  static CardDecorations _academicTypeA(Color blobColor) => CardDecorations(
        ribbonText: '★ CET-4',
        cornerEmojis: const ['📖', '⭐', '📚', '💎'],
        bgIcons: const [
          BgIconSpec(topPercent: 18, leftPercent: 24, fontSize: 14, char: '📖'),
          BgIconSpec(topPercent: 55, leftPercent: 80, fontSize: 12, char: '✏️'),
          BgIconSpec(
              topPercent: 82, leftPercent: 32, fontSize: 13, char: '🖋️'),
          BgIconSpec(topPercent: 25, leftPercent: 68, fontSize: 11, char: '📜'),
        ],
        bgBlobColors: [
          Colors.white,
          blobColor,
          const Color(0xFFFFD66B),
        ],
        sparkles: const [
          SparkleSpec(topPercent: 30, leftPercent: 18, fontSize: 13, char: '✦'),
          SparkleSpec(topPercent: 78, leftPercent: 20, fontSize: 10, char: '✧'),
        ],
        badgeText: 'EN',
        frameColor: const Color(0xFFFFD66B),
        ribbonColor: const Color(0xFFFFB93F),
        badgeColor: const Color(0xFF5B8DEF),
        sparkleColor: const Color(0xFFFFD66B),
        sealColor: const Color(0xFF5A8858),
      );

  /// 学术 typeB 装饰
  static CardDecorations _academicTypeB(Color blobColor) => CardDecorations(
        ribbonText: 'v. 释义',
        cornerEmojis: const ['📝', '💡', '📖', '✨'],
        bgIcons: const [
          BgIconSpec(topPercent: 18, leftPercent: 24, fontSize: 14, char: '📝'),
          BgIconSpec(topPercent: 55, leftPercent: 80, fontSize: 12, char: '💡'),
          BgIconSpec(topPercent: 82, leftPercent: 32, fontSize: 13, char: '📖'),
          BgIconSpec(topPercent: 25, leftPercent: 68, fontSize: 11, char: '✨'),
        ],
        bgBlobColors: [
          Colors.white,
          blobColor,
          const Color(0xFFFFD66B),
        ],
        sparkles: const [
          SparkleSpec(topPercent: 30, leftPercent: 18, fontSize: 13, char: '✦'),
          SparkleSpec(topPercent: 78, leftPercent: 20, fontSize: 10, char: '✧'),
        ],
        badgeText: '中',
        frameColor: const Color(0xFFFFD66B),
        ribbonColor: const Color(0xFFFFB93F),
        badgeColor: const Color(0xFFF06292),
        sparkleColor: const Color(0xFFFFD66B),
        sealColor: const Color(0xFF5A8858),
      );

  /// 森系 typeA 装饰
  static CardDecorations _forestTypeA(Color blobColor) => CardDecorations(
        ribbonText: '🍃 n.',
        cornerEmojis: const ['🌿', '🍃', '☀', '🌱'],
        bgIcons: const [
          BgIconSpec(topPercent: 20, leftPercent: 24, fontSize: 14, char: '🍃'),
          BgIconSpec(topPercent: 60, leftPercent: 78, fontSize: 12, char: '🌿'),
          BgIconSpec(topPercent: 80, leftPercent: 32, fontSize: 13, char: '☘️'),
          BgIconSpec(topPercent: 28, leftPercent: 68, fontSize: 11, char: '🌱'),
        ],
        bgBlobColors: [
          Colors.white,
          blobColor,
          const Color(0xFFFFF3B0),
        ],
        sparkles: const [
          SparkleSpec(topPercent: 30, leftPercent: 18, fontSize: 13, char: '✿'),
          SparkleSpec(topPercent: 78, leftPercent: 20, fontSize: 10, char: '❀'),
        ],
        badgeText: 'EN',
        frameColor: const Color(0xFFFFF3B0),
        ribbonColor: const Color(0xFFFFA726),
        badgeColor: const Color(0xFF4CAF50),
        sparkleColor: const Color(0xFFFFF3B0),
        sealColor: const Color(0xFF5A8858),
      );

  /// 森系 typeB 装饰
  static CardDecorations _forestTypeB(Color blobColor) => CardDecorations(
        ribbonText: 'v. 释义',
        cornerEmojis: const ['🍂', '🌻', '🌿', '🌰'],
        bgIcons: const [
          BgIconSpec(topPercent: 20, leftPercent: 24, fontSize: 14, char: '🍂'),
          BgIconSpec(topPercent: 60, leftPercent: 78, fontSize: 12, char: '🌻'),
          BgIconSpec(topPercent: 80, leftPercent: 32, fontSize: 13, char: '🌿'),
          BgIconSpec(topPercent: 28, leftPercent: 68, fontSize: 11, char: '🌰'),
        ],
        bgBlobColors: [
          Colors.white,
          blobColor,
          const Color(0xFFFFF3B0),
        ],
        sparkles: const [
          SparkleSpec(topPercent: 30, leftPercent: 18, fontSize: 13, char: '✿'),
          SparkleSpec(topPercent: 78, leftPercent: 20, fontSize: 10, char: '❀'),
        ],
        badgeText: '中',
        frameColor: const Color(0xFFFFF3B0),
        ribbonColor: const Color(0xFF8BD48E),
        badgeColor: const Color(0xFFFFA726),
        sparkleColor: const Color(0xFFFFF3B0),
        sealColor: const Color(0xFF5A8858),
      );

  /// 太空 typeA 装饰
  static CardDecorations _spaceTypeA(Color blobColor) => CardDecorations(
        ribbonText: '★ CET-4',
        cornerEmojis: const ['🪐', '⭐', '🌟', '✨'],
        bgIcons: const [
          BgIconSpec(topPercent: 18, leftPercent: 24, fontSize: 13, char: '✦'),
          BgIconSpec(topPercent: 55, leftPercent: 80, fontSize: 14, char: '⭐'),
          BgIconSpec(topPercent: 82, leftPercent: 32, fontSize: 12, char: '✧'),
          BgIconSpec(topPercent: 25, leftPercent: 68, fontSize: 11, char: '🌟'),
        ],
        bgBlobColors: [
          Colors.white,
          blobColor,
          const Color(0xFFC8A8F8),
        ],
        sparkles: const [
          SparkleSpec(topPercent: 30, leftPercent: 18, fontSize: 13, char: '✦'),
          SparkleSpec(topPercent: 78, leftPercent: 20, fontSize: 10, char: '✧'),
        ],
        badgeText: 'EN',
        frameColor: const Color(0xFFC8A8F8),
        ribbonColor: const Color(0xFFFFD66B),
        badgeColor: const Color(0xFF9C6ADE),
        sparkleColor: const Color(0xFFFFE9A8),
        sealColor: const Color(0xFF5A8858),
      );

  /// 太空 typeB 装饰
  static CardDecorations _spaceTypeB(Color blobColor) => CardDecorations(
        ribbonText: 'v. 释义',
        cornerEmojis: const ['🌙', '☄', '🚀', '💫'],
        bgIcons: const [
          BgIconSpec(topPercent: 18, leftPercent: 24, fontSize: 13, char: '🌙'),
          BgIconSpec(topPercent: 55, leftPercent: 80, fontSize: 14, char: '☄'),
          BgIconSpec(topPercent: 82, leftPercent: 32, fontSize: 12, char: '🚀'),
          BgIconSpec(topPercent: 25, leftPercent: 68, fontSize: 11, char: '💫'),
        ],
        bgBlobColors: [
          Colors.white,
          blobColor,
          const Color(0xFF80E8F0),
        ],
        sparkles: const [
          SparkleSpec(topPercent: 30, leftPercent: 18, fontSize: 13, char: '✦'),
          SparkleSpec(topPercent: 78, leftPercent: 20, fontSize: 10, char: '✧'),
        ],
        badgeText: '中',
        frameColor: const Color(0xFF80E8F0),
        ribbonColor: const Color(0xFF9C6ADE),
        badgeColor: const Color(0xFF26C6DA),
        sparkleColor: const Color(0xFFFFFFFF),
        sealColor: const Color(0xFF5A8858),
      );

  /// ============ 学术经典 — 晴空蓝 + 珊瑚粉 ============
  static final CardVisualTheme academic = CardVisualTheme(
    type: CardThemeType.academic,
    label: '学术经典',
    description: '晴空蓝 · 珊瑚粉 · 纸页质感',
    tag: '学术',
    light: CardThemeVariant(
      typeAIdle: CardStateColors(
        background: const Color(0xFFEEF2FF),
        border: const Color(0xFF5B8DEF),
        borderWidth: 1.5,
        text: const Color(0xFF1A3A8A),
        fontWeight: FontWeight.w700,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEF2FF), Color(0xFFDDE6FF)],
        ),
        badgeColor: const Color(0xFF5B8DEF),
        badgeText: const Color(0xFFEEF2FF),
        decorations: _academicTypeA(const Color(0xFFF06292)),
      ),
      typeBIdle: CardStateColors(
        background: const Color(0xFFFFF1F2),
        border: const Color(0xFFF06292),
        borderWidth: 1.5,
        text: const Color(0xFF8A1A3A),
        fontWeight: FontWeight.w600,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF1F2), Color(0xFFFFE0E6)],
        ),
        badgeColor: const Color(0xFFF06292),
        badgeText: const Color(0xFFFFF1F2),
        decorations: _academicTypeB(const Color(0xFF5B8DEF)),
      ),
      typeASelected: CardStateColors(
        background: const Color(0xFF5B8DEF),
        border: const Color(0xFFFFD66B),
        borderWidth: 2.0,
        text: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w800,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7AA5FF), Color(0xFF4A78D8)],
        ),
        textShadow:
            Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 2),
        decorations: _academicTypeA(const Color(0xFFF06292)),
      ),
      typeBSelected: CardStateColors(
        background: const Color(0xFFF06292),
        border: const Color(0xFFFFD66B),
        borderWidth: 2.0,
        text: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w800,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF80AA), Color(0xFFE04878)],
        ),
        textShadow:
            Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 2),
        decorations: _academicTypeB(const Color(0xFF5B8DEF)),
      ),
      matched: CardStateColors(
        background: const Color(0xFFF5F5F0),
        border: const Color(0xFFB8E0A0),
        borderWidth: 1.5,
        text: const Color(0xFFAAAAAA),
        fontWeight: FontWeight.w400,
        opacity: 0.6,
        useLineThrough: true,
        decorations: _academicTypeA(const Color(0xFFB0B5A8)),
      ),
      gameBgGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0e1a0c), Color(0xFF152710), Color(0xFF0a1208)],
      ),
      gameBgGlow: const Color(0x0F9FE870),
      material: const CardMaterial(
        textureType: CardTextureType.paper,
        noiseColor: Color(0xFF8B7355),
        noiseOpacity: 0.04,
        shimmerColor: Color(0xFFFFFFFF),
        shadowDepth: 6,
        shadowOpacity: 0.15,
        borderGlowWidth: 3.0,
      ),
      idleAnimation: IdleAnimationType.paperFlutter,
      burstColors: const [
        Color(0xFFEEF2FF),
        Color(0xFFFFF8E1),
        Color(0xFFDDE6FF),
        Color(0xFFFFE0E6),
        Color(0xFFF5F0E0),
      ],
      ambientElementColor: const Color(0xFF9FE870),
    ),
    dark: CardThemeVariant(
      typeAIdle: CardStateColors(
        background: const Color(0xFF101830),
        border: const Color(0xFF5B8DEF),
        borderWidth: 1.5,
        text: const Color(0xFF90B8FF),
        fontWeight: FontWeight.w700,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF182850), Color(0xFF0C1224)],
        ),
        badgeColor: const Color(0xFF5B8DEF),
        badgeText: const Color(0xFF90B8FF),
        decorations: _academicTypeA(const Color(0xFFF06292)),
      ),
      typeBIdle: CardStateColors(
        background: const Color(0xFF201020),
        border: const Color(0xFFF06292),
        borderWidth: 1.5,
        text: const Color(0xFFFFB0CC),
        fontWeight: FontWeight.w600,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF301830), Color(0xFF180818)],
        ),
        badgeColor: const Color(0xFFF06292),
        badgeText: const Color(0xFFFFB0CC),
        decorations: _academicTypeB(const Color(0xFF5B8DEF)),
      ),
      typeASelected: CardStateColors(
        background: const Color(0xFF5B8DEF),
        border: const Color(0xFFFFD66B),
        borderWidth: 2.0,
        text: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w800,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7AA5FF), Color(0xFF4A78D8)],
        ),
        textShadow:
            Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 2),
        decorations: _academicTypeA(const Color(0xFFF06292)),
      ),
      typeBSelected: CardStateColors(
        background: const Color(0xFFF06292),
        border: const Color(0xFFFFD66B),
        borderWidth: 2.0,
        text: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w800,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF80AA), Color(0xFFE04878)],
        ),
        textShadow:
            Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 2),
        decorations: _academicTypeB(const Color(0xFF5B8DEF)),
      ),
      matched: CardStateColors(
        background: const Color(0xFF080C18),
        border: const Color(0xFF2A5A18),
        borderWidth: 1.5,
        text: const Color(0xFF4A5878),
        fontWeight: FontWeight.w400,
        opacity: 0.4,
        useLineThrough: true,
        decorations: _academicTypeA(const Color(0xFF3A4050)),
      ),
      gameBgGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0e1a0c), Color(0xFF152710), Color(0xFF0a1208)],
      ),
      gameBgGlow: const Color(0x0F9FE870),
      material: const CardMaterial(
        textureType: CardTextureType.paper,
        noiseColor: Color(0xFF8B7355),
        noiseOpacity: 0.04,
        shimmerColor: Color(0xFFFFFFFF),
        shadowDepth: 6,
        shadowOpacity: 0.15,
        borderGlowWidth: 3.0,
      ),
      idleAnimation: IdleAnimationType.paperFlutter,
      burstColors: const [
        Color(0xFF90B8FF),
        Color(0xFFFFB0CC),
        Color(0xFF5B8DEF),
        Color(0xFFF06292),
        Color(0xFFDDE6FF),
      ],
      ambientElementColor: const Color(0xFF9FE870),
    ),
  );

  /// ============ 森系自然 — 翠叶绿 + 蜜糖橙 ============
  static final CardVisualTheme forest = CardVisualTheme(
    type: CardThemeType.forest,
    label: '森系自然',
    description: '翠叶绿 · 蜜糖橙 · 木纹质感',
    tag: '森系',
    light: CardThemeVariant(
      typeAIdle: CardStateColors(
        background: const Color(0xFFE8F8E0),
        border: const Color(0xFF4CAF50),
        borderWidth: 1.5,
        text: const Color(0xFF1A5A10),
        fontWeight: FontWeight.w700,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F8E0), Color(0xFFD0F0C8)],
        ),
        badgeColor: const Color(0xFF4CAF50),
        badgeText: const Color(0xFFE8F8E0),
        decorations: _forestTypeA(const Color(0xFFFFA726)),
      ),
      typeBIdle: CardStateColors(
        background: const Color(0xFFFFF8E1),
        border: const Color(0xFFFFA726),
        borderWidth: 1.5,
        text: const Color(0xFF5A3A00),
        fontWeight: FontWeight.w600,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8E1), Color(0xFFFFEFB8)],
        ),
        badgeColor: const Color(0xFFFFA726),
        badgeText: const Color(0xFFFFF8E1),
        decorations: _forestTypeB(const Color(0xFF4CAF50)),
      ),
      typeASelected: CardStateColors(
        background: const Color(0xFF4CAF50),
        border: const Color(0xFFFFF3B0),
        borderWidth: 2.0,
        text: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w800,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF66CC6A), Color(0xFF389840)],
        ),
        textShadow:
            Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 2),
        decorations: _forestTypeA(const Color(0xFFFFA726)),
      ),
      typeBSelected: CardStateColors(
        background: const Color(0xFFFFA726),
        border: const Color(0xFFFFF3B0),
        borderWidth: 2.0,
        text: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w800,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFC048), Color(0xFFF09010)],
        ),
        textShadow:
            Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 2),
        decorations: _forestTypeB(const Color(0xFF4CAF50)),
      ),
      matched: CardStateColors(
        background: const Color(0xFFF0F0E8),
        border: const Color(0xFFB0E8A0),
        borderWidth: 1.5,
        text: const Color(0xFFAAAAAA),
        fontWeight: FontWeight.w400,
        opacity: 0.6,
        useLineThrough: true,
        decorations: _forestTypeA(const Color(0xFFB0B5A8)),
      ),
      gameBgGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0a1808), Color(0xFF0e2410), Color(0xFF061006)],
      ),
      gameBgGlow: const Color(0x0F4CAF50),
      material: const CardMaterial(
        textureType: CardTextureType.wood,
        noiseColor: Color(0xFF8B7355),
        noiseOpacity: 0.05,
        shimmerColor: Color(0xFFFFD080),
        shadowDepth: 8,
        shadowOpacity: 0.2,
        borderGlowWidth: 3.5,
      ),
      idleAnimation: IdleAnimationType.organicBreathe,
      burstColors: const [
        Color(0xFF4CAF50),
        Color(0xFF8BD48E),
        Color(0xFFFFA726),
        Color(0xFFFFD080),
        Color(0xFFD0F0C8),
        Color(0xFFFFEFB8),
      ],
      ambientElementColor: const Color(0xFF4CAF50),
    ),
    dark: CardThemeVariant(
      typeAIdle: CardStateColors(
        background: const Color(0xFF0A1808),
        border: const Color(0xFF4CAF50),
        borderWidth: 1.5,
        text: const Color(0xFF8BD48E),
        fontWeight: FontWeight.w700,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF142810), Color(0xFF061006)],
        ),
        badgeColor: const Color(0xFF4CAF50),
        badgeText: const Color(0xFF8BD48E),
        decorations: _forestTypeA(const Color(0xFFFFA726)),
      ),
      typeBIdle: CardStateColors(
        background: const Color(0xFF181008),
        border: const Color(0xFFFFA726),
        borderWidth: 1.5,
        text: const Color(0xFFFFD080),
        fontWeight: FontWeight.w600,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF281810), Color(0xFF100A04)],
        ),
        badgeColor: const Color(0xFFFFA726),
        badgeText: const Color(0xFFFFD080),
        decorations: _forestTypeB(const Color(0xFF4CAF50)),
      ),
      typeASelected: CardStateColors(
        background: const Color(0xFF4CAF50),
        border: const Color(0xFFFFF3B0),
        borderWidth: 2.0,
        text: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w800,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF66CC6A), Color(0xFF389840)],
        ),
        textShadow:
            Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 2),
        decorations: _forestTypeA(const Color(0xFFFFA726)),
      ),
      typeBSelected: CardStateColors(
        background: const Color(0xFFFFA726),
        border: const Color(0xFFFFF3B0),
        borderWidth: 2.0,
        text: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w800,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFC048), Color(0xFFF09010)],
        ),
        textShadow:
            Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 2),
        decorations: _forestTypeB(const Color(0xFF4CAF50)),
      ),
      matched: CardStateColors(
        background: const Color(0xFF060A04),
        border: const Color(0xFF2A5A18),
        borderWidth: 1.5,
        text: const Color(0xFF4A5830),
        fontWeight: FontWeight.w400,
        opacity: 0.4,
        useLineThrough: true,
        decorations: _forestTypeA(const Color(0xFF3A4830)),
      ),
      gameBgGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0a1808), Color(0xFF0e2410), Color(0xFF061006)],
      ),
      gameBgGlow: const Color(0x0F4CAF50),
      material: const CardMaterial(
        textureType: CardTextureType.wood,
        noiseColor: Color(0xFF8B7355),
        noiseOpacity: 0.05,
        shimmerColor: Color(0xFFFFD080),
        shadowDepth: 8,
        shadowOpacity: 0.2,
        borderGlowWidth: 3.5,
      ),
      idleAnimation: IdleAnimationType.organicBreathe,
      burstColors: const [
        Color(0xFF4CAF50),
        Color(0xFF8BD48E),
        Color(0xFFFFA726),
        Color(0xFFFFD080),
        Color(0xFFD0F0C8),
        Color(0xFFFFEFB8),
      ],
      ambientElementColor: const Color(0xFF4CAF50),
    ),
  );

  /// ============ 太空星际 — 星云紫 + 极光青 ============
  static final CardVisualTheme space = CardVisualTheme(
    type: CardThemeType.space,
    label: '太空星际',
    description: '星云紫 · 极光青 · 玻璃质感',
    tag: '宇宙',
    light: CardThemeVariant(
      typeAIdle: CardStateColors(
        background: const Color(0xFFF0E8FF),
        border: const Color(0xFF9C6ADE),
        borderWidth: 1.5,
        text: const Color(0xFF3A1A8A),
        fontWeight: FontWeight.w700,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0E8FF), Color(0xFFE0D0FF)],
        ),
        badgeColor: const Color(0xFF9C6ADE),
        badgeText: const Color(0xFFF0E8FF),
        decorations: _spaceTypeA(const Color(0xFF26C6DA)),
      ),
      typeBIdle: CardStateColors(
        background: const Color(0xFFE0F8FF),
        border: const Color(0xFF26C6DA),
        borderWidth: 1.5,
        text: const Color(0xFF004A5A),
        fontWeight: FontWeight.w600,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0F8FF), Color(0xFFC0F0FF)],
        ),
        badgeColor: const Color(0xFF26C6DA),
        badgeText: const Color(0xFFE0F8FF),
        decorations: _spaceTypeB(const Color(0xFF9C6ADE)),
      ),
      typeASelected: CardStateColors(
        background: const Color(0xFF9C6ADE),
        border: const Color(0xFFFFE9A8),
        borderWidth: 2.0,
        text: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w800,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB888E8), Color(0xFF8858C8)],
        ),
        textShadow:
            Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 2),
        decorations: _spaceTypeA(const Color(0xFF26C6DA)),
      ),
      typeBSelected: CardStateColors(
        background: const Color(0xFF26C6DA),
        border: const Color(0xFFFFE9A8),
        borderWidth: 2.0,
        text: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w800,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF48D8E8), Color(0xFF18B0C8)],
        ),
        textShadow:
            Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 2),
        decorations: _spaceTypeB(const Color(0xFF9C6ADE)),
      ),
      matched: CardStateColors(
        background: const Color(0xFFF0F0F5),
        border: const Color(0xFFB0B8E0),
        borderWidth: 1.5,
        text: const Color(0xFFAAAAAA),
        fontWeight: FontWeight.w400,
        opacity: 0.6,
        useLineThrough: true,
        decorations: _spaceTypeA(const Color(0xFFB0B5A8)),
      ),
      gameBgGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0c0818), Color(0xFF140e28), Color(0xFF080414)],
      ),
      gameBgGlow: const Color(0x0F9C6ADE),
      material: const CardMaterial(
        textureType: CardTextureType.glass,
        noiseColor: Color(0xFFFFFFFF),
        noiseOpacity: 0.02,
        shimmerColor: Color(0xFFC8A8F8),
        shadowDepth: 10,
        shadowOpacity: 0.25,
        borderGlowWidth: 4.0,
      ),
      idleAnimation: IdleAnimationType.floatShimmer,
      burstColors: const [
        Color(0xFF9C6ADE),
        Color(0xFFC8A8F8),
        Color(0xFF26C6DA),
        Color(0xFF80E8F0),
        Color(0xFFFFFFFF),
        Color(0xFFE0D0FF),
      ],
      ambientElementColor: const Color(0xFF9C6ADE),
    ),
    dark: CardThemeVariant(
      typeAIdle: CardStateColors(
        background: const Color(0xFF180C30),
        border: const Color(0xFF9C6ADE),
        borderWidth: 1.5,
        text: const Color(0xFFC8A8F8),
        fontWeight: FontWeight.w700,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF281C40), Color(0xFF100820)],
        ),
        badgeColor: const Color(0xFF9C6ADE),
        badgeText: const Color(0xFFC8A8F8),
        decorations: _spaceTypeA(const Color(0xFF26C6DA)),
      ),
      typeBIdle: CardStateColors(
        background: const Color(0xFF081820),
        border: const Color(0xFF26C6DA),
        borderWidth: 1.5,
        text: const Color(0xFF80E8F0),
        fontWeight: FontWeight.w600,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102830), Color(0xFF041018)],
        ),
        badgeColor: const Color(0xFF26C6DA),
        badgeText: const Color(0xFF80E8F0),
        decorations: _spaceTypeB(const Color(0xFF9C6ADE)),
      ),
      typeASelected: CardStateColors(
        background: const Color(0xFF9C6ADE),
        border: const Color(0xFFFFE9A8),
        borderWidth: 2.0,
        text: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w800,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB888E8), Color(0xFF8858C8)],
        ),
        textShadow:
            Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 2),
        decorations: _spaceTypeA(const Color(0xFF26C6DA)),
      ),
      typeBSelected: CardStateColors(
        background: const Color(0xFF26C6DA),
        border: const Color(0xFFFFE9A8),
        borderWidth: 2.0,
        text: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w800,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF48D8E8), Color(0xFF18B0C8)],
        ),
        textShadow:
            Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 2),
        decorations: _spaceTypeB(const Color(0xFF9C6ADE)),
      ),
      matched: CardStateColors(
        background: const Color(0xFF040810),
        border: const Color(0xFF184858),
        borderWidth: 1.5,
        text: const Color(0xFF3A4A58),
        fontWeight: FontWeight.w400,
        opacity: 0.4,
        useLineThrough: true,
        decorations: _spaceTypeA(const Color(0xFF3A4858)),
      ),
      gameBgGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0c0818), Color(0xFF140e28), Color(0xFF080414)],
      ),
      gameBgGlow: const Color(0x0F9C6ADE),
      material: const CardMaterial(
        textureType: CardTextureType.glass,
        noiseColor: Color(0xFFFFFFFF),
        noiseOpacity: 0.02,
        shimmerColor: Color(0xFFC8A8F8),
        shadowDepth: 10,
        shadowOpacity: 0.25,
        borderGlowWidth: 4.0,
      ),
      idleAnimation: IdleAnimationType.floatShimmer,
      burstColors: const [
        Color(0xFF9C6ADE),
        Color(0xFFC8A8F8),
        Color(0xFF26C6DA),
        Color(0xFF80E8F0),
        Color(0xFFFFFFFF),
        Color(0xFFE0D0FF),
      ],
      ambientElementColor: const Color(0xFF9C6ADE),
    ),
  );
}
