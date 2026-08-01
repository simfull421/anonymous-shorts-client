// ⚙️ 설정 화면
// - 법적 문서 링크, 차단 유저 관리, 데이터 내보내기, 언어 표시
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../config/app_links.dart';
import '../theme/app_palette.dart';
import '../theme/theme_controller.dart';
import '../components/coach_mark_overlay.dart';
import '../components/notice_banner.dart';
import '../components/report_sheet.dart';
import '../services/api_service.dart';
import '../utils/block_manager.dart';
import '../utils/credit_manager.dart';
import '../utils/device_id.dart';
import '../utils/hidden_judge.dart';
import '../utils/notice_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;

  /// 🕵️ 심사관 모드 진입점 (UC09) — 하단 버전 표시를 1.5초 내 5회 탭
  late final HiddenJudge _hiddenJudge;

  @override
  void initState() {
    super.initState();
    _hiddenJudge = HiddenJudge(onActivated: _showJudgeLoginModal);
  }

  @override
  Widget build(BuildContext context) {
    return ThemedBuilder(builder: _buildScaffold);
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      // 하단 시스템 내비게이션 바에 마지막 항목이 가려지지 않도록 SafeArea 적용
      body: SafeArea(
        top: false,
        child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── 상단: 친근한 항목 먼저 ──
          _linkTile(
            icon: Icons.help_outline,
            title: '도움말',
            subtitle: '사용법이 궁금하다면',
            onTap: _showHelp,
          ),
          _linkTile(
            icon: Icons.campaign_outlined,
            title: '공지사항',
            subtitle: NoticeManager.notices.isNotEmpty
                ? NoticeManager.latest.title
                : '등록된 공지가 없어요',
            onTap: _showNoticeList,
          ),
          _linkTile(
            icon: Icons.palette_outlined,
            title: '화면 테마',
            subtitle: AppTheme.palette.label,
            onTap: _showThemeSheet,
          ),
          Divider(color: AppTheme.dividerColor, height: 32),

          // ── 내 정보 ──
          _sectionHeader('내 정보'),
          _linkTile(
            icon: Icons.person_off_outlined,
            title: '차단한 유저',
            subtitle: BlockManager.count > 0
                ? '${BlockManager.count}명'
                : '차단한 유저가 없어요',
            onTap: () => _showBlockedUsers(),
          ),
          ListTile(
            leading: Icon(
              _isExporting ? Icons.hourglass_top : Icons.download_outlined,
              color: AppTheme.textTertiary,
            ),
            title: Text('내 데이터 받기', style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: Text('내가 쓴 글과 활동 기록',
                style: TextStyle(color: AppTheme.textDisabled, fontSize: 12)),
            trailing: _isExporting
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textTertiary))
                : Icon(Icons.chevron_right, color: AppTheme.textFaint),
            onTap: _isExporting ? null : _exportData,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFFF6B81)),
            title: const Text('데이터 삭제', style: TextStyle(color: Color(0xFFFF6B81))),
            subtitle: Text('모든 기록이 영구적으로 지워져요',
                style: TextStyle(color: AppTheme.textDisabled, fontSize: 12)),
            trailing: Icon(Icons.chevron_right, color: AppTheme.textFaint),
            onTap: _showDataDeletionConfirm,
          ),
          Divider(color: AppTheme.dividerColor, height: 32),

          // ── 기타 (법적 문서는 한 단계 안으로) ──
          _sectionHeader('기타'),
          _linkTile(
            icon: Icons.shield_outlined,
            title: '약관 및 정책',
            subtitle: '개인정보처리방침 · 이용약관',
            onTap: _showPolicySheet,
          ),
          _linkTile(
            icon: Icons.gavel_outlined,
            title: '권리침해 신고',
            subtitle: '이미 사라진 글도 신고할 수 있어요',
            onTap: () => launchExpiredContentReport(context),
          ),
          const SizedBox(height: 32),

          // 앱 정보 (심사관 모드 진입점: 1.5초 내 5회 탭)
          Center(
            child: GestureDetector(
              onTap: _hiddenJudge.onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 6),
                child: Text(
                  '익명쇼츠 v1.1.0',
                  style: TextStyle(color: AppTheme.textDisabled, fontSize: 12),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              '${ApiService.deviceLanguage.toUpperCase()} · ${DateTime.now().year}',
              style: TextStyle(color: AppTheme.dividerColor, fontSize: 11),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(color: AppTheme.textDisabled, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _linkTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textTertiary),
      title: Text(title, style: TextStyle(color: AppTheme.textPrimary)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: AppTheme.textDisabled, fontSize: 12)) : null,
      trailing: Icon(Icons.chevron_right, color: AppTheme.textFaint),
      onTap: onTap,
    );
  }

  /// UC09: 심사관 로그인 모달 (버전 표시 5회 탭으로 진입)
  /// 다이얼로그 본체는 _ReviewerLoginDialog가 담당하고,
  /// 여기서는 결과를 받아 스낵바만 띄운다.
  Future<void> _showJudgeLoginModal() async {
    final outcome = await showDialog<_ReviewerLoginResult>(
      context: context,
      builder: (_) => const _ReviewerLoginDialog(),
    );

    if (!mounted || outcome == null) return;

    final messenger = ScaffoldMessenger.of(context);
    if (outcome.success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ 심사관 모드가 활성화되었습니다. (크레딧 999)'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (outcome.lockedMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(outcome.lockedMessage!),
          backgroundColor: const Color(0xFFFF1744),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// 화면 테마 선택 바텀시트
  /// 선택 즉시 반영되고(ThemeController가 앱 전체를 다시 그림), 재시작 후에도 유지된다.
  void _showThemeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ValueListenableBuilder<AppPalette>(
          valueListenable: ThemeController.palette,
          builder: (context, current, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  '화면 테마',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...AppPalettes.all.map((p) {
                final selected = p.id == current.id;
                return ListTile(
                  leading: _themeSwatch(p),
                  title: Text(
                    p.label,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    p.description,
                    style:
                        TextStyle(color: AppTheme.textDisabled, fontSize: 12),
                  ),
                  trailing: selected
                      ? Icon(Icons.check_circle,
                          color: AppTheme.accentColor, size: 22)
                      : null,
                  onTap: () => ThemeController.select(p),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// 테마 미리보기 — 배경/카드/포인트 3색을 겹쳐 보여준다
  Widget _themeSwatch(AppPalette p) {
    // 순수 장식 — 옆 텍스트가 이미 테마 이름을 말해주므로 중복해서 읽힐 필요가 없다
    return ExcludeSemantics(
      child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: p.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// 약관 및 정책 바텀시트 (법적 문서 모음)
  void _showPolicySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('약관 및 정책',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _policyTile(
                icon: Icons.privacy_tip_outlined,
                title: '개인정보처리방침',
                onTap: () {
                  Navigator.pop(sheetContext);
                  openExternalUrl(context, AppLinks.privacyPolicy);
                },
              ),
              _policyTile(
                icon: Icons.description_outlined,
                title: '서비스 이용약관',
                onTap: () {
                  Navigator.pop(sheetContext);
                  openExternalUrl(context, AppLinks.termsOfService);
                },
              ),
              _policyTile(
                icon: Icons.article_outlined,
                title: '오픈소스 라이선스',
                onTap: () {
                  Navigator.pop(sheetContext);
                  showLicensePage(
                    context: context,
                    applicationName: '익명쇼츠',
                    applicationVersion: 'v1.1.0',
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _policyTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.textTertiary, size: 21),
      title: Text(title,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14.5)),
      trailing: Icon(Icons.chevron_right, color: AppTheme.textFaint, size: 20),
      onTap: onTap,
    );
  }

  /// 도움말 바텀시트 (사용법 + 튜토리얼 다시 보기)
  void _showHelp() {
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
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('도움말',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _helpRow(Icons.swipe_up_rounded, '위로 스와이프',
                  '다음 쇼츠로 넘어갑니다. 쇼츠는 24시간 뒤 자동으로 사라져요.'),
              _helpRow(Icons.how_to_vote_rounded, '감정 투표 = 크레딧 +1',
                  '다른 쇼츠에 투표할 때마다 크레딧이 1개씩 쌓입니다. (최대 20개)'),
              _helpRow(Icons.edit_rounded, '크레딧 10개로 글쓰기',
                  '하단 가운데 연필 버튼이 크레딧이 쌓일수록 차오르고, 가득 차면 쇼츠를 작성할 수 있어요.'),
              _helpRow(Icons.more_horiz, '신고 · 차단',
                  '불쾌한 쇼츠는 카드 오른쪽 위 ⋯ 메뉴에서 신고하거나 작성자를 차단할 수 있어요.'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // 시트 닫고 피드(루트)로 바로 이동 → 즉시 튜토리얼 표시
                    Navigator.pop(sheetContext);
                    CoachMarkOverlay.replayRequested.value = true;
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('튜토리얼 다시 보기'),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 도움말 항목 아이콘은 '강조'가 아니라 '목록 표식'이다.
          // accent를 목록마다 뿌리면 정작 강조해야 할 곳에서 힘이 빠진다.
          Icon(icon, color: AppTheme.textTertiary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(desc,
                    style: TextStyle(
                        color: AppTheme.textTertiary, fontSize: 12.5, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 공지사항 목록 바텀시트
  void _showNoticeList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('공지사항',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (NoticeManager.notices.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('등록된 공지가 없습니다.',
                        style: TextStyle(color: AppTheme.textDisabled)),
                  ),
                )
              else
                ...NoticeManager.notices.map(
                  (notice) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.campaign_outlined,
                        color: AppTheme.textTertiary, size: 22),
                    title: Text(notice.title,
                        style: TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14.5)),
                    subtitle: Text(notice.date,
                        style: TextStyle(
                            color: AppTheme.textDisabled, fontSize: 12)),
                    trailing: Icon(Icons.chevron_right,
                        color: AppTheme.textFaint),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      showNoticeDetailSheet(context, notice,
                          onConfirmed: NoticeManager.markLatestSeen);
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showBlockedUsers() {
    final blocked = BlockManager.blockedHashes.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          top: false,
          child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('차단한 유저', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (blocked.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('차단한 유저가 없습니다.', style: TextStyle(color: AppTheme.textDisabled)),
                  ),
                )
              else
                ...blocked.map((hash) => ListTile(
                      leading: Icon(Icons.person_off, color: AppTheme.textDisabled),
                      title: Text('유저 #${hash.substring(0, 8)}', style: TextStyle(color: AppTheme.textPrimary)),
                      trailing: TextButton(
                        onPressed: () async {
                          await BlockManager.unblockUser(hash);
                          setSheetState(() => blocked.remove(hash));
                          setState(() {}); // 부모 리빌드
                        },
                        child: Text('차단 해제', style: TextStyle(color: AppTheme.accentColor)),
                      ),
                    )),
              const SizedBox(height: 16),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final data = await ApiService.exportUserData();
      if (data != null && mounted) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
        await SharePlus.instance.share(
          ShareParams(text: jsonStr, subject: '익명쇼츠 - 내 데이터'),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('데이터를 가져오지 못했습니다.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('내보내기에 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showDataDeletionConfirm() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('⚠️ 데이터 삭제', style: TextStyle(color: Color(0xFFFF1744), fontSize: 16)),
        content: Text(
          '모든 사용자 데이터(작성한 쇼츠, 크레딧, 투표 기록)가\n영구적으로 삭제됩니다.\n\n법적 보관 의무가 있는 아카이브 로그는\n90일 후 자동 삭제됩니다.\n\n이 작업은 되돌릴 수 없습니다.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('취소', style: TextStyle(color: AppTheme.textTertiary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ApiService.deleteAllUserData();
              if (mounted) {
                if (success) {
                  await DeviceId.reset();
                  await CreditManager.reset();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/consent', (route) => false);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('삭제에 실패했습니다. 다시 시도해 주세요.')),
                  );
                }
              }
            },
            child: const Text('전체 삭제', style: TextStyle(color: Color(0xFFFF1744), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// 심사관 로그인 결과 (다이얼로그 → 호출자 전달용)
class _ReviewerLoginResult {
  final bool success;
  final String? lockedMessage; // 브루트포스 잠금 안내 (있으면 표시)
  const _ReviewerLoginResult({this.success = false, this.lockedMessage});
}

/// 🔐 심사관 인증 다이얼로그 (UC09)
/// TextEditingController를 이 위젯이 소유하고 State.dispose()에서 정리한다.
/// (외부에서 수동 dispose하면 위젯이 아직 살아있는 동안 해제되어
///  '_dependents.isEmpty' assertion 오류가 발생함)
class _ReviewerLoginDialog extends StatefulWidget {
  const _ReviewerLoginDialog();

  @override
  State<_ReviewerLoginDialog> createState() => _ReviewerLoginDialogState();
}

class _ReviewerLoginDialogState extends State<_ReviewerLoginDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final result = await ApiService.adminLogin(_controller.text);
    if (!mounted) return;

    // 성공: 심사관 모드 활성화 후 결과와 함께 닫기
    if (result.token != null) {
      await CreditManager.enterAdminMode();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('audit_token', result.token!);
      if (!mounted) return;
      Navigator.of(context).pop(const _ReviewerLoginResult(success: true));
      return;
    }

    // 429 브루트포스 잠금: 안내와 함께 닫기
    if (result.error != null && result.error!.contains('15분')) {
      Navigator.of(context)
          .pop(_ReviewerLoginResult(lockedMessage: result.error));
      return;
    }

    // 일반 실패: 다이얼로그 유지하고 에러만 표시
    setState(() {
      _isLoading = false;
      _errorText = result.error ?? '인증에 실패했습니다.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: Text('🔐 심사관 인증',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '스토어 심사관 전용 접근입니다.\n발급받은 시크릿 코드를 입력하세요.',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: true,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Secret Code',
              errorText: _errorText,
              errorStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('취소', style: TextStyle(color: AppTheme.textTertiary)),
        ),
        TextButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('로그인', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
