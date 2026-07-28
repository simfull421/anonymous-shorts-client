// ⚙️ 설정 화면
// - 법적 문서 링크, 차단 유저 관리, 데이터 내보내기, 언어 표시
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
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
          const Divider(color: Colors.white12, height: 32),

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
              color: Colors.white54,
            ),
            title: const Text('내 데이터 받기', style: TextStyle(color: Colors.white)),
            subtitle: const Text('내가 쓴 글과 활동 기록',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            trailing: _isExporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54))
                : const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: _isExporting ? null : _exportData,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFFF6B81)),
            title: const Text('데이터 삭제', style: TextStyle(color: Color(0xFFFF6B81))),
            subtitle: const Text('모든 기록이 영구적으로 지워져요',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: _showDataDeletionConfirm,
          ),
          const Divider(color: Colors.white12, height: 32),

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
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 6),
                child: Text(
                  '익명쇼츠 v1.1.0',
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              '${ApiService.deviceLanguage.toUpperCase()} · ${DateTime.now().year}',
              style: TextStyle(color: Colors.white12, fontSize: 11),
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
        style: const TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w600),
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
      leading: Icon(icon, color: Colors.white54),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap,
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('브라우저를 열 수 없습니다.')),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다.')),
        );
      }
    }
  }

  /// UC09: 심사관 로그인 모달 (버전 표시 5회 탭으로 진입)
  void _showJudgeLoginModal() {
    final secretController = TextEditingController();
    bool isLoading = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('🔐 심사관 인증',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '스토어 심사관 전용 접근입니다.\n발급받은 시크릿 코드를 입력하세요.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: secretController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Secret Code',
                  errorText: errorText,
                  errorStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                secretController.dispose();
                Navigator.pop(dialogContext);
              },
              child: const Text('취소', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // 비동기 호출 전에 messenger·navigator를 미리 확보한다.
                      // (await 이후 BuildContext를 다시 참조하지 않기 위함)
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(dialogContext);

                      setDialogState(() {
                        isLoading = true;
                        errorText = null;
                      });
                      final result =
                          await ApiService.adminLogin(secretController.text);

                      if (result.token != null) {
                        secretController.dispose();
                        navigator.pop();
                        await CreditManager.enterAdminMode();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('audit_token', result.token!);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('✅ 심사관 모드가 활성화되었습니다. (크레딧 999)'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else if (result.error != null &&
                          result.error!.contains('15분')) {
                        secretController.dispose();
                        navigator.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(result.error!),
                            backgroundColor: const Color(0xFFFF1744),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      } else {
                        setDialogState(() {
                          isLoading = false;
                          errorText = result.error ?? '인증에 실패했습니다.';
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('로그인', style: TextStyle(color: Colors.white)),
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
              const Text('약관 및 정책',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _policyTile(
                icon: Icons.privacy_tip_outlined,
                title: '개인정보처리방침',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openUrl(
                      'https://simfull421.github.io/anonymous-shorts-privacy/privacy_policy.html');
                },
              ),
              _policyTile(
                icon: Icons.description_outlined,
                title: '서비스 이용약관',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openUrl(
                      'https://simfull421.github.io/anonymous-shorts-privacy/terms_of_service.html');
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
      leading: Icon(icon, color: Colors.white54, size: 21),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 14.5)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
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
              const Text('도움말',
                  style: TextStyle(
                      color: Colors.white,
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
          Icon(icon, color: AppTheme.accentColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12.5, height: 1.5)),
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
              const Text('공지사항',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (NoticeManager.notices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('등록된 공지가 없습니다.',
                        style: TextStyle(color: Colors.white38)),
                  ),
                )
              else
                ...NoticeManager.notices.map(
                  (notice) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.campaign_outlined,
                        color: AppTheme.accentColor, size: 22),
                    title: Text(notice.title,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14.5)),
                    subtitle: Text(notice.date,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right,
                        color: Colors.white24),
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
              const Text('차단한 유저', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (blocked.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('차단한 유저가 없습니다.', style: TextStyle(color: Colors.white38)),
                  ),
                )
              else
                ...blocked.map((hash) => ListTile(
                      leading: const Icon(Icons.person_off, color: Colors.white38),
                      title: Text('유저 #${hash.substring(0, 8)}', style: const TextStyle(color: Colors.white)),
                      trailing: TextButton(
                        onPressed: () async {
                          await BlockManager.unblockUser(hash);
                          setSheetState(() => blocked.remove(hash));
                          setState(() {}); // 부모 리빌드
                        },
                        child: const Text('차단 해제', style: TextStyle(color: AppTheme.accentColor)),
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
        content: const Text(
          '모든 사용자 데이터(작성한 쇼츠, 크레딧, 투표 기록)가\n영구적으로 삭제됩니다.\n\n법적 보관 의무가 있는 아카이브 로그는\n90일 후 자동 삭제됩니다.\n\n이 작업은 되돌릴 수 없습니다.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소', style: TextStyle(color: Colors.white54)),
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
