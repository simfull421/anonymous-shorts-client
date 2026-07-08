/// 🕵️ 심사관 모드 진입 로직 (UC09)
/// - 앱 버전 텍스트를 1.5초 이내에 5회 연속 탭 시 활성화
/// - 조건 충족 시 콜백 함수 호출 → 로그인 모달 팝업
class HiddenJudge {
  static const int _requiredTaps = 5;
  static const int _timeWindowMs = 1500; // 1.5초

  final List<int> _tapTimestamps = [];
  final void Function() onActivated;

  HiddenJudge({required this.onActivated});

  /// 앱 버전 텍스트 탭 시 호출
  void onTap() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 타임스탬프 기록
    _tapTimestamps.add(now);

    // 5회 미만이면 대기
    if (_tapTimestamps.length < _requiredTaps) return;

    // 최근 5회만 유지
    while (_tapTimestamps.length > _requiredTaps) {
      _tapTimestamps.removeAt(0);
    }

    // 첫 탭과 마지막 탭의 간격이 1.5초 이내인지 검사 (UC09 예외흐름 E1)
    final firstTap = _tapTimestamps.first;
    final lastTap = _tapTimestamps.last;

    if (lastTap - firstTap <= _timeWindowMs) {
      _tapTimestamps.clear();
      onActivated(); // 심사관 로그인 모달 팝업 트리거
    }
  }

  /// 상태 초기화
  void reset() {
    _tapTimestamps.clear();
  }
}
