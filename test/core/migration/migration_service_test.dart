import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:strawhut/core/crypto/crypto_constants.dart';
import 'package:strawhut/core/crypto/crypto_service.dart';
import 'package:strawhut/core/file_io/file_io_service.dart';
import 'package:strawhut/core/integrity/integrity_service.dart';
import 'package:strawhut/core/migration/migration_service.dart';
import 'package:strawhut/data/models/card_meta.dart';
import 'package:strawhut/data/models/integrity_info.dart';
import 'package:strawhut/data/models/straw_file.dart';

void main() {
  // 回归测试：迁移生成的是 v2.1 文件（AAD + format_version 2.1.0），
  // 解密对话框对 minor=1 的文件使用 HMAC-SHA256 校验完整性。
  // 迁移若写入无密钥 SHA-256，所有迁移后的卡片都会被判定为"文件可能被篡改"。
  test('migrated file passes the same v2.1 checks as the decrypt dialog',
      () async {
    final integrityService = IntegrityService();
    final cryptoService = CryptoService(integrityService);
    final fileIOService = FileIOService();
    final migrationService = MigrationService(
      cryptoService: cryptoService,
      integrityService: integrityService,
      fileIOService: fileIOService,
    );

    final key = Uint8List.fromList(List<int>.generate(32, (i) => i));
    const deltaJson = r'[{"insert":"迁移测试\n"}]';

    final dir = await Directory.systemTemp.createTemp('strawhut_migrate_');
    addTearDown(() => dir.delete(recursive: true));
    final outputPath = '${dir.path}/migrated.straw';

    final result = await migrationService.migrateFromDecryptedContent(
      deltaJson: deltaJson,
      meta: const CardMeta(
        publisherAlias: 'tester',
        publishDate: '2026-01-01T00:00:00Z',
        title: 'migration',
        isAnonymous: false,
      ),
      key: Uint8List.fromList(key),
      outputPath: outputPath,
    );
    expect(result.success, isTrue, reason: result.errorMessage);

    final parsed = await fileIOService.readStrawFile(outputPath);
    final strawFile = parsed.strawFile;
    expect(strawFile.formatVersion.minor, BINARY_FORMAT_MINOR_V21);
    expect(strawFile.integrity.hashAlgorithm, HASH_ALGORITHM_HMAC_SHA256);

    // 与 DecryptDialog 相同：minor=1 → v2.1 解密（AAD）
    final decrypted = await cryptoService.decrypt(
      chunks: parsed.chunks,
      key: Uint8List.fromList(key),
      chunkSize: strawFile.content.chunkSize,
      originalPayloadSize: strawFile.content.originalPayloadSize,
      useV21Security: true,
    );
    expect(utf8.decode(decrypted.payloadBytes), deltaJson);

    // 与 DecryptDialog 相同：hash='' 版本 + HMAC-SHA256
    final strawFileForHash = StrawFile(
      formatVersion: strawFile.formatVersion,
      meta: strawFile.meta,
      content: strawFile.content,
      integrity: IntegrityInfo(
        hash: '',
        hashAlgorithm: strawFile.integrity.hashAlgorithm,
      ),
    );
    final computed = await integrityService.computeHmacFromChunks(
      strawFile: strawFileForHash,
      chunks: parsed.chunks,
      hmacKey: cryptoService.deriveHmacKey(Uint8List.fromList(key)),
    );
    expect(computed, strawFile.integrity.hash);
  });
}
