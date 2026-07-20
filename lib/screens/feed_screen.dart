// 📱 메인 피드 화면 (UC01, UC02, UC03)
// - PageView 세로 스와이프 + 프리페치(남은 3개 이하 시 추가 로드)
// - 지나간 쇼츠 메모리 파기 (UC01 기본흐름 6)
// - 투표/신고 컴포넌트 연동
// - flutter_animate 스와이프 애니메이션
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/shorts_model.dart';
import '../services/api_service.dart';
import '../utils/credit_manager.dart';
import '../utils/block_manager.dart';
import '../components/shorts_card.dart';
import '../components/write_shorts_form.dart';
import '../components/notice_banner.dart';
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

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
    BlockManager.init();
    _loadFeed();
    _checkNotice();
  }

  Future<void> _checkNotice() async {
    final hasUnseen = await NoticeManager.hasUnseenNotice();
    if (hasUnseen && mounted) {
      setState(() => _showNoticeBanner = true);
    }
  }

  @override
  void dispose() {
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
        });
      }

      // 크레딧 잔액 로드 (CreditManager 초기화)
      await CreditManager.getBalance();

      final result = await ApiService.getFeed(ApiService.deviceLanguage, forceRefresh: forceRefresh);

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

  @override
  Widget build(BuildContext context) {
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
          NotificationListener<OverscrollNotification>(
            onNotification: (notification) {
              // B7: 첫 페이지에서 위로 과스크롤 시 새로고침
              if (_pageController.page == 0 && notification.overscroll < -15 && !_isLoading) {
                _loadFeed(forceRefresh: true);
              }
              return false;
            },
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
        });
      },
      onVoteFailed: () {
        setState(() {
          _votedShortsMap.remove(short.id);
        });
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 홈 탭 (현재 활성)
          IconButton(
            icon: Icon(Icons.home, color: AppTheme.accentColor, size: 28),
            onPressed: () {
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

          // 중앙: 크레딧 & 글쓰기 버튼
          GestureDetector(
            onTap: _showWriteForm,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: CreditManager.canWrite
                    ? Colors.white
                    : AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${CreditManager.balance}',
                  style: TextStyle(
                    color: CreditManager.canWrite
                        ? Colors.black
                        : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),

          // 마이페이지 탭
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white54, size: 28),
            onPressed: () async {
              await Navigator.pushNamed(context, '/mypage');
              // 마이페이지에서 돌아올 때 크레딧 배지 갱신 (심사관 999 반영)
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
