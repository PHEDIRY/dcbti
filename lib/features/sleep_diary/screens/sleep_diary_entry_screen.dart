import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import '../../../core/models/sleep_diary_entry.dart';
import 'package:intl/intl.dart';

class SleepDiaryEntryScreen extends StatefulWidget {
  const SleepDiaryEntryScreen({super.key});

  @override
  State<SleepDiaryEntryScreen> createState() => _SleepDiaryEntryScreenState();
}

class _SleepDiaryEntryScreenState extends State<SleepDiaryEntryScreen> {
  int _currentStep = 0;

  // Basic sleep info
  DateTime _bedTime = DateTime.now().subtract(const Duration(hours: 8));
  int _timeToFallAsleepHours = 0;
  int _timeToFallAsleepMinutes = 15;
  int _initialOutOfBedHours = 0;
  int _initialOutOfBedMinutes = 0;
  String? _sleepDifficultyReason;
  int _numberOfAwakenings = 0;
  final List<WakeUpEvent> _wakeUpEvents = [];
  String? _wakeUpDifficultyReason;
  DateTime _finalAwakeningTime = DateTime.now();
  bool _immediateWakeUp = false;
  int _timeInBedAfterWakingHours = 0;
  int _timeInBedAfterWakingMinutes = 0;
  double _sleepQuality = 3.0;

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
        _buildInitialOutOfBedPage(),
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

  void _handleSubmit() {
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
      sleepQuality: _sleepQuality,
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
      immediateWakeUp: _immediateWakeUp,
      initialOutOfBedDurationMinutes:
          _initialOutOfBedHours * 60 + _initialOutOfBedMinutes,
    );

    print('[SleepDiaryEntryScreen] Created entry: ${entry.toMap()}');
  }

  void _addWakeUpEvent() {
    setState(() {
      _wakeUpEvents.add(
        WakeUpEvent(
          time: DateTime.now(),
          gotOutOfBed: false,
          stayedInBedMinutes: 15,
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
    showCupertinoDialog<void>(
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
              Navigator.pop(context); // Close dialog
            },
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close entry form
            },
            child: const Text('離開'),
          ),
        ],
      ),
    );
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
          child: const Icon(CupertinoIcons.back),
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
          child: const Icon(CupertinoIcons.xmark),
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
            const Spacer(),
            Text(
              '${((_currentStep + 1) / _pages.length * 100).round()}%',
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
                      _currentStep++;
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
  }) {
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
        Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              '選擇時間',
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 17,
                color: CupertinoColors.systemGrey,
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
                        scrollController: FixedExtentScrollController(
                          initialItem: time.hour,
                        ),
                        onSelectedItemChanged: (int value) {
                          onChanged(DateTime(
                            time.year,
                            time.month,
                            time.day,
                            value,
                            time.minute,
                          ));
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
                        selectionOverlay: null,
                        magnification: 1.1,
                        squeeze: 1.0,
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                          initialItem: time.minute,
                        ),
                        onSelectedItemChanged: (int value) {
                          onChanged(DateTime(
                            time.year,
                            time.month,
                            time.day,
                            time.hour,
                            value,
                          ));
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
            const SizedBox(height: 16),
            Text(
              '選擇的時間: ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 17,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }

  Widget _buildBedTimePage() {
    return _buildTimePicker(
      title: '你什麼時候上床睡覺？',
      subtitle: '選擇你躺到床上準備睡覺的時間',
      time: _bedTime,
      onChanged: (time) {
        setState(() {
          _bedTime = DateTime(
            _bedTime.year,
            _bedTime.month,
            _bedTime.day,
            time.hour,
            time.minute,
          );
        });
      },
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

  Widget _buildInitialOutOfBedPage() {
    return _buildDurationPicker(
      title: '中間有離開床舖嗎？',
      subtitle: '如果有的話離開多長時間',
      hours: _initialOutOfBedHours,
      minutes: _initialOutOfBedMinutes,
      onChanged: (hours, minutes) {
        setState(() {
          _initialOutOfBedHours = hours;
          _initialOutOfBedMinutes = minutes;
        });
      },
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
            return Column(
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
                      outOfBedDurationMinutes: event.outOfBedDurationMinutes,
                      stayedInBedMinutes: event.stayedInBedMinutes,
                    ),
                  ),
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
                    title: '下床時間',
                    value: event.outOfBedDurationMinutes ?? 0,
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
                  ),
                ],
                const SizedBox(height: 16),
                _buildNumberInput(
                  title: '清醒時間',
                  value: event.stayedInBedMinutes,
                  onChanged: (value) => _updateWakeUpEvent(
                    index,
                    WakeUpEvent(
                      time: event.time,
                      gotOutOfBed: event.gotOutOfBed,
                      outOfBedDurationMinutes: event.outOfBedDurationMinutes,
                      stayedInBedMinutes: value,
                    ),
                  ),
                  suffix: '分鐘',
                ),
                if (index < _wakeUpEvents.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(),
                  ),
              ],
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
    return _buildTimePicker(
      title: '你最後是什麼時候醒來的？',
      subtitle: '選擇最後一次醒來的時間',
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
        const SizedBox(height: 8),
        const Text(
          '選擇最符合你情況的答案',
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 17,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 24),
        _buildImmediateWakeUpSection(),
      ],
    );
  }

  Widget _buildImmediateWakeUpSection() {
    final options = [
      '是',
      '否',
    ];

    return Column(
      children: options.map((option) {
        final isSelected = _immediateWakeUp == (option == '是');
        return GestureDetector(
          onTap: () => setState(() => _immediateWakeUp = option == '是'),
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
    );
  }

  Widget _buildTimeInBedAfterWakingPage() {
    return _buildDurationPicker(
      title: '在離開床舖之前，在床上賴床了多久？',
      subtitle: '若不確定，大致預估即可',
      hours: _timeInBedAfterWakingHours,
      minutes: _timeInBedAfterWakingMinutes,
      onChanged: (hours, minutes) {
        setState(() {
          _timeInBedAfterWakingHours = hours;
          _timeInBedAfterWakingMinutes = minutes;
        });
      },
    );
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
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                child: Icon(
                  CupertinoIcons.minus,
                  color: value > 0
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey3,
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
                onPressed: () => onChanged(value + 1),
                child: const Icon(
                  CupertinoIcons.plus,
                  color: CupertinoColors.activeBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsumptionEventsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '前一天是否有這些行為？',
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
        _buildConsumptionEventSection(
          title: '咖啡因攝入',
          event: _caffeineConsumption,
          onChanged: (event) => setState(() => _caffeineConsumption = event),
        ),
        const SizedBox(height: 24),
        _buildConsumptionEventSection(
          title: '酒精攝入',
          event: _alcoholConsumption,
          onChanged: (event) => setState(() => _alcoholConsumption = event),
        ),
        const SizedBox(height: 24),
        _buildConsumptionEventSection(
          title: '睡眠藥物',
          event: _sleepMedicineConsumption,
          onChanged: (event) =>
              setState(() => _sleepMedicineConsumption = event),
        ),
        const SizedBox(height: 24),
        _buildConsumptionEventSection(
          title: '吸菸',
          event: _smokingEvent,
          onChanged: (event) => setState(() => _smokingEvent = event),
        ),
        const SizedBox(height: 24),
        _buildConsumptionEventSection(
          title: '運動',
          event: _exerciseEvent,
          onChanged: (event) => setState(() => _exerciseEvent = event),
        ),
        const SizedBox(height: 24),
        _buildConsumptionEventSection(
          title: '睡前吃東西/消夜',
          event: _lastMealTime,
          onChanged: (event) => setState(() => _lastMealTime = event),
        ),
      ],
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

  Widget _buildConsumptionEventSection({
    required String title,
    required ConsumptionEvent? event,
    required ValueChanged<ConsumptionEvent?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            const Spacer(),
            CupertinoSwitch(
              value: event != null,
              onChanged: (value) {
                if (value) {
                  onChanged(ConsumptionEvent(
                    time: DateTime.now(),
                    details: null,
                  ));
                } else {
                  onChanged(null);
                }
              },
            ),
          ],
        ),
        if (event != null) ...[
          const SizedBox(height: 16),
          _buildTimeField(
            label: '時間',
            time: event.time,
            onTimeSelected: (time) => onChanged(ConsumptionEvent(
              time: time,
              details: event.details,
            )),
          ),
          const SizedBox(height: 16),
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
              placeholder: '備註（選填）',
              padding: const EdgeInsets.all(12),
              onChanged: (value) => onChanged(ConsumptionEvent(
                time: event.time,
                details: value.isEmpty ? null : value,
              )),
              style: const TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 17,
              ),
            ),
          ),
        ],
      ],
    );
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
        Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              '選擇持續時間',
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 17,
                color: CupertinoColors.systemGrey,
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
                        scrollController: FixedExtentScrollController(
                          initialItem: hours,
                        ),
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
                        selectionOverlay: null,
                        magnification: 1.1,
                        squeeze: 1.0,
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                          initialItem: minutes,
                        ),
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
            const SizedBox(height: 16),
            Text(
              '選擇的時間: ${hours.toString().padLeft(2, '0')} 小時 ${minutes.toString().padLeft(2, '0')} 分鐘',
              style: const TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 17,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }
}
