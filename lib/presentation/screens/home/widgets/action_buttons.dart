import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:strawhut/app/motion.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/presentation/dialogs/publish_dialog/publish_dialog.dart';
import 'package:strawhut/presentation/providers/card_provider.dart';
import 'package:strawhut/presentation/providers/crypto_provider.dart';
import 'package:strawhut/presentation/providers/picked_file_provider.dart';
import 'package:strawhut/presentation/widgets/neumorphic_button.dart';
import 'package:strawhut/presentation/widgets/neumorphic_icon.dart';

/// 首页操作按钮组件
///
/// 以两列色调操作卡显示首页的核心操作，包括：
/// - "新建知识卡片" 按钮：导航到 EditorScreen
/// - "打开知识卡片" 按钮：触发文件选择器，选择 .straw 文件后导航到 ReaderScreen
///
/// 架构位置：应用层（Presentation Layer）→ 首页子组件
/// 使用场景：HomeScreen 的 body 中使用
///
/// 按钮交互流程：
/// 1. 点击"新建知识卡片" → go_router 导航到 /editor
/// 2. 点击"打开知识卡片" → 调用 FilePicker 选择文件
///    → 验证文件扩展名为 .straw
///    → go_router 导航到 /reader?path=xxx
class ActionButtons extends ConsumerWidget {
  /// 创建操作按钮组件实例
  const ActionButtons({super.key});

  /// 构建按钮 UI
  ///
  /// 布局结构（M3 Expressive）：
  /// - 两列等高的色调操作卡（[ActionTile]），左"发布"、右"解密"
  /// - 卡片之间 12px 间距，整体横向撑满
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "发布知识卡片"：主入口（primary 填充，在 primaryContainer 主卡片上最突出）
          Expanded(
            child: ActionTile(
              label: '发布知识卡片',
              subtitle: '编辑富文本或加密文件',
              icon: StrawIcons.plusCircle,
              tone: ActionTileTone.primary,
              onPressed: () => _onCreateNewCard(context),
            ),
          ),
          const SizedBox(width: 12),
          // "解密知识卡片"：次入口（tertiaryContainer）
          Expanded(
            child: ActionTile(
              label: '解密知识卡片',
              subtitle: '打开 .straw / .png',
              icon: StrawIcons.folderOpen,
              tone: ActionTileTone.tertiary,
              onPressed: () => _onOpenCard(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理"发布知识卡片"按钮点击事件
  ///
  /// 弹出选择对话框，让用户选择内容来源：
  /// - "富文本编辑"：进入编辑器，编辑后发布
  /// - "直接加密文件"：跳过编辑器，直接打开发布对话框
  void _onCreateNewCard(BuildContext context) {
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (isMobile) {
      _showCreateOptionsMobile(context);
    } else {
      _showCreateOptionsDesktop(context);
    }
  }

  /// 桌面端：弹出选择对话框（M3 对话框：surfaceContainerHigh 底、32 圆角）
  ///
  /// 约束：两个选项 UI 权重一致（都用 secondary 色调按钮），
  /// 垂直排列在底部，宽度增加。
  void _showCreateOptionsDesktop(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;
        return Dialog(
          backgroundColor: tokens.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kDialogRadius),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '发布知识卡片',
                    style: textTheme.headlineSmall?.copyWith(
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '请选择内容来源：',
                    style: textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 选项一：富文本编辑（权重一致）
                  NeumorphicButton(
                    label: '富文本编辑',
                    icon: StrawIcons.editNote,
                    expanded: true,
                    minimumSize: const Size(double.infinity, 56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      context.go('/editor');
                    },
                  ),
                  const SizedBox(height: 12),
                  // 选项二：直接加密文件（权重一致）
                  NeumorphicButton(
                    label: '直接加密文件',
                    icon: StrawIcons.uploadFile,
                    expanded: true,
                    minimumSize: const Size(double.infinity, 56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      PublishDialog.show(
                        context,
                        initialMode: ContentSourceMode.fileUpload,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 移动端：弹出底部选择面板（surfaceContainerLow 底、32 顶部圆角）
  ///
  /// 约束：两个 ListTile 权重一致，垂直排列。
  void _showCreateOptionsMobile(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_kDialogRadius),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                ListTile(
                  leading: const _TonalLeadingIcon(StrawIcons.editNote),
                  title: const Text('富文本编辑'),
                  subtitle: const Text('在编辑器中创作内容后发布'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/editor');
                  },
                ),
                ListTile(
                  leading: const _TonalLeadingIcon(StrawIcons.uploadFile),
                  title: const Text('直接加密文件'),
                  subtitle: const Text('选择文件直接加密，无需编辑'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    PublishDialog.show(
                      context,
                      initialMode: ContentSourceMode.fileUpload,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 处理"打开知识卡片"按钮点击事件
  ///
  /// Android: 弹出底部选择框，支持"从相册加载(.png)"和"从文件系统加载(.straw/.png)"
  /// Desktop: 直接调用文件选择器
  ///
  /// 流程：
  /// 1. 用户点击按钮
  /// 2. Android 弹出底部选择框，Desktop 直接选择文件
  /// 3. 选择 .straw 或 .png 文件
  /// 4. 导航到阅读器页面并传入文件数据
  Future<void> _onOpenCard(BuildContext context, WidgetRef ref) async {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    if (isAndroid) {
      _showOpenCardOptions(context, ref);
    } else {
      await _doOpenCard(context, ref);
    }
  }

  /// 在 Android 上弹出文件来源选择底部面板（32 顶部圆角）
  void _showOpenCardOptions(BuildContext context, WidgetRef ref) {
    final tokens = NeumorphicTokens.ofContext(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_kDialogRadius),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                ListTile(
                  leading: const _TonalLeadingIcon(StrawIcons.image),
                  title: const Text('从相册加载'),
                  subtitle: const Text('选择 .png 格式的加密知识卡片图片'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _doOpenCardFromGallery(context, ref);
                    });
                  },
                ),
                ListTile(
                  leading: const _TonalLeadingIcon(StrawIcons.folderOpen),
                  title: const Text('从文件系统加载'),
                  subtitle: const Text('选择 .straw 或 .png 文件'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _doOpenCard(context, ref);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 从相册选择 .png 文件（Android 使用 image_picker，Desktop 使用 FilePicker）
  Future<void> _doOpenCardFromGallery(
      BuildContext context, WidgetRef ref,) async {
    Uint8List bytes;
    String fileName;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Android: 使用 image_picker 可靠地从相册读取图片
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      bytes = await pickedFile.readAsBytes();
      // Always force .png extension since we know we're picking a PNG
      // knowledge card.
      // image_picker may return filenames like "image_picker_xxx.jpg" or
      // no extension.
      fileName = 'strawhut_card.png';
    } else {
      // Desktop: 使用 FileSelectionService
      final fileSelectionService = ref.read(fileSelectionServiceProvider);
      final result = await fileSelectionService.pickImageFile();
      if (result == null) return;
      bytes = result.$1;
      fileName = result.$2;
    }

    if (context.mounted) {
      ref.read(pendingFileBytesProvider.notifier).state = (bytes, fileName);
      context.go('/reader?path=${Uri.encodeComponent(fileName)}');
    }
  }

  /// 从文件系统选择 .straw 或 .png 文件
  ///
  /// 安卓端使用路径模式（withData: false），避免将大文件加载到内存导致 OOM。
  /// 桌面端仍使用字节模式。
  Future<void> _doOpenCard(BuildContext context, WidgetRef ref) async {
    final fileSelectionService = ref.read(fileSelectionServiceProvider);

    if (fileSelectionService.isAndroid) {
      // 安卓端：使用路径模式，避免将大文件加载到内存
      final filePath = await fileSelectionService.pickStrawOrPngFilePath();
      if (filePath == null) return;
      if (context.mounted) {
        context.go('/reader?path=${Uri.encodeComponent(filePath)}');
      }
    } else {
      // 桌面端：使用字节模式
      final result = await fileSelectionService.pickStrawOrPngFile();
      if (result == null) return;
      final (bytes, fileName) = result;
      if (context.mounted) {
        ref.read(pendingFileBytesProvider.notifier).state = (bytes, fileName);
        context.go('/reader?path=${Uri.encodeComponent(fileName)}');
      }
    }
  }
}

/// 对话框/底部面板圆角（规范：对话框四角 32，底部面板顶部 32）
const double _kDialogRadius = 32;

/// 底部面板顶部的装饰性拖动指示条（纯视觉，不参与交互与语义）
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 12),
        child: Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: tokens.textHint.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// 底部面板列表项的前导图标：secondaryContainer 色调圆形底 + onSecondaryContainer 图标
class _TonalLeadingIcon extends StatelessWidget {
  const _TonalLeadingIcon(this.icon);

  final String icon;

  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: NeumorphicIcon(
        icon,
        size: 20,
        color: tokens.onSecondaryContainer,
      ),
    );
  }
}

/// [ActionTile] 的配色
enum ActionTileTone {
  /// primary 填充 + onPrimary 文字（主入口）
  ///
  /// 操作卡位于首页 primaryContainer 主卡片内，因此主入口用 primary 实色，
  /// 避免与主卡片底色融为一体。
  primary,

  /// tertiaryContainer 底 + tertiary 图标圆（次入口）
  tertiary,
}

/// 首页两列色调操作卡（M3 Expressive）
///
/// - 顶部圆形图标，其下标题 + 说明（顶部对齐），最小高度 120
/// - 按下：弹簧缩放到 0.95，圆角从 28 收到 20（减少动态效果时立即切换）
/// - 使用 InkWell：涟漪、键盘焦点与回车/空格激活由框架提供；
///   语义上合并为一个带标题的按钮节点
class ActionTile extends StatefulWidget {
  const ActionTile({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
    this.subtitle,
    this.tone = ActionTileTone.primary,
  });

  /// 标题
  final String label;

  /// 说明文字（可选，一行）
  final String? subtitle;

  /// 图标 SVG body（来自 [StrawIcons]）
  final String icon;

  /// 点击回调
  final VoidCallback onPressed;

  /// 配色
  final ActionTileTone tone;

  @override
  State<ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<ActionTile> {
  static const double _radius = 28;
  static const double _pressedRadius = 20;

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    final textTheme = Theme.of(context).textTheme;
    final isPrimary = widget.tone == ActionTileTone.primary;
    final background = isPrimary ? tokens.inkPrimary : tokens.tertiaryContainer;
    final foreground = isPrimary ? tokens.onPrimary : tokens.onTertiaryContainer;
    final badge = isPrimary ? tokens.onPrimary : tokens.success;
    final onBadge = isPrimary ? tokens.inkPrimary : tokens.onTertiary;
    final duration = StrawMotion.duration(context, StrawMotion.short);

    return MergeSemantics(
      child: Semantics(
        button: true,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: duration,
          curve: StrawMotion.spring,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _pressed ? _pressedRadius : _radius),
            duration: duration,
            curve: StrawMotion.spring,
            builder: (context, radius, child) {
              final shape = RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius.clamp(12, 36)),
              );
              return Material(
                color: background,
                shape: shape,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: shape,
                  onTap: widget.onPressed,
                  onHighlightChanged: (value) =>
                      setState(() => _pressed = value),
                  splashColor: foreground.withValues(alpha: 0.12),
                  highlightColor: foreground.withValues(alpha: 0.08),
                  child: child,
                ),
              );
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 120),
              child: Padding(
                padding: const EdgeInsets.all(16),
                // 顶部对齐：两张卡片的标题始终在同一水平线上（说明文字
                // 换行时多出的高度留在底部），等高由外层 IntrinsicHeight 保证
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: badge,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: NeumorphicIcon(
                        widget.icon,
                        size: 20,
                        color: onBadge,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: textTheme.titleMedium?.copyWith(
                            color: foreground,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: foreground.withValues(alpha: 0.86),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
