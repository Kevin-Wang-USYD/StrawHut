import 'package:flutter/material.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/l10n/l10n.dart';
import 'package:strawhut/presentation/dialogs/publish_dialog/widgets/key_display.dart';
import 'package:strawhut/presentation/widgets/neumorphic_container.dart';
import 'package:strawhut/presentation/widgets/neumorphic_icon.dart';

/// Shared completion notices for desktop and Android publish flows.
///
/// Keeping format-specific and encryption-specific guidance in one widget
/// prevents `.straw` and `.png` completion screens from drifting apart.
class PublishSecurityNotices extends StatelessWidget {
  const PublishSecurityNotices({
    required this.exportFormat,
    required this.isNegotiated,
    this.keyBase64,
    super.key,
  }) : assert(
          isNegotiated || keyBase64 != null,
          'isNegotiated 或 keyBase64 至少需要一个',
        );

  final String exportFormat;
  final bool isNegotiated;
  final String? keyBase64;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = NeumorphicTokens.ofContext(context);
    // 警示色调块：warning 10% 叠加在 surfaceContainer 上，文字仍为 warning 色（≥ 4.5:1）
    final warningTone = Color.alphaBlend(
      tokens.warning.withValues(alpha: 0.10),
      tokens.surfaceAlt,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (exportFormat == 'png') ...[
          NeumorphicContainer(
            shape: NeumorphicShape.flat,
            color: warningTone,
            borderRadius: tokens.radiusMedium,
            padding: EdgeInsets.all(tokens.spaceSm + tokens.spaceXs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeumorphicIcon(
                  StrawIcons.info,
                  size: 18,
                  color: tokens.warning,
                ),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: Text(
                    l10n.shareAsOriginalImage,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: tokens.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.spaceMd),
        ],
        if (isNegotiated)
          NeumorphicContainer.large(
            shape: NeumorphicShape.flat,
            color: tokens.inkWash,
            padding: EdgeInsets.all(tokens.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NeumorphicIcon(
                      StrawIcons.publish,
                      size: 20,
                      color: tokens.onPrimaryContainer,
                    ),
                    SizedBox(width: tokens.spaceSm),
                    Expanded(
                      child: Text(
                        l10n.passphraseShareNote,
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          color: tokens.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: tokens.spaceSm + tokens.spaceXs),
                NeumorphicContainer(
                  shape: NeumorphicShape.flat,
                  color: tokens.surface,
                  borderRadius: tokens.radiusMedium,
                  padding: EdgeInsets.all(tokens.spaceSm + tokens.spaceXs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NeumorphicIcon(
                        StrawIcons.warning,
                        size: 20,
                        color: tokens.warning,
                      ),
                      SizedBox(width: tokens.spaceSm),
                      Expanded(
                        child: Text(
                          l10n.passphraseSecurityNote,
                          style: TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            color: tokens.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          KeyDisplay(keyBase64: keyBase64!),
      ],
    );
  }
}
