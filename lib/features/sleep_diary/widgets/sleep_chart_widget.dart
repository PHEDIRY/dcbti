import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/models/sleep_diary_entry.dart';
import '../../../core/services/sleep_analysis_service.dart';

class SleepChartWidget extends StatefulWidget {
  final List<SleepDiaryEntry> entries;

  const SleepChartWidget({
    super.key,
    required this.entries,
  });

  @override
  State<SleepChartWidget> createState() => _SleepChartWidgetState();
}

class _SleepChartWidgetState extends State<SleepChartWidget> {
  final SleepAnalysisService _analysisService = SleepAnalysisService();
  List<SleepDiaryEntry?> _weekEntries =
      []; // Changed to nullable to handle empty days
  int? _selectedBarIndex;

  // Y-axis range (in minutes, 0 = midnight)
  double _minY = 0; // Will be set in _processData
  double _maxY = 0; // Will be set in _processData

  // Get Chinese day of week
  String _getChineseDayOfWeek(DateTime date) {
    final days = ['日', '一', '二', '三', '四', '五', '六'];
    return days[date.weekday % 7];
  }

  // Get the last 7 days entries, with null for days without entries
  List<SleepDiaryEntry?> _getLastSevenDaysEntries() {
    final now = DateTime.now();
    final lastSevenDays = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return DateTime(date.year, date.month, date.day);
    });

    // Group entries by date
    final entriesByDate = <DateTime, List<SleepDiaryEntry>>{};
    for (var entry in widget.entries) {
      final entryDate = DateTime(
        entry.entryDate.year,
        entry.entryDate.month,
        entry.entryDate.day,
      );
      entriesByDate.putIfAbsent(entryDate, () => []).add(entry);
    }

    // For each of the last 7 days, get the latest entry or null
    return lastSevenDays.map((date) {
      final dayEntries = entriesByDate[date];
      if (dayEntries == null || dayEntries.isEmpty) {
        return null;
      }
      // Sort by created time and get the latest
      dayEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return dayEntries.first;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _processData();
  }

  @override
  void didUpdateWidget(SleepChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entries != oldWidget.entries) {
      _processData();
    }
  }

  void _processData() {
    _weekEntries = _getLastSevenDaysEntries();

    // Find min and max time for y-axis scaling
    double earliestBedTime = double.infinity;
    double latestWakeTime = -double.infinity;

    for (var entry in _weekEntries) {
      if (entry == null) continue;

      // Convert to normalized minutes (minutes since midnight, can be negative for previous day)
      final bedTimeMinutes = _normalizeTimeToMinutes(entry.bedTime);
      final wakeTimeMinutes = _normalizeTimeToMinutes(entry.wakeTime) +
          entry.timeInBedAfterWakingMinutes;

      if (bedTimeMinutes < earliestBedTime) {
        earliestBedTime = bedTimeMinutes;
      }

      if (wakeTimeMinutes > latestWakeTime) {
        latestWakeTime = wakeTimeMinutes;
      }
    }

    // If no entries, set default range
    if (earliestBedTime == double.infinity) {
      earliestBedTime = -120; // 10 PM previous day
      latestWakeTime = 480; // 8 AM
    }

    // Add padding (30 minutes on each end)
    double minTime = earliestBedTime - 30;
    double maxTime = latestWakeTime + 30;

    // Round to nearest hour for cleaner display
    minTime = (minTime ~/ 60) * 60.0;
    maxTime = ((maxTime ~/ 60) + 1) * 60.0;

    // Ensure we have at least a 4-hour range for visibility
    if (maxTime - minTime < 240) {
      final midPoint = (minTime + maxTime) / 2;
      minTime = midPoint - 120;
      maxTime = midPoint + 120;
    }

    // Invert the values so that earlier times (smaller values) appear at the top
    _minY = -maxTime;
    _maxY = -minTime;
  }

  // Convert DateTime to minutes since midnight (can be negative for previous day)
  double _normalizeTimeToMinutes(DateTime time) {
    int minutes = time.hour * 60 + time.minute;

    // If time is in the evening (after 6 PM), treat it as previous day
    if (time.hour >= 18) {
      minutes = minutes - 24 * 60; // Make it negative to represent previous day
    }

    return minutes.toDouble();
  }

  // Format time for y-axis labels
  String _formatTimeLabel(double value) {
    // Invert the value back to get the actual time
    value = -value;

    // Convert to 24-hour format
    int totalMinutes = value.toInt();
    int hours = (totalMinutes ~/ 60) % 24;
    if (hours < 0) hours += 24;
    int minutes = totalMinutes % 60;
    if (minutes < 0) minutes += 60;

    return DateFormat('HH:mm').format(DateTime(2023, 1, 1, hours, minutes));
  }

  // Calculate sleep efficiency for an entry
  String _calculateEfficiency(SleepDiaryEntry entry) {
    final efficiency = _analysisService.calculateSE(entry);
    return '${efficiency.toStringAsFixed(0)}%';
  }

  List<BarChartGroupData> _buildBarGroups() {
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < _weekEntries.length; i++) {
      final entry = _weekEntries[i];

      if (entry == null) {
        // Empty bar for days without entries
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: 0,
                fromY: 0,
                width: 25,
                color: CupertinoColors.systemGrey6,
              ),
            ],
          ),
        );
        continue;
      }

      final segments = _createSleepSegments(entry);

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: -(_normalizeTimeToMinutes(entry.bedTime)),
              fromY: -(_normalizeTimeToMinutes(entry.wakeTime) +
                  entry.timeInBedAfterWakingMinutes),
              width: 25,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
                bottom: Radius.circular(0),
              ),
              rodStackItems: _invertStackItems(segments),
            ),
          ],
          showingTooltipIndicators: _selectedBarIndex == i ? [0] : [],
        ),
      );
    }

    return barGroups;
  }

  // Invert stack items for correct display orientation
  List<BarChartRodStackItem> _invertStackItems(
      List<BarChartRodStackItem> segments) {
    List<BarChartRodStackItem> invertedSegments = [];

    for (var segment in segments) {
      invertedSegments.add(
        BarChartRodStackItem(
          -segment.toY,
          -segment.fromY,
          segment.color,
        ),
      );
    }

    // Sort segments by fromY to ensure correct stacking
    invertedSegments.sort((a, b) => a.fromY.compareTo(b.fromY));

    return invertedSegments;
  }

  List<BarChartRodStackItem> _createSleepSegments(SleepDiaryEntry entry) {
    List<BarChartRodStackItem> segments = [];

    // Convert times to normalized minutes
    final bedTimeY = _normalizeTimeToMinutes(entry.bedTime);
    final wakeTimeY = _normalizeTimeToMinutes(entry.wakeTime);

    // Track current position as we build segments
    double currentY = bedTimeY;

    // 1. Sleep Onset Latency (SOL) segment
    if (entry.timeToFallAsleepMinutes > 0) {
      final solEndY = bedTimeY + entry.timeToFallAsleepMinutes;

      // Check if there was time out of bed during SOL
      if (entry.initialOutOfBedDurationMinutes != null &&
          entry.initialOutOfBedDurationMinutes! > 0) {
        // Split SOL into: in bed awake and out of bed
        final inBedAwakeMinutes = entry.timeToFallAsleepMinutes -
            entry.initialOutOfBedDurationMinutes!;
        final outOfBedStartY = bedTimeY + inBedAwakeMinutes;

        // In bed awake part
        segments.add(
          BarChartRodStackItem(
            bedTimeY,
            outOfBedStartY,
            CupertinoColors.systemOrange, // Awake color
          ),
        );

        // Out of bed part
        segments.add(
          BarChartRodStackItem(
            outOfBedStartY,
            solEndY,
            CupertinoColors.systemTeal, // Out of bed color
          ),
        );
      } else {
        // Regular SOL (all in bed)
        segments.add(
          BarChartRodStackItem(
            bedTimeY,
            solEndY,
            CupertinoColors.systemOrange, // Awake color
          ),
        );
      }

      currentY = solEndY;
    }

    // 2. Process sleep segments with WASO
    if (entry.numberOfAwakenings > 0) {
      // Sort wake events by time
      final sortedWakeEvents = List<WakeUpEvent>.from(entry.wakeUpEvents)
          .where((event) => event.time != null)
          .toList()
        ..sort((a, b) => a.time!.compareTo(b.time!));

      for (int i = 0; i < sortedWakeEvents.length; i++) {
        final wakeEvent = sortedWakeEvents[i];
        final wakeEventY = _normalizeTimeToMinutes(wakeEvent.time!);

        // Add sleep segment before wake event if needed
        if (wakeEventY > currentY) {
          segments.add(
            BarChartRodStackItem(
              currentY,
              wakeEventY,
              CupertinoColors.systemIndigo, // Asleep color
            ),
          );
        }

        // Add wake event segment(s)
        if (wakeEvent.gotOutOfBed &&
            wakeEvent.outOfBedDurationMinutes != null) {
          // Split into in-bed awake and out-of-bed
          final inBedEndY = wakeEventY + wakeEvent.stayedInBedMinutes;

          // In bed awake part
          segments.add(
            BarChartRodStackItem(
              wakeEventY,
              inBedEndY,
              CupertinoColors.systemOrange, // Awake color
            ),
          );

          // Out of bed part
          segments.add(
            BarChartRodStackItem(
              inBedEndY,
              inBedEndY + wakeEvent.outOfBedDurationMinutes!,
              CupertinoColors.systemTeal, // Out of bed color
            ),
          );

          currentY = inBedEndY + wakeEvent.outOfBedDurationMinutes!;
        } else {
          // Regular wake event (all in bed)
          final wakeEndY = wakeEventY + wakeEvent.stayedInBedMinutes;

          segments.add(
            BarChartRodStackItem(
              wakeEventY,
              wakeEndY,
              CupertinoColors.systemOrange, // Awake color
            ),
          );

          currentY = wakeEndY;
        }
      }

      // Add final sleep segment from last wake event to final awakening if needed
      if (currentY < wakeTimeY) {
        segments.add(
          BarChartRodStackItem(
            currentY,
            wakeTimeY,
            CupertinoColors.systemIndigo, // Asleep color
          ),
        );
      }
    } else {
      // No wake events, just one sleep segment from SOL end to wake time
      segments.add(
        BarChartRodStackItem(
          currentY,
          wakeTimeY,
          CupertinoColors.systemIndigo, // Asleep color
        ),
      );
    }

    // 3. Lingering in Bed (LIB) segment
    if (entry.timeInBedAfterWakingMinutes > 0) {
      segments.add(
        BarChartRodStackItem(
          wakeTimeY,
          wakeTimeY + entry.timeInBedAfterWakingMinutes,
          CupertinoColors.systemOrange, // Awake color
        ),
      );
    }

    return segments;
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 14,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
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

  @override
  Widget build(BuildContext context) {
    // Get today's date to calculate the dates for x-axis labels
    final now = DateTime.now();
    final dates =
        List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '睡眠模式',
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _maxY,
                minY: _minY,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 120, // 2-hour intervals
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: CupertinoColors.systemGrey5,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return const FlLine(
                      color: CupertinoColors.systemGrey5,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 120, // Show every 2 hours
                      getTitlesWidget: (value, meta) {
                        // Only show labels at 2-hour intervals
                        if (value % 120 != 0) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            _formatTimeLabel(value),
                            style: const TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= _weekEntries.length) {
                          return const SizedBox.shrink();
                        }

                        final date = dates[value.toInt()];
                        final dayText = _getChineseDayOfWeek(date);
                        final entry = _weekEntries[value.toInt()];

                        return Column(
                          children: [
                            Text(
                              entry != null
                                  ? _calculateEfficiency(entry)
                                  : '--',
                              style: TextStyle(
                                color: _selectedBarIndex == value.toInt()
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.systemGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dayText,
                              style: TextStyle(
                                color: _selectedBarIndex == value.toInt()
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.systemGrey,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                barGroups: _buildBarGroups(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor:
                        CupertinoColors.systemBackground.withOpacity(0.8),
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final entry = _weekEntries[groupIndex];
                      if (entry == null) return null;

                      final dateFormat = DateFormat('yyyy年MM月dd日');
                      final timeFormat = DateFormat('HH:mm');

                      return BarTooltipItem(
                        '${dateFormat.format(entry.entryDate)}\n'
                        '就寢時間: ${timeFormat.format(entry.bedTime)}\n'
                        '起床時間: ${timeFormat.format(entry.wakeTime)}\n'
                        '睡眠效率: ${_analysisService.calculateSE(entry).toStringAsFixed(1)}%\n'
                        '總睡眠時間: ${_formatDuration(_analysisService.calculateTST(entry))}',
                        const TextStyle(
                          color: CupertinoColors.label,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (event.isInterestedForInteractions &&
                        response != null &&
                        response.spot != null) {
                      setState(() {
                        _selectedBarIndex = response.spot!.touchedBarGroupIndex;
                      });
                    } else if (event is FlTapUpEvent) {
                      setState(() {
                        _selectedBarIndex = null;
                      });
                    }
                  },
                  touchExtraThreshold:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 150),
                  handleBuiltInTouches: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                  color: CupertinoColors.systemIndigo, label: '睡眠中'),
              const SizedBox(width: 16),
              _buildLegendItem(
                  color: CupertinoColors.systemOrange, label: '清醒'),
              const SizedBox(width: 16),
              _buildLegendItem(
                  color: CupertinoColors.systemTeal, label: '離開床鋪'),
            ],
          ),
        ],
      ),
    );
  }
}
