import 'package:moonly/utils/cycle_config.dart';

enum CyclePhase { menstruation, ovulation, fertile, pms, none }

class CyclePhaseHelper {
  final List<DateTime> bleedingDays;

  /// Normalized bleeding days (cached for performance).
  late final List<DateTime> _normalizedBleedingDays;
  final CycleConfig cycleConfig;

  CyclePhaseHelper({required this.bleedingDays, required this.cycleConfig}) {
    _normalizedBleedingDays = bleedingDays.map(_normalize).toList();
  }

  CyclePhase getPhase(DateTime date) {
    if (_isMenstruation(date)) {
      return CyclePhase.menstruation;
    }
    if (_isPms(date)) {
      return CyclePhase.pms;
    }
    if (_isOvulation(date)) {
      return CyclePhase.ovulation;
    }
    if (_isFertile(date)) {
      return CyclePhase.fertile;
    }
    return CyclePhase.none;
  }

  /// Normalizes a DateTime to midnight (removes time component).
  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Extracts period starts from bleeding days.
  ///
  /// A new period starts only when bleeding occurs after
  /// currentCycleStart + 21 days (minimum cycle length).
  /// Otherwise it's just spotting and ignored.
  ///
  /// Bleeding days with a gap of ≤ 1 day are treated as the same period.
  static const int _minCycleLength = 21;
  static const int _defaultPeriodLength = 4;

  /// Calculates the average period length based on all historical periods.
  /// For each period start, counts consecutive bleeding days (max 1 day gap).

  bool _isMenstruation(DateTime date) {
    final normalizedDate = _normalize(date);

    // Explicit bleeding day
    if (_normalizedBleedingDays.contains(normalizedDate)) {
      return true;
    }

    final sortedBleedingDays = List<DateTime>.from(_normalizedBleedingDays)
      ..sort();

    // Fill gaps between bleeding days (max 2 days gap)
    for (int i = 0; i < sortedBleedingDays.length - 1; i++) {
      final start = sortedBleedingDays[i];
      final end = sortedBleedingDays[i + 1];
      final gap = end.difference(start).inDays;

      // Only fill gaps of 2 days
      if (gap == 2) {
        if (normalizedDate.isAfter(start) && normalizedDate.isBefore(end)) {
          return true;
        }
      }
    }

    // Predict future menstruations based on cycle pattern
    final periodStarts = _extractPeriodStarts();
    if (periodStarts.isEmpty) {
      return false;
    }

    // Get the last period start
    final lastPeriodStart = periodStarts.last;

    // Calculate maximum period length
    final maxPeriodLength = _getPeriodLength();

    // Check if current period length is smaller than max period length
    // If so, mark those days as menstruation too
    if (!normalizedDate.isBefore(lastPeriodStart)) {
      // Calculate current period length (count bleeding days from period start)
      int currentPeriodLength = 1; // Start with the period start day
      DateTime currentDay = lastPeriodStart;

      while (true) {
        final nextDay = currentDay.add(const Duration(days: 1));
        final dayAfterNext = currentDay.add(const Duration(days: 2));

        if (_normalizedBleedingDays.contains(nextDay)) {
          currentPeriodLength++;
          currentDay = nextDay;
        } else if (_normalizedBleedingDays.contains(dayAfterNext)) {
          currentPeriodLength += 2;
          currentDay = dayAfterNext;
        } else {
          break;
        }
      }

      // If current period length is smaller than max, extend to max
      if (currentPeriodLength < maxPeriodLength) {
        final currentPeriodEnd = lastPeriodStart.add(
          Duration(days: maxPeriodLength - 1),
        );

        // Check if date is within the extended current period window
        if (!normalizedDate.isAfter(currentPeriodEnd)) {
          // Check if there's actual bleeding data for this specific date
          final hasActualBleedingOnThisDate = _normalizedBleedingDays.contains(
            normalizedDate,
          );

          // Also check if this date is in a gap between bleeding days
          bool isInGap = false;
          for (int i = 0; i < sortedBleedingDays.length - 1; i++) {
            final start = sortedBleedingDays[i];
            final end = sortedBleedingDays[i + 1];
            final gap = end.difference(start).inDays;
            if (gap == 2 &&
                normalizedDate.isAfter(start) &&
                normalizedDate.isBefore(end)) {
              isInGap = true;
              break;
            }
          }

          // Show prediction if there's no actual bleeding on this date
          // and it's not already filled as a gap
          if (!hasActualBleedingOnThisDate && !isInGap) {
            return true;
          }
        }
      }
    }

    // Calculate cycle length (or use default 30 days)
    final cycleLength = _getCycleLength();

    // Calculate predicted period length
    final predictedPeriodLength = _getPeriodLength();

    // Check all future periods (not just the next one)
    DateTime currentPeriodStart = lastPeriodStart;
    int maxFuturePeriods = 5; // Limit to prevent infinite loops

    for (int i = 0; i < maxFuturePeriods; i++) {
      // Calculate next period start
      final nextPeriodStart = currentPeriodStart.add(
        Duration(days: cycleLength),
      );
      final nextPeriodEnd = nextPeriodStart.add(
        Duration(days: predictedPeriodLength - 1),
      );

      // Check if date is within this predicted menstruation window
      if (!normalizedDate.isBefore(nextPeriodStart) &&
          !normalizedDate.isAfter(nextPeriodEnd)) {
        // Check if there's actual bleeding data for this specific date
        final hasActualBleedingOnThisDate = _normalizedBleedingDays.contains(
          normalizedDate,
        );

        // Also check if this date is in a gap between bleeding days
        bool isInGap = false;
        for (int j = 0; j < sortedBleedingDays.length - 1; j++) {
          final start = sortedBleedingDays[j];
          final end = sortedBleedingDays[j + 1];
          final gap = end.difference(start).inDays;
          if (gap == 2 &&
              normalizedDate.isAfter(start) &&
              normalizedDate.isBefore(end)) {
            isInGap = true;
            break;
          }
        }

        // Show prediction if there's no actual bleeding on this date
        // and it's not already filled as a gap
        if (!hasActualBleedingOnThisDate && !isInGap) {
          return true;
        }
      }

      // If the date is before this period, we can stop searching
      if (normalizedDate.isBefore(nextPeriodStart)) {
        break;
      }

      // Move to next period
      currentPeriodStart = nextPeriodStart;
    }

    return false;
  }

  int _getPeriodLength() {
    if (_normalizedBleedingDays.isEmpty) {
      return cycleConfig.averagePeriodLength;
    }

    final periodStarts = _extractPeriodStarts();
    if (periodStarts.isEmpty) {
      return cycleConfig.averagePeriodLength;
    }

    // Only calculate period length if there are at least 2 cycle starts
    if (periodStarts.length < 2) {
      return cycleConfig.averagePeriodLength;
    }

    final List<int> periodLengths = [];

    for (final periodStart in periodStarts) {
      int length = 1; // Start with the period start day
      DateTime currentDay = periodStart;

      // Count consecutive bleeding days (max 1 day gap)
      while (true) {
        final nextDay = currentDay.add(const Duration(days: 1));
        final dayAfterNext = currentDay.add(const Duration(days: 2));

        // Check if there's bleeding the next day
        if (_normalizedBleedingDays.contains(nextDay)) {
          length++;
          currentDay = nextDay;
        }
        // Or with 1 day gap (2 days later)
        else if (_normalizedBleedingDays.contains(dayAfterNext)) {
          length += 2; // Count both the gap day and the bleeding day
          currentDay = dayAfterNext;
        } else {
          break; // No more bleeding days
        }
      }

      if (length > 0) {
        periodLengths.add(length.clamp(1, 10));
      }
    }

    if (periodLengths.isEmpty) {
      return _defaultPeriodLength;
    }

    // Use maximum period length
    final maxLength = periodLengths.reduce((a, b) => a > b ? a : b);

    return maxLength.clamp(1, 10);
  }

  int _getCycleLength() {
    final periodStarts = _extractPeriodStarts();

    // Need at least 2 period starts to calculate cycle length
    if (periodStarts.length < 2) {
      return cycleConfig.averageCycleLength; // Default cycle length
    }

    final List<int> cycleLengths = [];

    // Calculate cycle length between consecutive period starts
    for (int i = 0; i < periodStarts.length - 1; i++) {
      final currentStart = periodStarts[i];
      final nextStart = periodStarts[i + 1];
      final cycleLength = nextStart.difference(currentStart).inDays;
      cycleLengths.add(cycleLength);
    }

    // Calculate average cycle length
    final sum = cycleLengths.reduce((a, b) => a + b);
    final average = (sum / cycleLengths.length).round();

    return average.clamp(21, 45); // Reasonable bounds for cycle length
  }

  List<DateTime> _extractPeriodStarts() {
    if (bleedingDays.isEmpty) return [];

    // Normalize and sort bleeding days
    final normalized = bleedingDays.map(_normalize).toList()..sort();
    final List<DateTime> starts = [];

    DateTime? lastAcceptedStart;

    for (int i = 0; i < normalized.length; i++) {
      // Check if this is a new cluster (gap > 2 days from previous bleeding day)
      final isNewCluster =
          i == 0 || normalized[i].difference(normalized[i - 1]).inDays > 2;

      if (!isNewCluster) continue;

      final candidate = normalized[i];

      // First bleeding day is always a period start
      if (lastAcceptedStart == null) {
        starts.add(candidate);
        lastAcceptedStart = candidate;
        continue;
      }

      // Accept as new period if:
      // 1. At least 21 days have passed since last period start, OR
      // 2. Bleeding occurs on a PMS day (likely start of next period)
      final daysSinceLastPeriod = candidate
          .difference(lastAcceptedStart)
          .inDays;
      if (daysSinceLastPeriod >= _minCycleLength) {
        starts.add(candidate);
        lastAcceptedStart = candidate;
      }
      // else: spotting → ignored for cycle modeling
    }

    return starts;
  }

  /// Finds the last known period start before or on a given date.
  DateTime? _lastPeriodStartBefore(DateTime day) {
    final normalizedDay = _normalize(day);
    final periodStarts = _extractPeriodStarts();

    DateTime? last;

    for (final start in periodStarts) {
      if (!start.isAfter(normalizedDay)) {
        last = start;
      }
    }

    return last;
  }

  /// Projects the correct cycle anchor for a date by advancing
  /// full cycles forward if needed.
  DateTime _projectPeriodStart(DateTime base, DateTime target) {
    var current = base;
    final normalizedTarget = _normalize(target);
    final cycleLength = _getCycleLength();

    while (current
        .add(Duration(days: cycleLength))
        .isBefore(normalizedTarget)) {
      current = current.add(Duration(days: cycleLength));
    }

    return current;
  }

  /// Calculates the first day of the current cycle for a given date.
  ///
  /// Returns the period start date of the cycle that contains the given date.
  /// If no period start is found, returns the given date normalized.
  DateTime getCycleFirstDay(DateTime date) {
    final normalizedDate = _normalize(date);

    // Find the last period start before or on the given date
    final lastPeriodStart = _lastPeriodStartBefore(normalizedDate);

    // If no period start found, return normalized date as fallback
    if (lastPeriodStart == null) {
      return normalizedDate;
    }

    // Project to the correct cycle that contains the given date
    return _projectPeriodStart(lastPeriodStart, normalizedDate);
  }

  bool _isOvulation(DateTime date) {
    final normalizedDate = _normalize(date);
    final cycleStart = getCycleFirstDay(normalizedDate);

    // Calculate cycle length (or use default 30 days)
    final cycleLength = _getCycleLength();

    // Ovulation typically occurs around cycleLength - 14 days
    // This is approximately the middle of the cycle
    final ovulationDay = cycleStart.add(Duration(days: cycleLength - 14));

    return normalizedDate == ovulationDay;
  }

  bool _isFertile(DateTime date) {
    final normalizedDate = _normalize(date);
    final cycleStart = getCycleFirstDay(normalizedDate);

    // Calculate cycle length (or use default 30 days)
    final cycleLength = _getCycleLength();

    // Fertile window: ovulation ± 5 days
    final ovulationDay = cycleStart.add(Duration(days: cycleLength - 14));

    final fertileStart = ovulationDay.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDay.add(const Duration(days: 2));

    // Check if date is in fertile window (excluding ovulation day itself)
    return normalizedDate.isAfter(fertileStart) &&
        normalizedDate.isBefore(fertileEnd) &&
        normalizedDate != ovulationDay;
  }

  bool _isPms(DateTime date) {
    final normalizedDate = _normalize(date);
    final periodStarts = _extractPeriodStarts();

    if (periodStarts.isEmpty) {
      return false;
    }

    // Check if date is 3 days before any period start (current or future)
    final cycleLength = _getCycleLength();

    for (final periodStart in periodStarts) {
      // Check PMS for the current cycle
      final pmsStart = periodStart.subtract(const Duration(days: 3));
      final pmsEnd = periodStart.subtract(const Duration(days: 1));

      if (!normalizedDate.isBefore(pmsStart) &&
          !normalizedDate.isAfter(pmsEnd)) {
        return true;
      }

      // Check PMS for future periods
      DateTime currentPeriodStart = periodStart;
      for (int i = 0; i < 5; i++) {
        final nextPeriodStart = currentPeriodStart.add(
          Duration(days: cycleLength),
        );
        final nextPmsStart = nextPeriodStart.subtract(const Duration(days: 3));
        final nextPmsEnd = nextPeriodStart.subtract(const Duration(days: 1));

        if (!normalizedDate.isBefore(nextPmsStart) &&
            !normalizedDate.isAfter(nextPmsEnd)) {
          return true;
        }

        // If date is before this PMS window, we can stop searching
        if (normalizedDate.isBefore(nextPmsStart)) {
          break;
        }

        currentPeriodStart = nextPeriodStart;
      }
    }

    return false;
  }

  /// Debug method: Returns the extracted period starts.
  /// For debugging purposes only.
  List<DateTime> getPeriodStarts() {
    return _extractPeriodStarts();
  }

  int getCycleLength() {
    return _getCycleLength();
  }
}
