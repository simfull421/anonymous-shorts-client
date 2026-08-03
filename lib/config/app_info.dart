// 📛 앱 표시 이름 상수
//
// 화면 곳곳에 이름을 직접 박아두면 다음 개명 때 또 전부 찾아 고쳐야 한다.
// 이 값 하나만 바꾸면 클라이언트 쪽 표시는 전부 따라간다.
//
// 단, 이 상수는 Dart 코드 안에서만 통함 — 아래는 여전히 별도로 관리해야 함:
//   - android/app/src/main/res/values(-ko)/strings.xml (app_name, 런처 라벨)
//   - ios/Runner/Info.plist (CFBundleDisplayName)
// OS 레벨 런처 이름은 네이티브 리소스라 Dart 상수가 대신할 수 없다.
class AppInfo {
  AppInfo._();

  static const String name = '타닥';
}
