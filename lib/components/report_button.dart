// 🚨 신고 버튼 위젯 (UC03)
// - 1.5초 디바운스 내장 (UC03 예외흐름 E2)
// - 로컬 1시간 5회 제한 검증 (UC03 예외흐름 E1)
// - 화면 즉시 은폐 → API 호출 (UC03 기본흐름 3)
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportButton extends StatefulWidget {
  final int shortsId;
  final VoidCallback onReported; // 신고 후 해당 쇼츠를 화면에서 제거하는 콜백

  const ReportButton({
    super.key,
    required this.shortsId,
    required this.onReported,
  });

  @override
  State<ReportButton> createState() => _ReportButtonState();
}

class _ReportButtonState extends State<ReportButton> {
  // 1.5초 디바운스용 타임스탬프 (UC03 E2)
  static DateTime _lastReportTime = DateTime(2000);
  static const int _debounceMs = 1500;

  // 1시간 5회 제한 (UC03 E1) — static으로 앱 세션 동안 유지
  static final List<DateTime> _reportHistory = [];
  static const int _hourlyLimit = 5;

  bool _isReporting = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isReporting ? null : () => _handleReport(context),
      icon: Icon(
        Icons.flag_outlined,
        color: _isReporting ? Colors.grey : Colors.white38,
        size: 22,
      ),
      tooltip: '신고',
    );
  }

  Future<void> _handleReport(BuildContext context) async {
    final now = DateTime.now();

    // E2: 1.5초 이내 연속 클릭 차단
    if (now.difference(_lastReportTime).inMilliseconds < _debounceMs) {
      return;
    }
    _lastReportTime = now;

    // E1: 1시간 5회 제한 검증 (슬라이딩 윈도우)
    _reportHistory.removeWhere(
        (time) => now.difference(time).inMinutes >= 60);

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

    setState(() => _isReporting = true);

    // 기본흐름 3: 화면에서 즉시 은폐
    widget.onReported();

    // API 호출 (백그라운드)
    _reportHistory.add(now);
    await ApiService.report(widget.shortsId);

    if (mounted) {
      setState(() => _isReporting = false);
    }
  }
}
