// ⚙️ 설정 화면
// - 법적 문서 링크, 차단 유저 관리, 데이터 내보내기, 언어 표시
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../services/api_service.dart';
import '../utils/block_manager.dart';
import '../utils/credit_manager.dart';
import '../utils/device_id.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 섹션: 법적 문서
          _sectionHeader('법적 문서'),
          _linkTile(
            icon: Icons.privacy_tip_outlined,
            title: '개인정보처리방침',
            onTap: () => _openUrl('https://simfull421.github.io/anonymous-shorts-privacy/privacy_policy.html'),
          ),
          _linkTile(
            icon: Icons.description_outlined,
            title: '서비스 이용약관',
            onTap: () => _openUrl('https://simfull421.github.io/anonymous-shorts-privacy/terms_of_service.html'),
          ),
          _linkTile(
            icon: Icons.article_outlined,
            title: '오픈소스 라이선스',
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Anonymous Shorts',
              applicationVersion: 'v1.0.0',
            ),
          ),
          const Divider(color: Colors.white12, height: 32),

          // 섹션: 유저 관리
          _sectionHeader('유저 관리'),
          _linkTile(
            icon: Icons.block,
            title: '차단 유저 관리',
            subtitle: '${BlockManager.count}명 차단 중',
            onTap: () => _showBlockedUsers(),
          ),
          const Divider(color: Colors.white12, height: 32),

          // 섹션: 데이터
          _sectionHeader('내 데이터'),
          ListTile(
            leading: Icon(
              _isExporting ? Icons.hourglass_top : Icons.download_outlined,
              color: Colors.white54,
            ),
            title: const Text('내 데이터 다운로드', style: TextStyle(color: Colors.white)),
            subtitle: const Text('GDPR/PIPA 데이터 열람권', style: TextStyle(color: Colors.white38, fontSize: 12)),
            trailing: _isExporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54))
                : const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: _isExporting ? null : _exportData,
          ),
          const Divider(color: Colors.white12, height: 32),

          // 섹션: 위험 영역
          _sectionHeader('계정'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Color(0xFFFF1744)),
            title: const Text('계정 데이터 삭제', style: TextStyle(color: Color(0xFFFF1744))),
            subtitle: const Text('모든 데이터가 영구 삭제됩니다', style: TextStyle(color: Colors.white38, fontSize: 12)),
            onTap: _showDataDeletionConfirm,
          ),
          const SizedBox(height: 32),

          // 앱 정보
          Center(
            child: Text(
              'Anonymous Shorts v1.0.0',
              style: TextStyle(color: Colors.white24, fontSize: 12),
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

  void _showBlockedUsers() {
    final blocked = BlockManager.blockedHashes.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('차단 유저 관리', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
    );
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final data = await ApiService.exportUserData();
      if (data != null && mounted) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
        await SharePlus.instance.share(
          ShareParams(text: jsonStr, subject: 'Anonymous Shorts - 내 데이터'),
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
