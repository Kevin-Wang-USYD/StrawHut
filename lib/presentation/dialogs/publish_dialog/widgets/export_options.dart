import 'package:flutter/material.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/presentation/widgets/neumorphic_container.dart';
import 'package:strawhut/presentation/widgets/neumorphic_icon.dart';

/// 发布对话框 - 导出选项组件
///
/// 提供密钥文件导出选项，用户可选择是否同时生成 .key 文件。
///
/// 架构位置：应用层（Presentation Layer）→ 发布对话框子组件
/// 使用场景：PublishDialog 中密钥生成后显示
///
/// 功能说明：
/// - "导出 .key 文件" 复选框
/// - 勾选后，在保存 .straw 文件后弹出 .key 文件保存对话框
/// - 默认不勾选（密钥文件为可选导出）
///
/// 设计原则：
/// - .key 文件与 .straw 文件分离存储和传输
/// - 用户自主选择是否导出
/// - 避免密钥与加密内容一起泄露
class ExportOptions extends StatelessWidget {
  /// 创建导出选项组件实例
  ///
  /// 参数说明：
  /// - [value]: 当前是否勾选导出选项
  /// - [onChanged]: 勾选状态变化时的回调函数
  const ExportOptions({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// 当前是否勾选导出选项
  final bool value;

  /// 勾选状态变化时的回调函数
  final ValueChanged<bool?> onChanged;

  /// 构建导出选项 UI
  ///
  /// 布局结构：
  /// - NeumorphicContainer（色调选项卡：未勾选 surfaceContainer，勾选 secondaryContainer）
  ///   - Row
  ///     - NeumorphicIcon（密钥图标）
  ///     - Expanded（标题 + 副标题）
  ///     - Checkbox（M3 主题配色）
  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    final foreground = value ? tokens.onSecondaryContainer : tokens.textPrimary;

    return NeumorphicContainer(
      shape: NeumorphicShape.flat,
      color: value ? tokens.secondaryContainer : tokens.surfaceAlt,
      borderRadius: tokens.radiusMedium,
      padding: EdgeInsets.only(
        left: tokens.spaceMd,
        right: tokens.spaceXs,
        top: tokens.spaceSm,
        bottom: tokens.spaceSm,
      ),
      child: Row(
        children: [
          NeumorphicIcon(
            StrawIcons.password,
            size: 20,
            color: value ? tokens.onSecondaryContainer : tokens.inkPrimary,
          ),
          SizedBox(width: tokens.spaceSm + tokens.spaceXs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '导出 .key 文件',
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '密钥文件可单独保存和传输，建议与 .straw 文件分开保管',
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: value
                        ? tokens.onSecondaryContainer
                        : tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: tokens.inkPrimary,
            checkColor: tokens.onPrimary,
            side: BorderSide(color: tokens.textSecondary, width: 2),
          ),
        ],
      ),
    );
  }
}
