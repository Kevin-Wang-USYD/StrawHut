import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:strawhut/app/motion.dart';
import 'package:strawhut/app/neumorphic_tokens.dart';

/// 应用主题配置（Material 3 Expressive · 稻草琥珀色调）
///
/// 基于 [NeumorphicTokens] 构建亮/暗主题方案，ColorScheme 的所有角色
/// （含 surfaceContainer* 系列）都来自令牌，因此 SnackBar、Switch、Checkbox、
/// TextField、Dialog、BottomSheet、ProgressIndicator 等原生组件开箱即合品牌。
///
/// 设计特点：
/// - 形状：按钮全药丸、输入框 16、卡片 28、底部面板/对话框 32、标签 10
/// - 字体：用字重表达层级（display/headline w800，title/label w700）
/// - 动效：页面切换使用 [StrawPageTransitionsBuilder]（淡入 + 上浮）
/// - 保留跨平台中文字体回退链（系统字体，零网络）
///
/// 字体配置：
/// - Windows：Microsoft YaHei（微软雅黑）
/// - macOS / iOS：PingFang SC（苹方-简）
/// - Android：Noto Sans CJK SC（思源黑体）
/// - Linux：Noto Sans CJK SC
///
/// 使用示例：
/// ```dart
/// MaterialApp(
///   theme: AppTheme.lightTheme,
///   darkTheme: AppTheme.darkTheme,
///   themeMode: ThemeMode.system,
/// )
/// ```
class AppTheme {
  AppTheme._();

  /// Windows 平台默认中文字体
  static const String _windowsFont = 'Microsoft YaHei';

  /// macOS / iOS 平台默认中文字体
  static const String _appleFont = 'PingFang SC';

  /// Android 平台默认中文字体
  static const String _androidFont = 'Noto Sans CJK SC';

  /// Linux 平台默认中文字体
  static const String _linuxFont = 'Noto Sans CJK SC';

  /// 根据运行平台返回最合适的中文字体
  static String get _platformFont {
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return _windowsFont;
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
        return _appleFont;
      case TargetPlatform.android:
        return _androidFont;
      case TargetPlatform.linux:
        return _linuxFont;
      case TargetPlatform.fuchsia:
        return _appleFont;
    }
  }

  /// 构建字体回退列表
  static List<String> get _fontFallbacks {
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return [_windowsFont, _appleFont, _linuxFont];
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
        return [_appleFont, _windowsFont, _androidFont];
      case TargetPlatform.android:
        return [_androidFont, _appleFont, _windowsFont];
      case TargetPlatform.linux:
        return [_linuxFont, _appleFont, _windowsFont];
      case TargetPlatform.fuchsia:
        return [_appleFont, _windowsFont];
    }
  }

  /// 创建包含所有字体的 TextStyle
  static TextStyle _fontStyle() => TextStyle(
        fontFamily: _fontFallbacks.first,
        fontFamilyFallback: _fontFallbacks.skip(1).toList(),
      );

  /// 构建完整的 M3 ColorScheme（所有角色均来自 [NeumorphicTokens]）
  static ColorScheme _colorScheme(NeumorphicTokens tokens) {
    return ColorScheme(
      brightness: tokens.brightness,
      primary: tokens.inkPrimary,
      onPrimary: tokens.onPrimary,
      primaryContainer: tokens.inkWash,
      onPrimaryContainer: tokens.onPrimaryContainer,
      secondary: tokens.inkSecondary,
      onSecondary: tokens.onSecondary,
      secondaryContainer: tokens.secondaryContainer,
      onSecondaryContainer: tokens.onSecondaryContainer,
      tertiary: tokens.success,
      onTertiary: tokens.onTertiary,
      tertiaryContainer: tokens.tertiaryContainer,
      onTertiaryContainer: tokens.onTertiaryContainer,
      error: tokens.error,
      onError: tokens.onError,
      errorContainer: tokens.errorContainer,
      onErrorContainer: tokens.onErrorContainer,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      surfaceDim: tokens.surfaceDim,
      surfaceBright: tokens.surfaceBright,
      surfaceContainerLowest: tokens.surfaceContainerLowest,
      surfaceContainerLow: tokens.surfaceContainerLow,
      surfaceContainer: tokens.surfaceAlt,
      surfaceContainerHigh: tokens.surfaceContainerHigh,
      surfaceContainerHighest: tokens.surfaceContainerHighest,
      onSurfaceVariant: tokens.textSecondary,
      outline: tokens.textHint,
      outlineVariant: tokens.divider,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: tokens.inverseSurface,
      onInverseSurface: tokens.onInverseSurface,
      inversePrimary: tokens.inversePrimary,
      surfaceTint: tokens.inkPrimary,
    );
  }

  /// 亮色主题
  static ThemeData get lightTheme => _buildTheme(NeumorphicTokens.light);

  /// 暗色主题
  static ThemeData get darkTheme => _buildTheme(NeumorphicTokens.dark);

  /// 页面切换：Android / Windows / Linux / Fuchsia 使用淡入上浮；
  /// iOS / macOS 保留 Cupertino 过渡，以保留系统的边缘滑动返回手势
  /// （减少动态效果开启时不做横滑）。
  static const PageTransitionsTheme _pageTransitionsTheme =
      PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: StrawPageTransitionsBuilder(),
      TargetPlatform.fuchsia: StrawPageTransitionsBuilder(),
      TargetPlatform.windows: StrawPageTransitionsBuilder(),
      TargetPlatform.linux: StrawPageTransitionsBuilder(),
      TargetPlatform.iOS: StrawCupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: StrawCupertinoPageTransitionsBuilder(),
    },
  );

  static ThemeData _buildTheme(NeumorphicTokens tokens) {
    final fontStyle = _fontStyle();
    final colorScheme = _colorScheme(tokens);
    final textTheme = _buildTextTheme(fontStyle, tokens);
    const pill = WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder());
    final labelStyle = WidgetStatePropertyAll<TextStyle?>(textTheme.labelLarge);
    const buttonMinSize = WidgetStatePropertyAll<Size>(Size(48, 48));
    const buttonPadding = WidgetStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    );
    final disabledBg = tokens.textPrimary.withValues(alpha: 0.12);
    final disabledFg = tokens.textPrimary.withValues(alpha: 0.38);

    Color? stateFg(Set<WidgetState> states, Color color) =>
        states.contains(WidgetState.disabled) ? disabledFg : color;

    return ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.surface,
      canvasColor: tokens.surface,
      fontFamily: _platformFont,
      fontFamilyFallback: _fontFallbacks.skip(1).toList(),
      textTheme: textTheme,
      pageTransitionsTheme: _pageTransitionsTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: tokens.textSecondary),
        actionsIconTheme: IconThemeData(color: tokens.textSecondary),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: tokens.surfaceAlt,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: tokens.textSecondary, size: 24),
      // 输入框：16 圆角描边；默认 1px outline，聚焦 2px primary
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: _outline(tokens.textHint, 1, tokens),
        enabledBorder: _outline(tokens.textHint, 1, tokens),
        focusedBorder: _outline(tokens.inkPrimary, 2, tokens),
        errorBorder: _outline(tokens.error, 1, tokens),
        focusedErrorBorder: _outline(tokens.error, 2, tokens),
        disabledBorder:
            _outline(tokens.textPrimary.withValues(alpha: 0.12), 1, tokens),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        // 占位提示属于文字：用 onSurfaceVariant 保证 ≥ 4.5:1 对比度
        hintStyle: fontStyle.copyWith(color: tokens.textSecondary),
        labelStyle: fontStyle.copyWith(color: tokens.textSecondary),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.error)) {
            return fontStyle.copyWith(color: tokens.error);
          }
          if (states.contains(WidgetState.focused)) {
            return fontStyle.copyWith(color: tokens.inkPrimary);
          }
          return fontStyle.copyWith(color: tokens.textSecondary);
        }),
        helperStyle: fontStyle.copyWith(
          color: tokens.textSecondary,
          fontSize: 12,
        ),
        errorStyle: fontStyle.copyWith(color: tokens.error, fontSize: 12),
        prefixIconColor: tokens.textSecondary,
        suffixIconColor: tokens.textSecondary,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: tokens.inkPrimary,
        selectionColor: tokens.inkPrimary.withValues(alpha: 0.28),
        selectionHandleColor: tokens.inkPrimary,
      ),
      // SnackBar：反色表面，非玻璃
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.inverseSurface,
        actionTextColor: tokens.inversePrimary,
        closeIconColor: tokens.onInverseSurface,
        contentTextStyle: fontStyle.copyWith(
          color: tokens.onInverseSurface,
          fontSize: 14,
          height: 20 / 14,
        ),
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surfaceContainerLow,
        modalBackgroundColor: tokens.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: tokens.textHint,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: fontStyle.copyWith(
          fontSize: 14,
          height: 20 / 14,
          color: tokens.textSecondary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: tokens.secondaryContainer,
        disabledColor: tokens.textPrimary.withValues(alpha: 0.12),
        checkmarkColor: tokens.onSecondaryContainer,
        deleteIconColor: tokens.textSecondary,
        labelStyle: textTheme.labelLarge?.copyWith(color: tokens.textSecondary),
        secondaryLabelStyle:
            textTheme.labelLarge?.copyWith(color: tokens.onSecondaryContainer),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const BorderSide(color: Colors.transparent);
          }
          return BorderSide(color: tokens.divider);
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return states.contains(WidgetState.selected)
                ? tokens.surface
                : disabledFg;
          }
          return states.contains(WidgetState.selected)
              ? tokens.onPrimary
              : tokens.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return disabledBg;
          return states.contains(WidgetState.selected)
              ? tokens.inkPrimary
              : tokens.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          if (states.contains(WidgetState.disabled)) return disabledBg;
          return tokens.textHint;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return states.contains(WidgetState.selected)
                ? disabledFg
                : Colors.transparent;
          }
          return states.contains(WidgetState.selected)
              ? tokens.inkPrimary
              : Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(tokens.onPrimary),
        side: BorderSide(color: tokens.textSecondary, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return disabledFg;
          return states.contains(WidgetState.selected)
              ? tokens.inkPrimary
              : tokens.textSecondary;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: tokens.inkPrimary,
        inactiveTrackColor: tokens.surfaceContainerHighest,
        thumbColor: tokens.inkPrimary,
        overlayColor: tokens.inkPrimary.withValues(alpha: 0.12),
      ),
      // 进度条：6px 圆角，primary 在 surfaceContainerHighest 轨道上
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.inkPrimary,
        linearTrackColor: tokens.surfaceContainerHighest,
        circularTrackColor: tokens.surfaceContainerHighest,
        linearMinHeight: 6,
        borderRadius: BorderRadius.circular(3),
        strokeCap: StrokeCap.round,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: tokens.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: fontStyle.copyWith(
          color: tokens.onInverseSurface,
          fontSize: 12,
          height: 16 / 12,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: tokens.surfaceAlt,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
        textStyle: textTheme.bodyLarge,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.textSecondary,
        textColor: tokens.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.inkWash,
        foregroundColor: tokens.onPrimaryContainer,
        elevation: 2,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: pill,
          textStyle: labelStyle,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? tokens.inkPrimary
                : Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return disabledFg;
            return states.contains(WidgetState.selected)
                ? tokens.onPrimary
                : tokens.textSecondary;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: tokens.textHint)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: tokens.inkPrimary,
        unselectedLabelColor: tokens.textSecondary,
        indicatorColor: tokens.inkPrimary,
        dividerColor: tokens.divider,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall,
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(8),
        thumbColor: WidgetStatePropertyAll(
          tokens.textHint.withValues(alpha: 0.6),
        ),
      ),
      // ============ 按钮：全部药丸形，最小 48 高 ============
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: pill,
          textStyle: labelStyle,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? disabledBg
                : tokens.inkPrimary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => stateFg(s, tokens.onPrimary),
          ),
          overlayColor: _overlay(tokens.onPrimary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: pill,
          textStyle: labelStyle,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          elevation: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return 0;
            if (s.contains(WidgetState.pressed)) return 1;
            if (s.contains(WidgetState.hovered)) return 3;
            return 1;
          }),
          shadowColor: const WidgetStatePropertyAll(Color(0xFF000000)),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? disabledBg
                : tokens.surfaceContainerLow,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => stateFg(s, tokens.inkPrimary),
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (s) => stateFg(s, tokens.inkPrimary),
          ),
          overlayColor: _overlay(tokens.inkPrimary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: pill,
          textStyle: labelStyle,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          side: WidgetStateProperty.resolveWith(
            (s) => BorderSide(
              color: s.contains(WidgetState.disabled)
                  ? disabledBg
                  : tokens.textHint,
            ),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => stateFg(s, tokens.inkPrimary),
          ),
          overlayColor: _overlay(tokens.inkPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: pill,
          textStyle: labelStyle,
          minimumSize: buttonMinSize,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => stateFg(s, tokens.inkPrimary),
          ),
          overlayColor: _overlay(tokens.inkPrimary),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(CircleBorder()),
          minimumSize: buttonMinSize,
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => stateFg(s, tokens.textSecondary),
          ),
          overlayColor: _overlay(tokens.textSecondary),
        ),
      ),
    );
  }

  /// 输入框描边
  static OutlineInputBorder _outline(
    Color color,
    double width,
    NeumorphicTokens tokens,
  ) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.radiusMedium),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// M3 状态层：悬停 8%、聚焦/按下 10%
  static WidgetStateProperty<Color?> _overlay(Color base) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return base.withValues(alpha: 0.10);
      }
      if (states.contains(WidgetState.focused)) {
        return base.withValues(alpha: 0.10);
      }
      if (states.contains(WidgetState.hovered)) {
        return base.withValues(alpha: 0.08);
      }
      return null;
    });
  }

  /// 构建文字主题
  ///
  /// 以字重表达层级：display/headline w800，title/label w700，body w400；
  /// ≥28px 的字号使用 -0.5 字距。
  static TextTheme _buildTextTheme(TextStyle base, NeumorphicTokens tokens) {
    TextStyle style(
      double size,
      double lineHeight,
      FontWeight weight,
      Color color,
    ) {
      return base.copyWith(
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        letterSpacing: size >= 28 ? -0.5 : 0,
        color: color,
      );
    }

    final on = tokens.textPrimary;
    final onVariant = tokens.textSecondary;
    return TextTheme(
      // Display（首页大标题）
      displayLarge: style(44, 50, FontWeight.w800, on),
      displayMedium: style(36, 44, FontWeight.w800, on),
      displaySmall: style(32, 40, FontWeight.w800, on),
      // Headline
      headlineLarge: style(32, 40, FontWeight.w800, on),
      headlineMedium: style(28, 36, FontWeight.w800, on),
      headlineSmall: style(24, 32, FontWeight.w800, on),
      // Title
      titleLarge: style(22, 28, FontWeight.w700, on),
      titleMedium: style(16, 24, FontWeight.w700, on),
      titleSmall: style(14, 20, FontWeight.w700, on),
      // Body
      bodyLarge: style(16, 24, FontWeight.w400, on),
      bodyMedium: style(14, 20, FontWeight.w400, on),
      bodySmall: style(12, 16, FontWeight.w400, onVariant),
      // Label
      labelLarge: style(14, 20, FontWeight.w700, on),
      labelMedium: style(12, 16, FontWeight.w700, onVariant),
      labelSmall: style(11, 16, FontWeight.w700, onVariant),
    );
  }
}
