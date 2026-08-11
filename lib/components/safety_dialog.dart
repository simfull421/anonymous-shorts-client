// 🫂 자해·자살 관련 내용 감지 시 안내 다이얼로그
// - 서버가 응답 본문에 Code = "SELF_HARM_DETECTED" 를 내려주면 표시
// - 차단을 통보하는 화면이 아니라, 도움받을 곳을 안내하는 화면
// - 자살예방법 제19조 대응 + 이용자 안전 목적
//
// ⚠️ 상담 연락처는 기기 지역에 따라 달라진다(CrisisLine).
//    한 나라 번호를 하드코딩하면 다른 나라 이용자가 위기 상황에
//    닿지 않는 번호를 받게 된다. 번호 추가는 AppLinks 쪽에서 한다.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../config/app_links.dart';

/// 서버 응답 코드 상수 (서버와 약속된 값)
const String kSelfHarmCode = 'SELF_HARM_DETECTED';

/// 자살예방상담전화 (국내 기본값 — 기존 참조 호환용)
const String kSuicidePreventionLine = AppLinks.suicidePreventionLine;

/// 다이얼로그 문구. 전체 다국어화(ARB) 전까지 이 화면만 별도로 분기한다.
class _SafetyStrings {
  const _SafetyStrings({
    required this.title,
    required this.body,
    required this.callAction,
    required this.webAction,
    required this.close,
  });

  final String title;
  final String body;
  final String callAction;
  final String webAction;
  final String close;

  static const _ko = _SafetyStrings(
    title: '혹시 지금 많이 힘드신가요?',
    body: '작성하신 내용이 등록되지 않았어요.\n'
        '지금 겪고 계신 어려움을 함께 이야기할 수 있는 곳이 있어요.\n'
        '언제든지, 무료로 연결됩니다.',
    callAction: '지금 전화 걸기',
    webAction: '상담처 찾아보기',
    close: '닫기',
  );

  static const _en = _SafetyStrings(
    title: 'Are you going through a hard time?',
    body: "Your post wasn't published.\n"
        'There are people who can talk with you about what you’re facing.\n'
        'Available anytime, free of charge.',
    callAction: 'Call now',
    webAction: 'Find a helpline',
    close: 'Close',
  );

  static _SafetyStrings of(ui.Locale locale) =>
      locale.languageCode == 'ko' ? _ko : _en;
}

void showSafetyDialog(BuildContext context) {
  final locale = ui.PlatformDispatcher.instance.locale;
  final line = CrisisLine.forLocale(locale);
  final t = _SafetyStrings.of(locale);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      contentPadding: const EdgeInsets.fromLTRB(22, 26, 22, 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.secondaryAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_rounded,
                color: AppTheme.secondaryAccent, size: 30),
          ),
          const SizedBox(height: 18),
          Text(
            t.title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            t.body,
            style: TextStyle(
              color: AppTheme.textPrimary.withValues(alpha: 0.72),
              fontSize: 13.5,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  line.orgName,
                  style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  line.display,
                  style: TextStyle(
                    color: AppTheme.secondaryAccent,
                    // 웹 주소는 번호보다 길어서 같은 크기로는 넘친다
                    fontSize: line.isWebOnly ? 18 : 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: line.isWebOnly ? 0 : 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  line.note,
                  style: TextStyle(
                      color: AppTheme.textPrimary.withValues(alpha: 0.4),
                      fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              if (line.isWebOnly) {
                // 번호가 확인되지 않은 지역 → 국가별 상담처 목록으로 안내
                final uri = Uri.parse(CrisisLine.worldwideUrl);
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {}
                return;
              }
              final uri = Uri(scheme: 'tel', path: line.dial);
              try {
                await launchUrl(uri);
              } catch (_) {}
            },
            icon: Icon(
                line.isWebOnly ? Icons.open_in_new_rounded : Icons.call_rounded,
                size: 18),
            label: Text(line.isWebOnly ? t.webAction : t.callAction,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryAccent,
              // 시안(다크)에는 검정, 짙은 청록(라이트)에는 흰색이 읽힌다
              foregroundColor: AppTheme.isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t.close,
                style: TextStyle(color: AppTheme.textDisabled, fontSize: 14)),
          ),
        ),
      ],
    ),
  );
}
