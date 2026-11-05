import 'package:flutter/material.dart';

import 'package:strawhut/app/motion.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';

/// 色调表面容器（M3 Expressive）
///
/// 类名沿用旧称，渲染已改为 M3 色调层级：不再使用双向阴影，
/// 而是以表面色调区分层级，仅凸起形态带一层柔和投影。
///
/// 形态说明（[color] 为空时的默认底色）：
/// - [NeumorphicShape.convex]（凸起）：surfaceContainerLow + 柔和投影，[intensity] 缩放投影
/// - [NeumorphicShape.concave]（凹陷）：surfaceContainerHighest，无投影（输入区/拖拽区/选中槽）
/// - [NeumorphicShape.flat]（平整）：surfaceContainer，无投影
///
/// 显式传入 [color] 时在所有形态下均优先使用该颜色。
/// 圆角默认 radiusMedium（16）；卡片/分区建议用 [NeumorphicContainer.large]（28），
/// 首页主卡片用 [NeumorphicContainer.xLarge]（36）。
/// 形态/颜色/圆角变化使用 [AnimatedContainer] 过渡，减少动态效果时立即切换。
///
/// 用法：
/// ```dart
/// NeumorphicContainer.large(
///   padding: EdgeInsets.all(16),
///   child: Text('色调卡片'),
/// )
/// ```
class NeumorphicContainer extends StatelessWidget {
  const NeumorphicContainer({
    required this.child, super.key,
    this.shape = NeumorphicShape.convex,
    this.intensity = NeumorphicIntensity.normal,
    this.borderRadius,
    this.radiusKey, // ignore: library_private_types_in_public_api, 使用私有枚举 _RadiusKey 仅内部解析圆角，不对外暴露类型
    this.padding,
    this.margin,
    this.color,
    this.alignment,
    this.width,
    this.height,
    this.constraints,
    this.duration = StrawMotion.short,
    this.curve = StrawMotion.standard,
    this.border,
  }) : assert(
          radiusKey == null || borderRadius == null,
          '只能指定 borderRadius 或 radiusKey 之一',
        );

  /// 使用 small 圆角（12）
  const NeumorphicContainer.small({
    required this.child, super.key,
    this.shape = NeumorphicShape.convex,
    this.intensity = NeumorphicIntensity.normal,
    this.padding,
    this.margin,
    this.color,
    this.alignment,
    this.width,
    this.height,
    this.constraints,
    this.duration = StrawMotion.short,
    this.curve = StrawMotion.standard,
    this.border,
  })  : borderRadius = null,
        radiusKey = _RadiusKey.small;

  /// 使用 large 圆角（28，卡片/分区）
  const NeumorphicContainer.large({
    required this.child, super.key,
    this.shape = NeumorphicShape.convex,
    this.intensity = NeumorphicIntensity.normal,
    this.padding,
    this.margin,
    this.color,
    this.alignment,
    this.width,
    this.height,
    this.constraints,
    this.duration = StrawMotion.short,
    this.curve = StrawMotion.standard,
    this.border,
  })  : borderRadius = null,
        radiusKey = _RadiusKey.large;

  /// 使用 xLarge 圆角（36，首页主卡片）
  const NeumorphicContainer.xLarge({
    required this.child, super.key,
    this.shape = NeumorphicShape.convex,
    this.intensity = NeumorphicIntensity.normal,
    this.padding,
    this.margin,
    this.color,
    this.alignment,
    this.width,
    this.height,
    this.constraints,
    this.duration = StrawMotion.short,
    this.curve = StrawMotion.standard,
    this.border,
  })  : borderRadius = null,
        radiusKey = _RadiusKey.xLarge;

  /// 子内容
  final Widget child;

  /// 软质形态
  final NeumorphicShape shape;

  /// 阴影强度
  final NeumorphicIntensity intensity;

  /// 自定义圆角半径
  final double? borderRadius;

  /// 使用令牌中的圆角档位（small/medium/large/xLarge）
  ///
  /// 与 [borderRadius] 互斥。
  final _RadiusKey? radiusKey; // ignore: library_private_types_in_public_api, 使用私有枚举 _RadiusKey 仅内部解析圆角，不对外暴露类型

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  /// 自定义表面色（为空时按 [shape] 取对应的 M3 色调容器色）
  final Color? color;

  /// 子内容对齐
  final AlignmentGeometry? alignment;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  /// 约束
  final BoxConstraints? constraints;

  /// 形态切换动画时长
  final Duration duration;

  /// 形态切换动画曲线
  final Curve curve;

  /// 可选描边（如选中态的 primary 描边、玻璃以外的轮廓）
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    final radius = borderRadius ?? _resolveRadius(tokens, radiusKey);
    final effectiveColor = color ?? _defaultColor(tokens);

    return AnimatedContainer(
      duration: StrawMotion.duration(context, duration),
      curve: curve,
      width: width,
      height: height,
      constraints: constraints,
      margin: margin,
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: buildNeumorphicShadows(
          tokens: tokens,
          shape: shape,
          intensity: intensity,
        ),
      ),
      child: child,
    );
  }

  /// 各形态的默认色调
  Color _defaultColor(NeumorphicTokens tokens) {
    switch (shape) {
      case NeumorphicShape.convex:
        return tokens.surfaceContainerLow;
      case NeumorphicShape.concave:
        return tokens.surfaceContainerHighest;
      case NeumorphicShape.flat:
        return tokens.surfaceAlt;
    }
  }

  double _resolveRadius(NeumorphicTokens tokens, _RadiusKey? key) {
    switch (key) {
      case _RadiusKey.small:
        return tokens.radiusSmall;
      case _RadiusKey.medium:
        return tokens.radiusMedium;
      case _RadiusKey.large:
        return tokens.radiusLarge;
      case _RadiusKey.xLarge:
        return tokens.radiusXLarge;
      case null:
        return tokens.radiusMedium;
    }
  }
}

/// 圆角档位枚举（内部使用，避免暴露 API 复杂度）
enum _RadiusKey {
  small,
  medium,
  large,
  xLarge,
}

/// 凹陷式容器（输入框/拖拽区/选中槽）
///
/// 等价于 [NeumorphicContainer] 的 [NeumorphicShape.concave] 形态：
/// 默认 surfaceContainerHighest 底色、无投影。
class NeumorphicInset extends NeumorphicContainer {
  const NeumorphicInset({
    required super.child, super.key,
    super.intensity,
    super.borderRadius,
    super.padding,
    super.margin,
    super.color,
    super.alignment,
    super.width,
    super.height,
    super.constraints,
    super.border,
  }) : super(
          shape: NeumorphicShape.concave,
        );
}
