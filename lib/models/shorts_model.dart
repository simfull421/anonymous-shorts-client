// 🧱 타입 안전 모델 클래스 (GC 최적화)
// - dynamic 맵 사용을 완전히 제거하여 박싱/언박싱 방지
// - fromJson 팩토리로 JSON 파싱 1회만 수행
// - 백엔드 ShortsEndpoints.cs의 DTO(ButtonDto, ShortRequest)와 1:1 매핑
import 'dart:convert';

class ButtonModel {
  final int index;
  final String text;
  int votes; // 로컬 투표 즉시 반영을 위해 mutable (UC02 기본흐름 2)

  ButtonModel({
    required this.index,
    required this.text,
    required this.votes,
  });

  factory ButtonModel.fromJson(Map<String, dynamic> json) {
    return ButtonModel(
      index: json['index'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      votes: json['votes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        'text': text,
        'votes': votes,
      };
}

class ShortsModel {
  final int id;
  final String textContent;
  final List<ButtonModel> buttons;
  final int totalVotes;
  final String? bgmId;
  final String status; // Active, Blind, Expired, Ad
  final DateTime createdAt;

  /// 소멸 예정 시각. 서버가 계산해서 내려준다.
  /// 구버전 서버(또는 이 필드가 없는 응답)에서는 null이 되므로
  /// 화면에서는 null 검사를 하고 표시를 생략한다. (임의로 24시간을 더하지 않는다 —
  /// 그러면 서버 정책이 바뀌었을 때 화면이 조용히 거짓말을 하게 된다)
  final DateTime? expiresAt;

  final bool isAd;
  final String? targetUrl;
  final String? creatorHash;
  final int? votedButtonIndex; // 서버에서 받은 투표 상태 (null이면 미투표)

  ShortsModel({
    required this.id,
    required this.textContent,
    required this.buttons,
    required this.totalVotes,
    this.bgmId,
    this.status = 'Active',
    required this.createdAt,
    this.expiresAt,
    this.isAd = false,
    this.targetUrl,
    this.creatorHash,
    this.votedButtonIndex,
  });

  /// 백엔드 GET /api/shorts 및 GET /api/shorts/my 응답 파싱
  /// 백엔드에서 custom_buttons를 JSON 문자열로 내려주므로 2차 디코딩 수행
  factory ShortsModel.fromJson(Map<String, dynamic> json) {
    List<ButtonModel> parsedButtons = [];
    final buttonsRaw = json['Buttons'] ?? json['buttons'] ?? json['custom_buttons'];

    if (buttonsRaw is String) {
      // JSON 문자열로 내려온 경우 → 디코딩
      final List<dynamic> decoded = jsonDecode(buttonsRaw) as List<dynamic>;
      parsedButtons = decoded
          .map((b) => ButtonModel.fromJson(b as Map<String, dynamic>))
          .toList();
    } else if (buttonsRaw is List) {
      // 이미 파싱된 리스트
      parsedButtons = buttonsRaw
          .map((b) => ButtonModel.fromJson(b as Map<String, dynamic>))
          .toList();
    }

    return ShortsModel(
      id: (json['Id'] ?? json['id'] ?? 0) as int,
      textContent:
          (json['Text'] ?? json['text'] ?? json['text_content'] ?? '') as String,
      buttons: parsedButtons,
      totalVotes:
          (json['Votes'] ?? json['votes'] ?? json['total_votes'] ?? 0) as int,
      bgmId: json['BgmId'] ?? json['bgmId'] ?? json['bgm_id'],
      status: (json['Status'] ?? json['status'] ?? 'Active') as String,
      createdAt: _parseDateTime(json['CreatedAt'] ?? json['createdAt'] ?? json['created_at']),
      expiresAt: _parseNullableDateTime(
          json['ExpiresAt'] ?? json['expiresAt'] ?? json['expires_at']),
      isAd: (json['IsAd'] ?? json['isAd'] ?? false) as bool,
      targetUrl: json['TargetUrl'] ?? json['targetUrl'],
      creatorHash: json['CreatorHash'] ?? json['creatorHash'],
      votedButtonIndex: json['VotedButtonIndex'] ?? json['votedButtonIndex'],
    );
  }

  /// 현재 버튼들의 투표 합계 (퍼센트 계산용, totalVotes 대신 실시간 합산)
  int get computedTotalVotes =>
      buttons.fold<int>(0, (sum, btn) => sum + btn.votes);

  /// 서버가 안 내려주면 null. 없는 값을 추측해서 만들지 않는다.
  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}
