// 💫 투표 순간 이모지 버스트
//
// 투표 버튼은 clipBehavior가 걸려 있어서 그 안에서 파티클을 띄우면 잘린다.
// 그래서 Overlay에 얹어 위젯 경계를 벗어나 날아가게 한다.
// 레이아웃에 영향을 주지 않고, 애니메이션이 끝나면 스스로 사라진다.
import 'dart:math';
import 'package:flutter/material.dart';

const List<String> _kEmojis = ['✨', '💜', '🔥', '⭐', '💫'];

final Random _rng = Random();

/// [context]가 가리키는 위젯의 중심에서 이모지를 터뜨린다.
/// 위젯이 아직 레이아웃되지 않았거나 Overlay가 없으면 조용히 무시한다.
void showVoteBurst(BuildContext context, {int count = 6}) {
  final overlay = Overlay.maybeOf(context);
  final box = context.findRenderObject() as RenderBox?;
  if (overlay == null || box == null || !box.hasSize) return;

  final origin = box.localToGlobal(box.size.center(Offset.zero));

  OverlayEntry? entry;
  var removed = false;
  void remove() {
    if (removed) return;
    removed = true;
    entry?.remove();
  }

  entry = OverlayEntry(
    builder: (_) => _VoteBurst(origin: origin, count: count, onDone: remove),
  );
  overlay.insert(entry);
}

class _Particle {
  final String emoji;
  final double dx; // 좌우 흩어짐
  final double rise; // 위로 올라가는 거리
  final double delay; // 0.0~0.25 — 동시에 튀어나오면 뭉쳐 보인다
  final double tilt;
  final double size;

  _Particle()
      : emoji = _kEmojis[_rng.nextInt(_kEmojis.length)],
        dx = (_rng.nextDouble() - 0.5) * 90,
        rise = 60 + _rng.nextDouble() * 55,
        delay = _rng.nextDouble() * 0.25,
        tilt = (_rng.nextDouble() - 0.5) * 0.6,
        size = 16 + _rng.nextDouble() * 10;
}

class _VoteBurst extends StatefulWidget {
  final Offset origin;
  final int count;
  final VoidCallback onDone;

  const _VoteBurst({
    required this.origin,
    required this.count,
    required this.onDone,
  });

  @override
  State<_VoteBurst> createState() => _VoteBurstState();
}

class _VoteBurstState extends State<_VoteBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.count, (_) => _Particle());
    _c = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 터치를 가로채면 안 된다 — 순수 장식
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Stack(
            children: _particles.map((p) {
              // 각 파티클이 자기 딜레이만큼 늦게 시작하도록 진행도를 재매핑
              final raw = ((_c.value - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
              if (raw == 0) return const SizedBox.shrink();

              final eased = Curves.easeOutCubic.transform(raw);
              // 마지막 45% 구간에서만 사라진다 (처음부터 흐려지면 안 보임)
              final opacity = raw < 0.55
                  ? 1.0
                  : (1.0 - (raw - 0.55) / 0.45).clamp(0.0, 1.0);
              final scale = raw < 0.3
                  ? 0.6 + (raw / 0.3) * 0.5 // 튀어나오며 커짐
                  : 1.1 - (raw - 0.3) / 0.7 * 0.25;

              return Positioned(
                left: widget.origin.dx + p.dx * eased - p.size,
                top: widget.origin.dy - p.rise * eased - p.size,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.rotate(
                    angle: p.tilt * eased,
                    child: Transform.scale(
                      scale: scale,
                      child: Text(
                        p.emoji,
                        style: TextStyle(fontSize: p.size),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
