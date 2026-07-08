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

class VoteButton extends StatefulWidget {
  final ButtonModel button;
  final int totalVotes;
  final int shortsId;
  final bool hasVoted; // 이 쇼츠에 이미 투표했는지
  final int? votedIndex; // 내가 투표한 버튼 index (null = 미투표)
  final VoidCallback onVoteSuccess;
  final VoidCallback onVoteFailed;

  const VoteButton({
    super.key,
    required this.button,
    required this.totalVotes,
    required this.shortsId,
    required this.hasVoted,
    this.votedIndex,
    required this.onVoteSuccess,
    required this.onVoteFailed,
  });

  @override
  State<VoteButton> createState() => _VoteButtonState();
}

class _VoteButtonState extends State<VoteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _percentAnimation;
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
    _percentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
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
        foregroundColor: Colors.white,
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
    final animatedPercent =
        _justVoted ? _percentAnimation.value * _percent : _percent;
    final displayPercent = (animatedPercent * 100).toStringAsFixed(1);

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
            AnimatedContainer(
              duration: _justVoted
                  ? const Duration(milliseconds: 500)
                  : const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: MediaQuery.of(context).size.width * animatedPercent * 0.85,
              decoration: BoxDecoration(
                color: _isMyVote
                    ? AppTheme.accentColor.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.08),
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
                          Icon(Icons.check_circle, color: AppTheme.accentColor, size: 16),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            widget.button.text,
                            style: TextStyle(
                              color: _isMyVote ? Colors.white : Colors.white70,
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
                    '$displayPercent%  ${widget.button.votes}표',
                    style: TextStyle(
                      color: _isMyVote ? AppTheme.accentColor : Colors.white54,
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

    // 로컬 즉시 반영 (Optimistic UI)
    widget.button.votes += 1;
    setState(() => _justVoted = true);
    _animController.forward(from: 0);
    widget.onVoteSuccess();

    // 크레딧 적립 시도
    final creditEarned = await CreditManager.earnCredit();

    // API 호출
    final success = await ApiService.vote(widget.shortsId, widget.button.index);

    if (!success) {
      // UC02 예외흐름 E3: API 실패 시 롤백
      widget.button.votes -= 1;
      if (creditEarned) {
        await CreditManager.syncBalance(CreditManager.balance - 1);
      }
      if (mounted) setState(() => _justVoted = false);
      widget.onVoteFailed();
    }

    // UC02 예외흐름 E1: 크레딧 상한 도달 알림
    if (!creditEarned && success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('크레딧이 꽉 찼습니다. 글을 작성해 보세요!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
