enum CyclePhase { menstruation, ovulation, fertility, pms, normal }

/// Calculates the cycle phase for a given day based on cycle parameters.
///
/// [day] - The day to calculate the phase for
/// [startDay] - The first day of the cycle (menstruation start)
/// [periodLength] - Length of menstruation period in days
/// [cycleLength] - Total length of the cycle in days
/// [ovulationStartDay] - Optional specific ovulation day (overrides calculation)
/// [pmsStartDay] - Optional specific PMS start day (overrides calculation)
///
/// Returns the [CyclePhase] for the given day, or null if the day is before the cycle start.
CyclePhase? getCyclePhase(
  DateTime day,
  DateTime startDay,
  int periodLength,
  int cycleLength, {
  DateTime? ovulationStartDay,
  DateTime? pmsStartDay,
}) {
  // Calculate days since cycle start
  final daysSinceStart = day.difference(startDay).inDays;
  if (daysSinceStart < 0) return null;

  // Calculate current day in cycle (0-based for calculations)
  // This handles repeating cycles
  final dayInCycle = daysSinceStart % cycleLength;

  // Menstruation: first periodLength days of each cycle
  if (dayInCycle < periodLength) {
    return CyclePhase.menstruation;
  }

  // Ovulation phase: use provided ovulationStartDay or calculate (cycleLength - 14)
  int ovulationDay;
  if (ovulationStartDay != null) {
    // Calculate relative day in the first cycle
    ovulationDay = ovulationStartDay.difference(startDay).inDays;
    // Normalize to cycle range
    ovulationDay = ovulationDay % cycleLength;
  } else {
    // Default calculation: cycleLength - 14 (typically day 14 in a 28-day cycle)
    ovulationDay = cycleLength - 14;
  }
  if (dayInCycle == ovulationDay) {
    return CyclePhase.ovulation;
  }

  if (dayInCycle >= ovulationDay - 2 && dayInCycle <= ovulationDay + 2) {
    return CyclePhase.fertility;
  }

  // PMS: use provided pmsStartDay or calculate (cycleLength - 7)
  int pmsStart;
  if (pmsStartDay != null) {
    // Calculate relative day in the first cycle
    pmsStart = pmsStartDay.difference(startDay).inDays;
    // Normalize to cycle range
    pmsStart = pmsStart % cycleLength;
  } else {
    // Default calculation: cycleLength - 3 (typically day 25 in a 28-day cycle)
    pmsStart = cycleLength - 3;
  }

  // Check if we're in PMS period (from pmsStart to end of cycle)
  if (dayInCycle >= pmsStart) {
    return CyclePhase.pms;
  }

  return CyclePhase.normal;
}
