// 🃏 쇼츠 카드 위젯 (feed_screen.dart에서 추출)
// - 본문 표시 + 투표 버튼 + 신고/차단 기능
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

  const ShortsCard({
    super.key,
    required this.short,
    required this.hasVoted,
    this.votedIndex,
    required this.onVoteSuccess,
    required this.onVoteFailed,
    required this.onReported,
    required this.onBlockUser,
  });

  @override
  Widget build(BuildContext context) {
    final int totalVotes = short.computedTotalVotes;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          decoration: AppTheme.glassDecoration,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 광고 배지
              if (short.isAd)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.5)),
                  ),
                  child: const Text('💎 Sponsored',
                      style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ).animate().fadeIn(duration: 500.ms).shimmer(duration: 2.seconds),

              // 쇼츠 본문
              Text(
                short.textContent,
                style: AppTheme.mainContentStyle,
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, duration: 400.ms),
              const SizedBox(height: 40),

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
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                  );
                }),

              const SizedBox(height: 20),

              // 신고 버튼
              if (!short.isAd)
                ReportButton(
                  shortsId: short.id,
                  onReported: onReported,
                ),

              // 유저 차단 버튼
              if (!short.isAd && short.creatorHash != null)
                TextButton.icon(
                  onPressed: onBlockUser,
                  icon: const Icon(Icons.block, color: Colors.white38, size: 16),
                  label: const Text('이 유저 차단', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 300.ms);
  }
}
