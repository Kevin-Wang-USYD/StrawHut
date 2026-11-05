import 'package:flutter/material.dart';

/// 设计令牌（Material 3 Expressive · 稻草琥珀色调）
///
/// 集中定义颜色、阴影、圆角、间距等设计常量，供所有组件复用。
/// 通过 [NeumorphicTokens.of] / [NeumorphicTokens.ofContext] 获取当前亮/暗模式下的令牌。
///
/// 类名与原有字段名保持不变（兼容旧代码），但字段含义已映射为 M3 色彩角色，
/// 种子色为琥珀「稻草」色 #7C5800：
///
/// | 字段            | M3 角色               |
/// |-----------------|-----------------------|
/// | surface         | surface（页面背景）   |
/// | surfaceAlt      | surfaceContainer      |
/// | divider         | outlineVariant        |
/// | textPrimary     | onSurface             |
/// | textSecondary   | onSurfaceVariant      |
/// | textHint        | outline               |
/// | inkPrimary      | primary               |
/// | inkSecondary    | secondary             |
/// | inkWash         | primaryContainer      |
/// | success         | tertiary（绿）        |
/// | warning         | 琥珀橙                |
/// | error           | error                 |
///
/// 阴影：不再使用 Neumorphism 双向阴影，仅保留一层柔和投影（[darkShadow]），
/// 克制使用；[lightShadow] 为透明，保留字段只为兼容。
class NeumorphicTokens {
  const NeumorphicTokens({
    required this.brightness,
    required this.surface,
    required this.surfaceAlt,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.inkWash,
    required this.success,
    required this.warning,
    required this.error,
    required this.lightShadow,
    required this.darkShadow,
    required this.shadowOffset,
    required this.shadowBlur,
    required this.shadowSpread,
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
    required this.radiusXLarge,
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.spaceXxl,
    // 以下为新增 M3 色彩角色（可选，默认值取亮色方案）
    this.onPrimary = const Color(0xFFFFFFFF),
    this.onPrimaryContainer = const Color(0xFF271900),
    this.onSecondary = const Color(0xFFFFFFFF),
    this.secondaryContainer = const Color(0xFFF5E0BB),
    this.onSecondaryContainer = const Color(0xFF241A04),
    this.onTertiary = const Color(0xFFFFFFFF),
    this.tertiaryContainer = const Color(0xFFCCEBC4),
    this.onTertiaryContainer = const Color(0xFF072109),
    this.onError = const Color(0xFFFFFFFF),
    this.errorContainer = const Color(0xFFFFDAD6),
    this.onErrorContainer = const Color(0xFF410002),
    this.surfaceDim = const Color(0xFFE2D9CC),
    this.surfaceBright = const Color(0xFFFFF8F2),
    this.surfaceContainerLowest = const Color(0xFFFFFFFF),
    this.surfaceContainerLow = const Color(0xFFFCF2E7),
    this.surfaceContainerHigh = const Color(0xFFF0E7DB),
    this.surfaceContainerHighest = const Color(0xFFEAE1D6),
    this.inverseSurface = const Color(0xFF353027),
    this.onInverseSurface = const Color(0xFFF9EFE3),
    this.inversePrimary = const Color(0xFFF9BC48),
  });

  final Brightness brightness;

  // ============ 背景与表面 ============
  /// M3 surface：页面背景
  final Color surface;

  /// M3 surfaceContainer：卡片、分区的默认色调容器
  final Color surfaceAlt;

  /// M3 outlineVariant：分隔线、弱描边
  final Color divider;

  /// M3 surfaceDim：最暗的表面（滚动遮挡等）
  final Color surfaceDim;

  /// M3 surfaceBright：最亮的表面
  final Color surfaceBright;

  /// M3 surfaceContainerLowest：最低层级容器
  final Color surfaceContainerLowest;

  /// M3 surfaceContainerLow：凸起卡片（convex）
  final Color surfaceContainerLow;

  /// M3 surfaceContainerHigh：对话框、玻璃回退底色
  final Color surfaceContainerHigh;

  /// M3 surfaceContainerHighest：凹陷/输入区（concave）、进度条轨道
  final Color surfaceContainerHighest;

  /// M3 inverseSurface：SnackBar、Tooltip 背景
  final Color inverseSurface;

  /// M3 onInverseSurface：反色表面上的文字
  final Color onInverseSurface;

  // ============ 文字 ============
  /// M3 onSurface：主要文字
  final Color textPrimary;

  /// M3 onSurfaceVariant：次要文字、默认图标
  final Color textSecondary;

  /// M3 outline：提示文字、输入框描边
  final Color textHint;

  // ============ 强调色 ============
  /// M3 primary：主 CTA、激活态、关键图标
  final Color inkPrimary;

  /// M3 onPrimary：primary 之上的文字/图标
  final Color onPrimary;

  /// M3 secondary：次级强调
  final Color inkSecondary;

  /// M3 onSecondary：secondary 之上的文字/图标
  final Color onSecondary;

  /// M3 primaryContainer：首页主卡片、选中态背景
  final Color inkWash;

  /// M3 onPrimaryContainer：primaryContainer 之上的文字/图标
  final Color onPrimaryContainer;

  /// M3 secondaryContainer：色调按钮、选中的标签
  final Color secondaryContainer;

  /// M3 onSecondaryContainer：secondaryContainer 之上的文字/图标
  final Color onSecondaryContainer;

  /// M3 inversePrimary：反色表面上的强调色（SnackBar 操作）
  final Color inversePrimary;

  // ============ 语义色 ============
  /// M3 tertiary（绿）：成功
  final Color success;

  /// M3 onTertiary：tertiary 之上的文字/图标
  final Color onTertiary;

  /// M3 tertiaryContainer：成功提示、首页色调操作卡
  final Color tertiaryContainer;

  /// M3 onTertiaryContainer：tertiaryContainer 之上的文字/图标
  final Color onTertiaryContainer;

  /// 警告（琥珀橙）
  final Color warning;

  /// M3 error：错误
  final Color error;

  /// M3 onError：error 之上的文字/图标
  final Color onError;

  /// M3 errorContainer：错误横幅、危险按钮背景
  final Color errorContainer;

  /// M3 onErrorContainer：errorContainer 之上的文字/图标
  final Color onErrorContainer;

  // ============ 阴影 ============
  /// 兼容字段：新设计不再使用亮阴影，恒为透明
  final Color lightShadow;

  /// 柔和投影色（单层，克制使用）
  final Color darkShadow;

  /// 投影纵向偏移量
  final double shadowOffset;

  /// 投影模糊半径
  final double shadowBlur;

  /// 投影扩散
  final double shadowSpread;

  // ============ 圆角 ============
  final double radiusSmall;   // 12
  final double radiusMedium;  // 16
  final double radiusLarge;   // 28
  final double radiusXLarge;  // 36

  // ============ 间距 ============
  final double spaceXs;  // 4
  final double spaceSm;  // 8
  final double spaceMd;  // 16
  final double spaceLg;  // 24
  final double spaceXl;  // 32
  final double spaceXxl; // 48

  /// 亮色模式令牌
  static const NeumorphicTokens light = NeumorphicTokens(
    brightness: Brightness.light,
    surface: Color(0xFFFFF8F2),
    surfaceAlt: Color(0xFFF6ECE1),
    divider: Color(0xFFD2C5B4),
    textPrimary: Color(0xFF1F1B13),
    textSecondary: Color(0xFF4E4639),
    textHint: Color(0xFF807667),
    inkPrimary: Color(0xFF7C5800),
    inkSecondary: Color(0xFF6B5D3F),
    inkWash: Color(0xFFFFDEA6),
    success: Color(0xFF4A6547),
    warning: Color(0xFF8A5100),
    error: Color(0xFFBA1A1A),
    lightShadow: Color(0x00000000),
    darkShadow: Color(0x241F1B13), // #1F1B13 @ 14%
    shadowOffset: 2,
    shadowBlur: 8,
    shadowSpread: 0,
    radiusSmall: 12,
    radiusMedium: 16,
    radiusLarge: 28,
    radiusXLarge: 36,
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 16,
    spaceLg: 24,
    spaceXl: 32,
    spaceXxl: 48,
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryContainer: Color(0xFF271900),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF5E0BB),
    onSecondaryContainer: Color(0xFF241A04),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFCCEBC4),
    onTertiaryContainer: Color(0xFF072109),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surfaceDim: Color(0xFFE2D9CC),
    surfaceBright: Color(0xFFFFF8F2),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFCF2E7),
    surfaceContainerHigh: Color(0xFFF0E7DB),
    surfaceContainerHighest: Color(0xFFEAE1D6),
    inverseSurface: Color(0xFF353027),
    onInverseSurface: Color(0xFFF9EFE3),
    inversePrimary: Color(0xFFF9BC48),
  );

  /// 暗色模式令牌
  static const NeumorphicTokens dark = NeumorphicTokens(
    brightness: Brightness.dark,
    surface: Color(0xFF17130B),
    surfaceAlt: Color(0xFF231F17),
    divider: Color(0xFF4E4639),
    textPrimary: Color(0xFFEAE1D4),
    textSecondary: Color(0xFFD2C5B4),
    textHint: Color(0xFF9B8F80),
    inkPrimary: Color(0xFFF9BC48),
    inkSecondary: Color(0xFFD8C4A0),
    inkWash: Color(0xFF5E4200),
    success: Color(0xFFB0CFAA),
    warning: Color(0xFFFFB870),
    error: Color(0xFFFFB4AB),
    lightShadow: Color(0x00000000),
    darkShadow: Color(0x66000000), // black @ 40%
    shadowOffset: 2,
    shadowBlur: 8,
    shadowSpread: 0,
    radiusSmall: 12,
    radiusMedium: 16,
    radiusLarge: 28,
    radiusXLarge: 36,
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 16,
    spaceLg: 24,
    spaceXl: 32,
    spaceXxl: 48,
    onPrimary: Color(0xFF422C00),
    onPrimaryContainer: Color(0xFFFFDEA6),
    onSecondary: Color(0xFF3A2F15),
    secondaryContainer: Color(0xFF52452A),
    onSecondaryContainer: Color(0xFFF5E0BB),
    onTertiary: Color(0xFF1D361C),
    tertiaryContainer: Color(0xFF334D31),
    onTertiaryContainer: Color(0xFFCCEBC4),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surfaceDim: Color(0xFF17130B),
    surfaceBright: Color(0xFF3E382F),
    surfaceContainerLowest: Color(0xFF120E07),
    surfaceContainerLow: Color(0xFF1F1B13),
    surfaceContainerHigh: Color(0xFF2E2921),
    surfaceContainerHighest: Color(0xFF39342B),
    inverseSurface: Color(0xFFEAE1D4),
    onInverseSurface: Color(0xFF353027),
    inversePrimary: Color(0xFF7C5800),
  );

  /// 根据亮度获取对应令牌
  static NeumorphicTokens of(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }

  /// 根据 BuildContext 获取当前主题令牌
  static NeumorphicTokens ofContext(BuildContext context) {
    return of(Theme.of(context).brightness);
  }

  /// M3 surfaceContainer（与 [surfaceAlt] 相同，语义化别名）
  Color get surfaceContainer => surfaceAlt;

  /// M3 primaryContainer（与 [inkWash] 相同，语义化别名）
  Color get primaryContainer => inkWash;

  /// M3 outline（与 [textHint] 相同，语义化别名）
  Color get outline => textHint;

  /// M3 outlineVariant（与 [divider] 相同，语义化别名）
  Color get outlineVariant => divider;

  /// 单层柔和投影（卡片/凸起容器使用）
  List<BoxShadow> get softShadow => buildNeumorphicShadows(
        tokens: this,
        shape: NeumorphicShape.convex,
      );
}

/// 容器形态（沿用旧名，含义映射为 M3 色调层级）
enum NeumorphicShape {
  /// 凸起（默认）：surfaceContainerLow + 单层柔和投影
  convex,

  /// 凹陷（输入区/拖拽区/选中槽）：surfaceContainerHighest，无投影
  concave,

  /// 平整：surfaceContainer，无投影
  flat,
}

/// 投影强度（用于 hover/pressed 等状态微调）
enum NeumorphicIntensity {
  /// 标准
  normal,

  /// 加深（hover）
  strong,

  /// 减弱（移动端小屏）
  subtle,
}

/// 根据令牌与形态构建投影
///
/// 新设计只保留一层柔和投影：
/// - 凸起：单层 [NeumorphicTokens.darkShadow] 向下投影，[intensity] 缩放偏移与模糊
/// - 凹陷 / 平整：无投影（靠色调层级区分）
List<BoxShadow> buildNeumorphicShadows({
  required NeumorphicTokens tokens,
  required NeumorphicShape shape,
  NeumorphicIntensity intensity = NeumorphicIntensity.normal,
}) {
  if (shape != NeumorphicShape.convex) {
    return const [];
  }

  var offset = tokens.shadowOffset;
  var blur = tokens.shadowBlur;
  switch (intensity) {
    case NeumorphicIntensity.strong:
      offset = tokens.shadowOffset * 2;
      blur = tokens.shadowBlur * 1.75;
    case NeumorphicIntensity.subtle:
      offset = tokens.shadowOffset * 0.5;
      blur = tokens.shadowBlur * 0.6;
    case NeumorphicIntensity.normal:
      break;
  }

  return [
    BoxShadow(
      color: tokens.darkShadow,
      offset: Offset(0, offset),
      blurRadius: blur,
      spreadRadius: tokens.shadowSpread,
    ),
  ];
}
