import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/models/sleep_diary_entry.dart';
import 'package:intl/intl.dart';
import '../../../core/services/sleep_diary_service.dart';

class SleepDiaryEntryScreen extends StatefulWidget {
  const SleepDiaryEntryScreen({super.key});

  @override
  State<SleepDiaryEntryScreen> createState() => _SleepDiaryEntryScreenState();
}

class _SleepDiaryEntryScreenState extends State<SleepDiaryEntryScreen> {
  int _currentStep = 0;

  // Basic sleep info
  late DateTime _bedTime;
  late DateTime _finalAwakeningTime;

  // Add state for Q3 selection
  bool? _hasLeftBed;
  late Duration _leftBedDuration;

  @override
  void initState() {
    super.initState();
    // Initialize Q3 selection as null (no selection)
    _hasLeftBed = null;
    _leftBedDuration = Duration.zero;
    // Set default times using DateTime.now() as base to ensure correct date
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    // Q1: Default bedtime is 23:00 previous day
    _bedTime = DateTime(
      yesterday.year,
      yesterday.month,
      yesterday.day,
      23, // 23:00 default
      0,
    );
    // Q7: Default wake time is 07:00 current day
    _finalAwakeningTime = DateTime(
      now.year,
      now.month,
      now.day,
      7, // 07:00 default
      0,
    );
  }

  // Other state variables
  int _timeToFallAsleepHours = 0;
  int _timeToFallAsleepMinutes = 0;
  int _initialOutOfBedHours = 0;
  int _initialOutOfBedMinutes = 0;
  String? _sleepDifficultyReason;
  int _numberOfAwakenings = 0;
  final List<WakeUpEvent> _wakeUpEvents = [];
  String? _wakeUpDifficultyReason;
  bool? _immediateWakeUp;
  int _timeInBedAfterWakingHours = 0;
  int _timeInBedAfterWakingMinutes = 0;
  double? _sleepQuality;

  // Quality and notes
  final TextEditingController _notesController = TextEditingController();

  // Consumption events
  ConsumptionEvent? _caffeineConsumption;
  ConsumptionEvent? _alcoholConsumption;
  ConsumptionEvent? _sleepMedicineConsumption;
  ConsumptionEvent? _smokingEvent;
  ConsumptionEvent? _exerciseEvent;
  ConsumptionEvent? _lastMealTime;

  // Tags
  final Set<String> _selectedTags = {};

  List<Widget> get _pages => [
        _buildBedTimePage(),
        _buildTimeToFallAsleepPage(),
        _buildLeftBedPage(),
        _buildSleepDifficultyReasonPage(),
        _buildNumberOfAwakeningsPage(),
        _buildWakeUpDifficultyReasonPage(),
        _buildFinalAwakeningPage(),
        _buildImmediateWakeUpPage(),
        _buildTimeInBedAfterWakingPage(),
        _buildSleepQualityPage(),
        _buildConsumptionEventsPage(),
        _buildTagsPage(),
      ];

  void _showTimePicker(BuildContext context, DateTime initialTime, String title,
      Function(DateTime) onTimeSelected) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 280,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CupertinoButton(
                  child: const Text('確定'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initialTime,
                onDateTimeChanged: onTimeSelected,
                use24hFormat: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 280,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  '選擇日期',
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),
                CupertinoButton(
                  child: const Text('確定'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _bedTime,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (DateTime newDate) {
                  setState(() {
                    _bedTime = DateTime(
                      newDate.year,
                      newDate.month,
                      newDate.day,
                      _bedTime.hour,
                      _bedTime.minute,
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    // Validation before creating entry
    final validationError = _validateEntry();
    if (validationError != null) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('資料有誤'),
          content: Text(validationError),
          actions: [
            CupertinoDialogAction(
              child: const Text('確定'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }
    final entry = SleepDiaryEntry.create(
      entryDate: _bedTime,
      bedTime: _bedTime,
      wakeTime: _finalAwakeningTime,
      timeToFallAsleepMinutes:
          _timeToFallAsleepHours * 60 + _timeToFallAsleepMinutes,
      numberOfAwakenings: _numberOfAwakenings,
      wakeUpEvents: _wakeUpEvents,
      finalAwakeningTime: _finalAwakeningTime,
      timeInBedAfterWakingMinutes:
          _timeInBedAfterWakingHours * 60 + _timeInBedAfterWakingMinutes,
      sleepQuality: _sleepQuality ?? 0.0,
      caffeineConsumption: _caffeineConsumption,
      alcoholConsumption: _alcoholConsumption,
      sleepMedicineConsumption: _sleepMedicineConsumption,
      smokingEvent: _smokingEvent,
      exerciseEvent: _exerciseEvent,
      lastMealTime: _lastMealTime,
      sleepTags: _selectedTags.toList(),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      sleepDifficultyReason: _sleepDifficultyReason,
      wakeUpDifficultyReason: _wakeUpDifficultyReason,
      immediateWakeUp: _immediateWakeUp ?? false,
      initialOutOfBedDurationMinutes:
          _initialOutOfBedHours * 60 + _initialOutOfBedMinutes,
    );

    final service = SleepDiaryService();
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        content: SizedBox(
          height: 60,
          child: Center(child: CupertinoActivityIndicator()),
        ),
      ),
    );
    try {
      await service.saveEntry(entry);
      if (mounted) {
        Navigator.of(context).pop(); // Remove loading dialog

        // Show success dialog
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('✅ '),
                const Text(
                  '已儲存',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            content: Text(
              '你的睡眠日記已經儲存成功！\n${DateFormat('yyyy年M月d日 (E)', 'zh_TW').format(_bedTime)}',
              style: const TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 13,
                height: 1.3,
              ),
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('完成'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context)
                      .pop(true); // Pop screen with success result
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Remove loading
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('儲存失敗'),
            content: Text('發生錯誤：\n$e'),
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

  void _addWakeUpEvent() {
    setState(() {
      DateTime wakeTime;
      if (_wakeUpEvents.isEmpty) {
        // First wake-up: 2 hours after bedtime as default
        wakeTime = DateTime(
          _bedTime.year,
          _bedTime.month,
          _bedTime.day,
          (_bedTime.hour + 2) % 24,
          _bedTime.minute,
        );
      } else {
        // Subsequent wake-ups: 2 hours after previous wake-up
        final lastEvent = _wakeUpEvents.last;
        wakeTime = DateTime(
          lastEvent.time.year,
          lastEvent.time.month,
          lastEvent.time.day,
          (lastEvent.time.hour + 2) % 24,
          lastEvent.time.minute,
        );
      }

      _wakeUpEvents.add(
        WakeUpEvent(
          time: wakeTime,
          gotOutOfBed: false,
          stayedInBedMinutes: 1, // Changed from 5 to 1 minutes as minimum
        ),
      );
    });
  }

  void _updateWakeUpEvent(int index, WakeUpEvent event) {
    setState(() {
      _wakeUpEvents[index] = event;
    });
  }

  void _removeWakeUpEvent(int index) {
    setState(() {
      _wakeUpEvents.removeAt(index);
      _numberOfAwakenings = _wakeUpEvents.length;
    });
  }

  void _showCloseConfirmation() {
    showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text(
          '確定要離開嗎？',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          '所有已輸入的資料將會遺失',
          style: TextStyle(
            fontFamily: 'SF Pro Text',
          ),
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context, false); // Close dialog and return false
            },
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context, true); // Close dialog and return true
            },
            child: const Text('離開'),
          ),
        ],
      ),
    ).then((shouldPop) {
      if (shouldPop ?? false) {
        // Only pop the screen if user confirmed
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        padding: const EdgeInsetsDirectional.only(end: 8),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _currentStep > 0
              ? () {
                  setState(() {
                    _currentStep--;
                  });
                }
              : () {
                  Navigator.of(context).pop();
                },
          child: _wrapIcon(CupertinoIcons.back),
        ),
        middle: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text(
            '新增睡眠日記',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showCloseConfirmation,
          child: _wrapIcon(CupertinoIcons.xmark),
        ),
      ),
      child: Container(
        color: CupertinoColors.systemGroupedBackground,
        child: GestureDetector(
          onHorizontalDragEnd: (DragEndDetails details) {
            if (details.primaryVelocity! > 0 && _currentStep > 0) {
              // Swipe right to go back
              setState(() {
                _currentStep--;
              });
            }
          },
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('yyyy年M月d日 (E)', 'zh_TW').format(_bedTime),
                        style: const TextStyle(
                          fontFamily: 'SF Pro Text',
                          fontSize: 15,
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildProgressIndicator(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          _pages[_currentStep],
                          // Add bottom padding to ensure content doesn't get cut off
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildNavigationButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '問題 ${_currentStep + 1}/${_pages.length}',
              style: const TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 13,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 3,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(1.5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (_currentStep + 1) / _pages.length,
            child: Container(
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_currentStep == _pages.length - 1)
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _handleSubmit,
                  child: const Text('儲存'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: () {
                    setState(() {
                      // Always skip Q9 (index 8) since it's merged with Q8
                      if (_currentStep == 7) {
                        _currentStep += 2;
                      } else {
                        _currentStep++;
                      }
                    });
                  },
                  child: const Text('繼續'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String title,
    required String subtitle,
    required DateTime time,
    required Function(DateTime) onChanged,
    DateTime? referenceTime,
    bool isWakeTime = false,
    DateTime? minTime,
    DateTime? maxTime,
  }) {
    // Calculate display date and hint
    DateTime displayDate = time;
    if (referenceTime != null) {
      if (isWakeTime) {
        if (time.isBefore(referenceTime)) {
          displayDate = time.add(const Duration(days: 1));
        }
      }
    }
    final dateHint =
        '你選擇的日期與時間：${DateFormat('yyyy年M月d日 HH:mm', 'zh_TW').format(displayDate)}';

    // --- Custom hour/minute picker logic ---
    final min = minTime ?? time;
    final max = maxTime ?? time;

    // For Q1: Create a continuous range from previous day 12:00 to current time
    // Calculate total hours from min to max
    int hoursFromMin;
    if (min.day != max.day) {
      // If spanning days, count hours from min time to midnight, then add hours until max time
      hoursFromMin = (24 - min.hour) + max.hour + 1;
    } else {
      hoursFromMin = max.hour - min.hour + 1;
    }

    // Calculate the current selection's position in the continuous range
    int selectedPosition;
    if (time.day == min.day) {
      selectedPosition = time.hour - min.hour;
    } else {
      selectedPosition = (24 - min.hour) + time.hour;
    }

    // For minutes, limit range if we're at boundary hours
    bool isAtMinHour = time.day == min.day && time.hour == min.hour;
    bool isAtMaxHour = time.day == max.day && time.hour == max.hour;
    int minMinute = isAtMinHour ? min.minute : 0;
    int maxMinute = isAtMaxHour ? max.minute : 59;

    final hourController =
        FixedExtentScrollController(initialItem: selectedPosition);
    final minuteController =
        FixedExtentScrollController(initialItem: time.minute - minMinute);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 17,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            dateHint,
            style: const TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 17,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                const Text(
                  '小時',
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 15,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 80,
                  height: 160,
                  child: CupertinoPicker(
                    selectionOverlay: null,
                    magnification: 1.1,
                    squeeze: 1.0,
                    itemExtent: 40,
                    scrollController: hourController,
                    onSelectedItemChanged: (int value) {
                      // Convert the continuous position back to actual date/hour
                      DateTime newTime;
                      int newHour;
                      if (value < (24 - min.hour)) {
                        // Previous day
                        newHour = min.hour + value;
                        newTime = DateTime(
                          min.year,
                          min.month,
                          min.day,
                          newHour,
                          time.minute,
                        );
                      } else {
                        // Current day
                        newHour = value - (24 - min.hour);
                        newTime = DateTime(
                          max.year,
                          max.month,
                          max.day,
                          newHour,
                          time.minute,
                        );
                      }

                      // Adjust minutes if needed
                      int adjustedMinute = time.minute;
                      if (newTime.day == min.day &&
                          newHour == min.hour &&
                          adjustedMinute < min.minute) {
                        adjustedMinute = min.minute;
                      }
                      if (newTime.day == max.day &&
                          newHour == max.hour &&
                          adjustedMinute > max.minute) {
                        adjustedMinute = max.minute;
                      }

                      newTime = DateTime(
                        newTime.year,
                        newTime.month,
                        newTime.day,
                        newHour,
                        adjustedMinute,
                      );

                      onChanged(newTime);
                    },
                    children: List<Widget>.generate(hoursFromMin, (int index) {
                      int displayHour;
                      if (index < (24 - min.hour)) {
                        // Previous day
                        displayHour = min.hour + index;
                      } else {
                        // Current day
                        displayHour = index - (24 - min.hour);
                      }
                      return Center(
                        child: Text(
                          displayHour.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 22,
                            color: CupertinoColors.label,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Column(
              children: [
                const Text(
                  '分鐘',
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 15,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 80,
                  height: 160,
                  child: CupertinoPicker(
                    selectionOverlay: null,
                    magnification: 1.1,
                    squeeze: 1.0,
                    itemExtent: 40,
                    scrollController: minuteController,
                    onSelectedItemChanged: (int value) {
                      int newMinute = minMinute + value;
                      onChanged(DateTime(
                        time.year,
                        time.month,
                        time.day,
                        time.hour,
                        newMinute,
                      ));
                    },
                    children: List<Widget>.generate(maxMinute - minMinute + 1,
                        (int index) {
                      final minute = minMinute + index;
                      return Center(
                        child: Text(
                          minute.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 22,
                            color: CupertinoColors.label,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBedTimePage() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final minTime = DateTime(
      yesterday.year,
      yesterday.month,
      yesterday.day,
      12,
      0,
    ); // 12:00 PM previous day
    final maxTime = now; // Current time
    return _buildTimePicker(
      title: '你什麼時候上床睡覺？',
      subtitle: '選擇你躺到床上準備睡覺的時間',
      time: _bedTime,
      onChanged: (time) {
        setState(() {
          _bedTime = time;
        });
      },
      referenceTime: DateTime(_bedTime.year, _bedTime.month, _bedTime.day),
      isWakeTime: false,
      minTime: minTime,
      maxTime: maxTime,
    );
  }

  Widget _buildTimeToFallAsleepPage() {
    return _buildDurationPicker(
      title: '躺上床後，花了多長時間才入睡？',
      subtitle: '從躺到床上到入睡花了多少時間',
      hours: _timeToFallAsleepHours,
      minutes: _timeToFallAsleepMinutes,
      onChanged: (hours, minutes) {
        setState(() {
          _timeToFallAsleepHours = hours;
          _timeToFallAsleepMinutes = minutes;
        });
      },
    );
  }

  Widget _buildLeftBedPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '等待入睡期間，有離開床舖嗎？',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 24),
        Column(
          children: ['是', '否'].map((option) {
            final isSelected = _hasLeftBed == (option == '是');
            return GestureDetector(
              onTap: () => setState(() {
                _hasLeftBed = option == '是';
                if (option == '否') {
                  _leftBedDuration = Duration.zero;
                }
              }),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey5,
                    width: 1,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 17,
                    color: isSelected
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.label,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_hasLeftBed == true) ...[
          _buildDurationPicker(
            title: '',
            subtitle: '選擇離開床舖的持續時間',
            hours: _leftBedDuration.inHours,
            minutes: _leftBedDuration.inMinutes.remainder(60),
            onChanged: (int hours, int minutes) {
              setState(() {
                _leftBedDuration = Duration(hours: hours, minutes: minutes);
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSleepDifficultyReasonPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '下列哪一項最讓你睡不著？',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '選擇最符合你情況的原因',
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 17,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 24),
        _buildSleepDifficultyReasonSection(),
      ],
    );
  }

  Widget _buildSleepDifficultyReasonSection() {
    final reasons = [
      '思緒奔騰',
      '身體躁動不安',
      '憂慮或焦慮',
      '其他',
      '以上皆無',
    ];

    return Column(
      children: reasons.map((reason) {
        final isSelected = _sleepDifficultyReason == reason;
        return GestureDetector(
          onTap: () => setState(
              () => _sleepDifficultyReason = isSelected ? null : reason),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey5,
                width: 1,
              ),
            ),
            child: Text(
              reason,
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 17,
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.label,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumberOfAwakeningsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '睡眠期間醒來幾次？',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '不包括最後起床的那一次',
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 17,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 24),
        _buildNumberInput(
          title: '醒來次數',
          value: _numberOfAwakenings,
          onChanged: (value) {
            setState(() {
              _numberOfAwakenings = value;
              while (_wakeUpEvents.length < value) {
                _addWakeUpEvent();
              }
              while (_wakeUpEvents.length > value) {
                _wakeUpEvents.removeLast();
              }
            });
          },
          suffix: '次',
        ),
        if (_numberOfAwakenings > 0) ...[
          const SizedBox(height: 32),
          ..._wakeUpEvents.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.systemGrey5,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '第 ${index + 1} 次醒來',
                      style: const TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeField(
                      label: '醒來時間',
                      time: event.time,
                      onTimeSelected: (time) => _updateWakeUpEvent(
                        index,
                        WakeUpEvent(
                          time: time,
                          gotOutOfBed: event.gotOutOfBed,
                          outOfBedDurationMinutes:
                              event.outOfBedDurationMinutes,
                          stayedInBedMinutes: event.stayedInBedMinutes,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNumberInput(
                      title: '清醒時長',
                      value: event.stayedInBedMinutes,
                      onChanged: (value) => _updateWakeUpEvent(
                        index,
                        WakeUpEvent(
                          time: event.time,
                          gotOutOfBed: event.gotOutOfBed,
                          outOfBedDurationMinutes:
                              event.outOfBedDurationMinutes,
                          stayedInBedMinutes: value,
                        ),
                      ),
                      suffix: '分鐘',
                      minValue: 1,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CupertinoSwitch(
                          value: event.gotOutOfBed,
                          onChanged: (value) => _updateWakeUpEvent(
                            index,
                            WakeUpEvent(
                              time: event.time,
                              gotOutOfBed: value,
                              outOfBedDurationMinutes:
                                  value ? event.outOfBedDurationMinutes : null,
                              stayedInBedMinutes: event.stayedInBedMinutes,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '是否下床',
                          style: TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 17,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ],
                    ),
                    if (event.gotOutOfBed) ...[
                      const SizedBox(height: 16),
                      _buildNumberInput(
                        title: '下床時長',
                        value: event.outOfBedDurationMinutes ?? 1,
                        onChanged: (value) => _updateWakeUpEvent(
                          index,
                          WakeUpEvent(
                            time: event.time,
                            gotOutOfBed: event.gotOutOfBed,
                            outOfBedDurationMinutes: value,
                            stayedInBedMinutes: event.stayedInBedMinutes,
                          ),
                        ),
                        suffix: '分鐘',
                        minValue: 1,
                        maxValue: event.stayedInBedMinutes,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildWakeUpDifficultyReasonPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '下列哪一項最讓你一直醒著？',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '選擇最符合你情況的原因',
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 17,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 24),
        _buildWakeUpDifficultyReasonSection(),
      ],
    );
  }

  Widget _buildWakeUpDifficultyReasonSection() {
    final reasons = [
      '思緒奔騰',
      '身體躁動不安',
      '憂慮或焦慮',
      '其他',
      '以上皆無',
    ];

    return Column(
      children: reasons.map((reason) {
        final isSelected = _wakeUpDifficultyReason == reason;
        return GestureDetector(
          onTap: () => setState(
              () => _wakeUpDifficultyReason = isSelected ? null : reason),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey5,
                width: 1,
              ),
            ),
            child: Text(
              reason,
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 17,
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.label,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFinalAwakeningPage() {
    final now = DateTime.now();
    final minTime = _bedTime;
    final maxTime = now;
    final defaultTime =
        DateTime(now.year, now.month, now.day, 7, 0); // 07:00 current day
    return _buildTimePicker(
      title: '什麼時候醒來 (起床時間)？',
      subtitle: '選擇你最後一次醒來的時間 (之後起床活動)',
      time: _finalAwakeningTime,
      onChanged: (time) {
        setState(() {
          _finalAwakeningTime = DateTime(
            _finalAwakeningTime.year,
            _finalAwakeningTime.month,
            _finalAwakeningTime.day,
            time.hour,
            time.minute,
          );
        });
      },
      referenceTime: _bedTime,
      isWakeTime: true,
      minTime: minTime,
      maxTime: maxTime,
    );
  }

  Widget _buildImmediateWakeUpPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '你有在醒來的五分鐘之內，起身離開床舖嗎？',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 24),
        Column(
          children: ['是', '否'].map((option) {
            final isSelected = _immediateWakeUp == (option == '是');
            return GestureDetector(
              onTap: () => setState(() {
                _immediateWakeUp = option == '是';
                if (option == '是') {
                  _timeInBedAfterWakingHours = 0;
                  _timeInBedAfterWakingMinutes = 0;
                }
              }),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey5,
                    width: 1,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 17,
                    color: isSelected
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.label,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_immediateWakeUp == false) ...[
          _buildDurationPicker(
            title: '',
            subtitle: '選擇賴床的持續時間',
            hours: _timeInBedAfterWakingHours,
            minutes: _timeInBedAfterWakingMinutes,
            onChanged: (hours, minutes) {
              setState(() {
                _timeInBedAfterWakingHours = hours;
                _timeInBedAfterWakingMinutes = minutes;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTimeInBedAfterWakingPage() {
    return Container(); // Empty page that will be skipped
  }

  Widget _buildSleepQualityPage() {
    final qualities = [
      {'value': 4.0, 'label': '很好', 'subtext': '精神飽滿、心情愉悅', 'emoji': '😊'},
      {'value': 3.0, 'label': '還不錯', 'subtext': '有點疲憊，但可以應付', 'emoji': '🙂'},
      {'value': 2.0, 'label': '不太好', 'subtext': '疲憊、昏沉', 'emoji': '😐'},
      {'value': 1.0, 'label': '很差', 'subtext': '非常疲憊、無法集中注意力', 'emoji': '😞'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '醒來後，感覺精神與心情如何？',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '選擇最符合你情況的答案',
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 17,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 32),
        ...qualities.map((quality) {
          final isSelected = _sleepQuality == quality['value'];
          return GestureDetector(
            onTap: () =>
                setState(() => _sleepQuality = quality['value'] as double),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey4,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    quality['emoji'] as String,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quality['label'] as String,
                          style: TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? CupertinoColors.white
                                : CupertinoColors.label,
                          ),
                        ),
                        Text(
                          quality['subtext'] as String,
                          style: TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 15,
                            color: isSelected
                                ? CupertinoColors.white.withOpacity(0.8)
                                : CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTimeField({
    required String label,
    required DateTime time,
    required Function(DateTime) onTimeSelected,
  }) {
    return GestureDetector(
      onTap: () => _showTimePicker(context, time, label, onTimeSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: CupertinoColors.systemGrey5,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 17,
                color: CupertinoColors.label,
              ),
            ),
            Text(
              DateFormat('HH:mm').format(time),
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput({
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
    required String suffix,
    int? minValue,
    int? maxValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CupertinoColors.systemGrey5,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.all(12),
                onPressed: (minValue != null && value <= minValue)
                    ? null
                    : () => onChanged(value - 1),
                child: _wrapIcon(
                  CupertinoIcons.minus,
                  color: (minValue != null && value <= minValue)
                      ? CupertinoColors.systemGrey3
                      : CupertinoColors.activeBlue,
                ),
              ),
              Expanded(
                child: Text(
                  '$value $suffix',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.label,
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.all(12),
                onPressed: (maxValue != null && value >= maxValue)
                    ? null
                    : () => onChanged(value + 1),
                child: _wrapIcon(
                  CupertinoIcons.plus,
                  color: (maxValue != null && value >= maxValue)
                      ? CupertinoColors.systemGrey3
                      : CupertinoColors.activeBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _wrapIcon(IconData icon, {Color? color, double? size}) {
    return Material(
      type: MaterialType.transparency,
      child: Icon(
        icon,
        color: color,
        size: size,
      ),
    );
  }

  Widget _buildConsumptionEventsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '昨天有攝取以下物品嗎？',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '選擇有攝取的項目並記錄時間',
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 17,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 24),
        _buildConsumptionEventsList(),
      ],
    );
  }

  Widget _buildConsumptionEventsList() {
    final consumptionTypes = [
      {
        'id': 'caffeine',
        'icon': '☕️',
        'title': '咖啡因',
        'subtitle': '咖啡、茶、能量飲料等',
        'event': _caffeineConsumption,
      },
      {
        'id': 'alcohol',
        'icon': '🍷',
        'title': '酒精',
        'subtitle': '啤酒、紅酒、烈酒等',
        'event': _alcoholConsumption,
      },
      {
        'id': 'medicine',
        'icon': '💊',
        'title': '助眠藥物',
        'subtitle': '安眠藥、褪黑激素等',
        'event': _sleepMedicineConsumption,
      },
      {
        'id': 'smoking',
        'icon': '🚬',
        'title': '尼古丁',
        'subtitle': '香菸、電子煙等',
        'event': _smokingEvent,
      },
      {
        'id': 'exercise',
        'icon': '🏃',
        'title': '運動',
        'subtitle': '中等強度以上的運動',
        'event': _exerciseEvent,
      },
      {
        'id': 'meal',
        'icon': '🍽️',
        'title': '消夜',
        'subtitle': '接近睡前吃的東西',
        'event': _lastMealTime,
      },
    ];

    return Column(
      children: [
        for (int row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                for (int col = 0; col < 2; col++) ...[
                  Expanded(
                    child: _buildConsumptionCard(
                      consumptionTypes[row * 2 + col],
                    ),
                  ),
                  if (col == 0) const SizedBox(width: 12),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildConsumptionCard(Map<String, dynamic> type) {
    final hasEvent = type['event'] != null;
    String timeText = '';
    if (hasEvent) {
      final event = type['event'] as ConsumptionEvent;
      timeText = DateFormat('HH:mm').format(event.time);
    }

    return GestureDetector(
      onTap: () => _showConsumptionDetailSheet(type['id'] as String),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasEvent
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemGrey5,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  type['icon'] as String,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    type['title'] as String,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: hasEvent
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.label,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: hasEvent
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey3,
                  size: 16,
                ),
              ],
            ),
            if (!hasEvent) ...[
              const SizedBox(height: 4),
              Text(
                type['subtitle'] as String,
                style: const TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                timeText,
                style: const TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 13,
                  color: CupertinoColors.activeBlue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showConsumptionDetailSheet(String typeId) {
    ConsumptionEvent? currentEvent;
    String title = '';
    String subtitle = '';

    switch (typeId) {
      case 'caffeine':
        currentEvent = _caffeineConsumption;
        title = '咖啡因攝取時間';
        subtitle = '選擇攝取咖啡因的時間';
        break;
      case 'alcohol':
        currentEvent = _alcoholConsumption;
        title = '酒精攝取時間';
        subtitle = '選擇攝取酒精的時間';
        break;
      case 'medicine':
        currentEvent = _sleepMedicineConsumption;
        title = '助眠藥物服用時間';
        subtitle = '選擇服用助眠藥物的時間';
        break;
      case 'smoking':
        currentEvent = _smokingEvent;
        title = '尼古丁攝取時間';
        subtitle = '選擇攝取尼古丁的時間';
        break;
      case 'exercise':
        currentEvent = _exerciseEvent;
        title = '運動時間';
        subtitle = '選擇運動的時間';
        break;
      case 'meal':
        currentEvent = _lastMealTime;
        title = '最後一餐時間';
        subtitle = '選擇最後一餐的時間';
        break;
    }

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    DateTime initialTime = currentEvent?.time ??
        DateTime(yesterday.year, yesterday.month, yesterday.day, 20, 0);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(
                    currentEvent != null ? '移除' : '取消',
                    style: const TextStyle(
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      switch (typeId) {
                        case 'caffeine':
                          _caffeineConsumption = null;
                          break;
                        case 'alcohol':
                          _alcoholConsumption = null;
                          break;
                        case 'medicine':
                          _sleepMedicineConsumption = null;
                          break;
                        case 'smoking':
                          _smokingEvent = null;
                          break;
                        case 'exercise':
                          _exerciseEvent = null;
                          break;
                        case 'meal':
                          _lastMealTime = null;
                          break;
                      }
                    });
                    Navigator.pop(context);
                  },
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('完成'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 17,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initialTime,
                minimumDate: DateTime(
                  yesterday.year,
                  yesterday.month,
                  yesterday.day,
                ),
                maximumDate: now,
                use24hFormat: true,
                onDateTimeChanged: (DateTime newTime) {
                  setState(() {
                    final event = ConsumptionEvent(
                      time: DateTime(
                        yesterday.year,
                        yesterday.month,
                        yesterday.day,
                        newTime.hour,
                        newTime.minute,
                      ),
                    );

                    switch (typeId) {
                      case 'caffeine':
                        _caffeineConsumption = event;
                        break;
                      case 'alcohol':
                        _alcoholConsumption = event;
                        break;
                      case 'medicine':
                        _sleepMedicineConsumption = event;
                        break;
                      case 'smoking':
                        _smokingEvent = event;
                        break;
                      case 'exercise':
                        _exerciseEvent = event;
                        break;
                      case 'meal':
                        _lastMealTime = event;
                        break;
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '請選擇所有跟這次睡眠有關的事項',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '選擇所有符合的項目',
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 17,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 24),
        _buildTagSection(
          title: '🌞日間活動',
          tags: SleepTags.daytimeActivities,
        ),
        const SizedBox(height: 24),
        _buildTagSection(
          title: '🌜睡前活動',
          tags: SleepTags.bedtimeActivities,
        ),
        const SizedBox(height: 24),
        _buildTagSection(
          title: '💊服用物質',
          tags: SleepTags.bedtimeSubstances,
        ),
        const SizedBox(height: 24),
        _buildTagSection(
          title: '⚡睡眠干擾',
          tags: SleepTags.sleepDisturbances,
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '備註',
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CupertinoColors.systemGrey5,
              width: 1,
            ),
          ),
          child: CupertinoTextField(
            controller: _notesController,
            placeholder: '添加備註...',
            padding: const EdgeInsets.all(12),
            maxLines: 4,
            style: const TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 17,
            ),
            placeholderStyle: const TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 17,
              color: CupertinoColors.systemGrey,
            ),
            decoration: null,
          ),
        ),
      ],
    );
  }

  Widget _buildTagSection({
    required String title,
    required List<String> tags,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey4,
                    width: 1,
                  ),
                ),
                child: Text(
                  _getTagDisplayName(tag),
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 15,
                    color: isSelected
                        ? CupertinoColors.white
                        : CupertinoColors.label,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getTagDisplayName(String tag) {
    // TODO: Implement proper localization
    switch (tag) {
      case SleepTags.exercise:
        return '運動';
      case SleepTags.longNap:
        return '長時間午睡';
      case SleepTags.morningSunlight:
        return '早晨曬太陽';
      case SleepTags.yoga:
        return '瑜伽';
      case SleepTags.afternoonCaffeine:
        return '下午咖啡因';
      case SleepTags.stretching:
        return '伸展';
      case SleepTags.meditation:
        return '冥想';
      case SleepTags.reading:
        return '閱讀';
      case SleepTags.lateEating:
        return '睡前進食';
      case SleepTags.journaling:
        return '寫日記';
      case SleepTags.lateAlcohol:
        return '睡前飲酒';
      case SleepTags.shower:
        return '淋浴';
      case SleepTags.workedLate:
        return '熬夜工作';
      case SleepTags.socializedLate:
        return '熬夜社交';
      case SleepTags.screenTime:
        return '使用螢幕';
      case SleepTags.capaTherapy:
        return 'CAPA治療';
      case SleepTags.sleepingPills:
        return '安眠藥';
      case SleepTags.melatonin:
        return '褪黑激素';
      case SleepTags.supplements:
        return '補充劑/草藥';
      case SleepTags.cannabis:
        return 'CBD/THC';
      case SleepTags.nicotine:
        return '尼古丁/菸草';
      case SleepTags.otherMedications:
        return '其他藥物';
      case SleepTags.stress:
        return '壓力/思緒紛飛';
      case SleepTags.nightmares:
        return '惡夢';
      case SleepTags.light:
        return '光線';
      case SleepTags.noise:
        return '噪音';
      case SleepTags.temperature:
        return '溫度';
      case SleepTags.snoring:
        return '打鼾';
      case SleepTags.bathroom:
        return '如廁';
      case SleepTags.householdDisruption:
        return '家人/寵物干擾';
      case SleepTags.jetLag:
        return '時差';
      case SleepTags.healthIssues:
        return '身體不適';
      default:
        return tag;
    }
  }

  Widget _buildNotesPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '有什麼想記錄的嗎？',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '記錄任何可能影響你睡眠的事情',
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 17,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CupertinoColors.systemGrey5,
              width: 1,
            ),
          ),
          child: CupertinoTextField(
            controller: _notesController,
            placeholder: '添加備註...',
            padding: const EdgeInsets.all(12),
            maxLines: 4,
            style: const TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 17,
            ),
            placeholderStyle: const TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 17,
              color: CupertinoColors.systemGrey,
            ),
            decoration: null,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationPicker({
    required String title,
    required String subtitle,
    required int hours,
    required int minutes,
    required Function(int hours, int minutes) onChanged,
  }) {
    // Always start at 0 unless user has picked a value
    final hourController =
        FixedExtentScrollController(initialItem: hours == 0 ? 0 : hours);
    final minuteController =
        FixedExtentScrollController(initialItem: minutes == 0 ? 0 : minutes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 17,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            '選擇的時間: ${hours.toString().padLeft(2, '0')} 小時 ${minutes.toString().padLeft(2, '0')} 分鐘',
            style: const TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 17,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                const Text(
                  '小時',
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 15,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 80,
                  height: 160,
                  child: CupertinoPicker(
                    key: ValueKey('hourPicker_$title'),
                    selectionOverlay: null,
                    magnification: 1.1,
                    squeeze: 1.0,
                    itemExtent: 40,
                    scrollController: hourController,
                    onSelectedItemChanged: (int value) {
                      onChanged(value, minutes);
                    },
                    children: List<Widget>.generate(24, (int index) {
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 22,
                            color: CupertinoColors.label,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Column(
              children: [
                const Text(
                  '分鐘',
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 15,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 80,
                  height: 160,
                  child: CupertinoPicker(
                    key: ValueKey('minutePicker_$title'),
                    selectionOverlay: null,
                    magnification: 1.1,
                    squeeze: 1.0,
                    itemExtent: 40,
                    scrollController: minuteController,
                    onSelectedItemChanged: (int value) {
                      onChanged(hours, value);
                    },
                    children: List<Widget>.generate(60, (int index) {
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 22,
                            color: CupertinoColors.label,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Validation logic for impossible situations
  String? _validateEntry() {
    // Calculate actual bed and wake times (with cross-midnight support)
    DateTime bed = _bedTime;
    DateTime wake = _finalAwakeningTime;
    if (wake.isBefore(bed)) {
      // Assume wake is next day
      wake = wake.add(const Duration(days: 1));
    }
    if (!wake.isAfter(bed)) {
      return '醒來時間必須在上床時間之後。';
    }
    final totalTimeInBed = wake.difference(bed).inMinutes;
    final timeToFallAsleep =
        _timeToFallAsleepHours * 60 + _timeToFallAsleepMinutes;
    final timeInBedAfterWaking =
        _timeInBedAfterWakingHours * 60 + _timeInBedAfterWakingMinutes;
    if (timeToFallAsleep < 0 || timeInBedAfterWaking < 0) {
      return '入睡時間或賴床時間不能為負數。';
    }
    if (timeToFallAsleep + timeInBedAfterWaking > totalTimeInBed) {
      return '入睡時間與賴床時間總和不能超過總在床時間。';
    }
    // Validate wake up events
    for (int i = 0; i < _wakeUpEvents.length; i++) {
      final event = _wakeUpEvents[i];
      if (event.stayedInBedMinutes < 0) {
        return '第${i + 1}次醒來的清醒時間不能為負數。';
      }
      if (event.gotOutOfBed && (event.outOfBedDurationMinutes ?? 0) < 0) {
        return '第${i + 1}次醒來的下床時間不能為負數。';
      }
    }
    // Optionally: check that sum of all wake event durations does not exceed total time in bed
    return null;
  }

  bool _canMoveToNextPage() {
    switch (_currentStep) {
      case 2: // Q3
        return _hasLeftBed != null &&
            (_hasLeftBed == false || _leftBedDuration.inMinutes > 0);
      default:
        return true;
    }
  }
}
