// 🚨 신고 처리 유틸 (UC03)
// - 기존 ReportButton 위젯에서 로직만 추출 (카드 ⋯ 메뉴에서 호출)
// - 1.5초 디바운스 (UC03 예외흐름 E2)
// - 로컬 1시간 5회 제한 검증 (UC03 예외흐름 E1)
// - 화면 즉시 은폐 → API 호출 (UC03 기본흐름 3)
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportGuard {
  // 1.5초 디바운스용 타임스탬프 (UC03 E2)
  static DateTime _lastReportTime = DateTime(2000);
  static const int _debounceMs = 1500;

  // 1시간 5회 제한 (UC03 E1) — 앱 세션 동안 유지
  static final List<DateTime> _reportHistory = [];
  static const int _hourlyLimit = 5;

  /// 신고 실행. 제한에 걸리면 스낵바 안내 후 무시.
  static Future<void> report(
    BuildContext context,
    int shortsId,
    VoidCallback onReported,
  ) async {
    final now = DateTime.now();

    // E2: 1.5초 이내 연속 클릭 차단
    if (now.difference(_lastReportTime).inMilliseconds < _debounceMs) {
      return;
    }
    _lastReportTime = now;

    // E1: 1시간 5회 제한 검증 (슬라이딩 윈도우)
    _reportHistory.removeWhere((time) => now.difference(time).inMinutes >= 60);

    if (_reportHistory.length >= _hourlyLimit) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('신고하기는 시간당 최대 5회까지만 가능합니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // 기본흐름 3: 화면에서 즉시 은폐
    onReported();

    // API 호출 (백그라운드)
    _reportHistory.add(now);
    await ApiService.report(shortsId);
  }
}
