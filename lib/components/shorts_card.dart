// 🃏 쇼츠 카드 위젯 (feed_screen.dart에서 추출)
// - 본문 표시 + 투표 버튼
// - 글자 수에 따른 가변 폰트 크기 (짧은 글일수록 크게)
// - 신고/차단은 우상단 ⋯ 메뉴로 정리 (부정적 액션 후면 배치)
// - Glassmorphism UI + 페이드인 애니메이션
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app_theme.dart';
import '../config/app_links.dart';
import '../models/shorts_model.dart';
import 'vote_button.dart';
import 'report_sheet.dart';

class ShortsCard extends StatelessWidget {
  final ShortsModel short;
  final bool hasVoted;
  final int? votedIndex;
  final ValueChanged<int> onVoteSuccess; // buttonIndex
  final VoidCallback onVoteFailed;
  final VoidCallback onReported;
  final VoidCallback onBlockUser;
  final VoidCallback? onCreditSynced; // 서버 크레딧 동기화 후 UI 갱신

  const ShortsCard({
    super.key,
    required this.short,
    required this.hasVoted,
    this.votedIndex,
    required this.onVoteSuccess,
    required this.onVoteFailed,
    required this.onReported,
    required this.onBlockUser,
    this.onCreditSynced,
  });

  /// 글자 수에 따른 가변 폰트 크기 — 짧은 글은 임팩트 있게, 긴 글은 밀도 있게
  double get _fontSize {
    final len = short.textContent.length;
    if (len <= 30) return 32;
    if (len <= 60) return 28;
    if (len <= 100) return 24;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    final int totalVotes = short.computedTotalVotes;

    // ⚡ 예전에는 ClipRRect > BackdropFilter(blur 10) 로 감싸고 있었다.
    // 카드 뒤에는 Scaffold의 단색 배경밖에 없어서 블러 결과가 원본과 동일했고
    // (단색을 흐리면 같은 단색), 화면에 보이는 유리 질감은 전부
    // glassDecoration의 반투명 흰 면 + 테두리에서 나온다.
    // 즉 눈에 보이는 변화 없이 saveLayer 2개(clip + backdrop)만 쓰고 있었다.
    // 배경에 그라디언트나 이미지를 넣게 되면 그때 다시 감싸면 된다.
    return Container(
          margin: const EdgeInsets.all(20),
          decoration: AppTheme.glassDecoration,
          child: Stack(
            children: [
              // ⏳ 소멸 카운트다운은 여기 두지 않는다.
              // 피드에는 시드 데이터가 섞여 있는데 시드는 스케줄러가 타임스탬프를
              // 갱신해서 실제로는 사라지지 않는다. "3시간 뒤 사라짐"은 지켜지지 않는
              // 약속이 되고, 사용자가 스크린샷 두 장으로 반증할 수 있다.
              // → 전부 본인 글인 마이페이지에서만 표시한다 (거기선 참이다).

              // ⋯ 메뉴 (신고/차단) — 우상단으로 후면 배치
              if (!short.isAd)
                Positioned(
                  top: 8,
                  right: 8,
                  child: PopupMenuButton<String>(
                    // 스크린리더에 '버튼'이 아니라 무슨 버튼인지 읽히도록
                    tooltip: '신고 및 차단 메뉴',
                    icon: Icon(Icons.more_horiz,
                        color: AppTheme.textDisabled, size: 22),
                    color: AppTheme.cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    onSelected: (value) {
                      if (value == 'report') {
                        // 2트랙 신고 시트 (규칙 위반 / 권리침해 분리)
                        showReportSheet(
                          context,
                          short: short,
                          onReported: onReported,
                        );
                      } else if (value == 'block') {
                        onBlockUser();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined,
                                color: AppTheme.textTertiary, size: 18),
                            const SizedBox(width: 10),
                            Text('신고하기',
                                style: TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 14)),
                          ],
                        ),
                      ),
                      if (short.creatorHash != null)
                        PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block,
                                  color: AppTheme.textTertiary, size: 18),
                              const SizedBox(width: 10),
                              Text('이 유저 차단',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary, fontSize: 14)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

              // 본문 + 투표 영역
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 광고 배지
                    if (short.isAd)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.accentColor
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Text('💎 Sponsored',
                            style: TextStyle(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .shimmer(duration: 2.seconds),

                    // 쇼츠 본문 (가변 폰트)
                    Text(
                      short.textContent,
                      style: AppTheme.mainContentStyle
                          .copyWith(fontSize: _fontSize),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, duration: 400.ms),
                    const SizedBox(height: 36),

                    // 광고: 외부 URL 버튼 / 일반: 투표 버튼
                    if (short.isAd)
                      ...short.buttons.map((btn) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: AppTheme.submitButtonStyle,
                                onPressed: () {
                                  final url = short.targetUrl;
                                  if (url != null) {
                                    openExternalUrl(context, url);
                                  }
                                },
                                child: Text(btn.text),
                              ),
                            ),
                          ))
                    else
                      ...short.buttons.map((btn) {
                        return VoteButton(
                          button: btn,
                          totalVotes: totalVotes,
                          shortsId: short.id,
                          hasVoted: hasVoted,
                          votedIndex: votedIndex,
                          onVoteSuccess: () => onVoteSuccess(btn.index),
                          onVoteFailed: onVoteFailed,
                          onCreditSynced: onCreditSynced,
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
            duration: 300.ms);
  }
}
