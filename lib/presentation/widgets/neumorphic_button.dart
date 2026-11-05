import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';

import 'package:strawhut/app/motion.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/presentation/widgets/neumorphic_icon.dart';

/// 药丸按钮（M3 Expressive）
///
/// 类名沿用旧称。全药丸形状，最小高度 48（`expanded` 的主按钮为 56）。
/// 按下时有「形变」反馈：按钮以弹簧曲线缩放到 0.95，同时圆角由药丸收缩到 12，
/// 松手后弹回；开启减少动态效果时不做缩放与形变动画。
///
/// 按钮类型（[NeumorphicButtonStyle]）：
/// - [NeumorphicButtonStyle.primary]：填充按钮（primary 底 / onPrimary 字）
/// - [NeumorphicButtonStyle.secondary]：色调按钮（secondaryContainer 底）
/// - [NeumorphicButtonStyle.flat]：文字按钮（透明底 / primary 字）
/// - [NeumorphicButtonStyle.outlined]：描边按钮（透明底 / outline 描边）
/// - [NeumorphicButtonStyle.danger]：危险操作（errorContainer 底）
///
/// 禁用（[onPressed] 为 null）：onSurface 12% 底 / 38% 字。
/// 忙碌（[busy] 为 true）：不响应点击、读屏视为禁用，但保留样式原有配色，
/// 以保证按钮上的实时进度文字（如「37%」「加密中...」）清晰可读。
///
/// 用法：
/// ```dart
/// NeumorphicButton(
///   label: '发布知识卡片',
///   icon: StrawIcons.plusCircle,
///   style: NeumorphicButtonStyle.primary,
///   onPressed: () => ...,
/// )
/// ```
class NeumorphicButton extends StatefulWidget {
  const NeumorphicButton({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.style = NeumorphicButtonStyle.secondary,
    this.padding,
    this.minimumSize,
    this.expanded = false,
    this.iconSpacing = 8,
    this.busy = false,
  }) : assert(
          label != null || icon != null,
          '至少需要 label 或 icon 之一',
        );

  /// 按钮文本
  final String? label;

  /// 图标 SVG body（来自 [StrawIcons]）
  final String? icon;

  /// 点击回调；为 null 时按钮禁用
  final VoidCallback? onPressed;

  /// 按钮样式
  final NeumorphicButtonStyle style;

  /// 自定义内边距
  final EdgeInsetsGeometry? padding;

  /// 最小尺寸；为空时默认 48×48（`expanded` 主按钮高 56）
  final Size? minimumSize;

  /// 是否撑满父级宽度
  final bool expanded;

  /// 图标与文字间距
  final double iconSpacing;

  /// 是否处于忙碌态（显示实时进度）：不响应点击，但保留样式配色
  final bool busy;

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  /// 不可交互：无回调或忙碌
  bool get _isDisabled => widget.onPressed == null || widget.busy;

  /// 使用禁用配色：仅在真正禁用（非忙碌）时
  bool get _useDisabledColors => widget.onPressed == null && !widget.busy;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    final reduced = StrawMotion.reducedMotion(context);
    final colors = _resolveColors(tokens);

    // 状态层：悬停 8%、按下 10%（叠加在底色之上）
    final stateAlpha = _isDisabled
        ? 0.0
        : _isPressed
            ? 0.10
            : (_isHovering && !_isMobile)
                ? 0.08
                : 0.0;
    final background = stateAlpha == 0
        ? colors.background
        : Color.alphaBlend(
            colors.foreground.withValues(alpha: stateAlpha),
            colors.background,
          );

    // 形状：静止为药丸，按下收缩为 12 圆角（形变）
    final pressedMorph = _isPressed && !reduced;
    final side = colors.border == null
        ? BorderSide.none
        : BorderSide(color: colors.border!);
    final ShapeBorder restShape = StadiumBorder(side: side);
    final ShapeBorder pressedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radiusSmall),
      side: side,
    );

    // 默认内边距与最小尺寸
    final defaultPadding = widget.label != null && widget.icon != null
        ? const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
        : widget.label != null
            ? const EdgeInsets.symmetric(horizontal: 24, vertical: 14)
            : const EdgeInsets.all(12);
    final padding = widget.padding ?? defaultPadding;
    final isHeroCta =
        widget.expanded && widget.style == NeumorphicButtonStyle.primary;
    final minSize = widget.minimumSize ?? Size(48, isHeroCta ? 56 : 48);

    // 内容
    var content = _buildContent(colors.foreground);

    // 包裹最小尺寸
    content = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize.width,
        minHeight: minSize.height,
      ),
      child: Padding(
        padding: padding,
        child: content,
      ),
    );

    // 容器：颜色过渡用标准曲线；圆角形变用弹簧曲线，
    // 插值进度钳制在 [0, 1]，避免弹簧过冲导致形状插值越界
    final duration = StrawMotion.duration(context, StrawMotion.short);
    Widget button = TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: background),
      duration: duration,
      curve: StrawMotion.standard,
      child: content,
      builder: (context, color, child) => TweenAnimationBuilder<double>(
        tween: Tween<double>(end: pressedMorph ? 1.0 : 0.0),
        duration: duration,
        curve: StrawMotion.spring,
        child: child,
        builder: (context, t, child) => DecoratedBox(
          decoration: ShapeDecoration(
            color: color,
            shape: ShapeBorder.lerp(
              restShape,
              pressedShape,
              t.clamp(0.0, 1.0),
            )!,
          ),
          child: child,
        ),
      ),
    );

    // 按压缩放：弹簧曲线
    button = AnimatedScale(
      scale: pressedMorph ? 0.95 : 1.0,
      duration: StrawMotion.duration(context, StrawMotion.short),
      curve: StrawMotion.spring,
      child: button,
    );

    // expanded
    if (widget.expanded) {
      button = SizedBox(width: double.infinity, child: button);
    }

    // 交互
    return Semantics(
      button: true,
      enabled: !_isDisabled,
      onTap: _isDisabled ? null : widget.onPressed,
      child: MouseRegion(
        cursor: _isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) {
          if (!_isDisabled && !_isMobile) {
            setState(() => _isHovering = true);
          }
        },
        onExit: (_) {
          if (_isHovering) {
            setState(() => _isHovering = false);
          }
        },
        child: GestureDetector(
          // 语义由外层 Semantics 统一提供，避免拆分出无标签的重复节点
          excludeFromSemantics: true,
          onTapDown: (_) {
            if (!_isDisabled) {
              setState(() => _isPressed = true);
            }
          },
          onTapUp: (_) {
            if (_isPressed) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          },
          onTapCancel: () {
            if (_isPressed) {
              setState(() => _isPressed = false);
            }
          },
          child: button,
        ),
      ),
    );
  }

  /// 按样式与禁用态解析颜色
  _ButtonColors _resolveColors(NeumorphicTokens tokens) {
    final isTextLike = widget.style == NeumorphicButtonStyle.flat ||
        widget.style == NeumorphicButtonStyle.outlined;

    if (_useDisabledColors) {
      return _ButtonColors(
        background: isTextLike
            ? Colors.transparent
            : tokens.textPrimary.withValues(alpha: 0.12),
        foreground: tokens.textPrimary.withValues(alpha: 0.38),
        border: widget.style == NeumorphicButtonStyle.outlined
            ? tokens.textPrimary.withValues(alpha: 0.12)
            : null,
      );
    }

    switch (widget.style) {
      case NeumorphicButtonStyle.primary:
        return _ButtonColors(
          background: tokens.inkPrimary,
          foreground: tokens.onPrimary,
        );
      case NeumorphicButtonStyle.secondary:
        return _ButtonColors(
          background: tokens.secondaryContainer,
          foreground: tokens.onSecondaryContainer,
        );
      case NeumorphicButtonStyle.flat:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: tokens.inkPrimary,
        );
      case NeumorphicButtonStyle.outlined:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: tokens.inkPrimary,
          border: tokens.textHint,
        );
      case NeumorphicButtonStyle.danger:
        return _ButtonColors(
          background: tokens.errorContainer,
          foreground: tokens.onErrorContainer,
        );
    }
  }

  Widget _buildContent(Color color) {
    // 响应式字号：窄屏（< 500）缩小，确保中文按钮文字不溢出容器
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 500
        ? 13.0
        : screenWidth < 800
            ? 14.0
            : 15.0;
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    );

    if (widget.label != null && widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NeumorphicIcon(widget.icon!, size: 18, color: color),
          SizedBox(width: widget.iconSpacing),
          // Flexible + FittedBox 兜底：文字超长时自动等比缩小，永不溢出
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(widget.label!, style: textStyle),
            ),
          ),
        ],
      );
    }
    if (widget.label != null) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(widget.label!, style: textStyle),
      );
    }
    return NeumorphicIcon(widget.icon!, size: 20, color: color);
  }
}

/// 按钮配色（内部使用）
class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Color? border;
}

/// 按钮样式枚举
enum NeumorphicButtonStyle {
  /// 填充按钮：primary 底、onPrimary 字（主 CTA）
  primary,

  /// 色调按钮：secondaryContainer 底、onSecondaryContainer 字（默认）
  secondary,

  /// 文字按钮：透明底、primary 字
  flat,

  /// 描边按钮：透明底、outline 描边、primary 字
  outlined,

  /// 危险操作：errorContainer 底、onErrorContainer 字
  danger,
}

/// 圆形图标按钮（M3 Expressive）
///
/// 48×48 圆形（默认 [size] 48），标准态为透明底 + onSurfaceVariant 图标；
/// [tonal] 为 true 时使用 secondaryContainer 色调底，适合明确的主要操作。
/// 按下时以弹簧曲线缩放到 0.9，并由圆形收缩为 16 圆角（形变）；
/// 开启减少动态效果时不做缩放与形变动画。
///
/// [circular] 为兼容参数：新设计下静止态一律为圆形。
/// 仅图标按钮请务必提供 [tooltip] 或 [semanticLabel]，以便读屏软件朗读。
///
/// 用法：
/// ```dart
/// NeumorphicIconButton(
///   icon: StrawIcons.help,
///   tooltip: '帮助',
///   onPressed: () => ...,
/// )
/// ```
class NeumorphicIconButton extends StatefulWidget {
  const NeumorphicIconButton({
    required this.icon, super.key,
    this.onPressed,
    this.size = 48,
    this.iconSize = 20,
    this.tooltip,
    this.color,
    this.circular = false,
    this.tonal = false,
    this.semanticLabel,
  });

  /// 图标 SVG body
  final String icon;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 按钮整体尺寸（圆形直径，建议 ≥ 48 以满足触摸目标）
  final double size;

  /// 图标尺寸
  final double iconSize;

  /// 长按提示（同时作为无障碍标签）
  final String? tooltip;

  /// 自定义图标颜色
  final Color? color;

  /// 兼容参数：新设计下静止态一律为圆形
  final bool circular;

  /// 是否使用色调底（secondaryContainer）
  final bool tonal;

  /// 无障碍标签（未提供 [tooltip] 时使用）
  final String? semanticLabel;

  @override
  State<NeumorphicIconButton> createState() => _NeumorphicIconButtonState();
}

class _NeumorphicIconButtonState extends State<NeumorphicIconButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  bool get _isDisabled => widget.onPressed == null;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    final reduced = StrawMotion.reducedMotion(context);

    final baseBackground = _isDisabled
        ? (widget.tonal
            ? tokens.textPrimary.withValues(alpha: 0.12)
            : Colors.transparent)
        : (widget.tonal ? tokens.secondaryContainer : Colors.transparent);
    final iconColor = _isDisabled
        ? tokens.textPrimary.withValues(alpha: 0.38)
        : widget.color ??
            (widget.tonal
                ? tokens.onSecondaryContainer
                : tokens.textSecondary);

    // 状态层：悬停 8%、按下 10%
    final stateAlpha = _isDisabled
        ? 0.0
        : _isPressed
            ? 0.10
            : (_isHovering && !_isMobile)
                ? 0.08
                : 0.0;
    final background = stateAlpha == 0
        ? baseBackground
        : Color.alphaBlend(
            iconColor.withValues(alpha: stateAlpha),
            baseBackground,
          );

    final pressedMorph = _isPressed && !reduced;
    final restRadius = widget.size / 2;
    final pressedRadius = tokens.radiusMedium.clamp(0.0, restRadius);
    final duration = StrawMotion.duration(context, StrawMotion.short);

    // 颜色过渡用标准曲线；圆角形变用弹簧曲线（进度钳制在 [0, 1]）
    Widget button = SizedBox(
      width: widget.size,
      height: widget.size,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: background),
        duration: duration,
        curve: StrawMotion.standard,
        child: NeumorphicIcon(
          widget.icon,
          size: widget.iconSize,
          color: iconColor,
        ),
        builder: (context, color, child) => TweenAnimationBuilder<double>(
          tween: Tween<double>(end: pressedMorph ? 1.0 : 0.0),
          duration: duration,
          curve: StrawMotion.spring,
          child: child,
          builder: (context, t, child) => DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(
                restRadius + (pressedRadius - restRadius) * t.clamp(0.0, 1.0),
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );

    button = AnimatedScale(
      scale: pressedMorph ? 0.9 : 1.0,
      duration: StrawMotion.duration(context, StrawMotion.short),
      curve: StrawMotion.spring,
      child: button,
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip,
        child: button,
      );
    } else if (widget.semanticLabel != null) {
      button = Semantics(label: widget.semanticLabel, child: button);
    }

    return Semantics(
      button: true,
      enabled: !_isDisabled,
      onTap: _isDisabled ? null : widget.onPressed,
      child: MouseRegion(
        cursor: _isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) {
          if (!_isDisabled && !_isMobile) {
            setState(() => _isHovering = true);
          }
        },
        onExit: (_) {
          if (_isHovering) {
            setState(() => _isHovering = false);
          }
        },
        child: GestureDetector(
          // 语义由外层 Semantics 统一提供，避免拆分出无标签的重复节点
          excludeFromSemantics: true,
          onTapDown: (_) {
            if (!_isDisabled) {
              setState(() => _isPressed = true);
            }
          },
          onTapUp: (_) {
            if (_isPressed) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          },
          onTapCancel: () {
            if (_isPressed) {
              setState(() => _isPressed = false);
            }
          },
          child: button,
        ),
      ),
    );
  }
}
