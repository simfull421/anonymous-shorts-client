import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'config/app_info.dart';
import 'theme/app_palette.dart';
import 'theme/theme_controller.dart';
import 'screens/feed_screen.dart';
import 'screens/my_page_screen.dart';
import 'screens/consent_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 전역 에러 핸들링 (크래시 원인 화면 표시)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  // 📱 Android 15(SDK 35)부터는 시스템이 강제로 edge-to-edge를 켠다.
  // 명시적으로 선언해두면 그 이전 버전에서도 동작이 같아져서,
  // 인셋 처리를 한 벌만 검증하면 된다.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runZonedGuarded(() async {
    final prefs = await SharedPreferences.getInstance();
    final consentAccepted = prefs.getBool('consent_accepted') ?? false;
    // 첫 프레임 전에 저장된 테마를 반영 (기본 테마가 번쩍이는 것 방지)
    await ThemeController.load();
    runApp(MyApp(consentAccepted: consentAccepted));
  }, (error, stack) {
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              '⚠️ CRASH LOG\n\n$error\n\n$stack',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ),
      ),
    ));
  });
}

class MyApp extends StatelessWidget {
  final bool consentAccepted;
  const MyApp({super.key, required this.consentAccepted});

  @override
  Widget build(BuildContext context) {
    // 팔레트가 바뀌면 여기서부터 전체가 다시 그려진다.
    return ValueListenableBuilder<AppPalette>(
      valueListenable: ThemeController.palette,
      builder: (context, palette, _) {
        // 시스템 바 아이콘 명암을 테마에 맞춘다.
        // ⚠️ systemNavigationBarColor / statusBarColor는 여기서 설정하지 않는다.
        // SDK 35를 타겟팅하면 Android가 이 값들을 무시한다(Window.setNavigationBarColor
        // 등이 deprecated). 배경은 앱이 직접 그리고, 시스템에는 아이콘 명암만 알려준다.
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarIconBrightness:
                palette.isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness:
                palette.isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarIconBrightness:
                palette.isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
        );

        return MaterialApp(
          title: AppInfo.name,
          theme: AppTheme.themeData,
          debugShowCheckedModeBanner: false,
          initialRoute: consentAccepted ? '/' : '/consent',
          routes: {
            '/': (context) => const FeedScreen(),
            '/mypage': (context) => const MyPageScreen(),
            '/consent': (context) => const ConsentScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
