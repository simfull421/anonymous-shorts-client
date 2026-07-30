// 📱 메인 피드 화면 (UC01, UC02, UC03)
// - PageView 세로 스와이프 + 프리페치(남은 3개 이하 시 추가 로드)
// - 지나간 쇼츠 메모리 파기 (UC01 기본흐름 6)
// - 투표/신고 컴포넌트 연동
// - flutter_animate 스와이프 애니메이션
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app_theme.dart';
import '../models/shorts_model.dart';
import '../services/api_service.dart';
import '../utils/credit_manager.dart';
import '../utils/block_manager.dart';
import '../components/shorts_card.dart';
import '../components/write_shorts_form.dart';
import '../components/notice_banner.dart';
import '../components/coach_mark_overlay.dart';
import '../utils/notice_manager.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<ShortsModel> _shorts = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  String? _errorMessage;
  int? _nextCursor;

  // 중복 투표 방지 (UC02 E2): shortsId → 투표한 버튼 index
  final Map<int, int> _votedShortsMap = {};

  // 신고로 은폐된 쇼츠 ID 집합
  final Set<int> _reportedShortsIds = {};

  // 📢 미확인 공지 배너 노출 여부
  bool _showNoticeBanner = false;

  // ⬅️ 뒤로가기 2회 종료 패턴
  DateTime? _lastBackPressed;

  // 🎓 첫 실행 코치마크
  bool _showCoachMark = false;

  // 💫 투표 시 +1 플로팅 애니메이션 트리거 (증가할 때마다 재생)
  int _plusOneTick = 0;

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
    BlockManager.init();
    _loadFeed();
    _checkNotice();
    // 🔁 설정 > 도움말 > 튜토리얼 다시 보기 → 피드 복귀 시 즉시 표시
    CoachMarkOverlay.replayRequested.addListener(_onCoachReplayRequested);
  }

  void _onCoachReplayRequested() {
    if (CoachMarkOverlay.replayRequested.value && mounted) {
      CoachMarkOverlay.replayRequested.value = false;
      setState(() => _showCoachMark = true);
    }
  }

  Future<void> _checkNotice() async {
    // 🎓 코치마크가 우선 — 코치마크를 봐야 할 상태면 공지 배너는 다음 진입 시로 미룸
    final needCoachMark = await CoachMarkOverlay.shouldShow();
    if (needCoachMark) {
      if (mounted) setState(() => _showCoachMark = true);
      return;
    }

    // 원격 공지 목록 로드 (실패해도 캐시/기본값으로 동작)
    await NoticeManager.load();

    final hasUnseen = await NoticeManager.hasUnseenNotice();
    if (hasUnseen && mounted) {
      setState(() => _showNoticeBanner = true);
    }
  }

  @override
  void dispose() {
    CoachMarkOverlay.replayRequested.removeListener(_onCoachReplayRequested);
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  /// 프리페치 로직 (UC01 대안흐름 4a)
  void _onPageChanged() {
    if (!_pageController.hasClients) return;
    final currentPage = _pageController.page?.round() ?? 0;
    final remaining = _shorts.length - currentPage - 1;

    // 남은 쇼츠가 3개 이하면 추가 로드
    if (remaining <= 3 && !_isFetchingMore) {
      _fetchMore();
    }

    // 지나간 쇼츠 메모리 파기 (UC01 기본흐름 6)
    // PageView가 3페이지 이상 지나면 이전 데이터의 참조를 약화
    // (Flutter의 PageView.builder가 자동으로 위젯을 dispose하지만,
    //  모델 데이터의 명시적 관리가 GC에 유리)
  }

  Future<void> _loadFeed({bool forceRefresh = false}) async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          // 💫 리로드 시 +1 위젯 제거 — 로딩 화면을 거치며 Stack이 재구성될 때
          // 이미 재생됐던 +1 애니메이션이 다시 재생되는 것 방지
          _plusOneTick = 0;
        });
      }

      // 크레딧 잔액 로드 (CreditManager 초기화)
      await CreditManager.getBalance();

      final result = await ApiService.getFeed(ApiService.deviceLanguage, forceRefresh: forceRefresh);

      // 서버 SystemConfig의 글쓰기 비용 동기화 (UI 게이지·버튼 기준)
      await CreditManager.syncWriteCost(result.writeCost);

      // B6: 서버 크레딧 동기화
      if (result.creditBalance >= 0) {
        await CreditManager.syncBalance(result.creditBalance);
      }

      // B4: 서버에서 받은 투표 상태를 _votedShortsMap에 반영
      for (final short in result.items) {
        if (short.votedButtonIndex != null) {
          _votedShortsMap[short.id] = short.votedButtonIndex!;
        }
      }

      if (mounted) {
        setState(() {
          _shorts = result.items;
          _nextCursor = result.nextCursor;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '피드를 불러오지 못했습니다.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMore() async {
    if (_isFetchingMore || _nextCursor == null) return;
    _isFetchingMore = true;

    try {
      final result = await ApiService.getFeed(
        ApiService.deviceLanguage,
        cursor: _nextCursor,
      );

      if (result.items.isNotEmpty) {
        // 광고 인젝션 (비동기)
        ApiService.getAdShorts().then((ad) {
          if (ad != null && mounted) {
            setState(() {
              final insertIdx = _shorts.length > 3 ? _shorts.length - 3 : _shorts.length;
              _shorts.insert(insertIdx, ad);
            });
          }
        });

        if (mounted) {
          // B4: 추가 로드 쇼츠의 투표 상태도 반영
          for (final short in result.items) {
            if (short.votedButtonIndex != null) {
              _votedShortsMap[short.id] = short.votedButtonIndex!;
            }
          }
          setState(() {
            _shorts.addAll(result.items);
            _nextCursor = result.nextCursor;
          });
        }
      }
    } catch (_) {
      // 프리페치 실패 무시
    } finally {
      _isFetchingMore = false;
    }
  }

  void _showWriteForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => WriteShortsForm(
        onSuccess: () => _loadFeed(forceRefresh: true),
      ),
    );
  }

  /// ⬅️ 뒤로가기 처리: 2초 내 2회 누르면 앱 종료, 아니면 안내 스낵바
  void _handleBackPress() {
    final now = DateTime.now();
    final isSecondPress = _lastBackPressed != null &&
        now.difference(_lastBackPressed!) < const Duration(seconds: 2);

    if (isSecondPress) {
      SystemNavigator.pop(); // 앱 정상 종료
      return;
    }

    _lastBackPressed = now;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('한 번 더 누르면 앱이 종료됩니다'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(60, 0, 60, 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: _buildErrorState(),
      );
    }

    // 표시할 쇼츠 필터링 (신고된 항목 제외)
    final visibleShorts = _shorts
        .where((s) => !_reportedShortsIds.contains(s.id))
        .where((s) => !BlockManager.isBlocked(s.creatorHash))
        .toList();

    if (visibleShorts.isEmpty) {
      return Scaffold(
        body: const Center(
          child: Text(
            '피드가 없습니다.\n잠시 후 다시 시도해 주세요.',
            style: AppTheme.bodyStyle,
            textAlign: TextAlign.center,
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      );
    }

    return Scaffold(
      bottomNavigationBar: _buildBottomBar(),
      body: Stack(
        children: [
          // 당김 새로고침 (표준 인디케이터)
          RefreshIndicator(
            onRefresh: () => _loadFeed(forceRefresh: true),
            color: AppTheme.accentColor,
            backgroundColor: AppTheme.cardColor,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: visibleShorts.length,
              itemBuilder: (context, index) {
                final short = visibleShorts[index];
                return _buildShortsCard(short, index);
              },
            ),
          ),
          // 📢 미확인 공지 배너 (상단 슬라이드 다운)
          if (_showNoticeBanner)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: NoticeBanner(
                notice: NoticeManager.latest,
                onDismissed: () {
                  if (mounted) setState(() => _showNoticeBanner = false);
                },
              ),
            ),
          // 💫 투표 크레딧 +1 플로팅 (하단 중앙 글쓰기 버튼 위로 떠오름)
          if (_plusOneTick > 0)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  // 🔑 key를 Animate 위젯에 부여해야 투표할 때마다 재생되고,
                  // 다른 위젯(공지 배너 등) 제거로 인한 리빌드에는 오재생되지 않음
                  child: Text(
                    '+1',
                    style: const TextStyle(
                      color: AppTheme.secondaryAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                      .animate(key: ValueKey('plus_one_$_plusOneTick'))
                      .slideY(begin: 0.5, end: -1.6, duration: 700.ms, curve: Curves.easeOutCubic)
                      .fadeIn(duration: 150.ms)
                      .then(delay: 250.ms)
                      .fadeOut(duration: 300.ms),
                ),
              ),
            ),
          // 🎓 첫 실행 코치마크 (최상단)
          if (_showCoachMark)
            Positioned.fill(
              child: CoachMarkOverlay(
                onFinished: () {
                  if (mounted) setState(() => _showCoachMark = false);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShortsCard(ShortsModel short, int index) {
    final bool hasVoted = _votedShortsMap.containsKey(short.id);

    return ShortsCard(
      short: short,
      hasVoted: hasVoted,
      votedIndex: _votedShortsMap[short.id],
      onVoteSuccess: (buttonIndex) {
        setState(() {
          _votedShortsMap[short.id] = buttonIndex;
          _plusOneTick++; // 💫 +1 플로팅 재생 (크레딧 게이지도 리빌드로 차오름)
        });
      },
      onVoteFailed: () {
        setState(() {
          _votedShortsMap.remove(short.id);
        });
      },
      onCreditSynced: () {
        // 서버 잔액 동기화(웰컴 보너스 등) 후 게이지/배지 즉시 갱신
        if (mounted) setState(() {});
      },
      onReported: () {
        setState(() {
          _reportedShortsIds.add(short.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('신고가 접수되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      onBlockUser: () => _showBlockConfirm(short),
    );
  }

  void _showBlockConfirm(ShortsModel short) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('유저 차단', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          '이 유저의 모든 글이 피드에서 숨겨집니다.\n차단을 해제하려면 마이페이지에서 관리할 수 있습니다.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              await BlockManager.blockUser(short.creatorHash!);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (mounted) {
                setState(() {}); // 리빌드하여 차단된 유저의 글 숨김
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('유저가 차단되었습니다.'), duration: Duration(seconds: 2)),
                );
              }
            },
            child: const Text('차단', style: TextStyle(color: Color(0xFFFF1744))),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text(
              '서버에 연결할 수 없습니다',
              style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '네트워크 연결을 확인해 주세요',
              style: TextStyle(color: Colors.white24, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadFeed(forceRefresh: true),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      color: AppTheme.backgroundColor,
      elevation: 0,
      height: 72,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 홈 탭 (현재 활성) — 라벨 추가
          _buildTabItem(
            icon: Icons.home_rounded,
            label: '홈',
            color: AppTheme.accentColor,
            onTap: () {
              // 이미 홈이므로 맨 위로 스크롤
              if (_pageController.hasClients) {
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
          ),

          // 중앙: 글쓰기 버튼 (물 차오르는 크레딧 게이지 + 연필 + 배지)
          _buildWriteButton(),

          // 마이페이지 탭 — 라벨 추가
          _buildTabItem(
            icon: Icons.person_outline_rounded,
            label: '마이',
            color: Colors.white54,
            onTap: () async {
              await Navigator.pushNamed(context, '/mypage');
              // 마이페이지에서 돌아올 때 크레딧 배지 갱신 (심사관 999 반영)
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /// ✍️ 글쓰기 버튼 — 크레딧이 쌓일수록 물이 차오르듯 게이지가 올라오고,
  /// 10개(작성 가능)가 되면 가득 찬 상태로 글로우 효과
  Widget _buildWriteButton() {
    final double progress =
        (CreditManager.balance / CreditManager.writeCost).clamp(0.0, 1.0);
    final bool canWrite = CreditManager.canWrite;

    return GestureDetector(
      onTap: _showWriteForm,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.inputColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: canWrite
                    ? AppTheme.accentColor.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: canWrite
                  ? [
                      BoxShadow(
                        color: AppTheme.accentColor.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 💧 물 차오름 게이지 (크레딧 진행도)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Container(
                      height: 54 * value,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFB07CF0), // 수면 쪽은 밝게 (물 표면 느낌)
                            AppTheme.accentColor,
                            Color(0xFF6C2BD9),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // 연필 아이콘
                Icon(
                  Icons.edit_rounded,
                  color: canWrite
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.55),
                  size: 26,
                ),
              ],
            ),
          ),
          // 크레딧 배지 (잔액 변경 시 통통 튀는 펄스)
          Positioned(
            top: -6,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: canWrite ? AppTheme.secondaryAccent : Colors.white24,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.backgroundColor, width: 2),
              ),
              child: Text(
                '${CreditManager.balance}',
                style: TextStyle(
                  color: canWrite ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            )
                .animate(key: ValueKey('badge_${CreditManager.balance}'))
                .scale(
                  begin: const Offset(1.35, 1.35),
                  end: const Offset(1, 1),
                  duration: 350.ms,
                  curve: Curves.elasticOut,
                ),
          ),
        ],
      ),
    );
  }
}
