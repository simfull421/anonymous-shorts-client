// 🗳️ 투표 버튼 위젯 (UC02)
// - 투표 전: 버튼 텍스트만 표시 (투표 유도)
// - 투표 후: 퍼센트 바 + 수치 애니메이션 (결과 공개)
// - 햅틱 피드백 + 스케일 애니메이션
// - 로컬 즉시 반영 + API 실패 시 롤백
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../models/shorts_model.dart';
import '../services/api_service.dart';
import '../utils/credit_manager.dart';
import 'vote_burst.dart';

class VoteButton extends StatefulWidget {
  final ButtonModel button;
  final int totalVotes;
  final int shortsId;
  final bool hasVoted; // 이 쇼츠에 이미 투표했는지
  final int? votedIndex; // 내가 투표한 버튼 index (null = 미투표)
  final VoidCallback onVoteSuccess;
  final VoidCallback onVoteFailed;
  final VoidCallback? onCreditSynced; // 서버 잔액 동기화 후 UI 갱신 (웰컴 보너스 등)

  const VoteButton({
    super.key,
    required this.button,
    required this.totalVotes,
    required this.shortsId,
    required this.hasVoted,
    this.votedIndex,
    required this.onVoteSuccess,
    required this.onVoteFailed,
    this.onCreditSynced,
  });

  @override
  State<VoteButton> createState() => _VoteButtonState();
}

class _VoteButtonState extends State<VoteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _percentAnimation;
  late Animation<double> _barAnimation;
  bool _justVoted = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    // 숫자용 — 절대 1.0을 넘으면 안 된다 (넘으면 112% 같은 값이 찍힌다)
    _percentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    // 막대용 — 살짝 넘쳤다 되돌아오며 '탁' 채워지는 느낌을 만든다
    _barAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double get _percent =>
      widget.totalVotes > 0 ? (widget.button.votes / widget.totalVotes) : 0;

  bool get _isMyVote => widget.votedIndex == widget.button.index;

  bool get _showResult => widget.hasVoted || _justVoted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) => Transform.scale(
          scale: _justVoted && _isMyVote ? _scaleAnimation.value : 1.0,
          child: SizedBox(
            width: double.infinity,
            child: _showResult ? _buildResultButton() : _buildVoteButton(),
          ),
        ),
      ),
    );
  }

  /// 투표 전: 깔끔한 텍스트 버튼
  Widget _buildVoteButton() {
    return ElevatedButton(
      onPressed: () => _handleVote(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.cardColor,
        foregroundColor: AppTheme.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        widget.button.text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 투표 후: 퍼센트 바 + 수치 표시
  Widget _buildResultButton() {
    // 숫자와 막대를 다른 커브로 굴린다 — 막대는 튀고, 숫자는 정확해야 한다
    final numberProgress = _justVoted ? _percentAnimation.value : 1.0;
    final barProgress = _justVoted ? _barAnimation.value.clamp(0.0, 1.15) : 1.0;

    final animatedPercent = _percent * barProgress;
    final displayPercent = (_percent * numberProgress * 100).toStringAsFixed(1);
    // 결과가 공개되며 표 수가 0부터 올라간다
    final displayVotes = (widget.button.votes * numberProgress).round();

    return GestureDetector(
      onTap: null, // 투표 후 비활성
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.cardColor.withValues(alpha: 0.5),
          border: _isMyVote
              ? Border.all(color: AppTheme.accentColor.withValues(alpha: 0.6), width: 1.5)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 퍼센트 바 (배경)
            // AnimatedContainer가 아니라 Container인 이유:
            // 폭을 AnimationController로 이미 매 프레임 직접 그리고 있어서,
            // 그 위에 암시적 애니메이션을 얹으면 값이 뒤처지며 뭉개진다.
            Container(
              width: MediaQuery.of(context).size.width * animatedPercent * 0.85,
              decoration: BoxDecoration(
                color: _isMyVote
                    ? AppTheme.accentColor.withValues(alpha: 0.25)
                    : AppTheme.glassFill,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // 텍스트 + 퍼센트
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 내 투표 표시 + 텍스트
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isMyVote) ...[
                          // 체크가 '툭' 하고 나타나도록 살짝 오버슈트
                          Transform.scale(
                            scale: _justVoted
                                ? Curves.easeOutBack
                                    .transform(_animController.value)
                                    .clamp(0.0, 1.2)
                                : 1.0,
                            child: Icon(Icons.check_circle,
                                color: AppTheme.accentColor, size: 16),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            widget.button.text,
                            style: TextStyle(
                              color: _isMyVote
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: _isMyVote ? FontWeight.w600 : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 퍼센트 + 투표수
                  Text(
                    '$displayPercent%  $displayVotes표',
                    style: TextStyle(
                      color: _isMyVote ? AppTheme.accentColor : AppTheme.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleVote(BuildContext context) async {
    // UC02 기본흐름 2: 햅틱 진동
    HapticFeedback.mediumImpact();
    // 💫 누른 자리에서 이모지가 터진다 (Overlay라 버튼 밖으로 날아간다)
    showVoteBurst(context);

    // 로컬 즉시 반영 (Optimistic UI)
    widget.button.votes += 1;
    setState(() => _justVoted = true);
    _animController.forward(from: 0);
    widget.onVoteSuccess();

    // 크레딧 적립 시도 (Optimistic +1)
    final creditEarned = await CreditManager.earnCredit();

    // API 호출
    final result = await ApiService.vote(widget.shortsId, widget.button.index);

    if (!result.success) {
      // UC02 예외흐름 E3: API 실패 시 롤백
      widget.button.votes -= 1;
      if (creditEarned) {
        await CreditManager.syncBalance(CreditManager.balance - 1);
      }
      if (mounted) setState(() => _justVoted = false);
      widget.onVoteFailed();
      return;
    }

    // 서버가 잔액을 내려주면 즉시 동기화 (웰컴 보너스 10 크레딧 반영)
    if (result.balance != null) {
      await CreditManager.syncBalance(result.balance!);
      widget.onCreditSynced?.call(); // 하단 게이지/배지 즉시 갱신
    }

    // UC02 예외흐름 E1: 크레딧 상한 도달 알림
    if (!creditEarned && result.balance == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('크레딧이 꽉 찼습니다. 글을 작성해 보세요!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
