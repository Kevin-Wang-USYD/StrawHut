import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:strawhut/core/crypto/crypto_constants.dart';
import 'package:strawhut/core/crypto/native/native_crypto_service.dart';
import 'package:strawhut/core/crypto/native/platform_crypto_channel.dart';
import 'package:strawhut/core/errors/crypto_exception.dart';
import 'package:strawhut/core/integrity/integrity_service.dart';

/// 解析阶段不会调用原生通道；任何调用都说明长度校验没有先行生效
class _UnusedChannel implements PlatformCryptoChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('native channel must not be called');
}

/// 回归测试：NativeCryptoService.decryptStream（Android / Windows 默认实现）
/// 必须与 CryptoService.decryptStream 一样，在分配内存前拒绝超大的
/// 头部长度、分块数和分块密文长度，否则恶意 .straw 文件可导致 OOM 崩溃。
void main() {
  late Directory dir;
  late NativeCryptoService service;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('strawhut_native_bounds_');
    service = NativeCryptoService(IntegrityService(), _UnusedChannel());
  });

  tearDown(() => dir.delete(recursive: true));

  void writeUint32(BytesBuilder b, int v) =>
      b.add([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);

  Uint8List header({required int totalChunks}) => Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'content': {'total_chunks': totalChunks},
          }),
        ),
      );

  Future<String> writeFile({
    int? headerLengthOverride,
    int totalChunks = 1,
    int? chunkLength,
  }) async {
    final h = header(totalChunks: totalChunks);
    final b = BytesBuilder()
      ..add(STRAW_MAGIC_BYTES)
      ..add([2, 0, 1, 0]);
    writeUint32(b, headerLengthOverride ?? h.length);
    b.add(h);
    if (chunkLength != null) {
      b.add(Uint8List(CHUNK_IV_LENGTH_BYTES));
      writeUint32(b, chunkLength);
    }
    final path = '${dir.path}/evil.straw';
    await File(path).writeAsBytes(b.toBytes());
    return path;
  }

  Future<void> expectRejected(String path) => expectLater(
        service.decryptStream(
          strawFilePath: path,
          key: Uint8List(KEY_LENGTH_BYTES),
          targetPath: '${dir.path}/out.bin',
          chunkSize: DEFAULT_CHUNK_SIZE,
          originalPayloadSize: 1,
        ),
        throwsA(
          isA<CryptoException>()
              .having((e) => e.code, 'code', 'INVALID_FILE_FORMAT')
              .having((e) => e.message, 'message', contains('上限')),
        ),
      );

  test('rejects header length above MAX_HEADER_SIZE_BYTES', () async {
    await expectRejected(
      await writeFile(headerLengthOverride: MAX_HEADER_SIZE_BYTES + 1),
    );
  });

  test('rejects total_chunks outside 1..MAX_TOTAL_CHUNKS_LIMIT', () async {
    for (final n in [0, MAX_TOTAL_CHUNKS_LIMIT + 1]) {
      await expectLater(
        service.decryptStream(
          strawFilePath: await writeFile(totalChunks: n),
          key: Uint8List(KEY_LENGTH_BYTES),
          targetPath: '${dir.path}/out.bin',
          chunkSize: DEFAULT_CHUNK_SIZE,
          originalPayloadSize: 1,
        ),
        throwsA(
          isA<CryptoException>()
              .having((e) => e.message, 'message', contains('totalChunks')),
        ),
        reason: 'total_chunks = $n',
      );
    }
  });

  test('rejects chunk ciphertext length above MAX_CHUNK_CIPHERTEXT_BYTES',
      () async {
    // 0xFFFFFFF0 ≈ 4 GiB：修复前会直接尝试 raf.read() 这么多字节
    await expectRejected(await writeFile(chunkLength: 0xFFFFFFF0));
  });
}
