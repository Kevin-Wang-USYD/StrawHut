import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/core/passphrase_vault/passphrase_entry.dart';
import 'package:strawhut/l10n/l10n.dart';
import 'package:strawhut/presentation/providers/passphrase_vault_provider.dart';
import 'package:strawhut/presentation/widgets/neumorphic_button.dart';
import 'package:strawhut/presentation/widgets/neumorphic_icon.dart';

/// 解密对话框 - 暗号输入组件
///
/// 提供暗号（passphrase）输入功能，用于协商密钥加密模式的解密流程。
///
/// 架构位置：应用层（Presentation Layer）→ 解密对话框子组件
/// 使用场景：DecryptDialog 中检测到协商密钥模式时显示
///
/// 功能：
/// - 暗号输入框（带密码可见性切换）
/// - 提示信息：此卡片通过暗号加密
/// - 提示文本：请与创作者确认暗号内容
///
/// 外部通过 `GlobalKey<PassphraseDecryptInputState>` 访问：
/// - passphrase: 获取当前暗号值（String?）
/// - clear(): 清空输入
class PassphraseDecryptInput extends ConsumerStatefulWidget {
  /// 创建解密暗号输入组件实例
  const PassphraseDecryptInput({
    super.key,
    this.enabled = true,
    this.onVaultSelectionChanged,
  });

  /// Whether selection and manual editing are enabled.
  final bool enabled;

  /// Reports whether a saved vault entry is currently selected.
  final ValueChanged<bool>? onVaultSelectionChanged;

  @override
  ConsumerState<PassphraseDecryptInput> createState() =>
      PassphraseDecryptInputState();
}

/// PassphraseDecryptInput 的公开状态类
///
/// 通过 GlobalKey 暴露给父组件，提供取值和清空功能。
class PassphraseDecryptInputState
    extends ConsumerState<PassphraseDecryptInput> {
  /// 暗号输入控制器
  final _controller = TextEditingController();

  /// 暗号是否可见
  bool _obscurePassphrase = true;

  PassphraseEntry? _selectedEntry;

  /// ID of the explicitly selected vault entry, if any.
  String? get selectedEntryId => _selectedEntry?.id;

  /// Whether the current value came from an explicit vault selection.
  bool get isFromVault => _selectedEntry != null;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    final selectedEntry = _selectedEntry;
    if (selectedEntry != null && _controller.text != selectedEntry.passphrase) {
      setState(() {
        _selectedEntry = null;
      });
      widget.onVaultSelectionChanged?.call(false);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    super.dispose();
  }

  /// 获取当前暗号值
  ///
  /// 返回：当前文本框中的暗号字符串（已 trim），如果为空则返回 null
  String? get passphrase {
    final text = _controller.text.trim();
    return text.isEmpty ? null : text;
  }

  /// 清空输入
  void clear() {
    _controller.clear();
    _selectedEntry = null;
  }

  void _selectEntry(PassphraseEntry entry) {
    setState(() {
      _selectedEntry = entry;
      _controller.text = entry.passphrase;
      _obscurePassphrase = true;
    });
    widget.onVaultSelectionChanged?.call(true);
  }

  Future<void> _showVaultPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final entriesAsync = ref.read(passphraseEntriesProvider);
    final entries = entriesAsync.when(
      data: (data) => data,
      loading: () => <PassphraseEntry>[],
      error: (_, __) => <PassphraseEntry>[],
    );

    if (entries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.vaultEmptySelectHint)));
      }
      return;
    }

    final PassphraseEntry? selected;
    if (defaultTargetPlatform == TargetPlatform.android) {
      selected = await showModalBottomSheet<PassphraseEntry>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        builder: (context) => _buildVaultBottomSheet(context, entries, l10n),
      );
    } else {
      selected = await showDialog<PassphraseEntry>(
        context: context,
        builder: (context) => _buildVaultDialog(context, entries, l10n),
      );
    }

    if (selected != null && mounted) {
      _selectEntry(selected);
    }
  }

  /// 保险库条目：tonal 圆角行，整行可点（≥ 48 高）
  Widget _buildVaultEntryTile(
    BuildContext context,
    PassphraseEntry entry,
    AppLocalizations l10n,
  ) {
    final tokens = NeumorphicTokens.ofContext(context);
    final radius = BorderRadius.circular(tokens.radiusMedium);
    return Material(
      color: tokens.surfaceContainerLow,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pop(context, entry),
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tokens.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: NeumorphicIcon(
                    StrawIcons.lock,
                    size: 18,
                    color: tokens.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.label,
                        style: TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                      Text(
                        l10n.usedCount(entry.useCount),
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 选择器标题行：tonal 圆形图标 + w700 标题
  Widget _buildPickerTitle(BuildContext context, AppLocalizations l10n) {
    final tokens = NeumorphicTokens.ofContext(context);
    return Row(
      children: [
        NeumorphicIcon(
          StrawIcons.lock,
          size: 22,
          color: tokens.inkPrimary,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            l10n.selectPassphraseTitle,
            style: TextStyle(
              fontSize: 22,
              height: 28 / 22,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVaultDialog(
    BuildContext context,
    List<PassphraseEntry> entries,
    AppLocalizations l10n,
  ) {
    final tokens = NeumorphicTokens.ofContext(context);
    return Dialog(
      backgroundColor: tokens.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPickerTitle(context, l10n),
              SizedBox(height: tokens.spaceMd),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: _buildVaultEntryTile(context, entry, l10n),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVaultBottomSheet(
    BuildContext context,
    List<PassphraseEntry> entries,
    AppLocalizations l10n,
  ) {
    final tokens = NeumorphicTokens.ofContext(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // M3 拖拽指示条
          Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(top: 16, bottom: 8),
            decoration: BoxDecoration(
              color: tokens.textSecondary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: _buildPickerTitle(context, l10n),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _buildVaultEntryTile(context, entry, l10n),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 描边输入框边框：16 圆角
  OutlineInputBorder _outline(Color color, double width, NeumorphicTokens tokens) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.radiusMedium),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = NeumorphicTokens.ofContext(context);
    final entriesAsync = ref.watch(passphraseEntriesProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 从保险库选择按钮（缩窄、居中，适配文字长度；tonal 药丸）
        Center(
          child: entriesAsync.when(
            data: (entries) => NeumorphicButton(
              label: l10n.selectFromVault,
              icon: StrawIcons.password,
              onPressed: widget.enabled && entries.isNotEmpty
                  ? () => _showVaultPicker(context)
                  : null,
            ),
            loading: () => NeumorphicButton(
              label: l10n.selectFromVault,
              icon: StrawIcons.password,
            ),
            error: (_, __) => NeumorphicButton(
              label: l10n.selectFromVault,
              icon: StrawIcons.password,
            ),
          ),
        ),

        if (_selectedEntry != null) ...[
          const SizedBox(height: 8),
          // 已选保险库条目：secondaryContainer 选中态 chip（10 圆角）
          InputChip(
            avatar: NeumorphicIcon(
              StrawIcons.lock,
              size: 18,
              color: tokens.onSecondaryContainer,
            ),
            label: Text(_selectedEntry!.label),
            backgroundColor: tokens.secondaryContainer,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            labelStyle: TextStyle(
              color: tokens.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
            deleteIconColor: tokens.onSecondaryContainer,
            onDeleted: widget.enabled
                ? () {
                    setState(() {
                      _selectedEntry = null;
                      _controller.clear();
                    });
                    widget.onVaultSelectionChanged?.call(false);
                  }
                : null,
          ),
          SizedBox(height: tokens.spaceSm),
        ] else ...[
          SizedBox(height: tokens.spaceMd),
        ],

        // 暗号输入框：M3 描边输入框（1px outline，聚焦 2px primary）
        TextField(
          controller: _controller,
          enabled: widget.enabled,
          obscureText: _obscurePassphrase,
          decoration: InputDecoration(
            labelText: l10n.decryptPassphraseLabel,
            labelStyle: TextStyle(color: tokens.textSecondary),
            hintText: l10n.decryptPassphraseHint,
            hintStyle: TextStyle(color: tokens.textSecondary),
            border: _outline(tokens.outline, 1, tokens),
            enabledBorder: _outline(tokens.outline, 1, tokens),
            focusedBorder: _outline(tokens.inkPrimary, 2, tokens),
            disabledBorder: _outline(
              tokens.textPrimary.withValues(alpha: 0.12),
              1,
              tokens,
            ),
            filled: false,
            prefixIcon: NeumorphicIcon(
              StrawIcons.lock,
              size: 20,
              color: tokens.textSecondary,
            ),
            suffixIcon: IconButton(
              // 仅读屏朗读（不新增可见文字）
              icon: Semantics(
                label: _obscurePassphrase ? '显示暗号' : '隐藏暗号',
                child: NeumorphicIcon(
                  _obscurePassphrase ? StrawIcons.eyeOff : StrawIcons.eye,
                  size: 20,
                  color: tokens.textSecondary,
                ),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassphrase = !_obscurePassphrase;
                });
              },
            ),
          ),
          style: TextStyle(color: tokens.textPrimary),
          cursorColor: tokens.inkPrimary,
        ),
        SizedBox(height: tokens.spaceSm),

        // 提示信息：此卡片通过暗号加密（tonal secondaryContainer 提示块）
        DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.secondaryContainer,
            borderRadius: BorderRadius.circular(tokens.radiusMedium),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeumorphicIcon(
                  StrawIcons.lock,
                  size: 18,
                  color: tokens.onSecondaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.decryptPassphraseInfo,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: tokens.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
