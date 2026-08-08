#!/usr/bin/env python3
"""
单词消消乐 App Icon 生成器

用 Pillow 绘制 2x2 消除网格 Logo，输出到：
- iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/
- Android: android/app/src/main/res/mipmap-*/
- assets/images/app_logo.png (启动页用)

运行: python3 tools/generate_app_icon.py
"""

import os
import math
from PIL import Image, ImageDraw, ImageFont

# 品牌色
BRIGHT_GREEN = (0x9F, 0xE8, 0x70)
DARK_GREEN = (0x16, 0x33, 0x00)
AMBER = (0xFF, 0xB8, 0x00)
BG_GREEN = (0xF2, 0xFF, 0xE8)
LIGHT_SURFACE = (0xE8, 0xEB, 0xE6)
WHITE = (0xFF, 0xFF, 0xFF)


def get_font(size):
    """获取中文字体"""
    font_paths = [
        "/System/Library/Fonts/STHeiti Medium.ttc",
        "/System/Library/Fonts/PingFang.ttc",
        "/System/Library/Fonts/PingFangSC.ttc",
        "/System/Library/Fonts/Supplemental/Songti.ttc",
    ]
    for path in font_paths:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except:
                pass
    return ImageFont.load_default()


def draw_logo(size):
    """绘制 Logo，返回 Image"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    s = size

    # 背景：深绿圆角矩形
    bg_radius = int(s * 0.22)
    draw.rounded_rectangle((0, 0, s, s), radius=bg_radius, fill=DARK_GREEN)

    # 内部浅色背景
    inner_pad = int(s * 0.08)
    inner_rect = (inner_pad, inner_pad, s - inner_pad, s - inner_pad)
    draw.rounded_rectangle(inner_rect, radius=int(s * 0.16), fill=BG_GREEN)

    # 2x2 网格区域
    grid_left = int(s * 0.16)
    grid_top = int(s * 0.16)
    grid_w = int(s * 0.68)
    grid_h = int(s * 0.68)
    gap = int(s * 0.04)
    card_r = int(s * 0.06)
    cell_w = (grid_w - gap) // 2
    cell_h = (grid_h - gap) // 2

    # 卡片数据
    cards = [
        (0, 0, 'E', BRIGHT_GREEN, DARK_GREEN),
        (0, 1, '预', WHITE, DARK_GREEN),
        (1, 0, 'M', BRIGHT_GREEN, DARK_GREEN),
        (1, 1, '测', LIGHT_SURFACE, DARK_GREEN),  # 已消除
    ]

    # 字体
    font_size = int(s * 0.14)
    font = get_font(font_size)

    # 绘制卡片
    for row, col, text, bg_color, text_color in cards:
        x = grid_left + col * (cell_w + gap) + gap // 2
        y = grid_top + row * (cell_h + gap) + gap // 2
        w = cell_w
        h = cell_h

        # 阴影
        shadow_offset = int(s * 0.02)
        draw.rounded_rectangle(
            (x, y + shadow_offset, x + w, y + h + shadow_offset),
            radius=card_r, fill=(0, 0, 0, 30)
        )

        # 卡片本体
        draw.rounded_rectangle((x, y, x + w, y + h), radius=card_r, fill=bg_color)

        # 边框
        draw.rounded_rectangle(
            (x, y, x + w, y + h), radius=card_r,
            outline=(*DARK_GREEN, 30), width=max(1, int(s * 0.006))
        )

        # 文字
        bbox = draw.textbbox((0, 0), text, font=font)
        text_w = bbox[2] - bbox[0]
        text_h = bbox[3] - bbox[1]
        text_x = x + (w - text_w) // 2
        text_y = y + (h - text_h) // 2
        draw.text((text_x, text_y), text, fill=text_color, font=font)

    # 匹配连线（第一行两张卡之间）
    line_y = grid_top + cell_h // 2 + gap // 2
    line_x1 = grid_left + cell_w + gap // 2 + int(s * 0.02)
    line_x2 = grid_left + cell_w + gap + cell_w - gap // 2 - int(s * 0.02)
    line_width = max(1, int(s * 0.016))
    draw.line([(line_x1, line_y), (line_x2, line_y)], fill=(*AMBER, 153), width=line_width)

    # 闪光点
    dot_r = max(1, int(s * 0.012))
    dot_x = (line_x1 + line_x2) // 2
    draw.ellipse(
        (dot_x - dot_r, line_y - dot_r, dot_x + dot_r, line_y + dot_r),
        fill=AMBER
    )

    # 已消除卡（右下）的爆裂粒子
    cx = grid_left + cell_w + cell_w // 2 + gap
    cy = grid_top + cell_h + cell_h // 2 + gap
    particle_colors = [BRIGHT_GREEN, AMBER, DARK_GREEN, WHITE] * 2
    dist = int(s * 0.06)
    p_r = max(1, int(s * 0.02))

    for i, p_color in enumerate(particle_colors):
        angle = i * 45 * math.pi / 180
        px = cx + int(dist * math.cos(angle))
        py = cy + int(dist * math.sin(angle))
        draw.ellipse(
            (px - p_r, py - p_r, px + p_r, py + p_r),
            fill=p_color
        )

    # 已消除卡缩小效果
    matched_x = grid_left + cell_w + gap // 2
    matched_y = grid_top + cell_h + gap // 2
    matched_w = int(cell_w * 0.7)
    matched_h = int(cell_h * 0.7)
    matched_cx = matched_x + cell_w // 2
    matched_cy = matched_y + cell_h // 2
    m_x1 = matched_cx - matched_w // 2
    m_y1 = matched_cy - matched_h // 2
    m_x2 = m_x1 + matched_w
    m_y2 = m_y1 + matched_h

    # 发光边
    glow_w = max(1, int(s * 0.02))
    draw.rounded_rectangle(
        (m_x1, m_y1, m_x2, m_y2), radius=int(card_r * 0.7),
        outline=(*BRIGHT_GREEN, 128), width=glow_w
    )

    # 半透明卡体
    draw.rounded_rectangle(
        (m_x1, m_y1, m_x2, m_y2), radius=int(card_r * 0.7),
        fill=(*LIGHT_SURFACE, 102)
    )

    return img


def generate_icons():
    """生成所有尺寸的 App Icon"""
    project_dir = os.getcwd()

    # iOS 尺寸映射
    ios_sizes = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
    }

    # Android 尺寸映射
    android_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }

    # 生成 iOS icons
    ios_dir = os.path.join(project_dir, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    os.makedirs(ios_dir, exist_ok=True)
    for filename, size in ios_sizes.items():
        img = draw_logo(size)
        img.save(os.path.join(ios_dir, filename))
        print(f'  Generated iOS/{filename} ({size}x{size})')

    # 生成 Android icons
    for folder, size in android_sizes.items():
        android_dir = os.path.join(project_dir, 'android', 'app', 'src', 'main', 'res', folder)
        os.makedirs(android_dir, exist_ok=True)
        img = draw_logo(size)
        img.save(os.path.join(android_dir, 'ic_launcher.png'))
        print(f'  Generated Android/{folder}/ic_launcher.png ({size}x{size})')

    # 生成启动页 Logo (512x512)
    splash_dir = os.path.join(project_dir, 'assets', 'images')
    os.makedirs(splash_dir, exist_ok=True)
    splash_img = draw_logo(512)
    splash_img.save(os.path.join(splash_dir, 'app_logo.png'))
    print(f'  Generated assets/images/app_logo.png (512x512)')

    print('\nDone! All icons generated.')


if __name__ == '__main__':
    generate_icons()
