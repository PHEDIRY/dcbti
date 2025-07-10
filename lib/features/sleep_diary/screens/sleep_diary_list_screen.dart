import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/sleep_diary_entry.dart';
import '../../../core/services/sleep_diary_service.dart';
import '../../../core/services/sleep_analysis_service.dart';
import '../widgets/sleep_chart_widget.dart';
import 'sleep_diary_entry_screen.dart';

class SleepDiaryListScreen extends StatefulWidget {
  const SleepDiaryListScreen({super.key});

  @override
  State<SleepDiaryListScreen> createState() => _SleepDiaryListScreenState();
}

class _SleepDiaryListScreenState extends State<SleepDiaryListScreen> {
  final SleepDiaryService _diaryService = SleepDiaryService();
  final SleepAnalysisService _analysisService = SleepAnalysisService();
  List<SleepDiaryEntry> _entries = [];
  Map<String, dynamic> _weeklyAverages = {};
  bool _isLoading = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    if (_isRefreshing) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final entries = await _diaryService.getEntries();
      final weeklyEntries = _analysisService.getLastWeekEntries(entries);
      final weeklyAverages =
          _analysisService.calculateWeeklyAverages(weeklyEntries);

      setState(() {
        _entries = entries;
        _weeklyAverages = weeklyAverages;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '載入失敗：${e.toString()}';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadEntries();
  }

  Future<void> _deleteEntry(String id) async {
    try {
      await _diaryService.deleteEntry(id);
      setState(() {
        _entries.removeWhere((entry) => entry.id == id);
      });
      // Recalculate weekly averages after deleting an entry
      final weeklyEntries = _analysisService.getLastWeekEntries(_entries);
      final weeklyAverages =
          _analysisService.calculateWeeklyAverages(weeklyEntries);
      setState(() {
        _weeklyAverages = weeklyAverages;
      });
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('刪除失敗'),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: const Text('確定'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  void _navigateToEntryScreen() {
    Navigator.of(context)
        .push(
          CupertinoPageRoute(
            builder: (context) => const SleepDiaryEntryScreen(),
          ),
        )
        .then((_) => _loadEntries());
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours小時 $minutes分鐘';
    } else {
      return '$minutes分鐘';
    }
  }

  Widget _buildAnalyticsCard() {
    if (_entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final avgTST = _weeklyAverages['avgTST'] as Duration;
    final avgSE = _weeklyAverages['avgSE'] as double;
    final avgSOL = _weeklyAverages['avgSOL'] as int;
    final avgWASO = _weeklyAverages['avgWASO'] as int;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '過去七天睡眠數據',
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_analysisService.getLastWeekEntries(_entries).length}筆記錄',
                    style: const TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    icon: CupertinoIcons.moon_fill,
                    label: '平均睡眠時間',
                    value: _formatDuration(avgTST),
                    color: CupertinoColors.systemIndigo,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    icon: CupertinoIcons.chart_bar_fill,
                    label: '睡眠效率',
                    value: '${avgSE.toStringAsFixed(1)}%',
                    color: CupertinoColors.systemGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    icon: CupertinoIcons.clock,
                    label: '平均入睡時間',
                    value: '$avgSOL分鐘',
                    color: CupertinoColors.systemOrange,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    icon: CupertinoIcons.exclamationmark_circle,
                    label: '平均夜醒時間',
                    value: '$avgWASO分鐘',
                    color: CupertinoColors.systemRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTagDisplayName(String tag) {
    // Translate tags to Traditional Chinese
    switch (tag) {
      case 'exercise':
        return '運動';
      case 'nap_longer_than_30min':
        return '長時間午睡';
      case 'sunlight_within_30min_of_waking':
        return '早晨曬太陽';
      case 'yoga':
        return '瑜伽';
      case 'caffeine_after_12pm':
        return '下午咖啡因';
      case 'stretching':
        return '伸展';
      case 'meditation':
        return '冥想';
      case 'reading':
        return '閱讀';
      case 'eat_within_3hours_of_bed':
        return '睡前進食';
      case 'journaling':
        return '寫日記';
      case 'alcohol_within_3hours_of_bed':
        return '睡前飲酒';
      case 'shower':
        return '淋浴';
      case 'worked_late':
        return '熬夜工作';
      case 'socialized_late':
        return '熬夜社交';
      case 'screen_time_within_1hour_of_bed':
        return '使用螢幕';
      case 'capa_therapy':
        return 'CAPA治療';
      case 'sleeping_pills':
        return '安眠藥';
      case 'melatonin':
        return '褪黑激素';
      case 'supplements_herbs':
        return '補充劑/草藥';
      case 'cbd_thc':
        return 'CBD/THC';
      case 'nicotine_tobacco':
        return '尼古丁/菸草';
      case 'other_medications':
        return '其他藥物';
      case 'stress_racing_thoughts':
        return '壓力/思緒紛飛';
      case 'nightmares':
        return '惡夢';
      case 'light':
        return '光線';
      case 'noises':
        return '噪音';
      case 'temperature':
        return '溫度';
      case 'snoring':
        return '打鼾';
      case 'woke_for_bathroom':
        return '如廁';
      case 'kids_partner_pets':
        return '家人/寵物干擾';
      case 'travel_jet_lag':
        return '時差';
      case 'pain_illness_injury':
        return '身體不適';
      default:
        return tag;
    }
  }

  Widget _buildEntryCard(SleepDiaryEntry entry) {
    final dateFormat = DateFormat('yyyy年MM月dd日');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CupertinoContextMenu(
          actions: [
            CupertinoContextMenuAction(
              isDestructiveAction: true,
              trailingIcon: CupertinoIcons.delete,
              onPressed: () {
                Navigator.of(context).pop();
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('確認刪除'),
                    content: const Text('確定要刪除這筆睡眠日記嗎？此操作無法復原。'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('取消'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        child: const Text('刪除'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _deleteEntry(entry.id);
                        },
                      ),
                    ],
                  ),
                );
              },
              child: const Text('刪除'),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateFormat.format(entry.entryDate),
                      style: const TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.star_fill,
                            size: 14,
                            color: CupertinoColors.systemYellow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.sleepQuality}',
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.systemBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '就寢時間',
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeFormat.format(entry.bedTime),
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.arrow_right,
                      color: CupertinoColors.systemGrey,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '起床時間',
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeFormat.format(entry.wakeTime),
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '睡眠時間',
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDuration(
                                _analysisService.calculateTST(entry)),
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '入睡時間',
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${entry.timeToFallAsleepMinutes}分鐘',
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '睡眠效率',
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_analysisService.calculateSE(entry).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '夜醒次數',
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${entry.numberOfAwakenings}次',
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '床上時間',
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDuration(
                                _analysisService.calculateTIB(entry)),
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '夜醒時間',
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDuration(Duration(
                                minutes:
                                    _analysisService.calculateWASO(entry))),
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '賴床時間',
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDuration(Duration(
                                minutes: _analysisService.calculateLIB(entry))),
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(
                        child: SizedBox()), // Empty space for alignment
                  ],
                ),
                if (entry.sleepTags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...entry.sleepTags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey5,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getTagDisplayName(tag),
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        );
                      }).toList(),

                      // Show +X more if there are more than 3 tags
                      if (entry.sleepTags.length > 3)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey5,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${entry.sleepTags.length - 3}',
                            style: const TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('睡眠日記'),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            if (_isLoading && !_isRefreshing)
              const Center(
                child: CupertinoActivityIndicator(),
              )
            else if (_errorMessage != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: CupertinoColors.systemRed),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      onPressed: _loadEntries,
                      child: const Text('重試'),
                    ),
                  ],
                ),
              )
            else if (_entries.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.moon_zzz_fill,
                      size: 64,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '尚無睡眠日記',
                      style: TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '點擊下方按鈕新增您的第一筆睡眠日記',
                      style: TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton.filled(
                      onPressed: _navigateToEntryScreen,
                      child: const Text('新增睡眠日記'),
                    ),
                  ],
                ),
              )
            else
              CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  CupertinoSliverRefreshControl(
                    onRefresh: _handleRefresh,
                  ),
                  SliverToBoxAdapter(
                    child: _buildAnalyticsCard(),
                  ),
                  SliverToBoxAdapter(
                    child: SleepChartWidget(entries: _entries),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildEntryCard(_entries[index]),
                        childCount: _entries.length,
                      ),
                    ),
                  ),
                ],
              ),

            // Add button
            if (!_isLoading && (_entries.isNotEmpty || _errorMessage != null))
              Positioned(
                right: 16,
                bottom: 16,
                child: CupertinoButton(
                  padding: const EdgeInsets.all(16),
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(30),
                  onPressed: _navigateToEntryScreen,
                  child: const Icon(
                    CupertinoIcons.add,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
