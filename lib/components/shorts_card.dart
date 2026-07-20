// 🃏 쇼츠 카드 위젯 (feed_screen.dart에서 추출)
// - 본문 표시 + 투표 버튼
// - 글자 수에 따른 가변 폰트 크기 (짧은 글일수록 크게)
// - 신고/차단은 우상단 ⋯ 메뉴로 정리 (부정적 액션 후면 배치)
// - Glassmorphism UI + 페이드인 애니메이션
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../models/shorts_model.dart';
import 'vote_button.dart';
import 'report_button.dart';

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: AppTheme.glassDecoration,
          child: Stack(
            children: [
              // ⋯ 메뉴 (신고/차단) — 우상단으로 후면 배치
              if (!short.isAd)
                Positioned(
                  top: 8,
                  right: 8,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz,
                        color: Colors.white38, size: 22),
                    color: AppTheme.cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    onSelected: (value) {
                      if (value == 'report') {
                        ReportGuard.report(context, short.id, onReported);
                      } else if (value == 'block') {
                        onBlockUser();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined,
                                color: Colors.white54, size: 18),
                            SizedBox(width: 10),
                            Text('신고하기',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                      if (short.creatorHash != null)
                        const PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block,
                                  color: Colors.white54, size: 18),
                              SizedBox(width: 10),
                              Text('이 유저 차단',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14)),
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
                        child: const Text('💎 Sponsored',
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
                                onPressed: () async {
                                  if (short.targetUrl != null) {
                                    final uri = Uri.parse(short.targetUrl!);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode:
                                              LaunchMode.externalApplication);
                                    }
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
        ),
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
