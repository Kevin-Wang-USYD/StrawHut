import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:strawhut/core/crypto/crypto_models.dart';
import 'package:strawhut/core/file_io/file_io_service.dart';
import 'package:strawhut/core/integrity/integrity_service.dart';
import 'package:strawhut/core/utils/cancellation_token.dart';
import 'package:strawhut/data/models/card_meta.dart';
import 'package:strawhut/data/models/format_version.dart';
import 'package:strawhut/data/models/integrity_info.dart';
import 'package:strawhut/data/models/straw_content.dart';
import 'package:strawhut/data/models/straw_file.dart';

void main() {
  const strawFile = StrawFile(
    formatVersion: FormatVersion(2, 0, 0),
    meta: CardMeta(
      publisherAlias: 'tester',
      publishDate: '2026-07-14T00:00:00Z',
      title: 'incremental hash',
      isAnonymous: false,
    ),
    content: StrawContent(
      encryptionAlgorithm: 'AES-256-GCM',
      chunkSize: 128,
      totalChunks: 2,
      originalPayloadSize: 100,
    ),
    integrity: IntegrityInfo(hash: '', hashAlgorithm: 'SHA-256'),
  );

  final chunks = <ChunkInfo>[
    ChunkInfo(iv: Uint8List(16), encryptedData: Uint8List.fromList([1, 2, 3])),
    ChunkInfo(
      iv: Uint8List.fromList(List<int>.filled(16, 4)),
      encryptedData: Uint8List.fromList([5, 6, 7, 8]),
    ),
  ];

  test('incremental chunk hash matches binary container hash', () async {
    final integrityService = IntegrityService();
    final binary = FileIOService().buildBinaryFileBytes(
      strawFile: strawFile,
      chunks: chunks,
    );

    final incremental = await integrityService.computeHashFromChunks(
      strawFile: strawFile,
      chunks: chunks,
    );

    expect(incremental, integrityService.computeHashFromBytes(binary));
  });

  // 回归测试：v1.2.0 及更早版本写入的 v2.0 文件，二进制头部 minor=0，
  // 完整性哈希也按 minor=0 计算。校验时必须使用文件自身的次版本号，
  // 否则所有旧文件都会被误判为"文件可能被篡改"。
  group('legacy v2.0 files (binary minor = 0)', () {
    Uint8List buildLegacyV20Bytes() {
      final builder = BytesBuilder()
        ..add(utf8.encode('STRAWHUT'))
        ..add([2, 0]) // major = 2 (uint16 LE)
        ..add([0, 0]); // minor = 0 (uint16 LE)
      final header = utf8.encode(strawFile.assembleHeaderToJson());
      final size = header.length;
      builder
        ..add([size & 0xFF, (size >> 8) & 0xFF, (size >> 16) & 0xFF, (size >> 24) & 0xFF])
        ..add(header);
      for (final chunk in chunks) {
        final len = chunk.encryptedData.length;
        builder
          ..add(chunk.iv)
          ..add([len & 0xFF, (len >> 8) & 0xFF, (len >> 16) & 0xFF, (len >> 24) & 0xFF])
          ..add(chunk.encryptedData);
      }
      return builder.toBytes();
    }

    test('writer emits minor = 0 for a v2.0 header', () {
      final binary = FileIOService().buildBinaryFileBytes(
        strawFile: strawFile,
        chunks: chunks,
      );
      expect(binary, buildLegacyV20Bytes());
    });

    test('chunk, streaming-sink and file hashes all match the legacy hash',
        () async {
      final integrityService = IntegrityService();
      final expected =
          integrityService.computeHashFromBytes(buildLegacyV20Bytes());

      final fromChunks = await integrityService.computeHashFromChunks(
        strawFile: strawFile,
        chunks: chunks,
      );
      expect(fromChunks, expected);

      final sink =
          integrityService.createIntegritySink(strawFileForHash: strawFile);
      for (final chunk in chunks) {
        final len = chunk.encryptedData.length;
        sink
          ..updateChunkIv(chunk.iv)
          ..updateChunkLength(
            [len & 0xFF, (len >> 8) & 0xFF, (len >> 16) & 0xFF, (len >> 24) & 0xFF],
          )
          ..updateChunkCipher(chunk.encryptedData);
      }
      expect(sink.finalize(), expected);

      final dir = await Directory.systemTemp.createTemp('strawhut_legacy_');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/legacy.straw');
      await file.writeAsBytes(buildLegacyV20Bytes());
      final fromFile = await integrityService.computeHashFromStrawFile(
        strawFile: strawFile,
        filePath: file.path,
      );
      expect(fromFile, expected);
    });
  });

  test('incremental chunk hash can be cancelled during verification', () async {
    final integrityService = IntegrityService();
    final token = CancellationToken();

    await expectLater(
      integrityService.computeHashFromChunks(
        strawFile: strawFile,
        chunks: chunks,
        cancellationToken: token,
        onProgress: (current, total) {
          if (current == 1) token.cancel();
        },
      ),
      throwsA(isA<OperationCancelledException>()),
    );
  });
}
