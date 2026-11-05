import 'package:flutter/cupertino.dart' show CupertinoPageTransition;
import 'package:flutter/material.dart';

/// StrawHut 动效令牌（Material 3 Expressive 风格）
///
/// 集中定义曲线、时长与「减少动态效果」的判断，所有组件的动画都应从这里取值，
/// 以保证整体节奏一致，并统一尊重系统的减少动态效果设置。
///
/// - [spring]：带回弹的弹簧曲线，用于按压、切换、选中滑块等「物理」反馈
/// - [emphasized]：强调曲线，用于元素进入
/// - [standard]：标准曲线，用于一般属性过渡（颜色、圆角）
///
/// 用法：
/// ```dart
/// AnimatedScale(
///   scale: pressed ? 0.95 : 1,
///   duration: StrawMotion.duration(context, StrawMotion.short),
///   curve: StrawMotion.spring,
/// )
/// ```
class StrawMotion {
  StrawMotion._();

  // ============ 曲线 ============
  /// 弹簧曲线（带过冲）：按压、切换、选中态
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1);

  /// 强调曲线：内容进入
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);

  /// 标准曲线：颜色、圆角等常规过渡
  static const Curve standard = Cubic(0.2, 0, 0, 1);

  // ============ 时长 ============
  /// 短：按压反馈、颜色切换（200ms）
  static const Duration short = Duration(milliseconds: 200);

  /// 中：页面切换、内容进入（420ms）
  static const Duration medium = Duration(milliseconds: 420);

  /// 长：大面积形变（560ms）
  static const Duration long = Duration(milliseconds: 560);

  /// 循环：表现力加载指示器一个周期（1.6s）
  static const Duration loop = Duration(milliseconds: 1600);

  /// 首页分段进入的错峰间隔（60–80ms 区间取中值）
  static const Duration stagger = Duration(milliseconds: 70);

  /// 进入动画的上浮距离（逻辑像素）
  static const double riseOffset = 24;

  /// 当前是否开启了「减少动态效果」
  ///
  /// 无 MediaQuery 时视为未开启。
  static bool reducedMotion(BuildContext context) {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  /// 根据减少动态效果设置返回实际时长：开启时返回 [Duration.zero]
  static Duration duration(BuildContext context, Duration d) {
    return reducedMotion(context) ? Duration.zero : d;
  }
}

/// 页面切换：淡入 + 上浮 24px（共享 Y 轴的轻量版本）
///
/// 通过 [ThemeData.pageTransitionsTheme] 注入，作用于 GoRouter 默认的
/// MaterialPage，不改变任何路由路径与构建逻辑。
/// 减少动态效果开启时直接显示目标页面，不做任何过渡。
class StrawPageTransitionsBuilder extends PageTransitionsBuilder {
  /// 创建页面切换构建器
  const StrawPageTransitionsBuilder();

  @override
  Duration get transitionDuration => StrawMotion.medium;

  @override
  Duration get reverseTransitionDuration => StrawMotion.short;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (StrawMotion.reducedMotion(context)) {
      return child;
    }
    return StrawFadeRiseTransition(animation: animation, child: child);
  }
}

/// iOS / macOS 页面切换：保留 Cupertino 横滑过渡与边缘滑动返回手势，
/// 但在减少动态效果开启时不做横滑与视差（手势拖动进行中除外，页面仍跟手）。
class StrawCupertinoPageTransitionsBuilder
    extends CupertinoPageTransitionsBuilder {
  /// 创建尊重减少动态效果的 Cupertino 页面切换构建器
  const StrawCupertinoPageTransitionsBuilder();

  static bool _skipMotion(BuildContext context, NavigatorState? navigator) {
    return StrawMotion.reducedMotion(context) &&
        !(navigator?.userGestureInProgress ?? false);
  }

  static Widget? _delegatedTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    if (_skipMotion(context, Navigator.maybeOf(context))) {
      return child;
    }
    return CupertinoPageTransition.delegatedTransition(
      context,
      animation,
      secondaryAnimation,
      allowSnapshotting,
      child,
    );
  }

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (_skipMotion(context, route.navigator)) {
      // 仍走 Cupertino 构建以保留返回手势，只是把进度固定为静止态
      return super.buildTransitions<T>(
        route,
        context,
        kAlwaysCompleteAnimation,
        kAlwaysDismissedAnimation,
        child,
      );
    }
    return super.buildTransitions<T>(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

/// 淡入 + 上浮过渡（被动驱动，由外部 [animation] 控制进度）
///
/// 用于页面切换，也可用于对话框/面板等自行持有动画的场景。
/// 曲线动画在 State 中创建并在销毁时释放，避免每帧重建时泄漏监听。
class StrawFadeRiseTransition extends StatefulWidget {
  /// 创建淡入上浮过渡
  const StrawFadeRiseTransition({
    required this.animation,
    required this.child,
    super.key,
    this.offset = StrawMotion.riseOffset,
  });

  /// 过渡进度（0 → 1）
  final Animation<double> animation;

  /// 上浮距离（逻辑像素）
  final double offset;

  /// 子内容
  final Widget child;

  @override
  State<StrawFadeRiseTransition> createState() =>
      _StrawFadeRiseTransitionState();
}

class _StrawFadeRiseTransitionState extends State<StrawFadeRiseTransition> {
  late CurvedAnimation _curved;

  CurvedAnimation _createCurved() => CurvedAnimation(
        parent: widget.animation,
        curve: StrawMotion.emphasized,
        reverseCurve: StrawMotion.emphasized.flipped,
      );

  @override
  void initState() {
    super.initState();
    _curved = _createCurved();
  }

  @override
  void didUpdateWidget(covariant StrawFadeRiseTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _curved.dispose();
      _curved = _createCurved();
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      child: widget.child,
      builder: (context, child) {
        final t = _curved.value;
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
