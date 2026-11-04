import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strawhut/core/crypto/crypto_models.dart';
import 'package:strawhut/core/crypto/crypto_service.dart';
import 'package:strawhut/core/file_io/file_io_service.dart';
import 'package:strawhut/core/integrity/integrity_service.dart';
import 'package:strawhut/l10n/l10n.dart';
import 'package:strawhut/presentation/dialogs/publish_dialog/publish_dialog.dart';
import 'package:strawhut/presentation/providers/crypto_provider.dart';
import 'package:strawhut/presentation/providers/editor_provider.dart';

class _MockCryptoService extends Mock implements ICryptoService {}

class _MockFileIOService extends Mock implements FileIOService {}

class _MockIntegrityService extends Mock implements IntegrityService {}

/// 回归测试：安卓端发布页是全屏 MaterialPageRoute，发布进行中按系统返回键
/// 曾直接关闭页面 —— 加密阶段会对已销毁的 State 调用 setState，保存阶段
/// 则可能在随机密钥模式下"文件已保存但密钥从未展示"。
void main() {
  testWidgets(
    'system back while publishing cancels instead of closing',
    (tester) async {
      final crypto = _MockCryptoService();
      // 让发布停在"加载中"：生成密钥的 Future 永不完成
      final pendingKey = Completer<GeneratedKey>();
      when(crypto.generateKey).thenAnswer((_) => pendingKey.future);
      when(crypto.clearSensitiveData).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          cryptoServiceProvider.overrideWith((ref) => crypto),
          fileIOServiceProvider.overrideWith((ref) => _MockFileIOService()),
          integrityServiceProvider
              .overrideWith((ref) => _MockIntegrityService()),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(editorContentProvider.notifier)
          .updateContent(r'[{"insert":"hello\n"}]');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => PublishDialog.show(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('发布知识卡片'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, '卡片标题'),
        'title',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '发布者代号'),
        'alias',
      );
      await tester.ensureVisible(find.text('生成并加密'));
      await tester.tap(find.text('生成并加密'));
      await tester.pump();
      verify(crypto.generateKey).called(1);

      // 发布进行中：系统返回键不应关闭页面
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('发布知识卡片'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 结束挂起的操作，避免测试结束时仍有未完成的 Future
      pendingKey.completeError(Exception('stop'));
      await tester.pumpAndSettle();
      expect(find.text('发布知识卡片'), findsOneWidget);

      // 发布结束后，返回键恢复正常关闭
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('发布知识卡片'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
