import 'package:flutter/material.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/presentation/widgets/neumorphic_icon.dart';

/// 色调图标徽标（M3 Expressive）
///
/// 圆形色调底 + 居中描线图标，用于对话框标题前缀和列表条目的前导图标。
/// 颜色由调用方从 [NeumorphicTokens] 中成对传入（容器色 + on 容器色），
/// 例如 primaryContainer / onPrimaryContainer、errorContainer / onErrorContainer。
class TonalIconBadge extends StatelessWidget {
  /// 创建色调图标徽标
  const TonalIconBadge({
    required this.icon,
    required this.background,
    required this.foreground,
    super.key,
    this.size = 40,
    this.iconSize = 20,
  });

  /// 图标 SVG body（[StrawIcons] 中的常量）
  final String icon;

  /// 徽标底色（容器色）
  final Color background;

  /// 图标颜色（on 容器色）
  final Color foreground;

  /// 徽标直径
  final double size;

  /// 图标尺寸
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: NeumorphicIcon(icon, size: iconSize, color: foreground),
    );
  }
}

/// M3 描边输入框边框：圆角 16，1px outline；聚焦时 2px primary
OutlineInputBorder vaultOutlinedBorder(
  NeumorphicTokens tokens, {
  bool focused = false,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(tokens.radiusMedium),
    borderSide: BorderSide(
      color: focused ? tokens.inkPrimary : tokens.outline,
      width: focused ? 2 : 1,
    ),
  );
}
