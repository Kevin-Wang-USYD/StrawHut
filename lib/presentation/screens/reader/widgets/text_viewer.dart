import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';

/// 文本内容查看器组件
///
/// 用于展示解密后的纯文本或 Markdown 内容。
///
/// 架构位置：应用层（Presentation Layer）-> 阅读器子组件
/// 使用场景：ReaderScreen 解密成功后，内容类型为 text 或 markdown 时展示
///
/// 核心功能：
/// - 纯文本模式：使用 SelectableText 展示，支持文本选择
/// - Markdown 模式：使用 flutter_markdown 渲染 Markdown 格式
class TextViewer extends StatelessWidget {
  /// 创建文本查看器组件实例
  ///
  /// 参数：
  /// - [text] - 要展示的文本内容，必填
  /// - [isMarkdown] - 是否为 Markdown 格式，默认 false
  const TextViewer({
    required this.text,
    this.isMarkdown = false,
    super.key,
  });

  /// 要展示的文本内容
  final String text;

  /// 是否为 Markdown 格式
  final bool isMarkdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = NeumorphicTokens.ofContext(context);
    // 阅读正文：17/30，onSurface，平铺在 surface 上（不放在玻璃上）
    final body = (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontSize: 17,
      height: 30 / 17,
      fontWeight: FontWeight.w400,
      color: tokens.textPrimary,
    );

    if (isMarkdown) {
      return MarkdownBody(
        data: text,
        selectable: true,
        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
          p: body,
          listBullet: body,
          h1: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 28,
            height: 36 / 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: tokens.textPrimary,
          ),
          h2: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 22,
            height: 28 / 22,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
          h3: theme.textTheme.titleLarge?.copyWith(
            fontSize: 18,
            height: 26 / 18,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
          a: body.copyWith(
            color: tokens.inkPrimary,
            decoration: TextDecoration.underline,
            decorationColor: tokens.inkPrimary,
          ),
          code: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            fontSize: 14,
            color: tokens.textPrimary,
            backgroundColor: tokens.surfaceContainerHighest,
          ),
          codeblockPadding: const EdgeInsets.all(16),
          codeblockDecoration: BoxDecoration(
            color: tokens.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(tokens.radiusMedium),
          ),
          blockquote: body.copyWith(color: tokens.textSecondary),
          blockquotePadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          blockquoteDecoration: BoxDecoration(
            color: tokens.surfaceContainerLow,
            border: Border(
              left: BorderSide(color: tokens.inkWash, width: 4),
            ),
          ),
          horizontalRuleDecoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: tokens.divider),
            ),
          ),
        ),
      );
    }

    return SelectableText(
      text,
      style: body,
    );
  }
}
