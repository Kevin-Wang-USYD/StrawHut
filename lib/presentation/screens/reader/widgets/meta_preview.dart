import 'package:flutter/material.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/core/crypto/crypto_constants.dart';
import 'package:strawhut/data/models/card_meta.dart';
import 'package:strawhut/data/models/format_version.dart';
import 'package:strawhut/data/models/integrity_info.dart';
import 'package:strawhut/data/models/straw_content.dart';
import 'package:strawhut/data/models/straw_file.dart';
import 'package:strawhut/presentation/widgets/neumorphic_container.dart';
import 'package:strawhut/presentation/widgets/neumorphic_icon.dart';

/// 元数据预览组件
///
/// 在 ReaderScreen 中展示知识卡片的公开元数据（未解密即可见）。
///
/// 架构位置：应用层（Presentation Layer）-> 阅读器子组件
/// 使用场景：ReaderScreen 未解密状态时显示在页面上方
///
/// 显示内容：
/// - 卡片标题（大字号）
/// - 发布者代号
/// - 发布日期（格式化显示）
/// - 描述文本
/// - 标签列表（圆角 10 色调胶囊）
/// - 匿名标识（如果是匿名模式）
/// - 加密算法标识
///
/// 数据来源：StrawFile.meta（CardMeta 对象）
/// 展示时机：.straw 文件解析成功后、用户输入密钥前
class MetaPreview extends StatelessWidget {
  /// 创建元数据预览组件实例
  ///
  /// 参数：
  /// - [strawFile] - 知识卡片文件对象，用于提取元数据和加密算法信息
  const MetaPreview({required this.strawFile, super.key});

  /// 便捷构造方法：直接从 CardMeta 创建
  ///
  /// 用于仅需展示元数据、不需要加密算法信息的场景。
  factory MetaPreview.fromMeta(CardMeta meta) {
    // 创建一个仅包含元数据的 StrawFile 实例
    // 注意：此方法仅用于 UI 展示，不适用于加密/解密操作
    return MetaPreview(
      strawFile: StrawFile(
        formatVersion: const FormatVersion(1, 0, 0),
        meta: meta,
        content: const StrawContent(
          encryptionAlgorithm: ENCRYPTION_ALGORITHM_AES_256_GCM,
          chunkSize: DEFAULT_CHUNK_SIZE,
          totalChunks: 0,
          originalPayloadSize: 0,
        ),
        integrity: const IntegrityInfo(
          hash: '',
          hashAlgorithm: HASH_ALGORITHM_SHA256,
        ),
      ),
    );
  }

  /// 知识卡片文件对象
  final StrawFile strawFile;

  /// 获取关联的 CardMeta 对象
  CardMeta get meta => strawFile.meta;

  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    // 色调卡片（surfaceContainer，圆角 28，无双向阴影）
    return NeumorphicContainer(
      shape: NeumorphicShape.flat,
      borderRadius: tokens.radiusLarge,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== 卡片标题（表现力大标题） ==========
          Text(
            meta.title,
            style: TextStyle(
              fontSize: 28,
              height: 36 / 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // ========== 元数据胶囊：匿名 / 发布者 / 发布日期 ==========
          // OverflowBar：一行放得下时横排，否则逐个换行纵排（窄屏 / 大字号
          // 下避免 RenderFlex 溢出；不使用 Wrap，无标签时页面中不出现 Wrap）
          OverflowBar(
            spacing: 8,
            overflowSpacing: 8,
            alignment: MainAxisAlignment.start,
            overflowAlignment: OverflowBarAlignment.start,
            children: [
              // 匿名标识
              if (meta.isAnonymous) _buildAnonymousTag(tokens),
              // 发布者代号
              _buildMetaChip(
                tokens,
                icon: StrawIcons.person,
                iconSize: 16,
                label: meta.publisherAlias,
              ),
              // 发布日期
              _buildMetaChip(
                tokens,
                icon: StrawIcons.calendar,
                iconSize: 14,
                label: _formatDate(meta.publishDate),
              ),
            ],
          ),

          // ========== 描述文本 ==========
          if (meta.description != null && meta.description!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Divider(height: 1, color: tokens.divider),
            const SizedBox(height: 16),
            Text(
              meta.description!,
              style: TextStyle(
                fontSize: 16,
                height: 24 / 16,
                color: tokens.textSecondary,
              ),
            ),
          ],

          // ========== 标签列表（圆角 10 色调胶囊） ==========
          if (meta.tags.isNotEmpty) ...[
            const SizedBox(height: 20),
            Divider(height: 1, color: tokens.divider),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: meta.tags.map((tag) => _buildTag(tokens, tag)).toList(),
            ),
          ],

          // ========== 加密算法标识 ==========
          const SizedBox(height: 20),
          Divider(height: 1, color: tokens.divider),
          const SizedBox(height: 16),
          Row(
            children: [
              NeumorphicIcon(
                StrawIcons.lock,
                size: 16,
                color: tokens.inkPrimary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '加密算法：${strawFile.content.encryptionAlgorithm}',
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建元数据胶囊（圆角 10，outlineVariant 描边，透明底）
  Widget _buildMetaChip(
    NeumorphicTokens tokens, {
    required String icon,
    required double iconSize,
    required String label,
  }) {
    return NeumorphicContainer(
      shape: NeumorphicShape.flat,
      color: Colors.transparent,
      borderRadius: 10,
      border: Border.all(color: tokens.divider),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NeumorphicIcon(
            icon,
            size: iconSize,
            color: tokens.textSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w700,
                color: tokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建匿名标识胶囊
  ///
  /// 圆角 10、警示色描边与文字，透明底。
  Widget _buildAnonymousTag(NeumorphicTokens tokens) {
    return NeumorphicContainer(
      shape: NeumorphicShape.flat,
      color: Colors.transparent,
      borderRadius: 10,
      border: Border.all(color: tokens.warning),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NeumorphicIcon(
            StrawIcons.eyeOff,
            size: 14,
            color: tokens.warning,
          ),
          const SizedBox(width: 4),
          Text(
            '匿名',
            style: TextStyle(
              color: tokens.warning,
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标签胶囊
  ///
  /// 圆角 10，secondaryContainer 底、onSecondaryContainer 字。
  Widget _buildTag(NeumorphicTokens tokens, String tag) {
    return NeumorphicContainer(
      shape: NeumorphicShape.flat,
      color: tokens.secondaryContainer,
      borderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w700,
          color: tokens.onSecondaryContainer,
        ),
      ),
    );
  }

  /// 格式化 ISO 8601 日期字符串为可读格式
  ///
  /// 将 "2026-05-01T12:00:00Z" 格式化为 "2026-05-01"。
  /// 如果解析失败，返回原始字符串。
  String _formatDate(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate).toLocal();
      return '${dateTime.year}-'
          '${dateTime.month.toString().padLeft(2, '0')}-'
          '${dateTime.day.toString().padLeft(2, '0')}';
    } on Exception {
      return isoDate;
    }
  }
}
