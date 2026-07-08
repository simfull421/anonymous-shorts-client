// 👤 마이페이지 화면 (UC05)
// - 내가 작성한 쇼츠 리스트 (GET /api/shorts/my?uuid=xxx)
// - 상태별 UI 분기: Active(정상), Expired(회색), Blind(블라인드 문구)
// - Empty State: 작성 이력 없음 안내
// - 앱 버전 5회 탭 → 심사관 모드 (UC09)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../models/shorts_model.dart';
import '../services/api_service.dart';
import '../utils/credit_manager.dart';
import '../utils/hidden_judge.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  List<ShortsModel> _myShorts = [];
  bool _isLoading = true;
  String? _errorMessage;

  late final HiddenJudge _hiddenJudge;

  @override
  void initState() {
    super.initState();
    _hiddenJudge = HiddenJudge(onActivated: _showJudgeLoginModal);
    _loadMyShorts();
  }

  Future<void> _loadMyShorts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await ApiService.getMyShorts();
      if (mounted) {
        setState(() {
          _myShorts = result.items;
          _isLoading = false;
        });
        // 서버 크레딧으로 로컬 동기화 (F-05) — 심사관 모드일 때는 덮어쓰지 않음
        await CreditManager.syncBalance(result.creditBalance);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = '데이터를 불러올 수 없습니다.';
          _isLoading = false;
        });
      }
    }
  }

  /// UC09: 심사관 로그인 모달
  void _showJudgeLoginModal() {
    final secretController = TextEditingController();
    bool isLoading = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            '🔐 심사관 인증',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
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
                      setDialogState(() {
                        isLoading = true;
                        errorText = null;
                      });
                      final result = await ApiService.adminLogin(secretController.text);

                      if (result.token != null) {
                        // 성공: 다이얼로그 닫기 + 심사관 모드 활성화
                        secretController.dispose();
                        if (!context.mounted) return;
                        Navigator.pop(dialogContext);
                        await CreditManager.enterAdminMode();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('audit_token', result.token!);
                        _loadMyShorts();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ 심사관 모드가 활성화되었습니다. (크레딧 999)'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } else if (result.error != null && result.error!.contains('15분')) {
                        // 429 브루트포스 잠금: 다이얼로그 닫고 잠금 안내
                        secretController.dispose();
                        if (!context.mounted) return;
                        Navigator.pop(dialogContext);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.error!),
                              backgroundColor: const Color(0xFFFF1744),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      } else {
                        // 일반 실패: 다이얼로그 유지, 에러 표시
                        setDialogState(() {
                          isLoading = false;
                          errorText = result.error ?? '인증에 실패했습니다.';
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('로그인', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// UC05 E3: 내 쇼츠 삭제
  void _showDeleteConfirm(ShortsModel short) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('쇼츠 삭제', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          '이 쇼츠를 삭제하시겠습니까?\n삭제된 글은 복구할 수 없습니다.',
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
              final success = await ApiService.deleteShorts(short.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '쇼츠가 삭제되었습니다.' : '삭제에 실패했습니다.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
                if (success) _loadMyShorts(); // 목록 새로고침
              }
            },
            child: const Text('삭제', style: TextStyle(color: Color(0xFFFF1744))),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white54, size: 22),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          // 앱 버전 표시 + 5회 탭 심사관 모드 (UC09)
          GestureDetector(
            onTap: _hiddenJudge.onTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'v1.0.0',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 로딩 중
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // 에러 (UC05 E2)
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              style: AppTheme.bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMyShorts,
              style: AppTheme.submitButtonStyle,
              child: const Text('재시도'),
            ),
          ],
        ),
      );
    }

    // Empty State (UC05 E1)
    if (_myShorts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMyShorts,
        color: Colors.white,
        backgroundColor: AppTheme.cardColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note, color: Colors.white24, size: 64),
                  SizedBox(height: 16),
                  Text(
                    '아직 작성한 쇼츠가 없습니다.\n첫 글을 남겨보세요!',
                    style: AppTheme.bodyStyle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 쇼츠 리스트
    return RefreshIndicator(
      onRefresh: _loadMyShorts,
      color: Colors.white,
      backgroundColor: AppTheme.cardColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myShorts.length,
        itemBuilder: (context, index) {
          return _buildShortsItem(_myShorts[index]);
        },
      ),
    );
  }

  Widget _buildShortsItem(ShortsModel short) {
    // 상태별 UI 분기 (UC05 대안흐름 5a, 5b)
    final bool isExpired = short.status == 'Expired';
    final bool isBlind = short.status == 'Blind';

    final Color statusColor = isBlind
        ? AppTheme.blindColor
        : isExpired
            ? AppTheme.expiredColor
            : AppTheme.activeColor;

    final String statusLabel = isBlind
        ? '블라인드'
        : isExpired
            ? '소멸됨'
            : '게시 중';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired
            ? AppTheme.cardColor.withValues(alpha: 0.5) // 회색 처리 (5a)
            : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태 배지 + 시간
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(short.createdAt),
                    style: AppTheme.captionStyle,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showDeleteConfirm(short),
                    child: const Icon(Icons.delete_outline, color: Colors.white24, size: 18),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 본문 텍스트
          if (isBlind)
            // UC05 대안흐름 5b: 블라인드 문구
            const Text(
              '운영 정책 위반으로 블라인드 처리되었습니다.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Text(
              short.textContent,
              style: TextStyle(
                color: isExpired ? Colors.white38 : Colors.white,
                fontSize: 16,
              ),
            ),

          if (!isBlind) ...[
            const SizedBox(height: 10),
            // 투표 통계
            Text(
              '총 ${short.totalVotes}표',
              style: AppTheme.captionStyle,
            ),
          ],

          // 만료 안내 (5a)
          if (isExpired)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '24시간이 지나 소멸되었습니다.',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    // 서버에서 UTC로 내려온 시간을 로컬 시간으로 변환
    final localTime = time.toLocal();
    final diff = DateTime.now().difference(localTime);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}
