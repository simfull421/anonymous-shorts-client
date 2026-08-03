// 📋 이용약관 및 개인정보처리방침 동의 화면 (Google Play UGC 정책 필수)
// - 최초 실행 시 노출, 동의 완료 후 피드로 이동
// - SharedPreferences에 동의 여부 저장
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../config/app_info.dart';
import '../config/app_links.dart';
import '../theme/theme_controller.dart';

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

  Future<void> _acceptAndContinue() async {
    if (!_allChecked) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('consent_accepted', true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }


  @override
  Widget build(BuildContext context) {
    return ThemedBuilder(builder: _buildScaffold);
  }

  Widget _buildScaffold(BuildContext context) {
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
                AppInfo.name,
                style: AppTheme.mainContentStyle.copyWith(fontSize: 40),
              ),
              const SizedBox(height: 12),
              Text(
                '회원가입 없이 익명으로 바로 시작해요.\n이름, 이메일, 전화번호는 수집하지 않아요.',
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '시작하려면 아래 약관에 동의해 주세요.',
                style: TextStyle(color: AppTheme.textDisabled, fontSize: 13),
              ),
              const Spacer(flex: 3),

              // 개인정보처리방침 동의
              _buildConsentItem(
                title: '개인정보처리방침',
                checked: _privacyChecked,
                onChanged: (v) => setState(() => _privacyChecked = v ?? false),
                onLinkTap: () => openExternalUrl(context, AppLinks.privacyPolicy),
              ),
              const SizedBox(height: 16),

              // 이용약관 동의
              _buildConsentItem(
                title: '서비스 이용약관',
                checked: _termsChecked,
                onChanged: (v) => setState(() => _termsChecked = v ?? false),
                onLinkTap: () => openExternalUrl(context, AppLinks.termsOfService),
              ),
              const SizedBox(height: 16),

              // 콘텐츠 책임 동의
              _buildConsentItemInline(
                title: '[필수] 만 14세 이상이며, 내가 작성하는 콘텐츠에 대한 책임은 나에게 있음을 확인해요.',
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
                      color: _allChecked ? AppTheme.accentColor : AppTheme.textDisabled,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '전체 동의',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
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
            side: BorderSide(color: AppTheme.textDisabled),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '[필수] $title',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onLinkTap,
          child: Text(
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
            side: BorderSide(color: AppTheme.textDisabled),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}
