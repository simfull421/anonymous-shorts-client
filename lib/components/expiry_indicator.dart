// ⏳ 소멸까지 남은 시간 표시
//
// 이 앱의 핵심 구조(24시간 뒤 자동 소멸)를 화면에서 실제로 보이게 만든다.
// "3시간 전"이라는 정적인 텍스트 대신, 링이 줄어들고 색이 변하면서
// 카드마다 남은 시간이 달라 보이도록 한다.
//
// - 서버 호출 없음. createdAt만 있으면 계산된다.
// - 남은 시간에 따라 갱신 주기를 바꾼다 (10분 이상이면 30초, 미만이면 1초).
//   화면에 안 보이는 값을 초당 다시 그리는 건 낭비라서.
import 'dart:async';
import 'package:flutter/material.dart';

import '../app_theme.dart';

/// 링 게이지의 기준이 되는 전체 수명.
/// 남은 시간 계산은 서버가 준 expiresAt로 하고, 이 값은 "얼마나 남았나"를
/// 비율로 그리기 위한 표시용 분모로만 쓴다. 만료 판정에는 쓰지 않는다.
const Duration kDisplayLifetime = Duration(hours: 24);

class ExpiryIndicator extends StatefulWidget {
  /// 서버가 계산해 내려준 소멸 시각
  final DateTime expiresAt;

  const ExpiryIndicator({super.key, required this.expiresAt});

  @override
  State<ExpiryIndicator> createState() => _ExpiryIndicatorState();
}

class _ExpiryIndicatorState extends State<ExpiryIndicator> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _calcRemaining();
    _scheduleTick();
  }

  @override
  void didUpdateWidget(ExpiryIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 리스트가 위젯을 재활용해 다른 쇼츠를 넘겨줄 수 있다
    if (oldWidget.expiresAt != widget.expiresAt) {
      _remaining = _calcRemaining();
      _scheduleTick();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _calcRemaining() {
    final left = widget.expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// 남은 시간대에 맞는 주기로 타이머를 다시 건다.
  void _scheduleTick() {
    _timer?.cancel();
    if (_remaining == Duration.zero) return;

    // 분 단위만 보여주는 구간에서 초마다 setState를 부르면 그냥 낭비다
    final interval = _remaining.inMinutes < 10
        ? const Duration(seconds: 1)
        : const Duration(seconds: 30);

    _timer = Timer.periodic(interval, (_) {
      if (!mounted) return;
      final next = _calcRemaining();
      final crossedThreshold =
          (_remaining.inMinutes >= 10) != (next.inMinutes >= 10);
      setState(() => _remaining = next);

      if (next == Duration.zero) {
        _timer?.cancel();
      } else if (crossedThreshold) {
        _scheduleTick(); // 10분 경계를 넘었으면 주기를 바꿔 다시 건다
      }
    });
  }

  /// 남은 비율 (1.0 = 방금 작성, 0.0 = 소멸)
  double get _ratio =>
      (_remaining.inSeconds / kDisplayLifetime.inSeconds).clamp(0.0, 1.0);

  /// 초록 → 앰버 → 빨강.
  /// 회색으로 두면 "비활성"으로 읽힌다. 게시 중인 글은 살아 있는 상태이므로
  /// 의미 색(success)을 쓴다. 테마(배경 명도)와는 별개로 뜻이 유지되는 축이다.
  ///
  /// ⚠️ 색만으로 정보를 전달하지 않는다 — 남은 시간은 옆 텍스트에 그대로 적혀 있고,
  /// 임박하면 글자 굵기와 배경까지 함께 바뀐다. 색은 보강 신호일 뿐이다.
  /// (적록색약이 가장 흔한데, 초록/앰버/빨강은 그들에게 구분이 어렵다)
  Color get _color {
    if (_remaining == Duration.zero) return AppTheme.expiredColor;
    if (_remaining.inMinutes < 60) return AppTheme.dangerColor;
    if (_remaining.inHours < 3) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  String get _label {
    if (_remaining == Duration.zero) return '곧 사라져요';

    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;

    if (h > 0) return '$h시간 $m분 후 사라짐';
    if (_remaining.inMinutes >= 10) return '$m분 후 사라짐';
    return '$m분 $s초 후 사라짐';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    // 3시간 미만 = 배경까지 물들여 눈에 띄게, 1시간 미만 = 글자도 굵게.
    // 색 외에 두 개의 신호를 더 두는 이유는 색각 이상에서도 구분되게 하기 위함.
    final tinted = _remaining > Duration.zero && _remaining.inHours < 3;
    final urgent = _remaining > Duration.zero && _remaining.inMinutes < 60;

    return Semantics(
      label: '소멸까지 $_label',
      excludeSemantics: true,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tinted ? color.withValues(alpha: 0.12) : AppTheme.glassFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tinted ? color.withValues(alpha: 0.35) : AppTheme.glassBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              value: _ratio,
              strokeWidth: 2,
              backgroundColor: AppTheme.glassBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            _label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: urgent ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
