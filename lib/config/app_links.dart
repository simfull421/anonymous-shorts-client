// 🔗 외부 링크 · 연락처 상수 + 공통 열기 헬퍼
//
// 법적 문서 URL이 여러 파일에 흩어져 있으면 개정 시 일부만 바뀌어
// 앱이 구버전 문서를 가리키는 사고가 난다. 링크는 이 파일에서만 관리한다.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppLinks {
  AppLinks._();

  /// 법적 문서·공지가 게시되는 GitHub Pages 루트
  static const String _base =
      'https://simfull421.github.io/anonymous-shorts-privacy';

  static const String privacyPolicy = '$_base/privacy_policy.html';
  static const String termsOfService = '$_base/terms_of_service.html';
  static const String privacyPolicyEn = '$_base/privacy_policy_en.html';
  static const String termsOfServiceEn = '$_base/terms_of_service_en.html';

  /// 원격 공지 목록 (앱 업데이트 없이 공지 게시 가능)
  static const String noticesJson = '$_base/notices.json';

  /// 운영자 연락처 — 권리침해 신고·문의 접수 창구
  static const String operatorEmail = 'anonymous.shorts.official@gmail.com';

  /// 자살예방 상담전화 (국내). 국가별 안내처는 CrisisLine을 사용한다.
  static const String suicidePreventionLine = '109';
}

/// 🫂 위기상담 안내처 — 기기 지역에 따라 분기한다.
///
/// 한 나라 번호만 하드코딩해 두면, 다른 나라 이용자에게는 걸어도
/// 닿지 않는 번호를 위기 상황에 보여주게 된다.
/// 확인되지 않은 나라의 번호는 추측해서 채우지 않고,
/// 국가별 상담처 목록(findahelpline.com)으로 안내한다.
class CrisisLine {
  const CrisisLine({
    required this.orgName,
    required this.display,
    required this.dial,
    required this.note,
  });

  /// 기관명 (예: 자살예방 상담전화, Samaritans)
  final String orgName;

  /// 화면 표기 (공백 포함 가능 — 예: '116 123')
  final String display;

  /// 실제 발신 번호. null이면 전화 대신 웹 안내로 대체한다.
  final String? dial;

  final String note;

  /// 전화 발신이 아니라 웹 목록으로 안내해야 하는 경우
  bool get isWebOnly => dial == null;

  static const CrisisLine kr = CrisisLine(
    orgName: '자살예방 상담전화',
    display: '109',
    dial: '109',
    note: '24시간 · 무료 · 익명 상담',
  );

  static const CrisisLine us = CrisisLine(
    orgName: 'Suicide & Crisis Lifeline',
    display: '988',
    dial: '988',
    note: '24/7 · Free · Confidential',
  );

  static const CrisisLine gb = CrisisLine(
    orgName: 'Samaritans',
    display: '116 123',
    dial: '116123',
    note: '24/7 · Free · Confidential',
  );

  /// 등록되지 않은 국가 — 틀린 번호를 보여주는 것보다 정확한 목록이 낫다.
  static const CrisisLine worldwide = CrisisLine(
    orgName: 'Find a helpline near you',
    display: 'findahelpline.com',
    dial: null,
    note: 'Helplines by country',
  );

  static const String worldwideUrl = 'https://findahelpline.com';

  /// 기기 지역 설정으로 안내처를 고른다.
  static CrisisLine forLocale(Locale locale) {
    switch (locale.countryCode) {
      case 'KR':
        return kr;
      case 'US':
        return us;
      case 'GB':
        return gb;
    }
    // 국가 정보가 없는 로케일(예: 'ko')은 언어로 추정한다.
    if (locale.languageCode == 'ko') return kr;
    return worldwide;
  }
}

/// 외부 브라우저 → 인앱 웹뷰 순으로 시도하고, 모두 실패하면 스낵바로 안내한다.
Future<void> openExternalUrl(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = Uri.parse(url);
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    if (await launchUrl(uri, mode: LaunchMode.inAppWebView)) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('브라우저를 열 수 없습니다.')),
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('링크를 열 수 없습니다.')),
    );
  }
}

/// 메일 앱 열기. 실패 시 주소를 안내한다.
Future<void> openMail(
  BuildContext context, {
  required String subject,
  required String body,
}) {
  return openMailWith(
    ScaffoldMessenger.of(context),
    subject: subject,
    body: body,
  );
}

/// 시트/다이얼로그를 닫은 뒤 메일을 열어야 할 때 사용한다.
/// context는 pop 이후 무효가 되므로, 닫기 전에 확보한 messenger를 넘긴다.
Future<void> openMailWith(
  ScaffoldMessengerState messenger, {
  required String subject,
  required String body,
}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: AppLinks.operatorEmail,
    query: 'subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}',
  );
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('메일 앱을 열 수 없습니다. ${AppLinks.operatorEmail} 으로 보내주세요.'),
        duration: Duration(seconds: 4),
      ),
    );
  }
}
