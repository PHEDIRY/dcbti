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
  bool _q3Skipped = false; // Add this variable to track if Q3 was skipped
  bool _showValidationWarnings =
      false; // Add this variable to track when to show validation warnings

  // Basic sleep info
  late DateTime _bedTime;
  late DateTime _finalAwakeningTime;

  // Add state for Q3 selection
  bool? _hasLeftBed;
  late Duration _leftBedDuration;

  @override
  void initState() {
    super.initState();
    // Initialize selections as null
    _quickSleep = null;
    _wokeUpDuringSleep = null;
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

    // Add listener to notes controller to update character count
    _notesController.addListener(() {
      setState(() {
        // This will trigger a rebuild when text changes
      });
    });
  }

  // Other state variables
  int _timeToFallAsleepHours = 0;
  int _timeToFallAsleepMinutes = 0;
  bool?
      _quickSleep; // Add this variable to track if user fell asleep within 5 minutes
  bool?
      _wokeUpDuringSleep; // Add this variable to track if user woke up during sleep
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
        _buildQuickSleepPage(),
        _buildTimeToFallAsleepPage(),
        _buildSleepDifficultyReasonPage(),
        _buildLeftBedPage(),
        _buildLeftBedDurationPage(),
        _buildWokeUpDuringSleepPage(),
        _buildNumberOfAwakeningsPage(),
        _buildWakeUpDifficultyReasonPage(),
        _buildFinalAwakeningPage(),
        _buildImmediateWakeUpPage(),
        _buildTimeInBedAfterWakingPage(),
        _buildSleepQualityPage(),
        _buildConsumptionEventsPage(),
        _buildTagsPage(),
        _buildNotesPage(),
      ];

  // Check if the current page is valid to enable the "continue" button
  bool _isCurrentPageValid() {
    switch (_currentStep) {
      // Q1: Bed time - always valid as it has default value
      case 0:
        return true;
      // Q2: Quick sleep question - require selection
      case 1:
        return _quickSleep != null;
      // Q3: Time to fall asleep - always valid as it has default value
      case 2:
        return true;
      // Q4: Sleep difficulty reason (only shown if Q3 > 5 minutes)
      case 3:
        return _sleepDifficultyReason != null;
      // Q5: Left bed during falling asleep (only shown if Q3 > 5 minutes)
      case 4:
        return _hasLeftBed != null;
      // Q6: Left bed duration (only shown if Q5 answer is "Yes")
      case 5:
        return true; // Always valid as it has default values
      // Q7: Woke up during sleep question
      case 6:
        return _wokeUpDuringSleep != null;
      // Q8: Number of awakenings - validate that all wake-up events have times selected
      case 7:
        if (_numberOfAwakenings > 0) {
          // Check if all wake-up events have times selected
          for (int i = 0; i < _wakeUpEvents.length; i++) {
            if (_wakeUpEvents[i].time == null) {
              return false;
            }
          }

          // Also validate that wake-up times are in chronological order
          for (int i = 1; i < _wakeUpEvents.length; i++) {
            final prevEvent = _wakeUpEvents[i - 1];
            final currentEvent = _wakeUpEvents[i];

            final prevEndTime = prevEvent.time!
                .add(Duration(minutes: prevEvent.stayedInBedMinutes));

            if (currentEvent.time!.isBefore(prevEndTime)) {
              return false;
            }
          }
        }
        return true;
      // Q9: Wake up difficulty reason (only shown if Q7 answer is "Yes")
      case 8:
        // Make Q9 mandatory only if user woke up during sleep
        return _wokeUpDuringSleep == false || _wakeUpDifficultyReason != null;
      // Q10: Final awakening time - always valid as it has default value
      case 9:
        return true;
      // Q11: Immediate wake up
      case 10:
        return _immediateWakeUp != null;
      // Q11: Time in bed after waking
      case 11:
        return true; // Always valid as it has default values
      // Q12: Sleep quality
      case 12:
        return _sleepQuality != null;
      // Q13: Consumption events - always valid as it's optional
      case 13:
        return true;
      // Q14: Tags - always valid as it's optional
      case 14:
        return true;
      // Q15: Notes - always valid as it's optional
      case 15:
        return true;
      default:
        return true;
    }
  }

  void _showTimePicker(BuildContext context, DateTime initialTime, String title,
      Function(DateTime) onTimeSelected,
      {DateTime? minTime, DateTime? maxTime}) {
    // Always use bedTime as minimum if not specified
    final effectiveMinTime = minTime ?? _bedTime;

    // Always use current time as maximum if not specified
    final effectiveMaxTime = maxTime ?? DateTime.now();

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
                minimumDate: effectiveMinTime,
                maximumDate: effectiveMaxTime,
                onDateTimeChanged: (DateTime newTime) {
                  // Determine if bedTime is after midnight (same day as entry)
                  final bool isBedTimeAfterMidnight =
                      _bedTime.day == DateTime.now().day;

                  DateTime adjustedTime;
                  if (isBedTimeAfterMidnight) {
                    // Keep all times on the same day as bedTime
                    adjustedTime = DateTime(
                      _bedTime.year,
                      _bedTime.month,
                      _bedTime.day,
                      newTime.hour,
                      newTime.minute,
                    );
                  } else {
                    // If the selected time is before bedTime hour, assume it's next day
                    if (newTime.hour < _bedTime.hour) {
                      adjustedTime = DateTime(
                        _bedTime.year,
                        _bedTime.month,
                        _bedTime.day + 1,
                        newTime.hour,
                        newTime.minute,
                      );
                    } else {
                      adjustedTime = DateTime(
                        _bedTime.year,
                        _bedTime.month,
                        _bedTime.day,
                        newTime.hour,
                        newTime.minute,
                      );
                    }
                  }

                  onTimeSelected(adjustedTime);
                },
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
    _notesController.removeListener(() {});
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    // Set q3Skipped flag if time to fall asleep is 5 minutes or less
    if (_timeToFallAsleepHours == 0 && _timeToFallAsleepMinutes <= 5) {
      _q3Skipped = true;
    }

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

    // Ensure all wake-up events have times before creating the entry
    final validatedWakeUpEvents = _wokeUpDuringSleep == true
        ? _wakeUpEvents.where((event) => event.time != null).toList()
        : <WakeUpEvent>[];

    final entry = SleepDiaryEntry.create(
      entryDate: DateTime.now(), // Set to current day
      bedTime: _bedTime,
      wakeTime: _finalAwakeningTime,
      timeToFallAsleepMinutes:
          _timeToFallAsleepHours * 60 + _timeToFallAsleepMinutes,
      numberOfAwakenings: validatedWakeUpEvents.length, // Use validated count
      wakeUpEvents: validatedWakeUpEvents, // Use validated events
      finalAwakeningTime: _finalAwakeningTime,
      timeInBedAfterWakingMinutes: _immediateWakeUp == true
          ? 0
          : _timeInBedAfterWakingHours * 60 + _timeInBedAfterWakingMinutes,
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
      initialOutOfBedDurationMinutes: _q3Skipped
          ? 0
          : (_hasLeftBed == true ? _leftBedDuration.inMinutes : 0),
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
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('✅ '),
                Text(
                  '已儲存',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            content: Text(
              '你的睡眠日記已經儲存成功！\n${DateFormat('yyyy年M月d日 (E)', 'zh_TW').format(DateTime.now())}',
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
      // No default time - we'll show a placeholder instead
      DateTime? wakeUpTime;

      // Calculate minimum allowed time for this wake-up event
      DateTime minTime;

      // If there are existing wake-up events, min time is after the last one
      if (_wakeUpEvents.isNotEmpty) {
        final lastEvent = _wakeUpEvents.last;
        if (lastEvent.time != null) {
          minTime = lastEvent.time!
              .add(Duration(minutes: lastEvent.stayedInBedMinutes));
        } else {
          // If previous event has no time yet, use bedTime + sleep latency
          minTime = _bedTime.add(Duration(
            hours: _timeToFallAsleepHours,
            minutes: _timeToFallAsleepMinutes,
          ));
        }
      } else {
        // If this is the first wake-up event, set min time to bedTime + sleep latency
        minTime = _bedTime.add(Duration(
          hours: _timeToFallAsleepHours,
          minutes: _timeToFallAsleepMinutes,
        ));
      }

      _wakeUpEvents.add(
        WakeUpEvent(
          time: wakeUpTime,
          gotOutOfBed: false,
          stayedInBedMinutes: 15, // Default to 15 minutes of being awake
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
                    // Handle skipped questions when navigating back

                    // If going back from Q3 to Q2 when Q2 is "是"
                    if (_quickSleep == true && _currentStep == 2) {
                      _currentStep = 1; // Go back to Q2 (quick sleep question)
                    }
                    // If going back from Q4-Q6 to Q2 when Q2 is "是" (skip Q3)
                    else if (_quickSleep == true &&
                        (_currentStep >= 3 && _currentStep <= 5)) {
                      _currentStep = 1; // Go back to Q2 (quick sleep question)
                    }
                    // If going back from Q7 to Q5 when Q5 answer is "否" (skip Q6)
                    else if (_hasLeftBed == false && _currentStep == 6) {
                      _currentStep = 4; // Go back to Q5 (left bed question)
                    }
                    // Also handle going back from Q6 to Q5 when Q5 answer is "否"
                    else if (_hasLeftBed == false && _currentStep == 5) {
                      _currentStep = 4; // Go back to Q5 (left bed question)
                    }
                    // If going back from Q10 to Q7 when Q7 is "沒有" (skip Q8 and Q9)
                    else if (_wokeUpDuringSleep == false && _currentStep == 9) {
                      _currentStep = 6; // Go back to Q7 (woke up during sleep)
                    }
                    // If going back from Q9 to Q7 when Q7 is "沒有"
                    else if (_wokeUpDuringSleep == false && _currentStep == 8) {
                      _currentStep = 6; // Go back to Q7 (woke up during sleep)
                    }
                    // If going back from Q8 to Q7 when Q7 is "沒有"
                    else if (_wokeUpDuringSleep == false && _currentStep == 7) {
                      _currentStep = 6; // Go back to Q7 (woke up during sleep)
                    }
                    // If going back from Q13 (sleep quality) to Q12 when Q11 answer is "有"
                    else if (_currentStep == 12 && _immediateWakeUp == true) {
                      _currentStep = 10; // Go back to Q11 (immediate wake up)
                    }
                    // If going back from Q12 (time in bed) to Q11 when Q11 answer is "有"
                    else if (_currentStep == 11 && _immediateWakeUp == true) {
                      _currentStep = 10; // Go back to Q11 (immediate wake up)
                    }
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
                        DateFormat('yyyy年M月d日 (E)', 'zh_TW')
                            .format(DateTime.now()),
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
    // Check if the current page is valid
    final bool isValid = _isCurrentPageValid();

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
                  // Disable the button if the current page is not valid
                  onPressed: isValid
                      ? () {
                          // Check for specific validation errors
                          if (_currentStep == 5 && _numberOfAwakenings > 0) {
                            // Validate wake-up times before proceeding
                            String? validationError = _validateWakeUpTimes();
                            if (validationError != null) {
                              showCupertinoDialog(
                                context: context,
                                builder: (context) => CupertinoAlertDialog(
                                  title: const Text('時間順序有誤'),
                                  content: Text(validationError),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('確定'),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                          }

                          setState(() {
                            // If user selected "Yes" for quick sleep in Q2, skip to Q7 (number of awakenings)
                            if (_currentStep == 1 && _quickSleep == true) {
                              _currentStep =
                                  6; // Skip to Q7 (number of awakenings)
                            }
                            // Skip Q4 and Q5 if Q3 is less than or equal to 5 minutes
                            else if (_currentStep == 2 &&
                                _timeToFallAsleepHours == 0 &&
                                _timeToFallAsleepMinutes <= 5) {
                              _currentStep += 2;
                              _q3Skipped = true; // Set flag when skipping Q4
                            }
                            // Skip Q6 (the duration question) if user selected "No" for leaving bed in Q5
                            else if (_currentStep == 4 &&
                                _hasLeftBed == false) {
                              _currentStep += 2;
                            }
                            // Skip Q8 (number of awakenings) and Q9 (wake up difficulty) if user selected "No" for woke up during sleep in Q7
                            else if (_currentStep == 6 &&
                                _wokeUpDuringSleep == false) {
                              _currentStep +=
                                  3; // Skip to Q10 (final awakening time)
                            }
                            // Skip time in bed after waking page if user selected "有" for immediate wake up
                            else if (_currentStep == 10 &&
                                _immediateWakeUp == true) {
                              _currentStep += 2;
                            } else {
                              _currentStep++;
                            }

                            // Reset validation warnings when moving to next question
                            _showValidationWarnings = false;
                          });
                        }
                      : () {
                          // If button is disabled and we're on Q6 (wake-up events),
                          // show validation warnings
                          if (_currentStep == 5 && _numberOfAwakenings > 0) {
                            setState(() {
                              _showValidationWarnings = true;
                            });
                          }
                        },
                  child: const Text('繼續'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // New method to validate wake-up times
  String? _validateWakeUpTimes() {
    // Check if all wake-up events have times selected
    for (int i = 0; i < _wakeUpEvents.length; i++) {
      if (_wakeUpEvents[i].time == null) {
        return '請為第 ${i + 1} 次醒來選擇時間';
      }
    }

    // Check if wake-up times are in chronological order
    for (int i = 1; i < _wakeUpEvents.length; i++) {
      final prevEvent = _wakeUpEvents[i - 1];
      final currentEvent = _wakeUpEvents[i];

      // Safe to use ! here as we've checked for null above
      final prevEndTime =
          prevEvent.time!.add(Duration(minutes: prevEvent.stayedInBedMinutes));

      if (currentEvent.time!.isBefore(prevEndTime)) {
        return '第 ${i + 1} 次醒來時間必須晚於第 $i 次醒來結束時間 (${DateFormat('HH:mm').format(prevEndTime)})';
      }
    }

    // Check if the first wake-up time is after bedTime + sleep latency
    final sleepLatency = Duration(
      hours: _timeToFallAsleepHours,
      minutes: _timeToFallAsleepMinutes,
    );
    final earliestWakeUpTime = _bedTime.add(sleepLatency);

    if (_wakeUpEvents.isNotEmpty &&
        _wakeUpEvents[0].time != null &&
        _wakeUpEvents[0].time!.isBefore(earliestWakeUpTime)) {
      return '第 1 次醒來時間必須晚於入睡時間 (${DateFormat('HH:mm').format(earliestWakeUpTime)})';
    }

    return null;
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
        '選擇的日期與時間：${DateFormat('yyyy年M月d日 HH:mm', 'zh_TW').format(displayDate)}';

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
      title: '昨天幾點上床睡覺？',
      subtitle: '可以填昨晚或今天凌晨的時間',
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

  Widget _buildQuickSleepPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '躺上床之後，有在5分鐘之內睡著嗎？',
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
            final isSelected = _quickSleep == (option == '是');
            return GestureDetector(
              onTap: () => setState(() {
                _quickSleep = option == '是';
                if (option == '是') {
                  // Skip Q3-Q5 by setting the flag
                  _q3Skipped = true;
                  // Reset Q3 values to null equivalent since we're skipping it
                  _timeToFallAsleepHours = 0;
                  _timeToFallAsleepMinutes = 0;
                } else {
                  // Reset Q3 values to default when answer is "否"
                  _timeToFallAsleepHours = 0;
                  _timeToFallAsleepMinutes = 5;
                  _q3Skipped = false;
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
      ],
    );
  }

  Widget _buildTimeToFallAsleepPage() {
    // Only enforce minimum time if Q2 answer is "否"
    if (_quickSleep == false &&
        _timeToFallAsleepHours == 0 &&
        _timeToFallAsleepMinutes < 5) {
      _timeToFallAsleepMinutes = 5;
    }

    return _buildDurationPicker(
      title: '躺上床後，花了多長時間才入睡？',
      subtitle: '包含中間離開床的時間',
      hours: _timeToFallAsleepHours,
      minutes: _timeToFallAsleepMinutes,
      onChanged: (hours, minutes) {
        // Only enforce minimum time if Q2 answer is "否"
        int adjustedMinutes = minutes;
        if (_quickSleep == false && hours == 0 && minutes < 5) {
          adjustedMinutes = 5;
        }

        setState(() {
          _timeToFallAsleepHours = hours;
          _timeToFallAsleepMinutes = adjustedMinutes;
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
      ],
    );
  }

  Widget _buildLeftBedDurationPage() {
    // Calculate maximum duration based on Q2
    final int maxMinutes =
        _timeToFallAsleepHours * 60 + _timeToFallAsleepMinutes;
    final int maxHours = maxMinutes ~/ 60;
    final int remainingMinutes = maxMinutes % 60;

    // Format the duration for the title
    String durationText = '';
    if (_timeToFallAsleepHours > 0) {
      durationText += '${_timeToFallAsleepHours}小時';
    }
    if (_timeToFallAsleepMinutes > 0) {
      if (durationText.isNotEmpty) {
        durationText += ' ';
      }
      durationText += '${_timeToFallAsleepMinutes}分鐘';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '在等待入睡的這$durationText之內，有多長時間不在床上？',
          style: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '如果不確定，填一個大致猜測即可',
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 17,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 24),
        _buildDurationPicker(
          title: '',
          subtitle: '',
          hours: _leftBedDuration.inHours,
          minutes: _leftBedDuration.inMinutes.remainder(60),
          maxHours: maxHours,
          maxMinutes: remainingMinutes,
          onChanged: (int hours, int minutes) {
            setState(() {
              _leftBedDuration = Duration(hours: hours, minutes: minutes);
            });
          },
        ),
      ],
    );
  }

  Widget _buildWokeUpDuringSleepPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '睡眠中途有醒來過嗎？',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 24),
        Column(
          children: ['有', '沒有'].map((option) {
            final isSelected = _wokeUpDuringSleep == (option == '有');
            return GestureDetector(
              onTap: () => setState(() {
                _wokeUpDuringSleep = option == '有';
                if (option == '有' && _numberOfAwakenings == 0) {
                  // If user woke up during sleep and no awakenings are set yet, set to 1
                  _numberOfAwakenings = 1;
                  // Add a default wake-up event if none exists
                  if (_wakeUpEvents.isEmpty) {
                    _addWakeUpEvent();
                  }
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
      ],
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
              // Reset validation warnings when changing the number of events
              _showValidationWarnings = false;
            });
          },
          suffix: '次',
          minValue: 1, // Set minimum to 1
        ),
        if (_numberOfAwakenings > 0) ...[
          const SizedBox(height: 32),
          ..._wakeUpEvents.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            // Get validation message for this event only if we should show warnings
            final validationError = _showValidationWarnings
                ? _validateWakeUpEventTime(index)
                : null;

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
                    _buildWakeUpTimeField(
                      index: index,
                      event: event,
                    ),
                    if (validationError != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_triangle_fill,
                            color: CupertinoColors.systemRed,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              validationError,
                              style: const TextStyle(
                                fontFamily: 'SF Pro Text',
                                fontSize: 13,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

  // Add a method to check if a specific wake-up event's time is valid
  String? _validateWakeUpEventTime(int index) {
    final event = _wakeUpEvents[index];

    // If no time selected, show a hint
    if (event.time == null) {
      return '請選擇醒來時間';
    }

    // Calculate minimum allowed time
    DateTime minTime;

    // If this is not the first event, min time is after the previous event
    if (index > 0) {
      final prevEvent = _wakeUpEvents[index - 1];
      if (prevEvent.time != null) {
        minTime = prevEvent.time!
            .add(Duration(minutes: prevEvent.stayedInBedMinutes));

        // Check if time is after previous event's end time
        if (event.time!.isBefore(minTime)) {
          return '時間必須晚於上一次醒來結束時間 (${DateFormat('HH:mm').format(minTime)})';
        }
      }
    } else {
      // If this is the first wake-up event, min time is bedTime + sleep latency
      minTime = _bedTime.add(Duration(
        hours: _timeToFallAsleepHours,
        minutes: _timeToFallAsleepMinutes,
      ));

      // Check if time is after sleep latency
      if (event.time!.isBefore(minTime)) {
        return '時間必須晚於入睡時間 (${DateFormat('HH:mm').format(minTime)})';
      }
    }

    // Check if time is before next event's time (if any)
    if (index < _wakeUpEvents.length - 1) {
      final nextEvent = _wakeUpEvents[index + 1];
      if (nextEvent.time != null) {
        final thisEventEndTime =
            event.time!.add(Duration(minutes: event.stayedInBedMinutes));
        if (thisEventEndTime.isAfter(nextEvent.time!)) {
          return '清醒時間太長，會與下一次醒來時間重疊';
        }
      }
    }

    // Check if time is before final awakening time
    final eventEndTime =
        event.time!.add(Duration(minutes: event.stayedInBedMinutes));
    if (eventEndTime.isAfter(_finalAwakeningTime)) {
      return '清醒時間太長，會超過最後起床時間';
    }

    return null;
  }

  // New method to build wake-up time field with proper constraints
  Widget _buildWakeUpTimeField({
    required int index,
    required WakeUpEvent event,
  }) {
    // Calculate minimum time for this wake-up event
    DateTime minTime;

    // If this is not the first event, min time is after the previous event
    if (index > 0) {
      final prevEvent = _wakeUpEvents[index - 1];
      if (prevEvent.time != null) {
        minTime = prevEvent.time!
            .add(Duration(minutes: prevEvent.stayedInBedMinutes));
      } else {
        // If previous event has no time yet, use bedTime + sleep latency
        minTime = _bedTime.add(Duration(
          hours: _timeToFallAsleepHours,
          minutes: _timeToFallAsleepMinutes,
        ));
      }
    } else {
      // If this is the first wake-up event, min time is bedTime + sleep latency
      minTime = _bedTime.add(Duration(
        hours: _timeToFallAsleepHours,
        minutes: _timeToFallAsleepMinutes,
      ));
    }

    return GestureDetector(
      onTap: () {
        // Show time picker with appropriate constraints
        _showWakeUpTimePicker(
          context: context,
          event: event,
          minTime: minTime,
          onTimeSelected: (newTime) {
            _updateWakeUpEvent(
              index,
              WakeUpEvent(
                time: newTime,
                gotOutOfBed: event.gotOutOfBed,
                outOfBedDurationMinutes: event.outOfBedDurationMinutes,
                stayedInBedMinutes: event.stayedInBedMinutes,
              ),
            );
            // Reset validation warnings when user selects a new time
            setState(() {
              _showValidationWarnings = false;
            });
          },
        );
      },
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
            const Text(
              '醒來時間',
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 17,
                color: CupertinoColors.label,
              ),
            ),
            Text(
              event.time != null
                  ? DateFormat('HH:mm').format(event.time!)
                  : '請選擇醒來時間',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: event.time != null
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New method for wake-up time picker with proper constraints
  void _showWakeUpTimePicker({
    required BuildContext context,
    required WakeUpEvent event,
    required DateTime minTime,
    required Function(DateTime) onTimeSelected,
  }) {
    // Max time is current time
    final maxTime = DateTime.now();

    // Initial time is either the existing time or the minimum allowed time
    final initialTime = event.time ?? minTime;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: SafeArea(
          child: Column(
            children: [
              // Header with buttons
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.systemGrey5,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('取消'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      '醒來時間',
                      style: TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('確定'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Time picker
              Expanded(
                child: _buildSimpleTimePicker(
                  time: initialTime,
                  onChanged: (newTime) {
                    onTimeSelected(newTime);
                  },
                  minTime: minTime,
                  maxTime: maxTime,
                ),
              ),
            ],
          ),
        ),
      ),
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
    DateTime minTime;

    // If there are wake-up events, final awakening must be after the last wake-up event plus its duration
    if (_wakeUpEvents.isNotEmpty) {
      final lastEvent = _wakeUpEvents.last;
      if (lastEvent.time != null) {
        minTime = lastEvent.time!
            .add(Duration(minutes: lastEvent.stayedInBedMinutes));
      } else {
        minTime = _bedTime;
      }
    } else {
      minTime = _bedTime;
    }

    final maxTime = now;
    return _buildTimePicker(
      title: '幾點起床？',
      subtitle: '(不算中途醒來) 最後一次醒來、準備起床的時間?',
      time: _finalAwakeningTime,
      onChanged: (time) {
        // Validate final awakening time against last wake-up event
        if (_wakeUpEvents.isNotEmpty) {
          final lastEvent = _wakeUpEvents.last;
          if (lastEvent.time != null) {
            final lastEventEndTime = lastEvent.time!
                .add(Duration(minutes: lastEvent.stayedInBedMinutes));
            if (time.isBefore(lastEventEndTime)) {
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('時間順序有誤'),
                  content: Text(
                      '最後起床時間必須晚於最後一次醒來結束的時間 (${DateFormat('HH:mm').format(lastEventEndTime)})'),
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
          }
        }

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
          '有在醒來的五分鐘之內，起身離開床舖嗎？',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 24),
        Column(
          children: ['有', '沒有'].map((option) {
            final isSelected = _immediateWakeUp == (option == '有');
            return GestureDetector(
              onTap: () => setState(() {
                _immediateWakeUp = option == '有';
                if (option == '有') {
                  _timeInBedAfterWakingHours = 0;
                  _timeInBedAfterWakingMinutes = 0;
                } else if (option == '沒有') {
                  // Set default values for time in bed after waking
                  _timeInBedAfterWakingHours = 0;
                  _timeInBedAfterWakingMinutes = 15; // Default to 15 minutes
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
      ],
    );
  }

  Widget _buildTimeInBedAfterWakingPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '賴床了多長時間？',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        _buildDurationPicker(
          title: '',
          subtitle: '',
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
    );
  }

  Widget _buildSleepQualityPage() {
    final qualities = [
      {'value': 5.0, 'label': '很好', 'subtext': '精神飽滿、煥然一新', 'emoji': '😊'},
      {'value': 4.0, 'label': '不錯', 'subtext': '有精神、心情良好', 'emoji': '🙂'},
      {'value': 3.0, 'label': '普通', 'subtext': '沒什麼差別、一般', 'emoji': '😐'},
      {'value': 2.0, 'label': '不太好', 'subtext': '疲憊、昏沉、想睡覺', 'emoji': '😕'},
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
        const SizedBox(height: 16),
        // Use a more compact layout with smaller padding and margins
        ...qualities.map((quality) {
          final isSelected = _sleepQuality == quality['value'];
          return GestureDetector(
            onTap: () =>
                setState(() => _sleepQuality = quality['value'] as double),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8), // Reduced bottom margin
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10), // Reduced padding
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
                    style:
                        const TextStyle(fontSize: 28), // Slightly smaller emoji
                  ),
                  const SizedBox(width: 10), // Reduced spacing
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quality['label'] as String,
                          style: TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 16, // Slightly smaller font
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
                            fontSize: 14, // Slightly smaller font
                            color: isSelected
                                ? CupertinoColors.white.withOpacity(0.8)
                                : CupertinoColors.systemGrey,
                          ),
                          maxLines: 1, // Limit to one line
                          overflow: TextOverflow
                              .ellipsis, // Add ellipsis if text is too long
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
      onTap: () {
        // Find the index of the current wake-up event
        final currentIndex =
            _wakeUpEvents.indexWhere((event) => event.time == time);

        // Calculate minimum time based on previous event if it exists
        DateTime minTime;
        if (currentIndex > 0) {
          final previousEvent = _wakeUpEvents[currentIndex - 1];
          if (previousEvent.time != null) {
            minTime = previousEvent.time!
                .add(Duration(minutes: previousEvent.stayedInBedMinutes));
          } else {
            minTime = _bedTime;
          }
        } else {
          minTime = _bedTime;
        }

        // Calculate maximum time based on next event if it exists
        DateTime? maxTime;
        if (currentIndex < _wakeUpEvents.length - 1) {
          maxTime = _wakeUpEvents[currentIndex + 1].time;
        } else {
          // Use current time as maximum
          maxTime = DateTime.now();
        }

        // Create a custom time picker that doesn't dismiss on scroll
        showCupertinoModalPopup<void>(
          context: context,
          barrierDismissible: true, // Allow tapping outside to dismiss
          builder: (BuildContext context) {
            return GestureDetector(
              // Prevent dismissal when interacting with the container's contents
              onTap: () {}, // Intercept tap events
              child: Container(
                height: 300,
                color: CupertinoColors.systemBackground,
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header with buttons
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: CupertinoColors.systemGrey5,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Text('取消'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Text(
                              label,
                              style: const TextStyle(
                                fontFamily: 'SF Pro Text',
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Text('確定'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),

                      // Time picker
                      Expanded(
                        child: _buildSimpleTimePicker(
                          time: time,
                          onChanged: (newTime) {
                            onTimeSelected(newTime);
                          },
                          minTime: minTime,
                          maxTime: maxTime,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

  // A simpler time picker without extra labels and with better scroll handling
  Widget _buildSimpleTimePicker({
    required DateTime time,
    required Function(DateTime) onChanged,
    required DateTime minTime,
    required DateTime? maxTime,
  }) {
    // Calculate display date and hint
    final effectiveMaxTime = maxTime ?? DateTime.now();

    // For Q5: Create a continuous range from bedTime to max time
    // Calculate total hours from min to max
    int hoursFromMin;
    if (minTime.day != effectiveMaxTime.day) {
      // If spanning days, count hours from min time to midnight, then add hours until max time
      hoursFromMin = (24 - minTime.hour) + effectiveMaxTime.hour + 1;
    } else {
      hoursFromMin = effectiveMaxTime.hour - minTime.hour + 1;
    }

    // Calculate the current selection's position in the continuous range
    int selectedPosition;
    if (time.day == minTime.day) {
      selectedPosition = time.hour - minTime.hour;
    } else {
      selectedPosition = (24 - minTime.hour) + time.hour;
    }

    // For minutes, limit range if we're at boundary hours
    bool isAtMinHour = time.day == minTime.day && time.hour == minTime.hour;
    bool isAtMaxHour =
        time.day == effectiveMaxTime.day && time.hour == effectiveMaxTime.hour;
    int minMinute = isAtMinHour ? minTime.minute : 0;
    int maxMinute = isAtMaxHour ? effectiveMaxTime.minute : 59;

    final hourController =
        FixedExtentScrollController(initialItem: selectedPosition);
    final minuteController =
        FixedExtentScrollController(initialItem: time.minute - minMinute);

    return Row(
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
              child: NotificationListener<ScrollNotification>(
                // Prevent scroll events from propagating up the widget tree
                onNotification: (notification) => true,
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
                    if (value < (24 - minTime.hour)) {
                      // Previous day
                      newHour = minTime.hour + value;
                      newTime = DateTime(
                        minTime.year,
                        minTime.month,
                        minTime.day,
                        newHour,
                        time.minute,
                      );
                    } else {
                      // Current day
                      newHour = value - (24 - minTime.hour);
                      newTime = DateTime(
                        effectiveMaxTime.year,
                        effectiveMaxTime.month,
                        effectiveMaxTime.day,
                        newHour,
                        time.minute,
                      );
                    }

                    // Adjust minutes if needed
                    int adjustedMinute = time.minute;
                    if (newTime.day == minTime.day &&
                        newHour == minTime.hour &&
                        adjustedMinute < minTime.minute) {
                      adjustedMinute = minTime.minute;
                    }
                    if (newTime.day == effectiveMaxTime.day &&
                        newHour == effectiveMaxTime.hour &&
                        adjustedMinute > effectiveMaxTime.minute) {
                      adjustedMinute = effectiveMaxTime.minute;
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
                    if (index < (24 - minTime.hour)) {
                      // Previous day
                      displayHour = minTime.hour + index;
                    } else {
                      // Current day
                      displayHour = index - (24 - minTime.hour);
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
              child: NotificationListener<ScrollNotification>(
                // Prevent scroll events from propagating up the widget tree
                onNotification: (notification) => true,
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
            ),
          ],
        ),
      ],
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

  Widget _buildDurationPicker({
    required String title,
    required String subtitle,
    required int hours,
    required int minutes,
    required Function(int hours, int minutes) onChanged,
    int? maxHours,
    int? maxMinutes,
  }) {
    // Always start at 0 unless user has picked a value
    final hourController =
        FixedExtentScrollController(initialItem: hours == 0 ? 0 : hours);
    final minuteController =
        FixedExtentScrollController(initialItem: minutes == 0 ? 0 : minutes);

    // Calculate maximum hours and minutes
    final effectiveMaxHours = maxHours ?? 23;
    final effectiveMaxMinutes = maxMinutes ?? 59;

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
            '選擇的時長: ${hours.toString().padLeft(2, '0')} 小時 ${minutes.toString().padLeft(2, '0')} 分鐘',
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
                      // If at max hours, ensure minutes are within range
                      int newMinutes = minutes;
                      if (value == effectiveMaxHours &&
                          minutes > effectiveMaxMinutes) {
                        newMinutes = effectiveMaxMinutes;
                      }
                      onChanged(value, newMinutes);
                    },
                    children: List<Widget>.generate(effectiveMaxHours + 1,
                        (int index) {
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
                      // If at max hours, ensure minutes are within range
                      if (hours == effectiveMaxHours &&
                          value > effectiveMaxMinutes) {
                        value = effectiveMaxMinutes;
                      }
                      onChanged(hours, value);
                    },
                    children: List<Widget>.generate(
                        hours == effectiveMaxHours
                            ? effectiveMaxMinutes + 1
                            : 60, (int index) {
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
    final timeInBedAfterWaking = _immediateWakeUp == true
        ? 0
        : _timeInBedAfterWakingHours * 60 + _timeInBedAfterWakingMinutes;
    if (timeToFallAsleep < 0 || timeInBedAfterWaking < 0) {
      return '入睡時間或賴床時間不能為負數。';
    }
    if (timeToFallAsleep + timeInBedAfterWaking > totalTimeInBed) {
      return '入睡時間與賴床時間總和不能超過總在床時間。';
    }

    // Check mandatory fields - already validated by _isCurrentPageValid
    // These checks are kept as a final safety check

    // Q3 (if not skipped)
    if (timeToFallAsleep > 5 && !_q3Skipped && _sleepDifficultyReason == null) {
      return '請選擇睡不著的原因。';
    }

    // Q4 (if not skipped)
    if (timeToFallAsleep > 5 && !_q3Skipped && _hasLeftBed == null) {
      return '請選擇是否有離開床舖。';
    }

    // Q5 - Validate wake-up times
    if (_numberOfAwakenings > 0) {
      String? wakeUpValidationError = _validateWakeUpTimes();
      if (wakeUpValidationError != null) {
        return wakeUpValidationError;
      }
    }

    // Q9 (only validate if user woke up during sleep)
    if (_wokeUpDuringSleep == true && _wakeUpDifficultyReason == null) {
      return '請選擇醒著的原因。';
    }

    // Q8
    if (_immediateWakeUp == null) {
      return '請選擇是否在醒來五分鐘內起身。';
    }

    // Q9 (now Q9 is sleep quality)
    if (_sleepQuality == null) {
      return '請評價你的睡眠品質。';
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
    return null;
  }

  // Add the _buildNotesPage method
  Widget _buildNotesPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '其他附註',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '可以補充任何跟這次睡眠相關的事項或細節',
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.systemGrey5,
              width: 1,
            ),
          ),
          child: CupertinoTextField(
            controller: _notesController,
            placeholder: '請輸入附註（最多50字）',
            padding: const EdgeInsets.all(16),
            maxLength: 50,
            maxLines: 4,
            decoration: null,
            style: const TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 17,
              color: CupertinoColors.label,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_notesController.text.length}/50',
          style: const TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 13,
            color: CupertinoColors.systemGrey,
          ),
          textAlign: TextAlign.end,
        ),
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
          '請選擇最接近的一項',
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
}
