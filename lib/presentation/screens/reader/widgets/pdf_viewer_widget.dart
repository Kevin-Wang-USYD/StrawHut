import 'dart:io';

import 'package:flutter/material.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/presentation/widgets/glass_surface.dart';
import 'package:strawhut/presentation/widgets/loading_indicator.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// PDF 查看器组件
///
/// 用于展示解密后的 PDF 文件。
///
/// 架构位置：应用层（Presentation Layer）-> 阅读器子组件
/// 使用场景：ReaderScreen 解密成功后，内容类型为 pdf 时展示
///
/// 核心功能：
/// - 使用 syncfusion_flutter_pdfviewer 渲染 PDF
/// - 支持页面滚动、缩放
/// - PDF 文件通过临时文件路径加载
class PdfViewerWidget extends StatefulWidget {
  /// 创建 PDF 查看器组件实例
  ///
  /// 参数：
  /// - [filePath] - 临时 PDF 文件路径，必填
  const PdfViewerWidget({
    required this.filePath,
    super.key,
  });

  /// 临时 PDF 文件路径
  final String filePath;

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  late final PdfViewerController _controller;
  String? _errorMessage;
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: tokens.error,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // PDF 查看器
        SfPdfViewer.file(
          File(widget.filePath),
          controller: _controller,
          onDocumentLoaded: (details) {
            setState(() {
              _isLoading = false;
              _totalPages = details.document.pages.count;
            });
          },
          onPageChanged: (details) {
            setState(() {
              _currentPage = details.newPageNumber;
            });
          },
          onDocumentLoadFailed: (details) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'PDF 加载失败：${details.error}';
            });
          },
        ),

        // 加载指示器
        if (_isLoading)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const StrawLoadingIndicator(),
                const SizedBox(height: 16),
                Text(
                  '正在加载 PDF...',
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w700,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),

        // 页码指示器（浮动玻璃胶囊）
        if (!_isLoading && _totalPages > 0)
          Positioned(
            bottom: 16,
            right: 16,
            child: GlassSurface(
              strong: true,
              borderRadius: BorderRadius.circular(999),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                '$_currentPage / $_totalPages',
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
