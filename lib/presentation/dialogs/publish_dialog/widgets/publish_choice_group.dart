import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:strawhut/app/motion.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/presentation/widgets/neumorphic_icon.dart';

/// 发布对话框 - 连接按钮组的单个选项
class PublishChoiceSegment<T> {
  /// 创建选项
  const PublishChoiceSegment({
    required this.value,
    required this.label,
    this.icon,
    this.description,
  });

  /// 选项值
  final T value;

  /// 选项标题
  final String label;

  /// 选项图标（[StrawIcons] 中的 SVG 路径）
  final String? icon;

  /// 选项说明（显示在标题下方的小字）
  final String? description;
}

/// 发布对话框 - 连接按钮组（M3 Expressive "connected button group"）
///
/// 用于内容来源、加密模式、导出格式等互斥的分段选择：
/// - 相邻药丸并排，外侧圆角 24、内侧圆角 8，间隔 2px
/// - 选中项为 primary 填充，四角全部变圆（半高，即完整药丸），切换时以弹簧曲线形变
/// - 未选中项为 surfaceContainerHighest 色调底
/// - 开启减少动态效果时立即切换，无形变动画
///
/// 只有点击「未选中」的选项时才会回调 [onSelected]，
/// 与 SegmentedButton / RadioListTile 的行为一致（重复点击已选项不触发）。
/// 语义沿用单选：每个分段暴露 checked 状态并处于互斥组中（读作单选按钮）。
class PublishConnectedButtonGroup<T> extends StatelessWidget {
  /// 创建连接按钮组
  const PublishConnectedButtonGroup({
    required this.segments,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// 选项列表
  final List<PublishChoiceSegment<T>> segments;

  /// 当前选中的值
  final T selected;

  /// 选中某个未选中选项时的回调
  final ValueChanged<T> onSelected;

  /// 外侧圆角（选中态为完整药丸：半高）
  static const double outerRadius = 24;

  /// 内侧圆角
  static const double innerRadius = 8;

  /// 选项间隔
  static const double gap = 2;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (i > 0) children.add(const SizedBox(width: gap));
      children.add(
        Expanded(
          child: _ConnectedSegment<T>(
            segment: segment,
            isFirst: i == 0,
            isLast: i == segments.length - 1,
            isSelected: segment.value == selected,
            onTap: () {
              if (segment.value != selected) onSelected(segment.value);
            },
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// 连接按钮组中的单个分段
class _ConnectedSegment<T> extends StatelessWidget {
  const _ConnectedSegment({
    required this.segment,
    required this.isFirst,
    required this.isLast,
    required this.isSelected,
    required this.onTap,
  });

  final PublishChoiceSegment<T> segment;
  final bool isFirst;
  final bool isLast;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    const outer = PublishConnectedButtonGroup.outerRadius;
    const inner = PublishConnectedButtonGroup.innerRadius;
    final leftRest = isFirst ? outer : inner;
    final rightRest = isLast ? outer : inner;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: isSelected ? 1 : 0),
      duration: StrawMotion.duration(context, StrawMotion.medium),
      curve: StrawMotion.spring,
      builder: (context, t, _) {
        // 颜色插值需钳制在 [0, 1]；圆角由 _SegmentShape 按实际高度
        // 插值到半高（完整药丸），弹簧过冲时钳制在合法范围内
        final c = t.clamp(0.0, 1.0);
        final background = Color.lerp(
          tokens.surfaceContainerHighest,
          tokens.inkPrimary,
          c,
        )!;
        final foreground =
            Color.lerp(tokens.textSecondary, tokens.onPrimary, c)!;

        return Semantics(
          checked: isSelected,
          inMutuallyExclusiveGroup: true,
          child: Material(
            color: background,
            clipBehavior: Clip.antiAlias,
            animationDuration: Duration.zero,
            shape: _SegmentShape(
              leftRest: leftRest,
              rightRest: rightRest,
              t: t,
            ),
            child: InkWell(
              onTap: onTap,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return foreground.withValues(alpha: 0.10);
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  return foreground.withValues(alpha: 0.08);
                }
                return null;
              }),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceSm + tokens.spaceXs,
                    vertical: segment.description == null ? 12 : 10,
                  ),
                  child: _SegmentContent(
                    segment: segment,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 分段形状：静止时左右圆角为 [leftRest] / [rightRest]，
/// 随进度 [t] 插值到实际高度的一半（完整药丸）。
///
/// 圆角依赖布局后的高度，因此不能用固定半径的 RoundedRectangleBorder。
class _SegmentShape extends OutlinedBorder {
  const _SegmentShape({
    required this.leftRest,
    required this.rightRest,
    required this.t,
    super.side,
  });

  final double leftRest;
  final double rightRest;
  final double t;

  RRect _rrect(Rect rect) {
    final full = rect.height / 2;
    final left = (lerpDouble(leftRest, full, t) ?? full).clamp(0.0, full);
    final right = (lerpDouble(rightRest, full, t) ?? full).clamp(0.0, full);
    return RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.circular(left),
      bottomLeft: Radius.circular(left),
      topRight: Radius.circular(right),
      bottomRight: Radius.circular(right),
    );
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(_rrect(rect).deflate(side.strokeInset));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(_rrect(rect));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawRRect(
      _rrect(rect).inflate(side.strokeOffset / 2),
      side.toPaint(),
    );
  }

  @override
  ShapeBorder scale(double t) => _SegmentShape(
        leftRest: leftRest * t,
        rightRest: rightRest * t,
        t: this.t,
        side: side.scale(t),
      );

  @override
  _SegmentShape copyWith({BorderSide? side}) => _SegmentShape(
        leftRest: leftRest,
        rightRest: rightRest,
        t: t,
        side: side ?? this.side,
      );

  @override
  bool operator ==(Object other) =>
      other is _SegmentShape &&
      other.leftRest == leftRest &&
      other.rightRest == rightRest &&
      other.t == t &&
      other.side == side;

  @override
  int get hashCode => Object.hash(leftRest, rightRest, t, side);
}

/// 分段内容：图标 + 标题（+ 说明）
class _SegmentContent extends StatelessWidget {
  const _SegmentContent({required this.segment, required this.color});

  final PublishChoiceSegment<dynamic> segment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (segment.icon != null) ...[
          NeumorphicIcon(segment.icon!, size: 18, color: color),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            segment.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );

    if (segment.description == null) {
      return Center(child: title);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        title,
        const SizedBox(height: 2),
        Text(
          segment.description!,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            color: color,
          ),
        ),
      ],
    );
  }
}
