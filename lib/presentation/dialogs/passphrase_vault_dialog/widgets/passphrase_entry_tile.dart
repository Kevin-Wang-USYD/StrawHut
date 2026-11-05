import 'package:flutter/material.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/core/passphrase_vault/passphrase_entry.dart';
import 'package:strawhut/l10n/l10n.dart';
import 'package:strawhut/presentation/dialogs/passphrase_vault_dialog/widgets/vault_styles.dart';
import 'package:strawhut/presentation/widgets/neumorphic_button.dart';
import 'package:strawhut/presentation/widgets/neumorphic_container.dart';
import 'package:strawhut/presentation/widgets/neumorphic_icon.dart';

/// 暗号保险库条目卡片组件
///
/// 展示单条暗号条目的信息，包括：
/// - 色调锁图标徽标 + 备注名称（标题）
/// - 创建时间（副标题，格式 YYYY-MM-DD HH:mm）
/// - 暗号内容（默认遮罩为 "********"，可通过眼睛图标切换显示）
/// - 删除按钮
///
/// 架构位置：应用层（Presentation Layer）→ 暗号保险库对话框子组件
class PassphraseEntryTile extends StatefulWidget {
  /// 创建暗号条目卡片实例
  ///
  /// 参数：
  /// - [entry]: 暗号条目数据
  /// - [onDelete]: 删除按钮回调，由父组件处理确认逻辑
  const PassphraseEntryTile({
    required this.entry,
    required this.onDelete,
    super.key,
  });

  /// 暗号条目数据
  final PassphraseEntry entry;

  /// 删除按钮回调
  ///
  /// 点击删除按钮时触发，由父组件负责显示确认对话框和执行删除操作。
  final VoidCallback onDelete;

  @override
  State<PassphraseEntryTile> createState() => _PassphraseEntryTileState();
}

class _PassphraseEntryTileState extends State<PassphraseEntryTile> {
  /// 暗号内容是否可见
  bool _isPassphraseVisible = false;

  /// 格式化 ISO 8601 时间字符串为 "YYYY-MM-DD HH:mm"
  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return '${dateTime.year}-'
          '${dateTime.month.toString().padLeft(2, '0')}-'
          '${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    } on Exception {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = NeumorphicTokens.ofContext(context);

    // 列表条目：圆角 16 的色调卡片（无投影），前导色调图标徽标
    return NeumorphicContainer(
      shape: NeumorphicShape.flat,
      color: tokens.surfaceContainerLowest,
      borderRadius: tokens.radiusMedium,
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 左侧色调锁图标
          TonalIconBadge(
            icon: StrawIcons.lock,
            background: tokens.secondaryContainer,
            foreground: tokens.onSecondaryContainer,
          ),
          const SizedBox(width: 12),

          // 中间内容区域
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 备注名称（标题）
                Text(
                  widget.entry.label,
                  style: TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // 创建时间（副标题）
                Text(
                  _formatDateTime(widget.entry.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: tokens.textSecondary,
                  ),
                ),

                // 暗号内容行
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isPassphraseVisible
                            ? widget.entry.passphrase
                            : '********',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          color: _isPassphraseVisible
                              ? tokens.textPrimary
                              : tokens.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // 眼睛切换图标（48×48 触摸目标）
                    NeumorphicIconButton(
                      icon: _isPassphraseVisible
                          ? StrawIcons.eye
                          : StrawIcons.eyeOff,
                      iconSize: 18,
                      color: tokens.textSecondary,
                      // 仅读屏朗读（不新增可见文字）
                      semanticLabel:
                          _isPassphraseVisible ? '隐藏暗号' : '显示暗号',
                      onPressed: () {
                        setState(() {
                          _isPassphraseVisible = !_isPassphraseVisible;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 右侧删除按钮（48×48 触摸目标）
          NeumorphicIconButton(
            icon: StrawIcons.trash,
            iconSize: 20,
            color: tokens.error,
            onPressed: widget.onDelete,
            tooltip: l10n.delete,
          ),
        ],
      ),
    );
  }
}
