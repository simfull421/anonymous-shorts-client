// 💰 크레딧 상태 관리 (UC02, UC04)
// - 서버가 진짜 잔액 관리 (UserWallet 테이블)
// - 로컬은 표시용 캐시 + UX 최적화 (빠른 UI 반영)
// - 투표 시 +1, 글쓰기 시 -10 (WRITE_CREDIT_COST)
// - 심사관 모드: 서버 잔액 동기화 무시 (로컬 999 유지)
import 'package:shared_preferences/shared_preferences.dart';

class CreditManager {
  static const String _key = 'credit_balance';
  static const String _costKey = 'write_credit_cost';

  /// 글쓰기 비용 — 서버 SystemConfig(WRITE_CREDIT_COST)를 따른다.
  /// 서버 응답을 받기 전에는 마지막으로 저장된 값(없으면 기본값)을 사용.
  static int _writeCost = _defaultWriteCost;
  static const int _defaultWriteCost = 10;
  static int get writeCost => _writeCost;

  static const int maxCredit = 20; // UC02 예외흐름 E1: 크레딧 상한선

  static int _cached = 0;
  static bool _initialized = false;
  static bool _isAdminMode = false; // 심사관 모드 활성 시 서버 동기화 차단

  /// 심사관 모드 여부
  static bool get isAdminMode => _isAdminMode;

  /// 로컬 캐시된 크레딧 잔액 로드
  static Future<int> getBalance() async {
    if (_initialized) return _cached;

    final prefs = await SharedPreferences.getInstance();
    _isAdminMode = prefs.getBool('is_admin_mode') ?? false;
    _cached = _isAdminMode ? 999 : (prefs.getInt(_key) ?? 0);
    _writeCost = prefs.getInt(_costKey) ?? _defaultWriteCost;
    _initialized = true;
    return _cached;
  }

  /// 서버가 내려준 글쓰기 비용 동기화 (SystemConfig.WRITE_CREDIT_COST)
  static Future<void> syncWriteCost(int? serverCost) async {
    if (serverCost == null || serverCost <= 0) return;
    if (serverCost == _writeCost) return;
    _writeCost = serverCost;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_costKey, serverCost);
  }

  /// 투표 시 크레딧 +1 (UC02)
  /// 반환값: true면 정상 적립, false면 상한 도달
  static Future<bool> earnCredit() async {
    await getBalance();
    if (_isAdminMode) return false; // 심사관은 크레딧 상한 도달 취급
    if (_cached >= maxCredit) return false;

    _cached += 1;
    await _save();
    return true;
  }

  /// 글쓰기 시 크레딧 -10 (UC04)
  /// 심사관 모드에서는 서버가 크레딧을 차감하지 않으므로 로컬도 차감 안 함
  static Future<bool> spendCredit() async {
    await getBalance();
    if (_isAdminMode) return true; // 심사관은 무조건 통과, 차감 안 함
    if (_cached < writeCost) return false;

    _cached -= writeCost;
    await _save();
    return true;
  }

  /// 서버 응답으로 잔액 동기화 (서버가 진짜)
  /// 심사관 모드에서는 무시하여 999 유지
  static Future<void> syncBalance(int serverBalance) async {
    if (_isAdminMode) return; // 심사관 모드: 서버 값으로 덮어쓰지 않음
    _cached = serverBalance;
    _initialized = true;
    await _save();
  }

  /// 심사관 모드 활성화 (999 크레딧 설정, 영구 저장)
  static Future<void> enterAdminMode() async {
    _isAdminMode = true;
    _cached = 999;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin_mode', true);
    await _save();
  }

  /// 심사관 모드 해제
  static Future<void> exitAdminMode() async {
    _isAdminMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin_mode', false);
  }

  /// 현재 글쓰기 가능 여부
  static bool get canWrite => _isAdminMode || _cached >= writeCost;

  /// 현재 캐시된 잔액 (동기식 접근)
  static int get balance => _cached;

  /// 데이터 삭제 시 초기화 (메모리 + SharedPreferences)
  static Future<void> reset() async {
    _cached = 0;
    _initialized = false;
    _isAdminMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove('is_admin_mode');
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, _cached);
  }
}
