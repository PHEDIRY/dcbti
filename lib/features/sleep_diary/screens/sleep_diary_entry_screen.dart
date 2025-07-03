import 'package:flutter/cupertino.dart';
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
  DateTime _entryDate =
      DateTime.now(); // Changed from final to allow modification
  DateTime _bedTime = DateTime.now().subtract(const Duration(hours: 8));
  int _timeToFallAsleepMinutes = 15;
  DateTime _finalAwakeningTime = DateTime.now();
  DateTime _outOfBedTime = DateTime.now();

  // Wake up events
  int _numberOfAwakenings = 0;
  final List<WakeUpEvent> _wakeUpEvents = [];

  // Quality and notes
  double _sleepQuality = 3.0;
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
                initialDateTime: _entryDate,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (DateTime newDate) {
                  setState(() {
                    _entryDate = DateTime(
                      newDate.year,
                      newDate.month,
                      newDate.day,
                      _entryDate.hour,
                      _entryDate.minute,
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
    // TODO: Implement submission to Firestore
    final entry = SleepDiaryEntry.create(
      entryDate: _entryDate,
      bedTime: _bedTime,
      wakeTime: _finalAwakeningTime,
      timeToFallAsleepMinutes: _timeToFallAsleepMinutes,
      numberOfAwakenings: _numberOfAwakenings,
      wakeUpEvents: _wakeUpEvents,
      finalAwakeningTime: _finalAwakeningTime,
      outOfBedTime: _outOfBedTime,
      sleepQuality: _sleepQuality,
      caffeineConsumption: _caffeineConsumption,
      alcoholConsumption: _alcoholConsumption,
      sleepMedicineConsumption: _sleepMedicineConsumption,
      smokingEvent: _smokingEvent,
      exerciseEvent: _exerciseEvent,
      lastMealTime: _lastMealTime,
      sleepTags: _selectedTags.toList(),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          '睡眠日記',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _currentStep == 2 ? _handleSubmit : null,
          child: const Text('儲存'),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateHeader(),
                    const SizedBox(height: 24),
                    _buildCurrentStep(),
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    final dateStr = DateFormat('yyyy年M月d日 (E)', 'zh_TW').format(_entryDate);

    return GestureDetector(
      onTap: () => _showDatePicker(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.calendar,
                  color: CupertinoColors.systemGrey,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '這是一筆睡眠日記，記錄你在這個時間點之前的一次睡眠。無論你是在晚上或白天睡覺，都可以記錄。',
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 15,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < 3; i++) ...[
            if (i > 0)
              Container(
                width: 24,
                height: 1,
                color: i <= _currentStep
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey4,
              ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _currentStep
                    ? CupertinoColors.activeBlue
                    : i < _currentStep
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBasicSleepInfo();
      case 1:
        return _buildConsumptionEvents();
      case 2:
        return _buildTagsAndNotes();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicSleepInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeField(
          label: '就寢時間',
          time: _bedTime,
          onTimeSelected: (time) => setState(() => _bedTime = time),
        ),
        const SizedBox(height: 24),
        _buildNumberInput(
          title: '入睡時間（分鐘）',
          value: _timeToFallAsleepMinutes,
          onChanged: (value) =>
              setState(() => _timeToFallAsleepMinutes = value),
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
        ),
        if (_numberOfAwakenings > 0) ...[
          const SizedBox(height: 24),
          ..._wakeUpEvents.map(_buildWakeUpEventItem),
        ],
        const SizedBox(height: 24),
        _buildTimeField(
          label: '最後醒來時間',
          time: _finalAwakeningTime,
          onTimeSelected: (time) => setState(() => _finalAwakeningTime = time),
        ),
        const SizedBox(height: 24),
        _buildTimeField(
          label: '起床時間',
          time: _outOfBedTime,
          onTimeSelected: (time) => setState(() => _outOfBedTime = time),
        ),
        const SizedBox(height: 32),
        _buildQualitySection(),
      ],
    );
  }

  Widget _buildQualitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '睡眠品質',
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 16),
        _buildQualityPicker(),
      ],
    );
  }

  Widget _buildQualityPicker() {
    final qualities = [
      {'value': 0.0, 'label': '很差'},
      {'value': 1.0, 'label': '差'},
      {'value': 2.0, 'label': '普通'},
      {'value': 3.0, 'label': '好'},
      {'value': 4.0, 'label': '很好'},
      {'value': 5.0, 'label': '極好'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.systemGrey5,
          width: 1,
        ),
      ),
      child: CupertinoSegmentedControl<double>(
        children: {
          for (var quality in qualities)
            quality['value'] as double: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                quality['label'] as String,
                style: const TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 15,
                ),
              ),
            ),
        },
        groupValue: _sleepQuality,
        onValueChanged: (value) => setState(() => _sleepQuality = value),
      ),
    );
  }

  Widget _buildConsumptionEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '生活習慣',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '記錄這次睡眠期間前後的生活習慣，幫助了解影響睡眠品質的因素。',
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 15,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
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
          title: '最後用餐時間',
          event: _lastMealTime,
          onChanged: (event) => setState(() => _lastMealTime = event),
        ),
      ],
    );
  }

  Widget _buildTagsAndNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTagSection(
          title: '日間活動',
          tags: SleepTags.daytimeActivities,
        ),
        const SizedBox(height: 24),
        _buildTagSection(
          title: '睡前活動',
          tags: SleepTags.bedtimeActivities,
        ),
        const SizedBox(height: 24),
        _buildTagSection(
          title: '睡前物質',
          tags: SleepTags.bedtimeSubstances,
        ),
        const SizedBox(height: 24),
        _buildTagSection(
          title: '睡眠干擾',
          tags: SleepTags.sleepDisturbances,
        ),
        const SizedBox(height: 32),
        _buildNotesSection(),
      ],
    );
  }

  Widget _buildNumberInput({
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
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
                  value.toString(),
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

  Widget _buildWakeUpEventItem(WakeUpEvent event) {
    final index = _wakeUpEvents.indexOf(event);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '第 ${index + 1} 次醒來',
          style: const TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
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
              ),
            ),
          ],
        ),
        if (event.gotOutOfBed) ...[
          const SizedBox(height: 8),
          _buildNumberInput(
            title: '下床時間（分鐘）',
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
          ),
        ],
        const SizedBox(height: 8),
        _buildNumberInput(
          title: '躺床時間（分鐘）',
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
        ),
        const SizedBox(height: 16),
        Container(
          height: 1,
          color: CupertinoColors.systemGrey5,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNavigationButtons() {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
              },
              child: const Text('上一步'),
            )
          else
            const SizedBox(width: 60),
          Text(
            '${_currentStep + 1}/3',
            style: const TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 15,
              color: CupertinoColors.systemGrey,
            ),
          ),
          if (_currentStep < 2)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _currentStep++;
                });
              },
              child: const Text('下一步'),
            )
          else
            const SizedBox(width: 60),
        ],
      ),
    );
  }
}
