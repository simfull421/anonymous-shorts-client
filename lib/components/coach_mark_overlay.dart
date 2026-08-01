// 🎓 첫 실행 코치마크 오버레이 (2단계 온보딩)
// - Step 1: 위로 스와이프 안내
// - Step 2: 투표 → 크레딧 → 글쓰기 루프 안내 (하단 연필 버튼 가리킴)
// - 어디든 탭하면 다음 단계 / 완료 시 SharedPreferences 저장
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 코치마크는 어떤 테마에서든 78% 검은 스크림 위에 그려진다.
// 그래서 여기서만은 AppTheme을 따르지 않고 다크 기준 색을 고정한다.
// (라이트 테마 색을 쓰면 검은 배경 위 검은 글씨가 된다)
const Color _onScrim = Colors.white;
const Color _onScrimMuted = Color(0xBFFFFFFF); // white 75%
const Color _scrimAccent = Color(0xFF9D4EDD);
const Color _scrimSecondary = Color(0xFF00E5FF);

class CoachMarkOverlay extends StatefulWidget {
  final VoidCallback onFinished;

  const CoachMarkOverlay({super.key, required this.onFinished});

  static const String _seenKey = 'coach_mark_seen';

  /// 코치마크를 아직 안 봤는지
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_seenKey) ?? false);
  }

  /// 완료 처리
  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  /// 🔁 튜토리얼 다시 보기 요청 (설정 > 도움말 → 피드로 복귀 시 즉시 표시)
  static final ValueNotifier<bool> replayRequested = ValueNotifier(false);

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay> {
  int _step = 0;
  static const int _lastStep = 2;

  Future<void> _nextStep() async {
    if (_step < _lastStep) {
      setState(() => _step += 1);
    } else {
      await CoachMarkOverlay.markSeen();
      widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _nextStep,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withValues(alpha: 0.78),
        width: double.infinity,
        height: double.infinity,
        child: switch (_step) {
          0 => _buildSwipeStep(),
          1 => _buildCreditStep(),
          _ => _buildReportStep(),
        },
      ),
    );
  }

  /// Step 1: 스와이프 안내
  Widget _buildSwipeStep() {
    return Column(
      key: const ValueKey('step0'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.keyboard_double_arrow_up_rounded,
                color: _scrimSecondary, size: 56)
            .animate(onPlay: (c) => c.repeat())
            .slideY(begin: 0.25, end: -0.25, duration: 900.ms, curve: Curves.easeInOut)
            .fadeIn(duration: 300.ms),
        const SizedBox(height: 20),
        const Text(
          '위로 스와이프하면\n다음 쇼츠가 나와요',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _onScrim,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 60),
        _tapHint('화면을 탭해서 계속'),
      ],
    ).animate().fadeIn(duration: 350.ms);
  }

  /// Step 2: 크레딧 루프 안내 (하단 연필 버튼을 가리킴)
  Widget _buildCreditStep() {
    return Column(
      key: const ValueKey('step1'),
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            '감정 버튼에 투표하면\n크레딧이 1개씩 쌓여요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _onScrim,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '10개를 모으면 아래 연필 버튼으로\n나만의 쇼츠를 쓸 수 있어요 ✍️',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _onScrimMuted,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '🎁 첫 투표에는 웰컴 보너스 10개를 바로 드려요!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _scrimSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 28),
        _tapHint('화면을 탭해서 계속'),
        const SizedBox(height: 24),
        // 하단 중앙 연필 버튼을 가리키는 화살표
        Icon(Icons.keyboard_double_arrow_down_rounded,
                color: _scrimAccent, size: 44)
            .animate(onPlay: (c) => c.repeat())
            .slideY(begin: -0.2, end: 0.2, duration: 800.ms, curve: Curves.easeInOut),
        const SizedBox(height: 66), // 하단 바 높이만큼 띄워 버튼 위를 가리키게
      ],
    ).animate().fadeIn(duration: 350.ms);
  }

  /// Step 3: 신고/차단 안내 (⋯ 메뉴 위치를 가리킴)
  Widget _buildReportStep() {
    return Stack(
      key: const ValueKey('step2'),
      children: [
        // 카드 우상단 ⋯ 위치를 가리키는 화살표 (카드 마진 20 + 여백 고려)
        Positioned(
          top: 90,
          right: 40,
          child: Icon(Icons.north_east_rounded,
                  color: _scrimAccent, size: 40)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .slideY(begin: 0.15, end: -0.15, duration: 800.ms, curve: Curves.easeInOut),
        ),
        // Positioned.fill로 감싸야 Stack 안에서 정중앙 정렬됨
        // (Stack의 기본 정렬이 topStart라 Column이 좌상단으로 밀리는 문제 수정)
        Positioned.fill(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined,
                color: _scrimSecondary, size: 44),
            const SizedBox(height: 16),
            const Text(
              '불쾌한 쇼츠가 보이면\n오른쪽 위 ⋯ 메뉴를 눌러요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _onScrim,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '신고하거나 작성자를 차단하면\n피드에서 바로 사라져요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _onScrimMuted,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            _tapHint('화면을 탭해서 시작하기'),
          ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _tapHint(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: _onScrimMuted, fontSize: 13),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
        begin: 0.6, end: 1.0, duration: 900.ms);
  }
}
