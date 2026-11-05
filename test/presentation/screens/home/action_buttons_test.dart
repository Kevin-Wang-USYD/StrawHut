import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strawhut/app/routes.dart';
import 'package:strawhut/presentation/screens/home/widgets/action_buttons.dart';
import 'package:strawhut/presentation/widgets/neumorphic_icon.dart';

/// 操作按钮 Widget 单元测试
///
/// 测试目标：验证 ActionButtons 的按钮点击行为是否符合任务 3.3 验收标准
/// 覆盖范围：
/// - "发布知识卡片" / "解密知识卡片" 使用 ActionTile 两列操作卡
/// - 按钮点击后触发正确的导航
/// - 布局结构正确（两列并排、等高、间距、窄屏不溢出）
/// - 语义：每张卡片是一个带标题的按钮
void main() {
  /// 在每个测试前重置路由到初始状态
  ///
  /// 因为 appRouter 是全局单例，测试之间会共享状态，
  /// 所以每次测试前都需要重置路由到首页。
  setUp(() {
    appRouter.go('/');
  });

  /// 构建带路由的测试 Widget
  ///
  /// 此辅助方法创建一个包含完整路由配置的 MaterialApp，
  /// 并将 ActionButtons 作为 body 内容，用于测试按钮交互。
  /// 使用 ProviderScope 包裹以支持 EditorScreen 中的 Riverpod 依赖。
  Widget createTestableWidget() {
    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: appRouter,
        localizationsDelegates: const [
          FlutterQuillLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }

  group('ActionButtons 按钮样式测试', () {
    testWidgets('"发布知识卡片"应为 ActionTile 操作卡', (WidgetTester tester) async {
      // 构建包含 ActionButtons 的测试 Widget
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // 查找"发布知识卡片"文字
      final createButton = find.text('发布知识卡片');
      expect(createButton, findsOneWidget);

      // 验证该文字在 ActionTile 内部
      expect(
        find.descendant(
          of: find.byType(ActionTile),
          matching: find.text('发布知识卡片'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('"解密知识卡片"应为 ActionTile 操作卡', (WidgetTester tester) async {
      // 构建包含 ActionButtons 的测试 Widget
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // 查找"解密知识卡片"文字
      final openButton = find.text('解密知识卡片');
      expect(openButton, findsOneWidget);

      // 验证该文字在 ActionTile 内部
      expect(
        find.descendant(
          of: find.byType(ActionTile),
          matching: find.text('解密知识卡片'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('"发布知识卡片"按钮应包含 NeumorphicIcon 图标',
        (WidgetTester tester) async {
      // 构建包含 ActionButtons 的测试 Widget
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // 验证按钮图标存在（NeumorphicIcon 渲染 SVG 图标）
      expect(
        find.descendant(
          of: find.widgetWithText(ActionTile, '发布知识卡片'),
          matching: find.byType(NeumorphicIcon),
        ),
        findsOneWidget,
      );
    });

    testWidgets('"解密知识卡片"按钮应包含 NeumorphicIcon 图标',
        (WidgetTester tester) async {
      // 构建包含 ActionButtons 的测试 Widget
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // 验证按钮图标存在（NeumorphicIcon 渲染 SVG 图标）
      expect(
        find.descendant(
          of: find.widgetWithText(ActionTile, '解密知识卡片'),
          matching: find.byType(NeumorphicIcon),
        ),
        findsOneWidget,
      );
    });

    testWidgets('按钮应使用 icon 和 label 的排列方式', (WidgetTester tester) async {
      // 构建包含 ActionButtons 的测试 Widget
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // 验证使用了两张 ActionTile
      expect(find.byType(ActionTile), findsNWidgets(2));
    });
  });

  group('ActionButtons 布局结构测试', () {
    testWidgets('两张操作卡应左右并排（发布在左，解密在右，顶部对齐）',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      final createRect = tester.getRect(find.widgetWithText(ActionTile, '发布知识卡片'));
      final openRect = tester.getRect(find.widgetWithText(ActionTile, '解密知识卡片'));

      expect(openRect.left, greaterThan(createRect.right));
      expect(openRect.top, moreOrLessEquals(createRect.top));
    });

    testWidgets('两张操作卡应等高、等宽，且最小高度 120', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      final createRect = tester.getRect(find.widgetWithText(ActionTile, '发布知识卡片'));
      final openRect = tester.getRect(find.widgetWithText(ActionTile, '解密知识卡片'));

      expect(openRect.height, moreOrLessEquals(createRect.height));
      expect(openRect.width, moreOrLessEquals(createRect.width));
      expect(createRect.height, greaterThanOrEqualTo(120));
    });

    testWidgets('两张操作卡之间应有至少 12 的间距', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      final createRect = tester.getRect(find.widgetWithText(ActionTile, '发布知识卡片'));
      final openRect = tester.getRect(find.widgetWithText(ActionTile, '解密知识卡片'));

      expect(openRect.left - createRect.right, greaterThanOrEqualTo(12));
    });

    testWidgets('配色：发布为主入口（primary），解密为次入口（tertiary）',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      final createTile = tester.widget<ActionTile>(
        find.widgetWithText(ActionTile, '发布知识卡片'),
      );
      final openTile = tester.widget<ActionTile>(
        find.widgetWithText(ActionTile, '解密知识卡片'),
      );

      expect(createTile.tone, ActionTileTone.primary);
      expect(openTile.tone, ActionTileTone.tertiary);
    });

    testWidgets('窄屏（320 宽）下两列布局不溢出', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ActionTile), findsNWidgets(2));
    });

    testWidgets('语义：每张操作卡是一个带标题的按钮', (WidgetTester tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      for (final label in ['发布知识卡片', '解密知识卡片']) {
        // 标题与说明合并为同一个按钮节点，读屏先读标题
        final data =
            tester.getSemantics(find.widgetWithText(ActionTile, label)).getSemanticsData();
        expect(data.label, startsWith(label), reason: label);
        expect(data.flagsCollection.isButton, isTrue, reason: label);
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: label);
      }
      handle.dispose();
    });
  });

  group('ActionButtons 导航功能测试', () {
    testWidgets('点击"发布知识卡片"按钮应弹出内容来源选择对话框', (WidgetTester tester) async {
      // 构建包含 ActionButtons 的测试 Widget
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // 验证初始路由为首页
      expect(appRouter.routerDelegate.currentConfiguration.uri.path, '/');

      // 点击"发布知识卡片"按钮
      await tester.tap(find.text('发布知识卡片'));
      await tester.pumpAndSettle();

      // 验证弹出了选择对话框（包含"富文本编辑"和"直接加密文件"选项）
      expect(find.text('富文本编辑'), findsOneWidget);
      expect(find.text('直接加密文件'), findsOneWidget);
    });

    testWidgets('选择"富文本编辑"应导航到 /editor', (WidgetTester tester) async {
      // 构建包含 ActionButtons 的测试 Widget
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // 点击"发布知识卡片"按钮
      await tester.tap(find.text('发布知识卡片'));
      await tester.pumpAndSettle();

      // 点击"富文本编辑"按钮
      await tester.tap(find.text('富文本编辑'));
      await tester.pumpAndSettle();

      // 验证已导航到编辑器页面
      expect(appRouter.routerDelegate.currentConfiguration.uri.path, '/editor');
    });

    testWidgets('点击"解密知识卡片"按钮后取消选择应留在首页', (WidgetTester tester) async {
      // 构建包含 ActionButtons 的测试 Widget
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // 验证初始路由为首页
      expect(appRouter.routerDelegate.currentConfiguration.uri.path, '/');

      // 点击"解密知识卡片"按钮（会触发文件选择器，但测试中无法交互）
      // 在测试环境中，file_selector 的 openFile 会返回 null（模拟取消）
      await tester.tap(find.text('解密知识卡片'));
      await tester.pumpAndSettle();

      // 验证仍停留在首页
      expect(appRouter.routerDelegate.currentConfiguration.uri.path, '/');
    });
  });

  group('ActionButtons 按钮存在性测试', () {
    testWidgets('页面应显示"发布知识卡片"文字', (WidgetTester tester) async {
      // 构建包含 ActionButtons 的测试 Widget
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // 验证文字存在
      expect(find.text('发布知识卡片'), findsOneWidget);
    });

    testWidgets('页面应显示"解密知识卡片"文字', (WidgetTester tester) async {
      // 构建包含 ActionButtons 的测试 Widget
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // 验证文字存在
      expect(find.text('解密知识卡片'), findsOneWidget);
    });

    testWidgets('两个按钮都应可点击（onPressed 不为 null）', (WidgetTester tester) async {
      // 构建包含 ActionButtons 的测试 Widget
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // 获取"发布知识卡片"操作卡
      final firstButton = tester.widget<ActionTile>(
        find.widgetWithText(ActionTile, '发布知识卡片'),
      );

      // 获取"解密知识卡片"操作卡
      final secondButton = tester.widget<ActionTile>(
        find.widgetWithText(ActionTile, '解密知识卡片'),
      );

      // 验证 onPressed 不为 null
      expect(firstButton.onPressed, isNotNull);
      expect(secondButton.onPressed, isNotNull);
    });
  });
}
