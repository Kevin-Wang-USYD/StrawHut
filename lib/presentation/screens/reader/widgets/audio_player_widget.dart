import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';
import 'package:strawhut/presentation/widgets/neumorphic_container.dart';

/// 音频播放器组件
///
/// 用于播放解密后的音频文件。
///
/// 架构位置：应用层（Presentation Layer）-> 阅读器子组件
/// 使用场景：ReaderScreen 解密成功后，内容类型为 audio 时展示
///
/// 核心功能：
/// - 使用 audioplayers 包播放音频
/// - 提供播放/暂停、进度条、时间显示
/// - 音频文件通过临时文件路径加载
class AudioPlayerWidget extends StatefulWidget {
  /// 创建音频播放器组件实例
  ///
  /// 参数：
  /// - [filePath] - 临时音频文件路径，必填
  const AudioPlayerWidget({
    required this.filePath,
    super.key,
  });

  /// 临时音频文件路径
  final String filePath;

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.setSourceDeviceFile(widget.filePath);

      _player.onDurationChanged.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });

      _player.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _player.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });

      _player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _position = Duration.zero;
            _isPlaying = false;
          });
        }
      });
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '音频加载失败：$e';
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        // 色调卡片（surfaceContainerLow，圆角 28）
        child: NeumorphicContainer(
          shape: NeumorphicShape.flat,
          color: tokens.surfaceContainerLow,
          borderRadius: tokens.radiusLarge,
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 音频图标（primaryContainer 圆形徽章）
                NeumorphicContainer(
                  shape: NeumorphicShape.flat,
                  color: tokens.inkWash,
                  borderRadius: 48,
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  padding: EdgeInsets.zero,
                  child: Icon(
                    Icons.audio_file_outlined,
                    size: 48,
                    color: tokens.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),

                // 进度条
                Slider(
                  value: _duration.inMilliseconds > 0
                      ? _position.inMilliseconds
                          .toDouble()
                          .clamp(0, _duration.inMilliseconds.toDouble())
                      : 0,
                  max: _duration.inMilliseconds.toDouble() > 0
                      ? _duration.inMilliseconds.toDouble()
                      : 1.0,
                  onChanged: (value) {
                    _player.seek(Duration(milliseconds: value.toInt()));
                  },
                ),

                // 时间显示
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: timeStyle,
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: timeStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 播放控制
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 后退 10 秒
                    IconButton(
                      onPressed: () {
                        final newPosition =
                            _position - const Duration(seconds: 10);
                        _player.seek(
                          newPosition < Duration.zero
                              ? Duration.zero
                              : newPosition,
                        );
                      },
                      icon: const Icon(Icons.replay_10),
                      iconSize: 28,
                      color: tokens.textSecondary,
                      tooltip: '后退 10 秒',
                    ),
                    const SizedBox(width: 16),

                    // 播放/暂停
                    IconButton.filled(
                      onPressed: () {
                        if (_isPlaying) {
                          _player.pause();
                        } else {
                          _player.resume();
                        }
                      },
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      iconSize: 36,
                      style: IconButton.styleFrom(
                        backgroundColor: tokens.inkPrimary,
                        foregroundColor: tokens.onPrimary,
                        minimumSize: const Size(64, 64),
                      ),
                      tooltip: _isPlaying ? '暂停' : '播放',
                    ),
                    const SizedBox(width: 16),

                    // 前进 10 秒
                    IconButton(
                      onPressed: () {
                        final newPosition =
                            _position + const Duration(seconds: 10);
                        _player.seek(
                          newPosition > _duration ? _duration : newPosition,
                        );
                      },
                      icon: const Icon(Icons.forward_10),
                      iconSize: 28,
                      color: tokens.textSecondary,
                      tooltip: '前进 10 秒',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
