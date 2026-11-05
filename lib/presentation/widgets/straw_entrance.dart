import 'package:flutter/material.dart';

import 'package:strawhut/app/motion.dart';

/// 内容进入动画：淡入 + 上浮 24px，可按序号错峰
///
/// 仅在首次构建时播放一次（非循环）。减少动态效果开启时直接显示终态。
/// 错峰通过单个控制器内的 [Interval] 实现，不使用 Timer，
/// 因此在测试中 `pumpAndSettle` 可以正常结束。
///
/// 用法（首页各分段依次进入）：
/// ```dart
/// StrawEntrance(index: 0, child: header),
/// StrawEntrance(index: 1, child: heroCard),
/// ```
class StrawEntrance extends StatefulWidget {
  /// 创建进入动画
  const StrawEntrance({
    required this.child,
    super.key,
    this.index = 0,
    this.stagger = StrawMotion.stagger,
    this.duration = StrawMotion.medium,
    this.offset = StrawMotion.riseOffset,
  });

  /// 子内容
  final Widget child;

  /// 错峰序号：第 n 个分段延迟 n × [stagger] 开始
  final int index;

  /// 错峰间隔
  final Duration stagger;

  /// 单个分段的进入时长
  final Duration duration;

  /// 上浮距离（逻辑像素）
  final double offset;

  @override
  State<StrawEntrance> createState() => _StrawEntranceState();
}

class _StrawEntranceState extends State<StrawEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final delay = widget.stagger * widget.index;
    final total = delay + widget.duration;
    final begin = total.inMicroseconds == 0
        ? 0.0
        : delay.inMicroseconds / total.inMicroseconds;
    _controller = AnimationController(vsync: this, duration: total);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, 1, curve: StrawMotion.emphasized),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (StrawMotion.reducedMotion(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (StrawMotion.reducedMotion(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) {
        final t = _progress.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
