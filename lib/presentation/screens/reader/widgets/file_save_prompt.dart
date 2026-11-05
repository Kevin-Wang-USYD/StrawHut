import 'package:flutter/material.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/core/crypto/crypto_models/content_type_classifier.dart';
import 'package:strawhut/core/crypto/crypto_models/payload_metadata.dart';
import 'package:strawhut/presentation/widgets/neumorphic_button.dart';
import 'package:strawhut/presentation/widgets/neumorphic_container.dart';
import 'package:strawhut/presentation/widgets/neumorphic_icon.dart';

/// 文件保存提示组件
///
/// 当解密后的文件类型无法在应用内直接展示时（如图片、音频、视频、PDF 等），
/// 提示用户保存文件到本地。
///
/// 架构位置：应用层（Presentation Layer）-> 阅读器子组件
/// 使用场景：ReaderScreen 解密成功后，内容类型非文本时展示
///
/// 核心功能：
/// - 显示文件信息（文件名、类型）
/// - 根据内容类型显示对应线性图标（primaryContainer 圆形徽章）
/// - 提供保存文件按钮（NeumorphicButton）
class FileSavePrompt extends StatelessWidget {
  /// 创建文件保存提示组件实例
  ///
  /// 参数：
  /// - [metadata] - 载荷元数据，包含文件信息
  /// - [tempFilePath] - 临时文件路径（可选，用于保存操作）
  /// - [contentType] - 内容类型，用于选择图标
  /// - [onSave] - 保存文件回调
  const FileSavePrompt({
    required this.metadata,
    required this.onSave,
    this.tempFilePath,
    this.contentType,
    super.key,
  });

  /// 载荷元数据
  final PayloadMetadata metadata;

  /// 临时文件路径
  final String? tempFilePath;

  /// 内容类型（用于选择图标）
  final ContentType? contentType;

  /// 保存文件回调
  final VoidCallback onSave;

  /// 根据文件后缀获取软质图标 SVG body
  ///
  /// 优先根据内容类型选择图标，回退到根据扩展名选择。
  /// 所有图标均来自 [StrawIcons] 线性细描边图标集。
  String _getFileIconBody() {
    // 优先根据内容类型选择图标
    if (contentType != null) {
      switch (contentType!) {
        case ContentType.image:
          return StrawIcons.image;
        case ContentType.audio:
          return StrawIcons.audio;
        case ContentType.video:
          return StrawIcons.video;
        case ContentType.pdf:
          return StrawIcons.document;
        case ContentType.richText:
        case ContentType.text:
        case ContentType.markdown:
          return StrawIcons.document;
        case ContentType.other:
          break;
      }
    }

    // 回退：根据扩展名选择图标
    final ext = metadata.originalExtension.toLowerCase();
    switch (ext) {
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
      case 'apk':
      case 'exe':
      case 'dmg':
        return StrawIcons.document;
      default:
        return StrawIcons.document;
    }
  }

  /// 获取类型标签文字
  String _getTypeLabel() {
    if (contentType != null) {
      switch (contentType!) {
        case ContentType.image:
          return '图片';
        case ContentType.audio:
          return '音频';
        case ContentType.video:
          return '视频';
        case ContentType.pdf:
          return 'PDF';
        case ContentType.richText:
          return '富文本';
        case ContentType.text:
          return '文本';
        case ContentType.markdown:
          return 'Markdown';
        case ContentType.other:
          return metadata.originalExtension.toUpperCase();
      }
    }
    return metadata.originalExtension.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    final fileName =
        metadata.originalFileName ?? 'unknown.${metadata.originalExtension}';
    final typeLabel = _getTypeLabel();
    final canSave = tempFilePath != null;

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          // 色调卡片（surfaceContainerLow，圆角 28，与其他卡片一致）
          child: NeumorphicContainer(
            shape: NeumorphicShape.flat,
            color: tokens.surfaceContainerLow,
            borderRadius: tokens.radiusLarge,
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 文件图标（primaryContainer 圆形徽章内放置线性图标）
                NeumorphicContainer(
                  shape: NeumorphicShape.flat,
                  color: tokens.inkWash,
                  borderRadius: 48,
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  padding: EdgeInsets.zero,
                  child: NeumorphicIcon(
                    _getFileIconBody(),
                    size: 40,
                    color: tokens.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),

                // 文件名
                Text(
                  fileName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    height: 28 / 22,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // 文件类型标签（圆角 10 色调胶囊）
                NeumorphicContainer(
                  shape: NeumorphicShape.flat,
                  color: tokens.secondaryContainer,
                  borderRadius: 10,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    '$typeLabel 文件',
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: tokens.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 提示文字
                Text(
                  '此$typeLabel文件需要保存到本地后查看，\n请选择保存位置。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // 保存按钮（填充主按钮）
                NeumorphicButton(
                  label: '保存文件',
                  icon: StrawIcons.saveAlt,
                  style: NeumorphicButtonStyle.primary,
                  minimumSize: const Size(180, 56),
                  onPressed: canSave ? onSave : null,
                ),

                // 临时文件不可用时的提示
                if (!canSave) ...[
                  const SizedBox(height: 12),
                  Text(
                    '临时文件不可用',
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w700,
                      color: tokens.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
