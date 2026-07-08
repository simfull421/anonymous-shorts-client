import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dart-define values should be injected', () {
    const hmacSecret = String.fromEnvironment('HMAC_SECRET');
    const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'NOT_SET');
    
    print('========== [TEST] dart-define 확인 ==========');
    print('  HMAC_SECRET 길이: ${hmacSecret.length}');
    print('  HMAC_SECRET 비어있음: ${hmacSecret.isEmpty}');
    print('  HMAC_SECRET 전체값: "$hmacSecret"');
    print('  API_URL: $apiUrl');
    print('=============================================');

    // HMAC_SECRET이 비어있지 않아야 함
    expect(hmacSecret.isNotEmpty, true, reason: 'HMAC_SECRET이 주입되지 않았습니다');
    expect(hmacSecret, 'AS_Prod_9xK2mP8vL5cW7bN4zR3yH1fQ_T6aJ_v2_SecureKey2026');
  });
}
