// 🌐 API 서비스 (제네릭 메서드 + 커서 기반 페이지네이션)
// - 중복 try-catch/statusCode 검사를 _request<T>()로 통합
// - 커서 기반 페이지네이션 적용 (캐시 제거)
// - 백엔드 ShortsEndpoints.cs의 5개 API와 1:1 매핑
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart' as crypto;
import '../models/shorts_model.dart';
import '../utils/device_id.dart';

class ApiService {
  // 백엔드 서버 주소 (빌드 시 --dart-define=API_URL=... 로 주입, 없으면 클라우드플레어 기본값)
  static const String baseUrl = String.fromEnvironment('API_URL',
      defaultValue: 'https://finishing-successful-thy-montana.trycloudflare.com');

  // HMAC 시크릿 키 (반드시 --dart-define=HMAC_SECRET=... 로 빌드 시 주입)
  static const String _hmacSecret = String.fromEnvironment('HMAC_SECRET');

  /// 기기 로케일 자동 감지 (i18n 기초)
  static String get deviceLanguage {
    final locale = ui.PlatformDispatcher.instance.locale;
    return locale.languageCode; // 'ko', 'en', 'ja', etc.
  }

  // ─── 서명 생성 (HMAC-SHA256) ───
  static Map<String, String> _generateHeaders(String path, String body) {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final payload = '$timestamp.$path.$body';
    
    final keyBytes = utf8.encode(_hmacSecret);
    final payloadBytes = utf8.encode(payload);
    
    final hmac = crypto.Hmac(crypto.sha256, keyBytes);
    final digest = hmac.convert(payloadBytes);
    final signature = base64Encode(digest.bytes);

    return {
      'Content-Type': 'application/json',
      'X-Timestamp': timestamp,
      'X-Signature': signature,
    };
  }

  // ─── 제네릭 HTTP 메서드 (중복 코드 통합) ───

  /// GET 요청 + JSON 파싱을 제네릭으로 처리
  static Future<T> _get<T>({
    required String path,
    Map<String, String>? queryParams,
    required T Function(dynamic json) parser,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    
    // 쿼리 스트링이 포함된 전체 경로로 서명 생성
    final fullPath = uri.hasQuery ? '$path?${uri.query}' : path;
    final headers = _generateHeaders(fullPath, '');
    if (extraHeaders != null) headers.addAll(extraHeaders);

    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return parser(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// POST 요청 + JSON 바디 전송을 제네릭으로 처리
  static Future<T> _post<T>({
    required String path,
    required Map<String, dynamic> body,
    required T Function(dynamic json) parser,
    Map<String, String>? extraHeaders,
  }) async {
    final bodyString = jsonEncode(body);
    final headers = _generateHeaders(path, bodyString);
    if (extraHeaders != null) headers.addAll(extraHeaders);

    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: bodyString,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return parser(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// DELETE 요청 제네릭 처리
  static Future<T> _delete<T>({
    required String path,
    Map<String, String>? extraHeaders,
    required T Function(dynamic json) parser,
  }) async {
    final headers = _generateHeaders(path, '');
    if (extraHeaders != null) headers.addAll(extraHeaders);

    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return parser(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  // ─── 개별 API 메서드 ───

  /// [API 1] 헬스 체크
  static Future<bool> checkHealth() async {
    try {
      await _get<Map<String, dynamic>>(
        path: '/health',
        parser: (json) => json as Map<String, dynamic>,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// [API 2] 피드 가져오기 (GET /api/shorts?lang=ko&cursor=123&voter=uuid)
  /// 커서 기반 페이지네이션 적용, 본인 피드 제외, 투표 상태 포함
  static Future<({List<ShortsModel> items, int? nextCursor, int creditBalance})> getFeed(
    String langCode, {
    bool forceRefresh = false,
    int? cursor,
  }) async {
    final uuid = await DeviceId.getOrCreate();
    final queryParams = <String, String>{
      'lang': langCode,
      'voter': uuid,
    };
    if (cursor != null) queryParams['cursor'] = cursor.toString();

    final result = await _get<Map<String, dynamic>>(
      path: '/api/shorts',
      queryParams: queryParams,
      parser: (json) => json as Map<String, dynamic>,
    );

    final itemsList = ((result['items'] ?? result['Items']) as List<dynamic>?) ?? [];
    final items = itemsList
        .map((item) => ShortsModel.fromJson(item as Map<String, dynamic>))
        .toList();
    final nextCursor = ((result['nextCursor'] ?? result['NextCursor']) as int?);
    final creditBalance = ((result['creditBalance'] ?? result['CreditBalance']) as int?) ?? -1;

    return (items: items, nextCursor: nextCursor, creditBalance: creditBalance);
  }

  /// [API 3] 마이페이지 - 내 쇼츠 조회 (GET /api/shorts/my)
  /// UUID는 X-User-UUID 헤더로 전송, 크레딧 잔액 동기화 포함
  static Future<({List<ShortsModel> items, int creditBalance})> getMyShorts() async {
    final uuid = await DeviceId.getOrCreate();
    final data = await _get<Map<String, dynamic>>(
      path: '/api/shorts/my',
      parser: (json) => json as Map<String, dynamic>,
      extraHeaders: {'X-User-UUID': uuid},
    );
    final itemsList = ((data['items'] ?? data['Items']) as List<dynamic>?) ?? [];
    final items = itemsList
        .map((item) => ShortsModel.fromJson(item as Map<String, dynamic>))
        .toList();
    final creditBalance = ((data['creditBalance'] ?? data['CreditBalance']) as int?) ?? 0;
    return (items: items, creditBalance: creditBalance);
  }

  /// [API 4] 감정 투표 (POST /api/shorts/vote)
  /// 백엔드 DTO: VoteRequest(ShortsId, ButtonIndex, VoterUuid)
  /// 응답에 CreditBalance가 있으면 반환 (웰컴 보너스 즉시 반영용, 없으면 null)
  static Future<({bool success, int? balance})> vote(
      int shortsId, int buttonIndex) async {
    try {
      final uuid = await DeviceId.getOrCreate();
      final result = await _post<Map<String, dynamic>>(
        path: '/api/shorts/vote',
        body: {
          'ShortsId': shortsId,
          'ButtonIndex': buttonIndex,
          'VoterUuid': uuid,
        },
        parser: (json) => json as Map<String, dynamic>,
      );
      final balance =
          (result['creditBalance'] ?? result['CreditBalance']) as int?;
      return (success: true, balance: balance);
    } catch (_) {
      return (success: false, balance: null);
    }
  }

  /// [API 5] 쇼츠 작성 (POST /api/shorts)
  /// 백엔드 DTO: ShortRequest(CreatorUuid, LanguageCode, TextContent, CustomButtons, BgmId)
  static Future<({bool success, String? error})> createShorts({
    required String textContent,
    required String customButtonsJson,
    String languageCode = 'ko',
    String? bgmId,
  }) async {
    try {
      final uuid = await DeviceId.getOrCreate();

      // 심사관 모드: audit token이 있으면 헤더에 포함
      final prefs = await SharedPreferences.getInstance();
      final auditToken = prefs.getString('audit_token');
      final extraHeaders = <String, String>{};
      if (auditToken != null) {
        extraHeaders['X-Audit-Token'] = auditToken;
      }

      await _post<Map<String, dynamic>>(
        path: '/api/shorts',
        body: {
          'CreatorUuid': uuid,
          'LanguageCode': languageCode,
          'TextContent': textContent,
          'CustomButtons': customButtonsJson,
          'BgmId': bgmId,
        },
        parser: (json) => json as Map<String, dynamic>,
        extraHeaders: extraHeaders.isNotEmpty ? extraHeaders : null,
      );
      return (success: true, error: null);
    } on ApiException catch (e) {
      // 서버 에러 응답에서 Message 추출 ({"message":"..."} 또는 {"Message":"..."})
      String errorMsg = '등록에 실패했습니다. 다시 시도해 주세요.';
      try {
        final parsed = jsonDecode(e.body);
        if (parsed is Map) {
          final msg = parsed['Message'] ?? parsed['message'];
          if (msg is String) errorMsg = msg;
        }
      } catch (_) {}
      return (success: false, error: errorMsg);
    } catch (_) {
      return (success: false, error: '네트워크 오류가 발생했습니다.');
    }
  }

  /// [API 6] 신고 (POST /api/shorts/report)
  /// 백엔드 DTO: ReportRequest(ShortsId, ReporterUuid)
  static Future<bool> report(int shortsId) async {
    try {
      final uuid = await DeviceId.getOrCreate();
      await _post<Map<String, dynamic>>(
        path: '/api/shorts/report',
        body: {'ShortsId': shortsId, 'ReporterUuid': uuid},
        parser: (json) => json as Map<String, dynamic>,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// [API 5.1] 내 쇼츠 삭제 (DELETE /api/shorts/{id})
  static Future<bool> deleteShorts(int shortsId) async {
    try {
      final uuid = await DeviceId.getOrCreate();
      await _delete<Map<String, dynamic>>(
        path: '/api/shorts/$shortsId',
        extraHeaders: {'X-User-UUID': uuid},
        parser: (json) => json as Map<String, dynamic>,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// [API 5.2] 사용자 데이터 전체 삭제 (DELETE /api/shorts/user/data)
  static Future<bool> deleteAllUserData() async {
    try {
      final uuid = await DeviceId.getOrCreate();
      await _delete<Map<String, dynamic>>(
        path: '/api/shorts/user/data',
        extraHeaders: {'X-User-UUID': uuid},
        parser: (json) => json as Map<String, dynamic>,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// [API 5.3] 사용자 데이터 내보내기 (GET /api/shorts/user/export)
  /// GDPR Article 15/20: 개인 데이터 열람/이동권
  static Future<Map<String, dynamic>?> exportUserData() async {
    try {
      final uuid = await DeviceId.getOrCreate();
      return await _get<Map<String, dynamic>>(
        path: '/api/shorts/user/export',
        parser: (json) => json as Map<String, dynamic>,
        extraHeaders: {'X-User-UUID': uuid},
      );
    } catch (_) {
      return null;
    }
  }

  // ─── 광고 API ───

  /// 쇼츠 피드 네이티브 광고 (GET /api/shorts/ads/shorts)
  static Future<ShortsModel?> getAdShorts() async {
    try {
      return await _get<ShortsModel>(
        path: '/api/shorts/ads/shorts',
        parser: (json) => ShortsModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (_) {
      return null; // 광고 로드 실패 시 일반 쇼츠만 노출
    }
  }

  /// 음악 스폰서 광고 (GET /api/shorts/ads/music)
  static Future<List<Map<String, dynamic>>> getAdMusics() async {
    try {
      return await _get<List<Map<String, dynamic>>>(
        path: '/api/shorts/ads/music',
        parser: (json) {
          final list = json as List<dynamic>;
          return list.map((e) => e as Map<String, dynamic>).toList();
        },
      );
    } catch (_) {
      return [];
    }
  }

  /// [API 6] 심사관 로그인 (POST /api/shorts/admin/login)
  /// 반환: (token, errorMessage) — token!=null이면 성공, null이면 실패(errorMessage 참조)
  static Future<({String? token, String? error})> adminLogin(String secretCode) async {
    try {
      final result = await _post<Map<String, dynamic>>(
        path: '/api/shorts/admin/login',
        body: {'SecretCode': secretCode},
        parser: (json) => json as Map<String, dynamic>,
      );
      final token = (result['auditToken'] ?? result['AuditToken']) as String?;
      return (token: token, error: null);
    } on ApiException catch (e) {
      if (e.statusCode == 429) {
        return (token: null, error: '너무 많은 시도입니다. 15분 후 다시 시도해 주세요.');
      }
      return (token: null, error: '인증에 실패했습니다.');
    } catch (_) {
      return (token: null, error: '서버에 연결할 수 없습니다.');
    }
  }
}

/// API 예외 클래스
class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}

