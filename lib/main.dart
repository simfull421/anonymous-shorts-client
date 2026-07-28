import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
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

  runZonedGuarded(() async {
    final prefs = await SharedPreferences.getInstance();
    final consentAccepted = prefs.getBool('consent_accepted') ?? false;
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
    return MaterialApp(
      title: '익명쇼츠',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: consentAccepted ? '/' : '/consent',
      routes: {
        '/': (context) => const FeedScreen(),
        '/mypage': (context) => const MyPageScreen(),
        '/consent': (context) => const ConsentScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
