import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dart-define values should be injected', () {
    const hmacSecret = String.fromEnvironment('HMAC_SECRET');
    const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'NOT_SET');

    // ⚠️ 시크릿 값 자체는 출력하거나 하드코딩하지 않는다 (주입 여부만 검증)
    expect(hmacSecret.isNotEmpty, true, reason: 'HMAC_SECRET이 주입되지 않았습니다');
    expect(apiUrl, isNot('NOT_SET'), reason: 'API_URL이 주입되지 않았습니다');
  });
}
