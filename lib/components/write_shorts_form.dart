// ✍️ 쇼츠 작성 바텀시트 (UC04)
// - 본문 + 커스텀 반응 버튼(2~4개) 입력
// - 유효성 검사: 본문 10자↑, 버튼별 1자↑, 총합 180자↓, URL 차단
// - 크레딧 10 소모 (WRITE_CREDIT_COST)
import 'dart:convert';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/api_service.dart';
import '../utils/credit_manager.dart';
import 'safety_dialog.dart';

class WriteShortsForm extends StatefulWidget {
  final VoidCallback? onSuccess; // 작성 성공 후 피드 새로고침 콜백

  const WriteShortsForm({super.key, this.onSuccess});

  @override
  State<WriteShortsForm> createState() => _WriteShortsFormState();
}

class _WriteShortsFormState extends State<WriteShortsForm> {
  final TextEditingController _textController = TextEditingController();
  final List<TextEditingController> _buttonControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  static const int _maxTotalChars = 180;
  static const int _minTextChars = 10;
  static const int _maxButtons = 4;
  static const int _minButtons = 2;

  bool _isSubmitting = false;
  String? _submitError; // B8: 제출 에러 메시지 (인라인 표시)
  // BGM 기능 (v1.1에서 활성화 예정)
  // String? _selectedBgmId;
  // List<Map<String, dynamic>> _bgmAds = [];

  // URL 패턴 정규식 (UC04 E1)
  static final RegExp _urlPattern =
      RegExp(r'(https?://|www\.)', caseSensitive: false);

  @override
  void initState() {
    super.initState();
    // _loadBgmAds(); // BGM v1.1에서 활성화
  }

  // Future<void> _loadBgmAds() async {
  //   final ads = await ApiService.getAdMusics();
  //   if (mounted) {
  //     setState(() {
  //       _bgmAds = ads;
  //     });
  //   }
  // }


  @override
  void dispose() {
    _textController.dispose();
    for (final c in _buttonControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// 현재 총 글자 수 (본문 + 모든 버튼)
  int get _totalChars {
    int total = _textController.text.length;
    for (final c in _buttonControllers) {
      total += c.text.length;
    }
    return total;
  }

  /// 업로드 가능 여부
  bool get _canSubmit {
    if (_isSubmitting) return false;
    if (_textController.text.trim().length < _minTextChars) return false;
    if (_totalChars > _maxTotalChars) return false;
    if (_urlPattern.hasMatch(_textController.text)) return false;

    // 모든 버튼에 최소 1자 이상 입력되었는지 검사
    for (final c in _buttonControllers) {
      if (c.text.trim().isEmpty) return false;
      if (_urlPattern.hasMatch(c.text)) return false;
    }

    // 크레딧 확인
    if (!CreditManager.canWrite) return false;

    return true;
  }

  void _addButton() {
    if (_buttonControllers.length >= _maxButtons) return;
    setState(() {
      _buttonControllers.add(TextEditingController());
    });
  }

  void _removeButton(int index) {
    if (_buttonControllers.length <= _minButtons) return;
    setState(() {
      _buttonControllers[index].dispose();
      _buttonControllers.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    // 크레딧 차감
    final spent = await CreditManager.spendCredit();
    if (!spent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('크레딧이 부족합니다. 투표를 통해 모아보세요!')),
        );
        setState(() => _isSubmitting = false);
      }
      return;
    }

    // 커스텀 버튼 JSON 생성 (백엔드 ButtonDto 형식: index, text, votes)
    final buttons = <Map<String, dynamic>>[];
    for (int i = 0; i < _buttonControllers.length; i++) {
      buttons.add({
        'index': i,
        'text': _buttonControllers[i].text.trim(),
        'votes': 0,
      });
    }
    final buttonsJson = jsonEncode(buttons);

    final result = await ApiService.createShorts(
      textContent: _textController.text.trim(),
      customButtonsJson: buttonsJson,
      bgmId: null, // BGM v1.1에서 활성화 예정
    );

    if (mounted) {
      if (result.success) {
        Navigator.pop(context);
        // 제출 성공 피드백
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 쇼츠가 성공적으로 업로드되었습니다!'),
            duration: Duration(seconds: 2),
          ),
        );
        widget.onSuccess?.call();
      } else {
        // 크레딧 롤백 (심사관 모드는 차감 안 했으므로 롤백 불필요)
        if (!CreditManager.isAdminMode) {
          await CreditManager.syncBalance(CreditManager.balance + CreditManager.writeCost);
        }
        if (!mounted) return;

        // 🫂 자해·자살 관련 내용 감지: 오류 문구 대신 상담 안내를 노출
        if (result.code == kSelfHarmCode) {
          setState(() => _isSubmitting = false);
          showSafetyDialog(context);
          return;
        }

        setState(() {
          _isSubmitting = false;
          _submitError = result.error ?? '등록에 실패했습니다. 다시 시도해 주세요.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 안드로이드 시스템 내비게이션 바(제스처/버튼 바)에 하단 버튼이 가려지는 문제 수정:
    // 키보드 인셋(viewInsets) + 시스템 바 인셋(viewPadding) 중 큰 값을 하단 여백으로 적용
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final systemBarInset = MediaQuery.of(context).viewPadding.bottom;
    final bottomInset =
        keyboardInset > systemBarInset ? keyboardInset : systemBarInset;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (+ 크레딧 소모 칩)
            Row(
              children: [
                const Text(
                  '쇼츠 작성',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '크레딧 -${CreditManager.writeCost}',
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$_totalChars / $_maxTotalChars자',
                  style: TextStyle(
                    color: _totalChars > _maxTotalChars
                        ? AppTheme.blindColor
                        : Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 본문 입력
            TextField(
              controller: _textController,
              maxLines: 3,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: '하고 싶은 말을 자유롭게 적어보세요 (최소 $_minTextChars자)',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            
            // BGM 스폰서 섹션 (v1.1에서 실제 음원 연동 후 활성화 예정)
            // 현재는 하드코딩 데이터만 있어 출시 시 숨김
            // if (_bgmAds.isNotEmpty) ...[
            //   ... (BGM UI 코드 보존)
            // ],


            // 반응 버튼 입력 영역
            const Text(
              '반응 버튼 설정',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(_buttonControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _buttonControllers[index],
                        style:
                            const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: '반응 ${index + 1} (예: 공감, 경멸, 기괴...)',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_buttonControllers.length > _minButtons)
                      IconButton(
                        onPressed: () => _removeButton(index),
                        icon: const Icon(Icons.close,
                            color: Colors.white38, size: 20),
                      ),
                  ],
                ),
              );
            }),

            // 버튼 추가
            if (_buttonControllers.length < _maxButtons)
              TextButton.icon(
                onPressed: _addButton,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('반응 버튼 추가'),
                style: TextButton.styleFrom(foregroundColor: Colors.white54),
              ),

            const SizedBox(height: 12),

            // 크레딧 부족 시에만 부드러운 안내 (한 줄)
            if (!_isSubmitting && !CreditManager.canWrite)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '투표로 크레딧을 모으면 글을 쓸 수 있어요 (${CreditManager.balance}/${CreditManager.writeCost})',
                  style: const TextStyle(
                      color: AppTheme.secondaryAccent, fontSize: 12.5),
                  textAlign: TextAlign.center,
                ),
              ),

            // B8: 제출 에러 메시지 (금지어/모더레이션 등)
            if (_submitError != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '⚠️ $_submitError',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),

            // 발사(등록) 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: AppTheme.submitButtonStyle,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        !CreditManager.canWrite
                            ? '크레딧 부족 (${CreditManager.balance}/${CreditManager.writeCost})'
                            : '쇼츠 올리기 ✍️',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 10),

            // 커뮤니티 가이드라인 안내 (탭 불가 플레인 텍스트)
            // 링크는 더블탭 오클릭 문제로 제거 — 전문은 설정 > 서비스 이용약관에서 확인 가능
            const Center(
              child: Text(
                '모든 쇼츠는 건강한 커뮤니티를 위해 가이드라인에 따라 검토돼요',
                style: TextStyle(color: Colors.white38, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
