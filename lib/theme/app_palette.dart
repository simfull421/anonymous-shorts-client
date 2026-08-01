// 🎨 팔레트 정의
//
// 색상은 "무슨 색인가"가 아니라 "무슨 역할인가"로 이름을 붙인다.
// (Colors.white70 대신 textSecondary) — 그래야 라이트 테마에서 반전이 가능하다.
//
// 새 테마를 추가하려면 AppPalette 인스턴스를 하나 더 만들고
// AppPalettes.all 에 넣기만 하면 된다.
import 'package:flutter/material.dart';

enum AppThemeId { midnight, carbon, paper }

class AppPalette {
  final AppThemeId id;
  final String label; // 설정 화면 표시용
  final String description;
  final Brightness brightness;

  // 표면
  final Color background;
  final Color surface; // 바텀시트·다이얼로그
  final Color card;
  final Color input;

  // 포인트
  final Color accent;
  final Color secondaryAccent;

  // 텍스트 (진함 → 옅음)
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color textFaint;

  // 선·면
  final Color divider;
  final Color glassFill;
  final Color glassBorder;
  final Color shadow;

  // ── 의미 색(semantic) ──
  // 테마 색(배경·표면·텍스트)과 성격이 다르다.
  // 테마 색은 명도 체계라서 라이트/다크에서 반전되지만,
  // 의미 색은 "살아있음/주의/위험"이라는 뜻을 나르기 때문에
  // 색상(hue)을 유지한 채 대비만 조정한다. 회색으로 녹여버리면 안 된다.
  final Color success; // 정상·진행 중·여유 있음
  final Color warning; // 임박·주의
  final Color danger; // 위험·차단·삭제

  final Color expired;

  const AppPalette({
    required this.id,
    required this.label,
    required this.description,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.card,
    required this.input,
    required this.accent,
    required this.secondaryAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.textFaint,
    required this.divider,
    required this.glassFill,
    required this.glassBorder,
    required this.shadow,
    required this.success,
    required this.warning,
    required this.danger,
    required this.expired,
  });

  bool get isDark => brightness == Brightness.dark;
}

class AppPalettes {
  AppPalettes._();

  /// 기본 — 기존 Vibrant Dark. 출시 시점의 앱 인상을 그대로 유지한다.
  static const AppPalette midnight = AppPalette(
    id: AppThemeId.midnight,
    label: '기본',
    description: '보라빛 감도는 깊은 밤',
    brightness: Brightness.dark,
    background: Color(0xFF090616),
    surface: Color(0xFF140F27),
    card: Color(0xFF1E1736),
    input: Color(0xFF261D42),
    accent: Color(0xFF9D4EDD),
    secondaryAccent: Color(0xFF00E5FF),
    // 대비비(WCAG)는 카드 배경 #1E1736 기준으로 계산해서 맞췄다.
    textPrimary: Color(0xFFFFFFFF), // 17.1:1
    textSecondary: Color(0xFFE0E0E0), // 12.9:1
    textTertiary: Color(0xFF9E9E9E), // 6.4:1
    textDisabled: Color(0xFF8A8A8A), // 4.9:1 — 본문 최소선(4.5:1) 통과
    textFaint: Color(0xFF6B6478), // 3.0:1 — 아이콘·테두리 전용(본문 금지)
    divider: Color(0xFF2A2140),
    glassFill: Color(0x0DFFFFFF), // white 5%
    glassBorder: Color(0x1AFFFFFF), // white 10%
    shadow: Color(0x33000000),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFFF1744),
    expired: Color(0xFF616161),
  );

  /// 블랙 — OLED 절전. 순수 검정 배경에 채도를 조금 낮춘 포인트.
  static const AppPalette carbon = AppPalette(
    id: AppThemeId.carbon,
    label: '블랙',
    description: '완전한 검정, OLED 절전',
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    surface: Color(0xFF0C0C0C),
    card: Color(0xFF141414),
    input: Color(0xFF1C1C1C),
    accent: Color(0xFFB07CE8),
    secondaryAccent: Color(0xFF4DD8E8),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFD6D6D6),
    textTertiary: Color(0xFF949494),
    textDisabled: Color(0xFF8A8A8A), // 5.3:1 (기존 #6B6B6B은 3.5:1로 미달)
    textFaint: Color(0xFF6B6B6B), // 3.5:1 (기존 #3D3D3D은 1.7:1로 크게 미달)
    divider: Color(0xFF212121),
    glassFill: Color(0x0DFFFFFF),
    glassBorder: Color(0x1FFFFFFF),
    shadow: Color(0x66000000),
    success: Color(0xFF5AE68C),
    warning: Color(0xFFFFC94D),
    danger: Color(0xFFFF5252),
    expired: Color(0xFF5C5C5C),
  );

  /// 화이트 — 밝은 곳·낮 사용. 포인트 색은 어둡게 낮춰 대비를 확보한다.
  /// (네온 시안은 흰 배경에서 글자로 못 쓴다 — 대비비가 3:1도 안 나옴)
  static const AppPalette paper = AppPalette(
    id: AppThemeId.paper,
    label: '화이트',
    description: '밝은 곳에서 보기 좋아요',
    brightness: Brightness.light,
    background: Color(0xFFF7F5FA),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    input: Color(0xFFEDEAF3),
    accent: Color(0xFF7B2CBF),
    secondaryAccent: Color(0xFF00788C),
    // 라이트 배경(#F7F5FA)에서는 옅은 회색이 거의 안 읽힌다.
    // 기존 값은 각각 2.7:1, 1.6:1로 크게 미달이었다.
    textPrimary: Color(0xFF16121F), // 17.0:1
    textSecondary: Color(0xFF3D3648),
    textTertiary: Color(0xFF57506B),
    textDisabled: Color(0xFF6F687F), // 4.9:1
    textFaint: Color(0xFF8B8496), // 3.3:1 — 아이콘·테두리 전용
    divider: Color(0xFFE2DEEA),
    glassFill: Color(0x0A000000), // black 4%
    glassBorder: Color(0x14000000), // black 8%
    shadow: Color(0x1A000000),
    // 라이트 배경에서는 밝은 초록·노랑이 글자로 안 읽힌다 → 명도를 낮춘다.
    // 색상(hue)은 그대로 유지해서 "초록=정상"이라는 의미를 잃지 않는다.
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    danger: Color(0xFFD50032),
    expired: Color(0xFF9A93A6),
  );

  static const List<AppPalette> all = [midnight, carbon, paper];

  static AppPalette byId(AppThemeId id) =>
      all.firstWhere((p) => p.id == id, orElse: () => midnight);

  static AppPalette byName(String? name) {
    if (name == null) return midnight;
    return all.firstWhere((p) => p.id.name == name, orElse: () => midnight);
  }
}
