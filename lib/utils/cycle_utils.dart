enum CyclePhase { menstruation, ovulation, fertility, pms, normal }

CyclePhase? getCyclePhase(
  DateTime day,
  DateTime startDay,
  int periodLength,
  int cycleLength, {
  DateTime? ovulationStartDay,
  DateTime? pmsStartDay,
}) {
  final daysSinceStart = day.difference(startDay).inDays;
  if (daysSinceStart < 0) return null;

  final dayInCycle = daysSinceStart % cycleLength;

  if (dayInCycle < periodLength) {
    return CyclePhase.menstruation;
  }

  int ovulationDay;
  if (ovulationStartDay != null) {
    ovulationDay = ovulationStartDay.difference(startDay).inDays;
    ovulationDay = ovulationDay % cycleLength;
  } else {
    ovulationDay = cycleLength - (cycleLength / 2).round();
  }
  if (dayInCycle == ovulationDay) {
    return CyclePhase.ovulation;
  }

  if (dayInCycle >= ovulationDay - 2 && dayInCycle <= ovulationDay + 2) {
    return CyclePhase.fertility;
  }

  int pmsStart;
  if (pmsStartDay != null) {
    pmsStart = pmsStartDay.difference(startDay).inDays;
    pmsStart = pmsStart % cycleLength;
  } else {
    pmsStart = cycleLength - 3;
  }

  if (dayInCycle >= pmsStart) {
    return CyclePhase.pms;
  }

  return CyclePhase.normal;
}
