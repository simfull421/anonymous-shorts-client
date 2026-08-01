// 🎭 반응 버튼 프리셋
//
// 작성 폼에서 사용자가 해야 하는 일이 원래 3가지였다.
//   (1) 본문 쓰기  (2) 반응1 짓기  (3) 반응2 짓기
// 이 중 (2)(3)은 "무슨 반응을 만들지"를 매번 발명해야 해서
// 글은 떠올랐는데 버튼에서 막히는 지점이 된다.
//
// 그래서 프리셋을 '옵션'으로 얹는 대신, **기본값을 미리 채워둔다.**
// 필수 행동이 3개 → 1개로 줄고, 커스텀은 하고 싶은 사람만 손대면 된다.
// (옵션으로 두면 대부분은 옵션이 있는지도 모른 채 빈 칸을 마주한다)
//
// 이모지를 붙인 이유는 피드에 색과 표정을 공짜로 넣기 위해서다.
// 작성자가 고른 값이라 조작이 아니고, 투표 버튼이 한눈에 구분된다.
class ReactionPreset {
  final String id;
  final String label; // 칩에 표시
  final List<String> buttons;

  const ReactionPreset({
    required this.id,
    required this.label,
    required this.buttons,
  });
}

class ReactionPresets {
  ReactionPresets._();

  /// 폼을 열었을 때 미리 채워지는 기본값
  static const ReactionPreset defaultPreset = empathy;

  static const ReactionPreset empathy = ReactionPreset(
    id: 'empathy',
    label: '공감',
    buttons: ['😌 나도 그래', '🤨 난 아닌데'],
  );

  static const ReactionPreset agree = ReactionPreset(
    id: 'agree',
    label: '찬반',
    buttons: ['👍 찬성', '👎 반대'],
  );

  static const ReactionPreset judge = ReactionPreset(
    id: 'judge',
    label: '판단',
    buttons: ['👏 잘했어', '😬 잘못했어', '🤔 애매해'],
  );

  static const ReactionPreset emotion = ReactionPreset(
    id: 'emotion',
    label: '감정',
    buttons: ['😂 웃겨', '😢 슬퍼', '😡 화나', '😲 놀라워'],
  );

  static const List<ReactionPreset> all = [empathy, agree, judge, emotion];

  /// 현재 입력값과 정확히 일치하는 프리셋 찾기.
  /// 사용자가 한 글자라도 고치면 null이 되고 칩 선택이 풀린다.
  /// (고쳤는데도 프리셋이 선택된 것처럼 보이면 그건 거짓말이다)
  static ReactionPreset? match(List<String> texts) {
    for (final p in all) {
      if (p.buttons.length != texts.length) continue;
      var same = true;
      for (var i = 0; i < texts.length; i++) {
        if (p.buttons[i] != texts[i]) {
          same = false;
          break;
        }
      }
      if (same) return p;
    }
    return null;
  }
}
