// 📢 앱 내 공지 관리
// - 하드코딩 공지 목록 (추후 서버 연동 가능 구조)
// - SharedPreferences에 마지막으로 확인한 공지 id 저장
// - 새 공지가 있으면 피드 상단 배너 노출 (법적 문서 변경 고지 의무 이행)
import 'package:shared_preferences/shared_preferences.dart';

class AppNotice {
  final int id;
  final String date; // 표시용 (예: 2026.07.20)
  final String title;
  final String summary; // 배너에 노출되는 한 줄 요약
  final List<String> details; // 상세 항목
  final String? linkUrl;
  final String? linkLabel;

  const AppNotice({
    required this.id,
    required this.date,
    required this.title,
    required this.summary,
    required this.details,
    this.linkUrl,
    this.linkLabel,
  });
}

class NoticeManager {
  static const String _seenKey = 'seen_notice_id';

  /// 공지 목록 (최신순 — 첫 번째가 최신)
  /// 새 공지 추가 시 id를 증가시켜 리스트 맨 앞에 추가
  static const List<AppNotice> notices = [
    AppNotice(
      id: 2,
      date: '2026.07.20',
      title: '개인정보처리방침·이용약관 개정 안내',
      summary: '법적 문서가 개정되었습니다. (2026.07.27 시행)',
      details: [
        '콘텐츠 검수를 위한 텍스트의 국외 이전(OpenAI, 미국) 내용이 명시되었습니다. 기기 식별자·IP는 전송되지 않습니다.',
        '데이터 파기 절차와 방법(30분 주기 자동 물리 삭제)이 구체적으로 기재되었습니다.',
        '만 14세 이상 이용 연령 기준이 명시되었습니다.',
        '이용 제한에 대한 이의제기 절차(이메일 접수, 15일 내 회신)가 신설되었습니다.',
        '권리침해 신고 및 임시조치 절차가 신설되었습니다.',
        '영문판(English) 문서가 추가되었습니다.',
        '개정 문서는 2026년 7월 27일부터 시행됩니다. 자세한 내용은 아래 링크에서 확인하실 수 있습니다.',
      ],
      linkUrl:
          'https://simfull421.github.io/anonymous-shorts-privacy/privacy_policy.html',
      linkLabel: '개정 전문 보기',
    ),
  ];

  static AppNotice get latest => notices.first;

  /// 아직 확인하지 않은 새 공지가 있는지
  static Future<bool> hasUnseenNotice() async {
    final prefs = await SharedPreferences.getInstance();
    final seenId = prefs.getInt(_seenKey) ?? 0;
    return latest.id > seenId;
  }

  /// 최신 공지를 확인 처리
  static Future<void> markLatestSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seenKey, latest.id);
  }
}
