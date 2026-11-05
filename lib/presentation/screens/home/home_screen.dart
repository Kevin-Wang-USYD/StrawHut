import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:strawhut/app/motion.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/core/utils/temp_file_manager.dart';
import 'package:strawhut/presentation/dialogs/passphrase_vault_dialog/passphrase_vault_dialog.dart';
import 'package:strawhut/presentation/screens/home/widgets/action_buttons.dart';
import 'package:strawhut/presentation/screens/home/widgets/drop_zone.dart';
import 'package:strawhut/presentation/screens/home/widgets/help_dialog.dart';
import 'package:strawhut/presentation/widgets/neumorphic_button.dart';
import 'package:strawhut/presentation/widgets/neumorphic_container.dart';
import 'package:strawhut/presentation/widgets/neumorphic_icon.dart';
import 'package:strawhut/presentation/widgets/responsive_utils.dart';
import 'package:strawhut/presentation/widgets/straw_entrance.dart';

/// 首页界面
///
/// StrawHut 应用的入口页面，提供以下功能：
/// - 展示应用标题和 Logo
/// - "新建知识卡片" 按钮 → 导航到 EditorScreen
/// - "打开知识卡片" 按钮 → 触发文件选择器
/// - 拖拽区域（仅 Windows 桌面端）→ 接受 .straw 文件拖入
///
/// 架构位置：应用层（Presentation Layer）
/// 路由路径：'/'（由 go_router 配置）
/// 依赖 Provider：CardProvider（加载文件时使用）
///
/// 设计特点：
/// - 简洁的布局，突出核心操作
/// - 使用 ConsumerStatefulWidget 支持 Android 返回键双击退出
/// - 拖拽功能仅 Windows 桌面端启用，移动端隐藏
///
/// 使用场景：
/// 1. 应用启动后显示此页面
/// 2. 用户点击"新建知识卡片" → 导航到 EditorScreen
/// 3. 用户点击"打开知识卡片" → 选择 .straw 文件 → 导航到 ReaderScreen
/// 4. 用户拖入 .straw 文件 → 解析后导航到 ReaderScreen
class HomeScreen extends ConsumerStatefulWidget {
  /// 创建首页实例
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  /// 上次按返回键的时间，用于双击退出逻辑
  DateTime? _lastBackPress;

  /// 软件版本号
  String _version = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Clean up any residual temp files from previous sessions
    TempFileManager.cleanAll();
    _loadVersion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 在应用分离时清理临时文件（包含敏感解密数据）
    if (state == AppLifecycleState.detached) {
      TempFileManager.cleanAll();
    }
  }

  /// 加载软件版本号
  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = 'v${packageInfo.version}';
        });
      }
    } on Exception catch (_) {
      // 忽略错误，版本号显示为空
    }
  }

  /// 处理 Android 返回键：双击退出应用
  Future<bool> _handleBack() async {
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      return true; // Exit app
    }
    _lastBackPress = now;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('再次点击返回键退出应用'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    return false; // Don't exit yet
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = getHorizontalPadding(screenWidth);
    final tokens = NeumorphicTokens.ofContext(context);
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: !isAndroid(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!isAndroid()) {
          if (context.canPop()) {
            context.pop();
          } else {
            await SystemNavigator.pop();
          }
          return;
        }
        final shouldExit = await _handleBack();
        if (shouldExit) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: tokens.surface,
        appBar: _buildSoftAppBar(context, tokens),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: tokens.spaceMd,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 480,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 主卡片：primaryContainer 底 + 36 圆角，
                      // 内含 Logo 徽章、表现力大标题、副标题与核心操作按钮组。
                      // 进入动效只作用于顶层分段（不嵌套），每段仅上浮 24px。
                      StrawEntrance(
                        child: _HomeHeroCard(
                          logo: _buildLogo(tokens),
                          headline: Text(
                            '欢迎使用 StrawHut',
                            style: textTheme.displayLarge?.copyWith(
                              color: tokens.onPrimaryContainer,
                            ),
                          ),
                          subtitle: Text(
                            '创建加密知识卡片，安全分享你的知识',
                            style: textTheme.bodyLarge?.copyWith(
                              color: tokens.onPrimaryContainer
                                  .withValues(alpha: 0.82),
                            ),
                          ),
                          // 核心操作按钮组
                          actions: const ActionButtons(),
                        ),
                      ),
                      SizedBox(height: tokens.spaceMd),
                      // 隐私承诺标签
                      StrawEntrance(
                        index: 1,
                        child: _buildPrivacyChips(tokens),
                      ),
                      SizedBox(height: tokens.spaceLg),
                      // 桌面端拖拽区域
                      const StrawEntrance(
                        index: 2,
                        child: DropZone(),
                      ),
                      // Android 分享提示
                      if (defaultTargetPlatform ==
                          TargetPlatform.android) ...[
                        SizedBox(height: tokens.spaceMd),
                        StrawEntrance(
                          index: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '您也可以从其他应用分享文件到 StrawHut 打开',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: tokens.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: tokens.spaceLg),
                      // 版本号
                      if (_version.isNotEmpty)
                        StrawEntrance(
                          index: 3,
                          child: Text(
                            _version,
                            textAlign: TextAlign.center,
                            style: textTheme.labelMedium?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建顶部应用栏
  ///
  /// 透明背景，左侧为品牌标识（primaryContainer 圆形徽标），
  /// 中间为标题，右侧为 48 圆形图标按钮，无下边线。
  PreferredSize _buildSoftAppBar(
    BuildContext context,
    NeumorphicTokens tokens,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 16),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              // 左侧：品牌标识（装饰性，不可点击；保留按钮语义且为禁用态）
              Semantics(
                button: true,
                enabled: false,
                // 与原禁用态 NeumorphicIconButton 一致：悬停显示禁止光标
                child: MouseRegion(
                  cursor: SystemMouseCursors.forbidden,
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tokens.inkWash,
                      shape: BoxShape.circle,
                    ),
                    child: NeumorphicIcon(
                      StrawIcons.lock,
                      size: 22,
                      color: tokens.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 标题
              Expanded(
                child: Text(
                  'StrawHut · 草棚',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: tokens.textPrimary,
                      ),
                ),
              ),
              // 右侧：暗号保险库
              NeumorphicIconButton(
                icon: StrawIcons.password,
                tooltip: '暗号保险库',
                onPressed: () => PassphraseVaultDialog.show(context),
              ),
              const SizedBox(width: 4),
              // 右侧：帮助（使用教程）
              NeumorphicIconButton(
                icon: StrawIcons.help,
                tooltip: '使用教程',
                onPressed: () => _showHelpDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建应用 Logo（圆形表面容器 + 应用图标 PNG 资源）
  ///
  /// 放置在主卡片中旋转的扇贝形徽章之上。
  Widget _buildLogo(NeumorphicTokens tokens) {
    return NeumorphicContainer(
      shape: NeumorphicShape.flat,
      color: tokens.surfaceContainerLowest,
      borderRadius: 60,
      width: 120,
      height: 120,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(48),
        child: Image.asset(
          'assets/icons/app_icon.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// 构建隐私承诺标签行（10 圆角描边标签，不可点击）
  Widget _buildPrivacyChips(NeumorphicTokens tokens) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _PrivacyChip(icon: StrawIcons.lock, label: '本地加密', tokens: tokens),
        _PrivacyChip(icon: StrawIcons.globe, label: '零网络请求', tokens: tokens),
        _PrivacyChip(icon: StrawIcons.eyeOff, label: '零持久化', tokens: tokens),
      ],
    );
  }

  /// 显示使用教程对话框
  void _showHelpDialog(BuildContext context) {
    if (shouldUseMobileDialog()) {
      showDialog<void>(
        context: context,
        builder: (context) => const HelpDialog(),
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (context) => const HelpDialog(),
      );
    }
  }
}

/// 首页主卡片（M3 Expressive「开放卡片」）
///
/// primaryContainer 底色、36 圆角；左上为 Logo 徽章（Logo 叠在扇贝形装饰上），
/// 右上角有一枚大号半透明扇贝形装饰。扇贝形在进入时由圆形「长出」花瓣并旋转到位；
/// 桌面端鼠标悬停卡片时缓慢持续旋转，移出即停。
/// 开启减少动态效果时扇贝形保持静止。
class _HomeHeroCard extends StatefulWidget {
  const _HomeHeroCard({
    required this.logo,
    required this.headline,
    required this.subtitle,
    required this.actions,
  });

  final Widget logo;
  final Widget headline;
  final Widget subtitle;
  final Widget actions;

  @override
  State<_HomeHeroCard> createState() => _HomeHeroCardState();
}

class _HomeHeroCardState extends State<_HomeHeroCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: NeumorphicContainer(
        shape: NeumorphicShape.flat,
        color: tokens.inkWash,
        borderRadius: tokens.radiusXLarge,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radiusXLarge),
          child: Stack(
            children: [
              // 右上角大号装饰扇贝形（反向旋转）
              Positioned(
                top: -72,
                right: -72,
                child: _ScallopShape(
                  size: 232,
                  lobes: 9,
                  depth: 0.07,
                  color: tokens.inkPrimary.withValues(alpha: 0.10),
                  introTurns: 0.18,
                  spinning: _hovering,
                  reverse: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo 徽章：Logo 叠在旋转扇贝形之上
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _ScallopShape(
                              size: 140,
                              lobes: 12,
                              depth: 0.05,
                              color: tokens.inkPrimary,
                              introTurns: -0.12,
                              spinning: _hovering,
                            ),
                            widget.logo,
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: tokens.spaceMd),
                    widget.headline,
                    SizedBox(height: tokens.spaceSm),
                    widget.subtitle,
                    SizedBox(height: tokens.spaceLg),
                    widget.actions,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 装饰性扇贝形（M3 Expressive「cookie」形状）
///
/// 由 [CustomPainter] 绘制。进入时一次性动画：花瓣深度由 0 生长到 [depth]，
/// 同时以弹簧曲线从 [introTurns] 圈旋转回 0；[spinning] 为 true 时缓慢持续旋转。
/// 开启减少动态效果时直接显示静止终态，不旋转。
/// 纯装饰，不参与语义树。
class _ScallopShape extends StatefulWidget {
  const _ScallopShape({
    required this.size,
    required this.lobes,
    required this.depth,
    required this.color,
    required this.introTurns,
    required this.spinning,
    this.reverse = false,
  });

  final double size;
  final int lobes;
  final double depth;
  final Color color;
  final double introTurns;
  final bool spinning;
  final bool reverse;

  @override
  State<_ScallopShape> createState() => _ScallopShapeState();
}

class _ScallopShapeState extends State<_ScallopShape>
    with TickerProviderStateMixin {
  /// 进入动画（一次性，不循环，保证 pumpAndSettle 可结束）
  late final AnimationController _intro;

  /// 悬停旋转（仅在 [_ScallopShape.spinning] 时循环）
  late final AnimationController _spin;

  late final Animation<double> _introTurn;
  late final Animation<double> _introDepth;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: StrawMotion.long + StrawMotion.medium,
    );
    _introTurn = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.15, 1, curve: StrawMotion.spring),
    );
    _introDepth = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.15, 0.85, curve: StrawMotion.emphasized),
    );
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = StrawMotion.reducedMotion(context);
    if (!_started) {
      _started = true;
      if (reduced) {
        _intro.value = 1;
      } else {
        _intro.forward();
      }
    }
    _syncSpin(reduced);
  }

  @override
  void didUpdateWidget(covariant _ScallopShape oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spinning != widget.spinning) {
      _syncSpin(StrawMotion.reducedMotion(context));
    }
  }

  void _syncSpin(bool reduced) {
    if (widget.spinning && !reduced) {
      if (!_spin.isAnimating) _spin.repeat();
    } else if (_spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_intro, _spin]),
          builder: (context, _) {
            final direction = widget.reverse ? -1.0 : 1.0;
            final turns = widget.introTurns * (1 - _introTurn.value) +
                direction * _spin.value;
            return CustomPaint(
              size: Size.square(widget.size),
              painter: _ScallopPainter(
                lobes: widget.lobes,
                depth: widget.depth * _introDepth.value.clamp(0.0, 1.0),
                rotation: turns * 2 * math.pi,
                color: widget.color,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 扇贝形绘制器：半径随角度按余弦起伏，形成 [lobes] 片圆润花瓣
class _ScallopPainter extends CustomPainter {
  const _ScallopPainter({
    required this.lobes,
    required this.depth,
    required this.rotation,
    required this.color,
  });

  final int lobes;

  /// 花瓣深度（相对半径的比例，0 为正圆）
  final double depth;

  /// 旋转角（弧度）
  final double rotation;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    const steps = 240;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final theta = i / steps * 2 * math.pi;
      final r = outer * (1 - depth) + outer * depth * math.cos(lobes * theta);
      final point = center +
          Offset(
            r * math.cos(theta + rotation),
            r * math.sin(theta + rotation),
          );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _ScallopPainter oldDelegate) {
    return oldDelegate.lobes != lobes ||
        oldDelegate.depth != depth ||
        oldDelegate.rotation != rotation ||
        oldDelegate.color != color;
  }
}

/// 隐私承诺标签（不可交互）：10 圆角、outlineVariant 描边
class _PrivacyChip extends StatelessWidget {
  const _PrivacyChip({
    required this.icon,
    required this.label,
    required this.tokens,
  });

  final String icon;
  final String label;
  final NeumorphicTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NeumorphicIcon(icon, size: 16, color: tokens.inkPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: tokens.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
