import '../models/sleep_diary_entry.dart';

class SleepAnalysisService {
  // Calculate Sleep Onset Latency (SOL)
  int calculateSOL(SleepDiaryEntry entry) {
    return entry.timeToFallAsleepMinutes;
  }

  // Calculate Wake After Sleep Onset (WASO) - total duration
  int calculateWASO(SleepDiaryEntry entry) {
    int totalWasoMinutes = 0;
    for (var wakeEvent in entry.wakeUpEvents) {
      totalWasoMinutes += wakeEvent.stayedInBedMinutes;
      if (wakeEvent.gotOutOfBed && wakeEvent.outOfBedDurationMinutes != null) {
        totalWasoMinutes += wakeEvent.outOfBedDurationMinutes!;
      }
    }
    return totalWasoMinutes;
  }

  // Get number of wake after sleep onset (WASO_N)
  int calculateWASON(SleepDiaryEntry entry) {
    return entry.numberOfAwakenings;
  }

  // Get duration of specific wake after sleep onset (WASO_duration_n)
  int? calculateWASODurationN(SleepDiaryEntry entry, int n) {
    if (n < 0 || n >= entry.wakeUpEvents.length) {
      return null;
    }

    final wakeEvent = entry.wakeUpEvents[n];
    int duration = wakeEvent.stayedInBedMinutes;
    if (wakeEvent.gotOutOfBed && wakeEvent.outOfBedDurationMinutes != null) {
      duration += wakeEvent.outOfBedDurationMinutes!;
    }

    return duration;
  }

  // Get time of specific wake after sleep onset (WASO_time_n)
  DateTime? calculateWASOTimeN(SleepDiaryEntry entry, int n) {
    if (n < 0 || n >= entry.wakeUpEvents.length) {
      return null;
    }

    return entry.wakeUpEvents[n].time;
  }

  // Calculate Total Sleep Time (TST)
  Duration calculateTST(SleepDiaryEntry entry) {
    // Total time between bed and wake, minus time to fall asleep and WASO
    final totalMinutes = entry.wakeTime.difference(entry.bedTime).inMinutes -
        entry.timeToFallAsleepMinutes -
        calculateWASO(entry);

    return Duration(minutes: totalMinutes > 0 ? totalMinutes : 0);
  }

  // Calculate Total Time in Bed (TIB)
  Duration calculateTIB(SleepDiaryEntry entry) {
    return entry.wakeTime.difference(entry.bedTime);
  }

  // Calculate Sleep Efficiency (SE)
  double calculateSE(SleepDiaryEntry entry) {
    final tst = calculateTST(entry).inMinutes;
    final tib = calculateTIB(entry).inMinutes;

    if (tib <= 0) return 0.0;

    final efficiency = (tst / tib) * 100;
    return efficiency.clamp(0.0, 100.0); // Ensure it's between 0-100%
  }

  // Calculate Lingering in Bed (LIB)
  int calculateLIB(SleepDiaryEntry entry) {
    return entry.timeInBedAfterWakingMinutes;
  }

  // Calculate weekly averages for a list of entries
  Map<String, dynamic> calculateWeeklyAverages(List<SleepDiaryEntry> entries) {
    if (entries.isEmpty) {
      return {
        'avgSOL': 0,
        'avgWASO': 0,
        'avgWASON': 0,
        'avgTST': const Duration(hours: 0),
        'avgTIB': const Duration(hours: 0),
        'avgSE': 0.0,
        'avgLIB': 0,
        'avgSleepQuality': 0.0,
      };
    }

    int totalSOL = 0;
    int totalWASO = 0;
    int totalWASON = 0;
    int totalTSTMinutes = 0;
    int totalTIBMinutes = 0;
    double totalSE = 0.0;
    int totalLIB = 0;
    double totalSleepQuality = 0.0;

    for (var entry in entries) {
      totalSOL += calculateSOL(entry);
      totalWASO += calculateWASO(entry);
      totalWASON += calculateWASON(entry);
      totalTSTMinutes += calculateTST(entry).inMinutes;
      totalTIBMinutes += calculateTIB(entry).inMinutes;
      totalSE += calculateSE(entry);
      totalLIB += calculateLIB(entry);
      totalSleepQuality += entry.sleepQuality;
    }

    final count = entries.length;

    return {
      'avgSOL': totalSOL ~/ count,
      'avgWASO': totalWASO ~/ count,
      'avgWASON': totalWASON ~/ count,
      'avgTST': Duration(minutes: totalTSTMinutes ~/ count),
      'avgTIB': Duration(minutes: totalTIBMinutes ~/ count),
      'avgSE': totalSE / count,
      'avgLIB': totalLIB ~/ count,
      'avgSleepQuality': totalSleepQuality / count,
    };
  }

  // Get entries from the last 7 days
  List<SleepDiaryEntry> getLastWeekEntries(List<SleepDiaryEntry> allEntries) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return allEntries
        .where((entry) =>
            entry.entryDate.isAfter(weekAgo) ||
            entry.entryDate.isAtSameMomentAs(weekAgo))
        .toList();
  }
}
