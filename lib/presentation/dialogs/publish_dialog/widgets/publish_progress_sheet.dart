import 'package:flutter/material.dart';
import 'package:strawhut/app/motion.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/presentation/widgets/glass_surface.dart';
import 'package:strawhut/presentation/widgets/loading_indicator.dart';

/// 发布对话框 - 加密进度浮层（液态玻璃）
///
/// 加密进行中时浮在表单上方：表现力加载指示器 + 加粗圆角进度条。
/// 纯展示组件，不处理任何交互（调用方应以 [IgnorePointer] 包裹，
/// 保证浮层不拦截下方表单与取消按钮的操作）。
///
/// - [progress] 为 0 时显示不确定进度（减少动态效果时显示静止的空轨道）
/// - [cancelling] 为 true 时进度条与指示器退为 onSurfaceVariant 色
/// - 进入：淡入 + 上浮 24px（强调曲线），减少动态效果时直接显示
/// - 玻璃在减少动态效果 / 高对比度下自动回退为不透明表面（见 [GlassSurface]）
class PublishProgressSheet extends StatelessWidget {
  /// 创建加密进度浮层
  const PublishProgressSheet({
    required this.progress,
    this.cancelling = false,
    super.key,
  });

  /// 加密进度（0.0 ~ 1.0）
  final double progress;

  /// 是否正在取消
  final bool cancelling;

  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    final reduced = StrawMotion.reducedMotion(context);
    final accent = cancelling ? tokens.textSecondary : tokens.inkPrimary;

    Widget sheet(double opacity) => GlassSurface(
      strong: true,
      opacity: opacity,
      borderRadius: BorderRadius.circular(tokens.radiusLarge),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMd + tokens.spaceXs,
        vertical: tokens.spaceMd,
      ),
      child: Row(
        children: [
          StrawLoadingIndicator(size: 36, color: accent),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: progress > 0 || reduced
                ? TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: progress.clamp(0.0, 1.0)),
                    duration: StrawMotion.duration(context, StrawMotion.short),
                    curve: StrawMotion.standard,
                    builder: (context, value, _) => _bar(tokens, accent, value),
                  )
                : _bar(tokens, accent, null),
          ),
        ],
      ),
    );

    // 进入动画：淡入 + 上浮（一次性，结束后静止）。
    // 透明度在玻璃内部插值（GlassSurface.opacity），外层只做位移，
    // 避免 Opacity 包裹 BackdropFilter 导致渐变期间模糊失效。
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: StrawMotion.duration(context, StrawMotion.medium),
      curve: StrawMotion.emphasized,
      builder: (context, t, _) => Transform.translate(
        offset: Offset(0, StrawMotion.riseOffset * (1 - t)),
        child: sheet(t.clamp(0.0, 1.0)),
      ),
    );
  }

  /// 加粗圆角进度条（10px，primary 于 surfaceContainerHighest 轨道之上）
  Widget _bar(NeumorphicTokens tokens, Color accent, double? value) {
    return LinearProgressIndicator(
      value: value,
      minHeight: 10,
      borderRadius: BorderRadius.circular(5),
      color: accent,
      backgroundColor: tokens.surfaceContainerHighest,
    );
  }
}
