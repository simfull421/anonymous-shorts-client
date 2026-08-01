// 👤 마이페이지 화면 (UC05)
// - 내가 작성한 쇼츠 리스트 (GET /api/shorts/my?uuid=xxx)
// - 상태별 UI 분기: Active(정상), Expired(회색), Blind(블라인드 문구)
// - Empty State: 작성 이력 없음 안내
// - 심사관 모드(UC09) 진입점은 설정 화면 하단 버전 표시로 이동
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../components/expiry_indicator.dart';
import '../theme/theme_controller.dart';
import '../models/shorts_model.dart';
import '../services/api_service.dart';
import '../utils/credit_manager.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  List<ShortsModel> _myShorts = [];
  bool _isLoading = true;
  String? _errorMessage;

  /// 0 = 게시 중, 1 = 지난 기록(아카이브)
  /// 두 그룹은 '할 수 있는 일'이 다르다. 게시 중인 글은 삭제할 수 있고
  /// 카운트다운이 돌아가지만, 지난 기록은 읽기 전용이다.
  /// 섞어두면 살아 있는 한두 개가 90일치 수십 개에 묻힌다.
  int _segment = 0;

  List<ShortsModel> get _liveShorts =>
      _myShorts.where((s) => s.status != 'Expired').toList();

  List<ShortsModel> get _archivedShorts =>
      _myShorts.where((s) => s.status == 'Expired').toList();

  List<ShortsModel> get _visibleShorts =>
      _segment == 0 ? _liveShorts : _archivedShorts;

  @override
  void initState() {
    super.initState();
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

  /// UC05 E3: 내 쇼츠 삭제
  /// [sheetContext]를 주면 삭제 확정 시 그 시트도 같이 닫는다.
  /// (Navigator.canPop()으로 판단하면 시트가 없을 때 마이페이지가 닫혀버린다)
  void _showDeleteConfirm(ShortsModel short, {BuildContext? sheetContext}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text('쇼츠 삭제', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        content: Text(
          '이 쇼츠를 삭제하시겠습니까?\n삭제된 글은 복구할 수 없습니다.',
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
              // 상세 시트에서 삭제한 경우, 삭제된 글을 계속 띄워둘 이유가 없다
              if (sheetContext != null && sheetContext.mounted) {
                Navigator.pop(sheetContext);
              }

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
    return ThemedBuilder(builder: _buildScaffold);
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        actions: [
          IconButton(
            tooltip: '설정',
            icon: Icon(Icons.settings_outlined, color: AppTheme.textTertiary, size: 22),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          // (심사관 모드 진입점은 설정 화면 하단 버전 표시로 이동)
        ],
      ),
      // 마지막 항목이 제스처 바에 가리지 않도록 (Android 15 edge-to-edge)
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    // 로딩 중
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.textPrimary),
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
        color: AppTheme.textPrimary,
        backgroundColor: AppTheme.cardColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note, color: AppTheme.textFaint, size: 64),
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

    // 격자 — 마이페이지는 '읽는' 화면이 아니라 '훑는' 화면이다.
    // 피드용 큰 카드를 그대로 쓰면 스크롤만 길어지고 훑기가 안 된다.
    final items = _visibleShorts;

    return Column(
      children: [
        _buildSegmentControl(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadMyShorts,
            color: AppTheme.textPrimary,
            backgroundColor: AppTheme.cardColor,
            child: items.isEmpty
                ? _buildSegmentEmpty()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.78, // 살짝 세로로 길쭉하게
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _buildGridTile(items[index]),
                  ),
          ),
        ),
      ],
    );
  }

  /// 게시 중 / 지난 기록 전환.
  /// 탭 바가 아니라 세그먼트인 이유: 이건 앱 레벨 내비게이션이 아니라
  /// 한 화면 안의 필터다.
  Widget _buildSegmentControl() {
    final live = _liveShorts.length;
    final archived = _archivedShorts.length;

    Widget seg(int index, String label, int count) {
      final selected = _segment == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _segment = index),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 44, // 탭 영역 최소 기준
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppTheme.cardColor : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '$label $count',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    selected ? AppTheme.textPrimary : AppTheme.textDisabled,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.glassFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // '게시 중'이 아니라 '올린 글'인 이유: 블라인드 처리된 글도 여기 들어가는데
          // 그건 게시 중이 아니다. 라벨이 사실이 아닌 걸 주장하지 않도록.
          seg(0, '올린 글', live),
          seg(1, '지난 기록', archived),
        ],
      ),
    );
  }

  Widget _buildSegmentEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Text(
            _segment == 0
                ? '올린 쇼츠가 없어요.'
                : '아직 소멸된 쇼츠가 없어요.',
            style: TextStyle(color: AppTheme.textDisabled, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// 격자 한 칸 — 본문 앞부분으로 어떤 글인지 알아보고, 총 득표로 성과를 본다.
  Widget _buildGridTile(ShortsModel short) {
    final bool isBlind = short.status == 'Blind';
    final bool isExpired = short.status == 'Expired';
    final int total = short.computedTotalVotes;

    // 격자 칸은 본문이 잘려 있어서 스크린리더로는 맥락이 끊긴다.
    // 상태와 득표수를 문장으로 붙여 한 번에 읽히도록 한다.
    final String semanticLabel = isBlind
        ? '블라인드 처리된 쇼츠. 눌러서 자세히 보기'
        : '${isExpired ? "소멸된 쇼츠" : "게시 중인 쇼츠"}. '
            '${short.textContent}. 총 $total표. 눌러서 자세히 보기';

    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
      onTap: () => _showShortsDetail(short),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isExpired
              ? AppTheme.cardColor.withValues(alpha: 0.45)
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: isBlind
              ? Border.all(color: AppTheme.blindColor.withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                isBlind ? '블라인드 처리됨' : short.textContent,
                style: TextStyle(
                  color: isBlind
                      ? AppTheme.textDisabled
                      : (isExpired
                          ? AppTheme.textDisabled
                          : AppTheme.textSecondary),
                  fontSize: 12,
                  height: 1.35,
                  fontStyle: isBlind ? FontStyle.italic : FontStyle.normal,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.how_to_vote_outlined,
                    size: 12, color: AppTheme.textFaint),
                const SizedBox(width: 3),
                Text(
                  '$total',
                  style: TextStyle(
                    color: isExpired
                        ? AppTheme.textDisabled
                        : AppTheme.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// 격자 칸을 누르면 지금까지 쓰던 상세 카드를 그대로 띄운다.
  void _showShortsDetail(ShortsModel short) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.textFaint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildShortsItem(short, sheetContext: sheetContext),
            ],
          ),
        ),
      ),
    );
  }

  /// 📊 내 글의 성적표
  /// - 총 득표수를 제일 크게: 작성자가 이 화면에 오는 이유가 그거다
  /// - 1등은 왕관 + 보라로 승격 (반응 텍스트는 작성자가 자유롭게 쓰는 값이라
  ///   길이를 예측할 수 없다 → 문장으로 요약하지 않고 시각적으로만 강조한다)
  /// - 막대는 스크롤로 들어올 때 0부터 차오른다 (피드 투표 연출과 같은 문법)
  Widget _buildVoteResult(ShortsModel short, {required bool dimmed}) {
    final total = short.computedTotalVotes;

    // 성적표니까 득표순으로 세운다. 원래 버튼 순서는 작성자가 정한 입력 순서라
    // 결과를 읽는 데는 의미가 없다.
    final ranked = [...short.buttons]
      ..sort((a, b) => b.votes.compareTo(a.votes));

    final Color winnerColor =
        dimmed ? AppTheme.textDisabled : AppTheme.accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 총 득표 헤드라인 ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: total.toDouble()),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Text(
                '${value.round()}',
                style: TextStyle(
                  color: dimmed ? AppTheme.textDisabled : AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '표',
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (total == 0)
              Text(
                '아직 반응이 없어요',
                style: TextStyle(color: AppTheme.textDisabled, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── 누적 막대 하나 ──
        // 막대는 '비교' 도구인데, 합이 100%인 값들은 비교가 아니라 '구성'이다.
        // 전체 폭 막대를 항목마다 쌓으면 같은 정보를 N배 공간에 그리게 된다.
        if (total > 0)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    for (int i = 0; i < ranked.length; i++)
                      if (ranked[i].votes > 0)
                        Expanded(
                          flex: (ranked[i].votes * 1000 * t).round() + 1,
                          child: Container(
                            color: _segmentColor(i, dimmed: dimmed),
                          ),
                        ),
                    // 아직 안 채워진 부분
                    if (t < 1)
                      Expanded(
                        flex: ((1 - t) * total * 1000).round() + 1,
                        child: Container(color: AppTheme.glassFill),
                      ),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: AppTheme.glassFill,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        const SizedBox(height: 12),

        // ── 범례 ──
        for (int i = 0; i < ranked.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                // 색 네모가 아니라 순위 숫자.
                // 막대의 어느 구간인지 색으로만 알려주면 색각 이상에서 대응이 끊긴다.
                // 숫자는 막대의 왼쪽부터의 순서와 같아서 색 없이도 매칭된다.
                Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: total > 0
                        ? _segmentColor(i, dimmed: dimmed)
                        : AppTheme.textFaint,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: (i == 0 && total > 0)
                          ? Colors.white
                          : AppTheme.backgroundColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (i == 0 && total > 0) ...[
                  Icon(Icons.emoji_events_rounded,
                      color: winnerColor, size: 13),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    ranked[i].text,
                    style: TextStyle(
                      color: (i == 0 && total > 0)
                          ? AppTheme.textPrimary
                          : AppTheme.textDisabled,
                      fontSize: 13,
                      fontWeight: (i == 0 && total > 0)
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  total > 0
                      ? '${ranked[i].votes}표 · ${(ranked[i].votes / total * 100).toStringAsFixed(0)}%'
                      : '0표',
                  style: TextStyle(
                    color: (i == 0 && total > 0)
                        ? winnerColor
                        : AppTheme.textDisabled,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 누적 막대 구간 색 — 1등만 accent, 나머지는 명도 단계로 구분한다.
  /// (accent를 여러 곳에 쓰면 강조가 아니게 된다)
  Color _segmentColor(int rank, {required bool dimmed}) {
    if (rank == 0) {
      return dimmed ? AppTheme.textDisabled : AppTheme.accentColor;
    }
    const steps = [0.55, 0.38, 0.24];
    final alpha = steps[(rank - 1).clamp(0, steps.length - 1)];
    return AppTheme.textTertiary.withValues(alpha: alpha);
  }

  Widget _buildShortsItem(ShortsModel short, {BuildContext? sheetContext}) {
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
              // ⏳ 게시 중인 글은 배지 대신 남은 시간을 보여준다.
              // 여긴 전부 본인이 쓴 실제 글이라 카운트다운이 참이다
              // (피드에는 시드가 섞여 있어서 넣지 않는다).
              // expiresAt가 없으면(구버전 서버 응답) 표시하지 않는다.
              // 24시간을 임의로 더해 그리면 서버 정책이 바뀌었을 때 거짓말이 된다.
              if (!isBlind && !isExpired && short.expiresAt != null)
                ExpiryIndicator(expiresAt: short.expiresAt!)
              else
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
                  // 아이콘은 18px이지만 탭 영역은 44px 이상이어야 한다.
                  // GestureDetector는 자식 크기만큼만 반응하므로 IconButton으로 교체.
                  Semantics(
                    button: true,
                    label: '이 쇼츠 삭제',
                    child: IconButton(
                      onPressed: () =>
                          _showDeleteConfirm(short, sheetContext: sheetContext),
                      icon: Icon(Icons.delete_outline,
                          color: AppTheme.textTertiary, size: 20),
                      constraints: const BoxConstraints(
                          minWidth: 44, minHeight: 44),
                      padding: EdgeInsets.zero,
                      tooltip: '삭제',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 본문 텍스트
          if (isBlind)
            // UC05 대안흐름 5b: 블라인드 문구
            Text(
              '운영 정책 위반으로 블라인드 처리되었습니다.',
              style: TextStyle(
                color: AppTheme.textDisabled,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Text(
              short.textContent,
              style: TextStyle(
                color: isExpired ? AppTheme.textDisabled : AppTheme.textPrimary,
                fontSize: 16,
              ),
            ),

          if (!isBlind) ...[
            const SizedBox(height: 14),
            _buildVoteResult(short, dimmed: isExpired),
          ],

          // 만료 안내 (5a) — 피드에서는 사라졌지만 기록은 여기 남는다
          if (isExpired)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '피드에서 사라졌어요. 기록은 여기 남아 있어요.',
                style: TextStyle(
                  color: AppTheme.textDisabled,
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
    final localTime = time.toLocal();
    final diff = DateTime.now().difference(localTime);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}
