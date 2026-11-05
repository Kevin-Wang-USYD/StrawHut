import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:strawhut/app/motion.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/presentation/widgets/neumorphic_icon.dart';

/// 错误抖动：子组件首次出现或 [trigger] 变化时左右轻晃一次
///
/// 一次性动画（约 420ms，振幅逐渐衰减），不循环，因此不会阻塞
/// `pumpAndSettle`。开启减少动态效果时完全不抖动。
class ErrorShake extends StatefulWidget {
  /// 创建错误抖动包装
  const ErrorShake({
    required this.child,
    super.key,
    this.trigger,
    this.amplitude = 8,
  });

  /// 抖动的内容
  final Widget child;

  /// 触发值：与上一次不同时重新抖动（通常传入错误文本）
  final Object? trigger;

  /// 最大水平位移（逻辑像素）
  final double amplitude;

  @override
  State<ErrorShake> createState() => _ErrorShakeState();
}

class _ErrorShakeState extends State<ErrorShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: StrawMotion.medium);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _shake();
    }
  }

  @override
  void didUpdateWidget(covariant ErrorShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      _shake();
    }
  }

  void _shake() {
    if (StrawMotion.reducedMotion(context)) {
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        // 三个半周期的正弦，振幅线性衰减到 0
        final dx = math.sin(t * math.pi * 6) * widget.amplitude * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

/// 解密流程中的错误提示条
///
/// errorContainer 底色、error 色图标与文字、16 圆角，出现或文案变化时抖动一次。
class DecryptErrorMessage extends StatelessWidget {
  /// 创建错误提示条
  const DecryptErrorMessage({
    required this.message,
    super.key,
    this.iconSize = 18,
  });

  /// 错误文本
  final String message;

  /// 图标尺寸
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    return ErrorShake(
      trigger: message,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.errorContainer,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeumorphicIcon(
                StrawIcons.error,
                size: iconSize,
                color: tokens.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: tokens.error,
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
