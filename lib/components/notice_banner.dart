// 📢 공지 배너 컴포넌트
// - 새 공지가 있을 때 피드 상단에서 부드럽게 슬라이드 다운
// - '자세히' 탭 → 상세 바텀시트 (법적 문서 변경 고지 의무 이행)
// - X 탭 또는 상세 확인 시 markLatestSeen() 처리 후 다시 노출 안 함
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../utils/notice_manager.dart';

class NoticeBanner extends StatelessWidget {
  final AppNotice notice;
  final VoidCallback onDismissed; // 확인/닫기 완료 후 부모에서 배너 제거

  const NoticeBanner({
    super.key,
    required this.notice,
    required this.onDismissed,
  });

  Future<void> _dismiss() async {
    await NoticeManager.markLatestSeen();
    onDismissed();
  }

  void _showDetail(BuildContext context) {
    showNoticeDetailSheet(context, notice, onConfirmed: _dismiss);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.accentColor.withValues(alpha: 0.45),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.campaign_outlined,
                  color: AppTheme.accentColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notice.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${notice.summary} · 자세히 보기',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _dismiss,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, color: Colors.white38, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .slideY(
          begin: -1.4,
          end: 0,
          duration: 550.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 400.ms);
  }
}

/// 공지 상세 바텀시트 (배너와 설정 화면에서 공용 사용)
void showNoticeDetailSheet(
  BuildContext context,
  AppNotice notice, {
  Future<void> Function()? onConfirmed,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign_outlined,
                    color: AppTheme.accentColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notice.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(notice.date,
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: notice.details
                      .map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('•  ',
                                  style: TextStyle(
                                      color: AppTheme.accentColor,
                                      fontSize: 13)),
                              Expanded(
                                child: Text(
                                  d,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13.5,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (notice.linkUrl != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(notice.linkUrl!);
                    try {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(notice.linkLabel ?? '자세히 보기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondaryAccent,
                    side: BorderSide(
                        color:
                            AppTheme.secondaryAccent.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  if (onConfirmed != null) await onConfirmed();
                },
                style: AppTheme.submitButtonStyle,
                child: const Text('확인',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
