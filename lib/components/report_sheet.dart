// 🚨 2트랙 신고 시트 (정보통신망법 제44조의2 대응)
// - 트랙 A: 커뮤니티 규칙 위반 → 기존 신고 로직(임계치 누적 → 자동 블라인드)
// - 트랙 B: 권리침해 신고 → 1건 즉시 처리 의무. 이메일로 운영자에게 직접 접수
//   (게시물 ID·본문 스냅샷·접수 시각을 앱이 자동 첨부)
// - 자해/자살 조장 신고는 트랙 A 항목이지만 임계치를 기다리지 않고 즉시 접수 경로로 우회
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../models/shorts_model.dart';
import 'report_button.dart';

const String kOperatorEmail = 'anonymous.shorts.official@gmail.com';

/// 신고 시트 열기
void showReportSheet(
  BuildContext context, {
  required ShortsModel short,
  required VoidCallback onReported,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _ReportSheet(
      short: short,
      onReported: onReported,
    ),
  );
}

class _ReportSheet extends StatelessWidget {
  final ShortsModel short;
  final VoidCallback onReported;

  const _ReportSheet({required this.short, required this.onReported});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '신고 사유를 선택해 주세요',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ── 트랙 A: 커뮤니티 규칙 위반 (기존 로직) ──
            _sectionLabel('커뮤니티 규칙 위반'),
            _reasonTile(
              context,
              icon: Icons.sentiment_very_dissatisfied,
              title: '욕설 · 혐오 표현',
              onTap: () => _submitCommunityReport(context),
            ),
            _reasonTile(
              context,
              icon: Icons.campaign_outlined,
              title: '스팸 · 광고',
              onTap: () => _submitCommunityReport(context),
            ),
            _reasonTile(
              context,
              icon: Icons.error_outline,
              title: '허위 정보',
              onTap: () => _submitCommunityReport(context),
            ),
            // 자해·자살 조장 → 임계치 대기 없이 즉시 접수 경로로 우회
            _reasonTile(
              context,
              icon: Icons.favorite_border,
              title: '폭력 · 자해 조장',
              subtitle: '운영자가 직접 확인해요',
              highlight: true,
              onTap: () => _submitUrgentReport(context, '폭력·자해 조장'),
            ),

            const SizedBox(height: 14),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 14),

            // ── 트랙 B: 권리침해 (1건 즉시 처리) ──
            // 3개 항목이 모두 같은 처리 경로이므로 안내 문구는 섹션 라벨에 한 번만 표기
            _sectionLabel('내 권리를 침해합니다', note: '운영자가 직접 확인해요'),
            _reasonTile(
              context,
              icon: Icons.gavel_outlined,
              title: '명예훼손',
              highlight: true,
              onTap: () => _submitUrgentReport(context, '명예훼손'),
            ),
            _reasonTile(
              context,
              icon: Icons.person_off_outlined,
              title: '사생활 침해 · 개인정보 노출',
              highlight: true,
              onTap: () => _submitUrgentReport(context, '사생활 침해·개인정보 노출'),
            ),
            _reasonTile(
              context,
              icon: Icons.copyright_outlined,
              title: '저작권 등 권리 침해',
              highlight: true,
              onTap: () => _submitUrgentReport(context, '저작권 등 권리 침해'),
            ),

            const SizedBox(height: 10),
            Text(
              '권리침해 신고는 접수 후 지체 없이 검토하며, 통상 7일 이내에 결과를 회신드립니다.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, {String? note}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
                color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          if (note != null) ...[
            const SizedBox(width: 8),
            Text(
              note,
              style: const TextStyle(
                  color: AppTheme.secondaryAccent, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reasonTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    bool highlight = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      leading: Icon(icon,
          color: highlight ? AppTheme.secondaryAccent : Colors.white54,
          size: 21),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 14.5)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: const TextStyle(
                  color: AppTheme.secondaryAccent, fontSize: 11))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      onTap: onTap,
    );
  }

  /// 트랙 A — 기존 신고 로직 (누적 임계치 → 자동 블라인드)
  void _submitCommunityReport(BuildContext context) {
    Navigator.pop(context);
    ReportGuard.report(context, short.id, onReported);
  }

  /// 트랙 B — 권리침해/긴급 신고. 운영자 이메일로 즉시 접수
  /// 게시물 ID, 본문 스냅샷, 접수 시각을 앱이 자동으로 채워 넣는다.
  Future<void> _submitUrgentReport(BuildContext context, String type) async {
    Navigator.pop(context);

    // 피드에서는 즉시 숨김 처리 (신고자 보호)
    onReported();

    final now = DateTime.now().toIso8601String();
    final subject = '[권리침해 신고] $type · 게시물 #${short.id}';
    final body = '''
아래 내용은 앱이 자동으로 입력한 정보입니다. 수정하지 마시고,
맨 아래 [작성해 주세요] 항목만 채워서 보내주세요.

────────────────────────
■ 침해 주장 유형: $type
■ 대상 게시물 ID: ${short.id}
■ 접수 시각: $now
■ 게시물 본문(신고 시점 원문):
${short.textContent}
────────────────────────

[작성해 주세요]
1) 어떤 점이 권리를 침해하는지 구체적으로 적어주세요.
   →

2) 회신받을 이메일 주소 (필수)
   →

* 회신용 연락처가 없으면 처리 결과를 알려드릴 수 없습니다.
* 접수 후 지체 없이 검토하며, 통상 7일 이내에 결과를 회신드립니다.
''';

    final uri = Uri(
      scheme: 'mailto',
      path: kOperatorEmail,
      query: 'subject=${Uri.encodeComponent(subject)}'
          '&body=${Uri.encodeComponent(body)}',
    );

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메일 앱을 열 수 없습니다. $kOperatorEmail 으로 보내주세요.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

/// 게시물이 이미 소멸한 뒤의 권리침해 신고 (설정 화면에서 진입)
/// 게시물 ID 없이 본문 일부 + 목격 시각으로 접수 → 90일 아카이브와 대조
Future<void> launchExpiredContentReport(BuildContext context) async {
  const subject = '[권리침해 신고] 이미 사라진 게시물';
  const body = '''
이미 피드에서 사라진 게시물에 대한 권리침해 신고입니다.
아래 항목을 채워서 보내주세요. 서버 보관 기록과 대조하여 확인합니다.

[작성해 주세요]
1) 침해 주장 유형 (명예훼손 / 사생활 침해 / 저작권 등)
   →

2) 게시물 본문 중 기억나는 문구 (일부라도 좋습니다)
   →

3) 게시물을 본 대략적인 날짜와 시각
   →

4) 어떤 점이 권리를 침해하는지 구체적으로
   →

5) 회신받을 이메일 주소 (필수)
   →

* 게시물은 24시간 후 피드에서 사라지지만, 원문은 90일간 별도 보관됩니다.
* 접수 후 지체 없이 검토하며, 통상 7일 이내에 결과를 회신드립니다.
''';

  final uri = Uri(
    scheme: 'mailto',
    path: kOperatorEmail,
    query: 'subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}',
  );

  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('메일 앱을 열 수 없습니다. $kOperatorEmail 으로 보내주세요.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}
