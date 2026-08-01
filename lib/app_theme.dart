import 'package:flutter/material.dart';

import 'theme/app_palette.dart';
import 'theme/theme_controller.dart';

/// 🎨 앱 전역 디자인 시스템 (CSS 파일 역할)
/// - 모든 화면에서 인라인 색상/스타일 대신 이 클래스를 참조
/// - 값은 ThemeController가 들고 있는 현재 팔레트에서 읽어온다.
///   → const가 아니므로, 이 값을 쓰는 위젯에는 const를 붙일 수 없다.
class AppTheme {
  AppTheme._();

  static AppPalette get palette => ThemeController.palette.value;

  // ─── 표면 ───
  static Color get backgroundColor => palette.background;
  static Color get surfaceColor => palette.surface;
  static Color get cardColor => palette.card;
  static Color get inputColor => palette.input;

  // ─── 포인트 컬러 ───
  static Color get accentColor => palette.accent;
  static Color get secondaryAccent => palette.secondaryAccent;

  // ─── 텍스트 (진함 → 옅음) ───
  // 기존의 Colors.white / white70 / white54 / white38 / white24 를 대체한다.
  static Color get textPrimary => palette.textPrimary;
  static Color get textSecondary => palette.textSecondary;
  static Color get textTertiary => palette.textTertiary;
  static Color get textDisabled => palette.textDisabled;
  static Color get textFaint => palette.textFaint;

  // ─── 선·면 ───
  static Color get dividerColor => palette.divider;
  static Color get glassFill => palette.glassFill;
  static Color get glassBorder => palette.glassBorder;

  // ─── 의미 색(semantic) ───
  // 테마와 무관하게 뜻이 유지되어야 하는 색. 배경 명도에 맞춰 대비만 조정된다.
  static Color get successColor => palette.success;
  static Color get warningColor => palette.warning;
  static Color get dangerColor => palette.danger;

  // ─── 상태별 색상 ───
  static Color get activeColor => palette.success;
  static Color get expiredColor => palette.expired;
  static Color get blindColor => palette.danger;

  /// 라이트 테마 분기가 필요한 곳에서만 사용 (예: 그림자 세기, 이미지 반전)
  static bool get isDark => palette.isDark;

  // ─── Glassmorphism 스타일 ───
  static BoxDecoration get glassDecoration => BoxDecoration(
        color: palette.glassFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      );

  // ─── 글꼴 스타일 (Typography) ───
  static TextStyle get mainContentStyle => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: palette.textPrimary,
        height: 1.35,
        letterSpacing: -0.5,
      );

  static TextStyle get bodyStyle => TextStyle(
        fontSize: 16,
        color: palette.textSecondary,
        height: 1.6,
      );

  static TextStyle get captionStyle => TextStyle(
        fontSize: 13,
        color: palette.textTertiary,
        letterSpacing: 0.2,
      );

  static TextStyle get buttonTextStyle => TextStyle(
        fontSize: 16,
        // 버튼 텍스트는 대부분 채워진 accent 위에 놓인다
        color: Colors.white,
        fontWeight: FontWeight.w600,
      );

  // ─── 버튼 스타일시트 ───
  static ButtonStyle get voteButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: palette.glassFill,
        foregroundColor: palette.textPrimary,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: palette.glassBorder, width: 1),
        ),
      ).copyWith(
        overlayColor:
            WidgetStateProperty.all(palette.accent.withValues(alpha: 0.2)),
      );

  static ButtonStyle get submitButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: palette.accent,
        // 강조 버튼은 어느 테마에서도 채워진 보라 위 흰 글씨 — 대비 유지
        foregroundColor: Colors.white,
        disabledBackgroundColor: palette.isDark ? palette.card : palette.input,
        disabledForegroundColor: palette.textDisabled,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: palette.isDark ? 5 : 2,
        shadowColor: palette.accent.withValues(alpha: 0.5),
      );

  static ButtonStyle get reportButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.danger,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      );

  // ─── 글로벌 ThemeData ───
  /// 기존 이름 유지 (호출부 변경 최소화). 실제로는 현재 팔레트를 따른다.
  static ThemeData get darkTheme => themeData;

  static ThemeData get themeData {
    final p = palette;
    return ThemeData(
      brightness: p.brightness,
      scaffoldBackgroundColor: p.background,
      colorScheme: ColorScheme(
        brightness: p.brightness,
        primary: p.accent,
        onPrimary: Colors.white,
        secondary: p.secondaryAccent,
        onSecondary: p.isDark ? Colors.black : Colors.white,
        error: p.danger,
        onError: Colors.white,
        surface: p.surface,
        onSurface: p.textPrimary,
      ),
      dividerColor: p.divider,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: p.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.background,
        selectedItemColor: p.accent,
        unselectedItemColor: p.textDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // BottomSheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(backgroundColor: p.surface),

      // SnackBar — 배경과 반대 명도로 띄워야 읽힌다
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.isDark ? p.card : const Color(0xFF2B2536),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.input,
        hintStyle: TextStyle(color: p.textDisabled),
        counterStyle: TextStyle(color: p.textTertiary),
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: p.accent, width: 2),
        ),
      ),

      // 기본 텍스트 테마
      textTheme: TextTheme(
        bodyLarge: bodyStyle,
        bodyMedium: TextStyle(fontSize: 14, color: p.textSecondary),
        titleLarge: mainContentStyle,
      ),
    );
  }
}
