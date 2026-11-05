import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:strawhut/app/motion.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/presentation/widgets/neumorphic_container.dart';

/// 加载指示器组件
///
/// 通用加载状态展示组件：表现力加载指示器 [StrawLoadingIndicator]
/// 置于色调容器中，下方可选提示文字。
///
/// 架构位置：应用层 → 通用 UI 组件
/// 使用场景：
/// - 文件加载中（HomeScreen 打开 .straw 文件时）
/// - 加密处理中（PublishDialog 点击"生成并加密"后）
/// - 解密处理中（DecryptDialog 点击"解密"后）
///
/// 设计特点：
/// - 垂直居中布局（Column + MainAxisSize.min）
/// - 可选的提示文字，显示在指示器下方
/// - M3 Expressive：surfaceContainer 圆角容器内的形变加载形状
///
/// 使用示例：
/// ```dart
/// LoadingIndicator(message: '正在加载文件...')
/// LoadingIndicator() // 仅指示器
/// ```
class LoadingIndicator extends StatelessWidget {

  /// 创建加载指示器实例
  ///
  /// 参数：[message] - 可选的加载提示文字
  const LoadingIndicator({super.key, this.message});
  /// 可选的加载提示文字
  ///
  /// 为 null 时不显示文字，仅展示指示器。
  final String? message;

  /// 构建加载指示器 UI
  ///
  /// 布局结构：
  /// - Center → Column → NeumorphicContainer(flat) 内
  ///   StrawLoadingIndicator + Text（可选）
  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NeumorphicContainer(
            shape: NeumorphicShape.flat,
            borderRadius: tokens.radiusLarge,
            padding: const EdgeInsets.all(16),
            // 文案已由下方 Text 朗读，指示器不再重复提供语义标签
            child: const StrawLoadingIndicator(),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                color: tokens.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 表现力加载指示器（M3 Expressive）
///
/// 一个 primary 色的「曲奇」形状：在 8 瓣扇形与 4 瓣软方之间来回形变，
/// 同时匀速旋转，一个周期 1.6s。用于替代裸露的 [CircularProgressIndicator]。
///
/// 开启减少动态效果时为静态形状（不启动循环动画）。
///
/// 注意：与 [CircularProgressIndicator] 一样是无限循环动画，
/// 在 widget 测试中显示时请用 `pump()` 而非 `pumpAndSettle()`。
///
/// 用法：
/// ```dart
/// const StrawLoadingIndicator(size: 40)
/// ```
class StrawLoadingIndicator extends StatefulWidget {
  /// 创建表现力加载指示器
  const StrawLoadingIndicator({
    super.key,
    this.size = 48,
    this.color,
    this.semanticLabel,
  });

  /// 指示器边长（逻辑像素）
  final double size;

  /// 形状颜色；为空时取 primary（tokens.inkPrimary）
  final Color? color;

  /// 无障碍标签（读屏朗读，不显示）
  final String? semanticLabel;

  @override
  State<StrawLoadingIndicator> createState() => _StrawLoadingIndicatorState();
}

class _StrawLoadingIndicatorState extends State<StrawLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: StrawMotion.loop);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  /// 根据减少动态效果设置启动/停止循环
  void _syncAnimation() {
    if (StrawMotion.reducedMotion(context)) {
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ?? NeumorphicTokens.ofContext(context).inkPrimary;
    return Semantics(
      label: widget.semanticLabel,
      child: SizedBox.square(
        dimension: widget.size,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _MorphShapePainter(
                progress: _controller.value,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 形变形状绘制器
///
/// 极坐标半径 r(θ) = R · (1 + a4·cos 4θ + a8·cos 8θ)，
/// 通过在一个周期内交替两种瓣数的振幅实现平滑形变，并整体旋转一周。
class _MorphShapePainter extends CustomPainter {
  _MorphShapePainter({required this.progress, required this.color});

  /// 周期进度 0 → 1
  final double progress;

  /// 填充色
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // 0 → 1 → 0 的平滑往返，用于形变
    final morph = 0.5 - 0.5 * math.cos(progress * 2 * math.pi);
    final a8 = 0.07 * (1 - morph); // 8 瓣曲奇
    final a4 = 0.10 * morph; // 4 瓣软方
    final baseRadius = size.shortestSide / 2 / (1 + a4 + a8);
    final rotation = progress * 2 * math.pi;

    const steps = 96;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final theta = i / steps * 2 * math.pi;
      final r = baseRadius *
          (1 + a4 * math.cos(4 * theta) + a8 * math.cos(8 * theta));
      final point = center +
          Offset(math.cos(theta + rotation), math.sin(theta + rotation)) * r;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color..isAntiAlias = true);
  }

  @override
  bool shouldRepaint(_MorphShapePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
