import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:strawhut/core/passphrase_vault/passphrase_entry.dart';
import 'package:strawhut/core/passphrase_vault/passphrase_vault_service.dart';
import 'package:strawhut/presentation/providers/passphrase_vault_provider.dart';

void main() {
  group('passphraseVaultServiceProvider', () {
    test('应返回 PassphraseVaultService 实例', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(passphraseVaultServiceProvider);

      expect(result, isA<PassphraseVaultService>());
    });

    test('多次读取应返回同一个实例（单例）', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final instance1 = container.read(passphraseVaultServiceProvider);
      final instance2 = container.read(passphraseVaultServiceProvider);

      expect(identical(instance1, instance2), isTrue);
    });

    // 回归测试：autoDispose 时，无人 watch 的 provider 会在读取后被释放，
    // 下次 ref.read 得到新实例（各自持有独立的互斥锁），并发写可能互相覆盖。
    test('无人监听时跨事件循环读取仍为同一实例（锁全局生效）', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final instance1 = container.read(passphraseVaultServiceProvider);
      // 让 autoDispose 有机会生效
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final instance2 = container.read(passphraseVaultServiceProvider);

      expect(identical(instance1, instance2), isTrue);
    });
  });

  group('passphraseEntriesProvider', () {
    test('应返回 Future<List<PassphraseEntry>>', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final asyncValue = container.read(passphraseEntriesProvider);

      // 初始状态应该是 AsyncLoading 或 AsyncData
      expect(asyncValue, isA<AsyncValue<List<PassphraseEntry>>>());
    });
  });
}
