// 🫂 자해·자살 관련 내용 감지 시 안내 다이얼로그
// - 서버가 응답 본문에 Code = "SELF_HARM_DETECTED" 를 내려주면 표시
// - 차단을 통보하는 화면이 아니라, 도움받을 곳을 안내하는 화면
// - 자살예방법 제19조 대응 + 이용자 안전 목적
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../config/app_links.dart';

/// 서버 응답 코드 상수 (서버와 약속된 값)
const String kSelfHarmCode = 'SELF_HARM_DETECTED';

/// 자살예방상담전화
const String kSuicidePreventionLine = AppLinks.suicidePreventionLine;

void showSafetyDialog(BuildContext context) {
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
            '혹시 지금 많이 힘드신가요?',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '작성하신 내용이 등록되지 않았어요.\n'
            '지금 겪고 계신 어려움을 함께 이야기할 수 있는 곳이 있어요.\n'
            '언제든지, 무료로 연결됩니다.',
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
                  '자살예방 상담전화',
                  style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  kSuicidePreventionLine,
                  style: TextStyle(
                    color: AppTheme.secondaryAccent,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '24시간 · 무료 · 익명 상담',
                  style: TextStyle(
                      color: AppTheme.textPrimary.withValues(alpha: 0.4), fontSize: 11),
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
              final uri = Uri(scheme: 'tel', path: kSuicidePreventionLine);
              try {
                await launchUrl(uri);
              } catch (_) {}
            },
            icon: const Icon(Icons.call_rounded, size: 18),
            label: const Text('지금 전화 걸기',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
            child: Text('닫기',
                style: TextStyle(color: AppTheme.textDisabled, fontSize: 14)),
          ),
        ),
      ],
    ),
  );
}
