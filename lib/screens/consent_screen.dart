// 📋 이용약관 및 개인정보처리방침 동의 화면 (Google Play UGC 정책 필수)
// - 최초 실행 시 노출, 동의 완료 후 피드로 이동
// - SharedPreferences에 동의 여부 저장
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _privacyChecked = false;
  bool _termsChecked = false;
  bool _responsibilityChecked = false;
  bool _isLoading = false;

  bool get _allChecked => _privacyChecked && _termsChecked && _responsibilityChecked;

  // 노션 호스팅 법적 문서 URL
  static const String _privacyUrl = 'https://shining-juice-96b.notion.site/393cbc2f0ed4807b8fe7fd0e32d848fe';
  static const String _termsUrl = 'https://shining-juice-96b.notion.site/393cbc2f0ed480bd9606c0751447605e';

  Future<void> _acceptAndContinue() async {
    if (!_allChecked) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('consent_accepted', true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              // 앱 타이틀
              Text(
                'Anonymous\nShorts',
                style: AppTheme.mainContentStyle.copyWith(fontSize: 36),
              ),
              const SizedBox(height: 12),
              Text(
                '서비스 이용을 위해\n아래 약관에 동의해 주세요.',
                style: AppTheme.bodyStyle.copyWith(
                  color: Colors.white70,
                ),
              ),
              const Spacer(flex: 3),

              // 개인정보처리방침 동의
              _buildConsentItem(
                title: '개인정보처리방침',
                checked: _privacyChecked,
                onChanged: (v) => setState(() => _privacyChecked = v ?? false),
                onLinkTap: () => _openUrl(_privacyUrl),
              ),
              const SizedBox(height: 16),

              // 이용약관 동의
              _buildConsentItem(
                title: '서비스 이용약관',
                checked: _termsChecked,
                onChanged: (v) => setState(() => _termsChecked = v ?? false),
                onLinkTap: () => _openUrl(_termsUrl),
              ),
              const SizedBox(height: 16),

              // 콘텐츠 책임 동의
              _buildConsentItemInline(
                title: '[필수] 본인이 작성한 콘텐츠에 대한 모든 법적 책임은 본인에게 있음을 확인합니다.',
                checked: _responsibilityChecked,
                onChanged: (v) => setState(() => _responsibilityChecked = v ?? false),
              ),
              const SizedBox(height: 12),

              // 전체 동의
              GestureDetector(
                onTap: () {
                  final newVal = !_allChecked;
                  setState(() {
                    _privacyChecked = newVal;
                    _termsChecked = newVal;
                    _responsibilityChecked = newVal;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      _allChecked ? Icons.check_circle : Icons.check_circle_outline,
                      color: _allChecked ? AppTheme.accentColor : Colors.white38,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '전체 동의',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // 시작하기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _allChecked ? _acceptAndContinue : null,
                  style: AppTheme.submitButtonStyle,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '시작하기',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentItem({
    required String title,
    required bool checked,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onLinkTap,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: checked,
            onChanged: onChanged,
            activeColor: AppTheme.accentColor,
            checkColor: Colors.white,
            side: const BorderSide(color: Colors.white38),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '[필수] $title',
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onLinkTap,
          child: const Text(
            '보기',
            style: TextStyle(
              color: AppTheme.secondaryAccent,
              fontSize: 13,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.secondaryAccent,
            ),
          ),
        ),
      ],
    );
  }

  /// 링크 없는 인라인 체크박스 (면책 동의용)
  Widget _buildConsentItemInline({
    required String title,
    required bool checked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: checked,
            onChanged: onChanged,
            activeColor: AppTheme.accentColor,
            checkColor: Colors.white,
            side: const BorderSide(color: Colors.white38),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}
