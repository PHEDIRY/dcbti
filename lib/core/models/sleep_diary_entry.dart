import 'package:cloud_firestore/cloud_firestore.dart';

class SleepDiaryEntry {
  final String id;
  final DateTime entryDate;
  final DateTime bedTime;
  final DateTime wakeTime;
  final int timeToFallAsleepMinutes;
  final int numberOfAwakenings;
  final List<WakeUpEvent> wakeUpEvents;
  final DateTime finalAwakeningTime;
  final int timeInBedAfterWakingMinutes;
  final double sleepQuality; // 0.0 to 5.0
  final ConsumptionEvent? caffeineConsumption;
  final ConsumptionEvent? alcoholConsumption;
  final ConsumptionEvent? sleepMedicineConsumption;
  final ConsumptionEvent? smokingEvent;
  final ConsumptionEvent? exerciseEvent;
  final ConsumptionEvent? lastMealTime;
  final List<String> sleepTags;
  final String? notes;
  final DateTime createdAt;
  final String? sleepDifficultyReason; // 思緒奔騰、身體躁動不安、憂慮或焦慮、其他、以上皆無
  final String? wakeUpDifficultyReason; // 思緒奔騰、身體躁動不安、憂慮或焦慮、其他、以上皆無
  final bool immediateWakeUp; // 在醒來的五分鐘之內是否有起身離開床舖
  final int? initialOutOfBedDurationMinutes; // 躺上床後離開床舖的時間

  Duration get sleepDuration => wakeTime.difference(bedTime);
  Duration get timeInBed => Duration(
      minutes: timeToFallAsleepMinutes +
          sleepDuration.inMinutes +
          timeInBedAfterWakingMinutes);

  const SleepDiaryEntry({
    required this.id,
    required this.entryDate,
    required this.bedTime,
    required this.wakeTime,
    required this.timeToFallAsleepMinutes,
    required this.numberOfAwakenings,
    required this.wakeUpEvents,
    required this.finalAwakeningTime,
    required this.timeInBedAfterWakingMinutes,
    required this.sleepQuality,
    this.caffeineConsumption,
    this.alcoholConsumption,
    this.sleepMedicineConsumption,
    this.smokingEvent,
    this.exerciseEvent,
    this.lastMealTime,
    required this.sleepTags,
    this.notes,
    required this.createdAt,
    this.sleepDifficultyReason,
    this.wakeUpDifficultyReason,
    required this.immediateWakeUp,
    this.initialOutOfBedDurationMinutes,
  });

  // Create a new entry
  factory SleepDiaryEntry.create({
    required DateTime entryDate,
    required DateTime bedTime,
    required DateTime wakeTime,
    required int timeToFallAsleepMinutes,
    required int numberOfAwakenings,
    required List<WakeUpEvent> wakeUpEvents,
    required DateTime finalAwakeningTime,
    required int timeInBedAfterWakingMinutes,
    required double sleepQuality,
    ConsumptionEvent? caffeineConsumption,
    ConsumptionEvent? alcoholConsumption,
    ConsumptionEvent? sleepMedicineConsumption,
    ConsumptionEvent? smokingEvent,
    ConsumptionEvent? exerciseEvent,
    ConsumptionEvent? lastMealTime,
    required List<String> sleepTags,
    String? notes,
    String? sleepDifficultyReason,
    String? wakeUpDifficultyReason,
    bool immediateWakeUp = false,
    int? initialOutOfBedDurationMinutes,
  }) {
    return SleepDiaryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      entryDate: entryDate,
      bedTime: bedTime,
      wakeTime: wakeTime,
      timeToFallAsleepMinutes: timeToFallAsleepMinutes,
      numberOfAwakenings: numberOfAwakenings,
      wakeUpEvents: wakeUpEvents,
      finalAwakeningTime: finalAwakeningTime,
      timeInBedAfterWakingMinutes: timeInBedAfterWakingMinutes,
      sleepQuality: sleepQuality,
      caffeineConsumption: caffeineConsumption,
      alcoholConsumption: alcoholConsumption,
      sleepMedicineConsumption: sleepMedicineConsumption,
      smokingEvent: smokingEvent,
      exerciseEvent: exerciseEvent,
      lastMealTime: lastMealTime,
      sleepTags: sleepTags,
      notes: notes,
      createdAt: DateTime.now(),
      sleepDifficultyReason: sleepDifficultyReason,
      wakeUpDifficultyReason: wakeUpDifficultyReason,
      immediateWakeUp: immediateWakeUp,
      initialOutOfBedDurationMinutes: initialOutOfBedDurationMinutes,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entryDate': Timestamp.fromDate(entryDate),
      'bedTime': Timestamp.fromDate(bedTime),
      'wakeTime': Timestamp.fromDate(wakeTime),
      'timeToFallAsleepMinutes': timeToFallAsleepMinutes,
      'numberOfAwakenings': numberOfAwakenings,
      'wakeUpEvents': wakeUpEvents.map((e) => e.toMap()).toList(),
      'finalAwakeningTime': Timestamp.fromDate(finalAwakeningTime),
      'timeInBedAfterWakingMinutes': timeInBedAfterWakingMinutes,
      'sleepQuality': sleepQuality,
      'caffeineConsumption': caffeineConsumption?.toMap(),
      'alcoholConsumption': alcoholConsumption?.toMap(),
      'sleepMedicineConsumption': sleepMedicineConsumption?.toMap(),
      'smokingEvent': smokingEvent?.toMap(),
      'exerciseEvent': exerciseEvent?.toMap(),
      'lastMealTime': lastMealTime?.toMap(),
      'sleepTags': sleepTags,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'sleepDifficultyReason': sleepDifficultyReason,
      'wakeUpDifficultyReason': wakeUpDifficultyReason,
      'immediateWakeUp': immediateWakeUp,
      'initialOutOfBedDurationMinutes': initialOutOfBedDurationMinutes,
    };
  }

  // Create from Firestore document
  factory SleepDiaryEntry.fromMap(Map<String, dynamic> map) {
    return SleepDiaryEntry(
      id: map['id'] as String,
      entryDate: (map['entryDate'] as Timestamp).toDate(),
      bedTime: (map['bedTime'] as Timestamp).toDate(),
      wakeTime: (map['wakeTime'] as Timestamp).toDate(),
      timeToFallAsleepMinutes: map['timeToFallAsleepMinutes'] as int,
      numberOfAwakenings: map['numberOfAwakenings'] as int,
      wakeUpEvents: (map['wakeUpEvents'] as List<dynamic>)
          .map((e) => WakeUpEvent.fromMap(e as Map<String, dynamic>))
          .toList(),
      finalAwakeningTime: (map['finalAwakeningTime'] as Timestamp).toDate(),
      timeInBedAfterWakingMinutes: map['timeInBedAfterWakingMinutes'] as int,
      sleepQuality: (map['sleepQuality'] as num).toDouble(),
      caffeineConsumption: map['caffeineConsumption'] != null
          ? ConsumptionEvent.fromMap(
              map['caffeineConsumption'] as Map<String, dynamic>)
          : null,
      alcoholConsumption: map['alcoholConsumption'] != null
          ? ConsumptionEvent.fromMap(
              map['alcoholConsumption'] as Map<String, dynamic>)
          : null,
      sleepMedicineConsumption: map['sleepMedicineConsumption'] != null
          ? ConsumptionEvent.fromMap(
              map['sleepMedicineConsumption'] as Map<String, dynamic>)
          : null,
      smokingEvent: map['smokingEvent'] != null
          ? ConsumptionEvent.fromMap(
              map['smokingEvent'] as Map<String, dynamic>)
          : null,
      exerciseEvent: map['exerciseEvent'] != null
          ? ConsumptionEvent.fromMap(
              map['exerciseEvent'] as Map<String, dynamic>)
          : null,
      lastMealTime: map['lastMealTime'] != null
          ? ConsumptionEvent.fromMap(
              map['lastMealTime'] as Map<String, dynamic>)
          : null,
      sleepTags: (map['sleepTags'] as List<dynamic>).cast<String>(),
      notes: map['notes'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      sleepDifficultyReason: map['sleepDifficultyReason'] as String?,
      wakeUpDifficultyReason: map['wakeUpDifficultyReason'] as String?,
      immediateWakeUp: map['immediateWakeUp'] as bool? ?? false,
      initialOutOfBedDurationMinutes:
          map['initialOutOfBedDurationMinutes'] as int?,
    );
  }

  // Copy with method for immutability
  SleepDiaryEntry copyWith({
    String? id,
    DateTime? entryDate,
    DateTime? bedTime,
    DateTime? wakeTime,
    int? timeToFallAsleepMinutes,
    int? numberOfAwakenings,
    List<WakeUpEvent>? wakeUpEvents,
    DateTime? finalAwakeningTime,
    int? timeInBedAfterWakingMinutes,
    double? sleepQuality,
    ConsumptionEvent? caffeineConsumption,
    ConsumptionEvent? alcoholConsumption,
    ConsumptionEvent? sleepMedicineConsumption,
    ConsumptionEvent? smokingEvent,
    ConsumptionEvent? exerciseEvent,
    ConsumptionEvent? lastMealTime,
    List<String>? sleepTags,
    String? notes,
    DateTime? createdAt,
    String? sleepDifficultyReason,
    String? wakeUpDifficultyReason,
    bool? immediateWakeUp,
    int? initialOutOfBedDurationMinutes,
  }) {
    return SleepDiaryEntry(
      id: id ?? this.id,
      entryDate: entryDate ?? this.entryDate,
      bedTime: bedTime ?? this.bedTime,
      wakeTime: wakeTime ?? this.wakeTime,
      timeToFallAsleepMinutes:
          timeToFallAsleepMinutes ?? this.timeToFallAsleepMinutes,
      numberOfAwakenings: numberOfAwakenings ?? this.numberOfAwakenings,
      wakeUpEvents: wakeUpEvents ?? this.wakeUpEvents,
      finalAwakeningTime: finalAwakeningTime ?? this.finalAwakeningTime,
      timeInBedAfterWakingMinutes:
          timeInBedAfterWakingMinutes ?? this.timeInBedAfterWakingMinutes,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      caffeineConsumption: caffeineConsumption ?? this.caffeineConsumption,
      alcoholConsumption: alcoholConsumption ?? this.alcoholConsumption,
      sleepMedicineConsumption:
          sleepMedicineConsumption ?? this.sleepMedicineConsumption,
      smokingEvent: smokingEvent ?? this.smokingEvent,
      exerciseEvent: exerciseEvent ?? this.exerciseEvent,
      lastMealTime: lastMealTime ?? this.lastMealTime,
      sleepTags: sleepTags ?? this.sleepTags,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      sleepDifficultyReason:
          sleepDifficultyReason ?? this.sleepDifficultyReason,
      wakeUpDifficultyReason:
          wakeUpDifficultyReason ?? this.wakeUpDifficultyReason,
      immediateWakeUp: immediateWakeUp ?? this.immediateWakeUp,
      initialOutOfBedDurationMinutes:
          initialOutOfBedDurationMinutes ?? this.initialOutOfBedDurationMinutes,
    );
  }
}

class WakeUpEvent {
  final DateTime time;
  final bool gotOutOfBed;
  final int? outOfBedDurationMinutes;
  final int stayedInBedMinutes;

  const WakeUpEvent({
    required this.time,
    required this.gotOutOfBed,
    this.outOfBedDurationMinutes,
    required this.stayedInBedMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'time': Timestamp.fromDate(time),
      'gotOutOfBed': gotOutOfBed,
      'outOfBedDurationMinutes': outOfBedDurationMinutes,
      'stayedInBedMinutes': stayedInBedMinutes,
    };
  }

  factory WakeUpEvent.fromMap(Map<String, dynamic> map) {
    return WakeUpEvent(
      time: (map['time'] as Timestamp).toDate(),
      gotOutOfBed: map['gotOutOfBed'] as bool,
      outOfBedDurationMinutes: map['outOfBedDurationMinutes'] as int?,
      stayedInBedMinutes: map['stayedInBedMinutes'] as int,
    );
  }
}

class ConsumptionEvent {
  final DateTime time;
  final String? details;

  const ConsumptionEvent({
    required this.time,
    this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'time': Timestamp.fromDate(time),
      'details': details,
    };
  }

  factory ConsumptionEvent.fromMap(Map<String, dynamic> map) {
    return ConsumptionEvent(
      time: (map['time'] as Timestamp).toDate(),
      details: map['details'] as String?,
    );
  }
}

// Sleep tag constants
class SleepTags {
  // Daytime activities
  static const String exercise = 'exercise';
  static const String longNap = 'nap_longer_than_30min';
  static const String morningSunlight = 'sunlight_within_30min_of_waking';
  static const String yoga = 'yoga';
  static const String afternoonCaffeine = 'caffeine_after_12pm';

  // Bedtime activities
  static const String stretching = 'stretching';
  static const String meditation = 'meditation';
  static const String reading = 'reading';
  static const String lateEating = 'eat_within_3hours_of_bed';
  static const String journaling = 'journaling';
  static const String lateAlcohol = 'alcohol_within_3hours_of_bed';
  static const String shower = 'shower';
  static const String workedLate = 'worked_late';
  static const String socializedLate = 'socialized_late';
  static const String screenTime = 'screen_time_within_1hour_of_bed';
  static const String capaTherapy = 'capa_therapy';

  // Bedtime substances
  static const String sleepingPills = 'sleeping_pills';
  static const String melatonin = 'melatonin';
  static const String supplements = 'supplements_herbs';
  static const String cannabis = 'cbd_thc';
  static const String nicotine = 'nicotine_tobacco';
  static const String otherMedications = 'other_medications';

  // Sleep disturbances
  static const String stress = 'stress_racing_thoughts';
  static const String nightmares = 'nightmares';
  static const String light = 'light';
  static const String noise = 'noises';
  static const String temperature = 'temperature';
  static const String snoring = 'snoring';
  static const String bathroom = 'woke_for_bathroom';
  static const String householdDisruption = 'kids_partner_pets';
  static const String jetLag = 'travel_jet_lag';
  static const String healthIssues = 'pain_illness_injury';

  static List<String> get daytimeActivities => [
        exercise,
        longNap,
        morningSunlight,
        yoga,
        afternoonCaffeine,
      ];

  static List<String> get bedtimeActivities => [
        stretching,
        meditation,
        reading,
        lateEating,
        journaling,
        lateAlcohol,
        shower,
        workedLate,
        socializedLate,
        screenTime,
        capaTherapy,
      ];

  static List<String> get bedtimeSubstances => [
        sleepingPills,
        melatonin,
        supplements,
        cannabis,
        nicotine,
        otherMedications,
      ];

  static List<String> get sleepDisturbances => [
        stress,
        nightmares,
        light,
        noise,
        temperature,
        snoring,
        bathroom,
        householdDisruption,
        jetLag,
        healthIssues,
      ];

  static List<String> get all => [
        ...daytimeActivities,
        ...bedtimeActivities,
        ...bedtimeSubstances,
        ...sleepDisturbances,
      ];
}
