import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/presentation/widgets/loading_indicator.dart';
import 'package:video_player/video_player.dart';

/// 视频播放器组件
///
/// 用于播放解密后的视频文件。
///
/// 架构位置：应用层（Presentation Layer）-> 阅读器子组件
/// 使用场景：ReaderScreen 解密成功后，内容类型为 video 时展示
///
/// 核心功能：
/// - 使用 video_player 包播放视频
/// - 提供播放/暂停控制
/// - 视频文件通过临时文件路径加载
class VideoPlayerWidget extends StatefulWidget {
  /// 创建视频播放器组件实例
  ///
  /// 参数：
  /// - [filePath] - 临时视频文件路径，必填
  const VideoPlayerWidget({
    required this.filePath,
    super.key,
  });

  /// 临时视频文件路径
  final String filePath;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final VideoPlayerController _controller;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    _controller = VideoPlayerController.file(File(widget.filePath));

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        unawaited(_controller.setLooping(true));
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '视频加载失败：$e';
        });
      }
    }

    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = NeumorphicTokens.ofContext(context);
    final timeStyle = TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: tokens.textSecondary,
    );
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

    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const StrawLoadingIndicator(),
            const SizedBox(height: 16),
            Text(
              '正在加载视频...',
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w700,
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 视频画面
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radiusLarge),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      // 播放/暂停指示器
                      if (!_controller.value.isPlaying)
                        Container(
                          decoration: BoxDecoration(
                            color:
                                tokens.inverseSurface.withValues(alpha: 0.72),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Icon(
                            Icons.play_arrow,
                            color: tokens.onInverseSurface,
                            size: 48,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // 进度条和控制区
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // 进度条
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                colors: VideoProgressColors(
                  playedColor: tokens.inkPrimary,
                  bufferedColor: tokens.inkPrimary.withValues(alpha: 0.3),
                  backgroundColor: tokens.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),

              // 控制按钮
              Row(
                children: [
                  // 播放/暂停按钮
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    iconSize: 28,
                    tooltip: _controller.value.isPlaying ? '暂停' : '播放',
                    style: IconButton.styleFrom(
                      backgroundColor: tokens.secondaryContainer,
                      foregroundColor: tokens.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 时间显示
                  Text(
                    '${_formatDuration(_controller.value.position)} / '
                    '${_formatDuration(_controller.value.duration)}',
                    style: timeStyle,
                  ),

                  const Spacer(),

                  // 音量/全屏等可扩展按钮位置
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
