// 🔑 기기 고유 UUID 발급 및 관리
// - SharedPreferences로 UUID 관리 (flutter_secure_storage 크래시 문제 해결)
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceId {
  static const String _key = 'device_uuid';
  static String? _cachedUuid;

  /// UUID를 가져오거나, 없으면 최초 생성
  static Future<String> getOrCreate() async {
    if (_cachedUuid != null) return _cachedUuid!;

    final prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString(_key);

    if (uuid == null || uuid.isEmpty) {
      uuid = _generateUuidV4();
      await prefs.setString(_key, uuid);
    }

    _cachedUuid = uuid;
    return uuid;
  }

  /// 데이터 삭제 시 UUID 초기화
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _cachedUuid = null;
  }

  /// UUID v4 생성
  static String _generateUuidV4() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
