// 📢 앱 내 공지 관리
// - 공지 목록을 원격 JSON(GitHub Pages)에서 불러온다.
//   → 앱 업데이트나 서버 배포 없이 공지 게시 가능 (개인정보 유출 통지 72시간 대응)
// - 네트워크 실패 시: 캐시 → 내장 기본값 순으로 폴백
// - SharedPreferences에 마지막으로 확인한 공지 id 저장
import 'dart:convert';
import 'package:http/http.dart' as http;
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

  factory AppNotice.fromJson(Map<String, dynamic> json) {
    return AppNotice(
      id: (json['id'] as num?)?.toInt() ?? 0,
      date: json['date'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      linkUrl: json['linkUrl'] as String?,
      linkLabel: json['linkLabel'] as String?,
    );
  }
}

class NoticeManager {
  static const String _seenKey = 'seen_notice_id';
  static const String _cacheKey = 'notices_cache_json';

  /// 공지 원본 (GitHub Pages). 여기에 항목을 추가하고 push하면 즉시 반영된다.
  static const String _remoteUrl =
      'https://simfull421.github.io/anonymous-shorts-privacy/notices.json';

  /// 네트워크·캐시 모두 실패했을 때 사용하는 내장 기본 공지
  static const List<AppNotice> _fallbackNotices = [
    AppNotice(
      id: 2,
      date: '2026.07.20',
      title: '개인정보처리방침·이용약관 개정 안내',
      summary: '개인정보처리방침과 이용약관이 개정되었습니다.',
      details: [
        '서비스 운영을 위해 데이터가 저장되는 국가(미국)와, 콘텐츠 검수를 위한 텍스트의 국외 이전(OpenAI, 미국) 내용이 명시되었습니다. 검수 시 기기 식별자·IP는 전송되지 않습니다.',
        '데이터 파기 절차와 방법(30분 주기 자동 물리 삭제)이 구체적으로 기재되었습니다.',
        '개인정보 유출 시 통지 절차가 추가되었습니다.',
        '만 14세 이상 이용 연령 기준이 명시되었습니다.',
        '이용 제한에 대한 이의제기 절차(이메일 접수, 15일 내 회신)가 신설되었습니다.',
        '권리침해 신고 및 임시조치 절차가 신설되었습니다.',
        '영문판(English) 문서가 추가되었습니다.',
        '개정된 문서는 정식 출시일부터 적용됩니다. 자세한 내용은 아래 링크에서 확인하실 수 있습니다.',
      ],
      linkUrl:
          'https://simfull421.github.io/anonymous-shorts-privacy/privacy_policy.html',
      linkLabel: '개정 전문 보기',
    ),
  ];

  /// 현재 공지 목록 (최신순 — 첫 번째가 최신)
  static List<AppNotice> notices = _fallbackNotices;

  static bool _loaded = false;

  /// 공지 로드 — 캐시를 먼저 적용한 뒤 원격을 시도한다.
  /// 앱 시작 시 1회 호출.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) 캐시 먼저 반영 (오프라인에서도 최근 공지가 보이도록)
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      final parsed = _parse(cached);
      if (parsed.isNotEmpty) notices = parsed;
    }

    // 2) 원격 갱신 시도 (실패해도 조용히 무시)
    try {
      final res = await http
          .get(Uri.parse(_remoteUrl))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final body = utf8.decode(res.bodyBytes);
        final parsed = _parse(body);
        if (parsed.isNotEmpty) {
          notices = parsed;
          await prefs.setString(_cacheKey, body);
        }
      }
    } catch (_) {
      // 네트워크 실패 → 캐시 또는 내장 기본값 유지
    }

    _loaded = true;
  }

  static List<AppNotice> _parse(String body) {
    try {
      final decoded = jsonDecode(body);
      final list = decoded is Map<String, dynamic>
          ? decoded['notices'] as List<dynamic>?
          : decoded as List<dynamic>?;
      if (list == null) return const [];
      final result = list
          .map((e) => AppNotice.fromJson(e as Map<String, dynamic>))
          .toList();
      // id 내림차순 정렬 (최신이 앞)
      result.sort((a, b) => b.id.compareTo(a.id));
      return result;
    } catch (_) {
      return const [];
    }
  }

  static bool get isLoaded => _loaded;

  static AppNotice get latest => notices.first;

  /// 아직 확인하지 않은 새 공지가 있는지
  static Future<bool> hasUnseenNotice() async {
    if (notices.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final seenId = prefs.getInt(_seenKey) ?? 0;
    return latest.id > seenId;
  }

  /// 최신 공지를 확인 처리
  static Future<void> markLatestSeen() async {
    if (notices.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seenKey, latest.id);
  }
}
