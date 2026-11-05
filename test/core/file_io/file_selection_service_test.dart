import 'package:flutter_test/flutter_test.dart';
import 'package:strawhut/core/file_io/file_selection_service.dart';

void main() {
  group('FileSelectionService.sanitizeFileName', () {
    test('普通文件名保持不变', () {
      expect(FileSelectionService.sanitizeFileName('报告 v2.pdf'), '报告 v2.pdf');
      expect(FileSelectionService.sanitizeFileName('.bashrc'), '.bashrc');
    });

    test('路径穿越只保留最后一段', () {
      expect(
        FileSelectionService.sanitizeFileName(
          '../../../../data/data/com.strawhut.strawhut/shared_prefs/x.xml',
        ),
        'x.xml',
      );
      expect(
        FileSelectionService.sanitizeFileName(r'..\..\Startup\a.bat'),
        'a.bat',
      );
    });

    test('空名、. 和 .. 回退为 untitled', () {
      for (final name in ['', '.', '..', 'dir/', '../', ' \n']) {
        expect(
          FileSelectionService.sanitizeFileName(name),
          'untitled',
          reason: name,
        );
      }
    });

    test('去除控制字符', () {
      expect(FileSelectionService.sanitizeFileName('a\u0000b\nc.txt'), 'abc.txt');
    });
  });
}
