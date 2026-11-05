import 'package:flutter/material.dart';

import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/presentation/widgets/neumorphic_button.dart';
import 'package:strawhut/presentation/widgets/neumorphic_container.dart';
import 'package:strawhut/presentation/widgets/neumorphic_icon.dart';

/// 错误横幅组件
///
/// 在页面顶部显示错误提示信息，支持关闭操作。
///
/// 架构位置：应用层 → 通用 UI 组件
/// 使用场景：
/// - 文件加载失败时在 HomeScreen 顶部显示
/// - 解密失败时在 ReaderScreen 顶部显示
/// - 格式验证失败时在任意页面显示
///
/// 设计特点：
/// - M3 Expressive：errorContainer 色调容器，16 圆角
/// - 错误图标 + onErrorContainer 文字（对比度 ≥ 4.5:1）
/// - 错误消息文字可换行（Expanded）
/// - 可选的关闭按钮（onDismiss）
/// - 固定在页面顶部，不随内容滚动
///
/// 使用示例：
/// ```dart
/// ErrorBanner(
///   message: '文件加载失败：文件格式不正确',
///   onDismiss: () => setState(() => showError = false),
/// )
/// ```
class ErrorBanner extends StatelessWidget {

  /// 创建错误横幅实例
  ///
  /// 参数说明：
  /// - [message]: 错误提示文字，必填
  /// - [onDismiss]: 可选的关闭按钮回调
  const ErrorBanner({
    required this.message, super.key,
    this.onDismiss,
  });
  /// 错误提示文字
  ///
  /// 必填参数，人类可读的错误描述。
  final String message;

  /// 关闭按钮回调
  ///
  /// 可选参数，为 null 时不显示关闭按钮。
  /// 通常在用户点击关闭按钮后设置错误状态为 false。
  final VoidCallback? onDismiss;

  /// 构建错误横幅 UI
  ///
  /// 布局结构：
  /// - NeumorphicContainer（errorContainer 色调容器 + 内边距）
  ///   - Row
  ///     - NeumorphicIcon（错误图标）
  ///     - Text（错误消息，可换行）
  ///     - NeumorphicIconButton（关闭按钮，可选）
  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);

    return NeumorphicContainer(
      shape: NeumorphicShape.flat,
      color: tokens.errorContainer,
      borderRadius: tokens.radiusMedium,
      padding: EdgeInsets.only(
        left: 16,
        right: onDismiss != null ? 4 : 16,
        top: onDismiss != null ? 4 : 12,
        bottom: onDismiss != null ? 4 : 12,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          NeumorphicIcon(
            StrawIcons.error,
            size: 20,
            color: tokens.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: tokens.onErrorContainer,
                height: 20 / 14,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            NeumorphicIconButton(
              icon: StrawIcons.close,
              iconSize: 18,
              onPressed: onDismiss,
              color: tokens.onErrorContainer,
              semanticLabel: '关闭',
            ),
          ],
        ],
      ),
    );
  }
}
