// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'passphrase_vault_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$passphraseVaultServiceHash() =>
    r'600779e0ea2c1faf37e522da0e40d14e3cc99f47';

/// 暗号保险库服务 Provider
///
/// 提供全局单例的 PassphraseVaultService 实例，用于暗号的增删查操作。
///
/// 必须 keepAlive：服务内部的互斥锁只在同一实例内生效。若为 autoDispose，
/// 无人 watch 时每次 ref.read 都会创建新实例（各自持有独立的锁），
/// 并发的写操作可能互相覆盖保险库数据。
///
/// Copied from [passphraseVaultService].
@ProviderFor(passphraseVaultService)
final passphraseVaultServiceProvider =
    Provider<PassphraseVaultService>.internal(
  passphraseVaultService,
  name: r'passphraseVaultServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$passphraseVaultServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PassphraseVaultServiceRef = ProviderRef<PassphraseVaultService>;
String _$passphraseEntriesHash() => r'd0fc19666c21feaf7d193b022040d7075375ae17';

/// 暗号保险库条目列表 Provider
///
/// 监听保险库数据变化，自动刷新 UI。
/// 返回按创建时间倒序排列的暗号条目列表。
///
/// Copied from [passphraseEntries].
@ProviderFor(passphraseEntries)
final passphraseEntriesProvider =
    AutoDisposeFutureProvider<List<PassphraseEntry>>.internal(
  passphraseEntries,
  name: r'passphraseEntriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$passphraseEntriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PassphraseEntriesRef
    = AutoDisposeFutureProviderRef<List<PassphraseEntry>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
