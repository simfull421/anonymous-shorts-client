import 'package:flutter/material.dart';

/// 🎨 앱 전역 디자인 시스템 (CSS 파일 역할)
/// - 모든 화면에서 인라인 색상/스타일 대신 이 클래스를 참조
/// - MaterialApp.theme에 darkTheme를 주입하여 글로벌 적용
class AppTheme {
  // ─── 프리미엄 다크 팔레트 (Vibrant Dark) ───
  static const Color backgroundColor = Color(0xFF090616); // 심해 같은 깊은 다크
  static const Color surfaceColor = Color(0xFF140F27);
  static const Color cardColor = Color(0xFF1E1736); // 카드는 약간 띄워진 느낌
  static const Color inputColor = Color(0xFF261D42);
  
  // 네온 포인트 컬러 (Neon Accents)
  static const Color accentColor = Color(0xFF9D4EDD); // Vibrant Purple
  static const Color secondaryAccent = Color(0xFF00E5FF); // Neon Cyan

  // 상태별 색상
  static const Color activeColor = secondaryAccent;
  static const Color expiredColor = Color(0xFF616161);
  static const Color blindColor = Color(0xFFFF1744);

  // ─── Glassmorphism 스타일 ───
  // UI 컴포넌트에서 Container의 decoration으로 사용
  static final BoxDecoration glassDecoration = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 10,
        spreadRadius: 2,
      )
    ],
  );

  // ─── 글꼴 스타일 (Typography) ───
  static const TextStyle mainContentStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.35,
    letterSpacing: -0.5,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: Color(0xFFE0E0E0),
    height: 1.6,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 13,
    color: Color(0xFF9E9E9E),
    letterSpacing: 0.2,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontWeight: FontWeight.w600,
  );

  // ─── 버튼 스타일시트 ───
  static ButtonStyle voteButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white.withValues(alpha: 0.1),
    foregroundColor: Colors.white,
    shadowColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
    ),
  ).copyWith(
    overlayColor: WidgetStateProperty.all(accentColor.withValues(alpha: 0.2)),
  );

  static ButtonStyle submitButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: accentColor,
    foregroundColor: Colors.white,
    disabledBackgroundColor: cardColor,
    disabledForegroundColor: const Color(0xFF757575),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    elevation: 5,
    shadowColor: accentColor.withValues(alpha: 0.5),
  );

  static ButtonStyle reportButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: const Color(0xFFFF1744),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 0,
  );

  // ─── 글로벌 ThemeData ───
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundColor,

        colorScheme: const ColorScheme.dark(
          surface: backgroundColor,
          primary: accentColor,
          secondary: secondaryAccent,
        ),

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        // BottomNavigationBar (Glass 효과 적용을 위해 랩핑 필요, 여기선 기본 컬러만)
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: backgroundColor,
          selectedItemColor: accentColor,
          unselectedItemColor: Color(0xFF616161),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),

        // BottomSheet
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),

        // InputDecoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: inputColor,
          hintStyle: const TextStyle(color: Color(0xFF616161)),
          counterStyle: const TextStyle(color: Color(0xFFBDBDBD)),
          contentPadding: const EdgeInsets.all(20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: accentColor, width: 2),
          ),
        ),

        // 기본 텍스트 테마
        textTheme: const TextTheme(
          bodyLarge: bodyStyle,
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
          titleLarge: mainContentStyle,
        ),
      );
}
