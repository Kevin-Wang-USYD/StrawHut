import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:strawhut/app/motion.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';

/// 液态玻璃表面（仅用于浮层）
///
/// 背景模糊 + 半透明表面填充 + 1px 白色描边 + 顶部高光 + 柔和投影。
/// 只用于漂浮层：阅读器底部浮动工具栏、解密对话框容器、发布进度浮层、
/// 首页浮动「新建」操作区。SnackBar 不使用玻璃；长篇阅读正文绝不放在玻璃上。
///
/// 可读性：填充为 surface 72%（[strong] 为 82%），以保证玻璃上的文字对比度 ≥ 4.5:1。
///
/// 回退（强制）：开启减少动态效果或高对比度时，渲染为同形状的
/// 不透明 surfaceContainerHigh，不使用 BackdropFilter。
///
/// 淡入淡出：不要在外层用 [Opacity] / [FadeTransition] 包裹玻璃（模糊会在
/// 渐变期间失效、结束时突然出现），改为传入 [opacity]，由玻璃内部同步插值
/// 模糊强度、填充、描边与内容透明度。
///
/// 内容外包一层透明 [Material]，使 InkWell 的水波纹与焦点高亮绘制在玻璃之上。
///
/// 用法：
/// ```dart
/// GlassSurface(
///   borderRadius: BorderRadius.circular(32),
///   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
///   child: Row(mainAxisSize: MainAxisSize.min, children: [...]),
/// )
/// ```
class GlassSurface extends StatelessWidget {
  /// 创建玻璃表面
  const GlassSurface({
    required this.child,
    super.key,
    this.borderRadius,
    this.padding,
    this.margin,
    this.tint,
    this.blur = 24,
    this.strong = false,
    this.opacity = 1,
  });

  /// 子内容
  final Widget child;

  /// 圆角；为空时为 28（radiusLarge）
  final BorderRadiusGeometry? borderRadius;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  /// 填充基色；为空时取 surface（tokens.surface），透明度由 [strong] 决定
  final Color? tint;

  /// 背景模糊 sigma
  final double blur;

  /// 是否使用更不透明的填充（82%，用于承载较多文字的浮层）
  final bool strong;

  /// 整体不透明度（0 ~ 1），用于进入/退出渐变；在玻璃内部插值，不破坏背景模糊
  final double opacity;

  /// 当前环境是否应使用不透明回退（减少动态效果或高对比度）
  static bool useOpaqueFallback(BuildContext context) {
    return StrawMotion.reducedMotion(context) ||
        (MediaQuery.maybeHighContrastOf(context) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    final isDark = tokens.brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(tokens.radiusLarge);
    final resolvedRadius = radius.resolve(Directionality.maybeOf(context));
    final o = opacity.clamp(0.0, 1.0);

    // 内容：透明 Material 承载水波纹/焦点高亮，使其绘制在填充之上
    Widget content = Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );

    Widget result;
    if (useOpaqueFallback(context)) {
      // 不透明回退：同形状、无模糊（无 BackdropFilter，可直接整体渐变）
      result = DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surfaceContainerHigh,
          borderRadius: resolvedRadius,
          border: Border.all(color: tokens.divider),
        ),
        child: content,
      );
      if (o < 1) {
        result = Opacity(opacity: o, child: result);
      }
    } else {
      final fill = (tint ?? tokens.surface)
          .withValues(alpha: (strong ? 0.82 : 0.72) * o);
      final rim = Colors.white.withValues(alpha: (isDark ? 0.18 : 0.45) * o);
      final sigma = blur * o;
      if (o < 1) {
        content = Opacity(opacity: o, child: content);
      }

      result = DecoratedBox(
        // 外投影：BlurStyle.outer 只画在形状外侧，避免透过玻璃看到阴影
        decoration: BoxDecoration(
          borderRadius: resolvedRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18 * o),
              offset: const Offset(0, 10),
              blurRadius: 36,
              blurStyle: BlurStyle.outer,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: resolvedRadius,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: CustomPaint(
              foregroundPainter: _TopHighlightPainter(
                radius: resolvedRadius,
                color:
                    Colors.white.withValues(alpha: (isDark ? 0.28 : 0.7) * o),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: resolvedRadius,
                  border: Border.all(color: rim),
                ),
                child: content,
              ),
            ),
          ),
        ),
      );
    }

    if (margin != null) {
      result = Padding(padding: margin!, child: result);
    }
    return result;
  }
}

/// 顶部高光：沿圆角矩形内侧描 1px，颜色自上而下迅速淡出，
/// 形成玻璃上沿的一道亮边。
class _TopHighlightPainter extends CustomPainter {
  _TopHighlightPainter({required this.radius, required this.color});

  final BorderRadius radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = (Offset.zero & size).deflate(0.5);
    final fadeEnd = (radius.topLeft.y + 12).clamp(1.0, size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withValues(alpha: 0)],
        stops: [0, fadeEnd / size.height],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(radius.toRRect(rect), paint);
  }

  @override
  bool shouldRepaint(_TopHighlightPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.color != color;
}
