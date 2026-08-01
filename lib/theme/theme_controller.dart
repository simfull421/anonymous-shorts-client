// 🎚 테마 선택 상태 관리
//
// 앱 전역에서 색을 읽는 곳이 90군데가 넘어서, 화면마다 context를 넘기는 대신
// 루트에서 ValueListenableBuilder 하나로 다시 그리는 방식을 쓴다.
// (Provider/Riverpod을 넣을 만큼의 상태가 아직 아니다 — 값 하나뿐)
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_palette.dart';

class ThemeController {
  ThemeController._();

  static const String _prefsKey = 'app_theme_id';

  /// 현재 팔레트. 이 값이 바뀌면 앱 전체가 다시 그려진다.
  static final ValueNotifier<AppPalette> palette =
      ValueNotifier<AppPalette>(AppPalettes.midnight);

  /// 앱 시작 시 1회 호출 (runApp 이전)
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    palette.value = AppPalettes.byName(prefs.getString(_prefsKey));
  }

  static Future<void> select(AppPalette next) async {
    if (palette.value.id == next.id) return;
    palette.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, next.id.name);
  }
}

/// 🔁 테마가 바뀔 때 이 화면을 강제로 다시 그린다.
///
/// AppTheme.textPrimary 같은 값은 static 게터라서 InheritedWidget이 아니다.
/// 즉 그 값을 읽는 위젯은 테마에 "구독"되어 있지 않다.
/// 루트에서 MaterialApp을 다시 만들어도, Navigator에 이미 쌓여 있는 화면은
/// 캐시된 위젯 인스턴스가 그대로 전달돼 리빌드가 생략된다.
/// → 뒤로 갔을 때 이전 화면이 옛 색으로 남아 있다가, 다른 이유로
///   setState가 한 번 돌면 그제서야 바뀐다.
///
/// ValueListenableBuilder는 스스로 리스너를 달기 때문에 조상이 리빌드를
/// 건너뛰어도 자기 서브트리는 다시 그린다. 각 화면 최상단에 하나씩 두면 된다.
class ThemedBuilder extends StatelessWidget {
  final WidgetBuilder builder;

  const ThemedBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPalette>(
      valueListenable: ThemeController.palette,
      builder: (context, _, __) => builder(context),
    );
  }
}
