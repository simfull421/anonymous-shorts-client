// 🚫 유저 차단 관리 (Google Play UGC 정책 필수)
// - 차단한 creator_hash 목록을 로컬에 저장
// - 피드에서 해당 유저의 글을 클라이언트 사이드로 필터링
import 'package:shared_preferences/shared_preferences.dart';

class BlockManager {
  static const String _key = 'blocked_users';
  static Set<String> _blockedHashes = {};
  static bool _initialized = false;

  /// 초기화 (앱 시작 시 1회 호출)
  static Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    _blockedHashes = list.toSet();
    _initialized = true;
  }

  /// 유저 차단
  static Future<void> blockUser(String creatorHash) async {
    _blockedHashes.add(creatorHash);
    await _save();
  }

  /// 유저 차단 해제
  static Future<void> unblockUser(String creatorHash) async {
    _blockedHashes.remove(creatorHash);
    await _save();
  }

  /// 차단 여부 확인
  static bool isBlocked(String? creatorHash) {
    if (creatorHash == null) return false;
    return _blockedHashes.contains(creatorHash);
  }

  /// 차단 목록 조회
  static Set<String> get blockedHashes => Set.unmodifiable(_blockedHashes);

  /// 차단 수
  static int get count => _blockedHashes.length;

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _blockedHashes.toList());
  }
}
