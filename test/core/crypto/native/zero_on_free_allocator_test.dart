import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strawhut/core/crypto/native/windows_crypto_ffi.dart';

/// 在真正释放前记录内存内容的底层分配器
class _RecordingAllocator implements Allocator {
  final List<List<int>> contentsAtFree = [];
  final Map<int, int> _sizes = {};

  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    final p = calloc.allocate<T>(byteCount, alignment: alignment);
    _sizes[p.address] = byteCount;
    return p;
  }

  @override
  void free(Pointer<NativeType> pointer) {
    final size = _sizes.remove(pointer.address)!;
    contentsAtFree.add(List<int>.of(pointer.cast<Uint8>().asTypedList(size)));
    calloc.free(pointer);
  }
}

/// 回归测试：Windows FFI 中存放密钥、暗号与明文的原生内存曾在释放前
/// 未清零，数据会原样留在原生堆中。
void main() {
  test('memory is zeroed before being returned to the backing allocator', () {
    final recorder = _RecordingAllocator();
    final allocator = ZeroOnFreeAllocator(recorder);

    final p = allocator<Uint8>(32);
    p.asTypedList(32).fillRange(0, 32, 0xAB);
    allocator.free(p);

    expect(recorder.contentsAtFree.single, List<int>.filled(32, 0));
  });

  test('Arena.releaseAll zeroes every allocation', () {
    final recorder = _RecordingAllocator();
    final arena = Arena(ZeroOnFreeAllocator(recorder));

    arena<Uint8>(16).asTypedList(16).fillRange(0, 16, 0x11);
    'secret passphrase'.toNativeUtf8(allocator: arena);
    arena.releaseAll();

    expect(recorder.contentsAtFree, hasLength(2));
    for (final contents in recorder.contentsAtFree) {
      expect(contents.every((b) => b == 0), isTrue);
    }
  });
}
