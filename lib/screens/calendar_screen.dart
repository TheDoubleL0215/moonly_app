import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moonly/l10n/app_localizations.dart';
import 'package:moonly/utils/cycle_utils.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  // Optimistic state for bottom sheet toggles
  final Map<String, bool> _optimisticToggleStates = {};
  final Map<String, int> _optimisticPeriodLengths = {};
  final Map<String, List<DateTime>> _optimisticBleedingDays = {};

  Color? _getDayColor(CyclePhase? phase) {
    switch (phase) {
      case CyclePhase.menstruation:
        return const Color(0xFFE56164); // Red
      case CyclePhase.ovulation:
        return Colors.amber; // Amber
      case CyclePhase.fertility:
        return const Color(0xFFDA93E2); // Pink
      case CyclePhase.pms:
        return const Color(0xFF6165E5); // Blue
      case CyclePhase.normal:
      case null:
        return null; // Default color
    }
  }

  void _showBleedingBottomSheet({
    required BuildContext context,
    required DateTime selectedDay,
    required String cycleDocId,
    required String userId,
    required DateTime startDay,
    required int periodLength,
    required int cycleLength,
    required AppLocalizations loc,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      builder: (context) {
        final selectedDayKey =
            '${selectedDay.year}-${selectedDay.month}-${selectedDay.day}';

        return StatefulBuilder(
          builder: (context, setState) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('cycles')
                  .doc(cycleDocId)
                  .snapshots(),
              builder: (context, cycleSnapshot) {
                if (!cycleSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final currentCycleData =
                    cycleSnapshot.data!.data() as Map<String, dynamic>;
                final bleedingDaysList =
                    currentCycleData['bleedingDays'] as List<dynamic>? ?? [];
                final bleedingDays = bleedingDaysList
                    .map((e) => (e as Timestamp).toDate())
                    .toList();
                final currentPeriodLength =
                    (currentCycleData['periodLength'] as int?) ?? periodLength;

                // Clear optimistic state when Firebase data updates (to sync with server)
                // This ensures that after Firebase updates, we use the server data
                if (_optimisticPeriodLengths.containsKey(selectedDayKey) &&
                    _optimisticPeriodLengths[selectedDayKey] ==
                        currentPeriodLength) {
                  _optimisticPeriodLengths.remove(selectedDayKey);
                }
                if (_optimisticBleedingDays.containsKey(selectedDayKey)) {
                  final optimisticDays =
                      _optimisticBleedingDays[selectedDayKey]!;
                  final normalizedOptimistic = optimisticDays
                      .map((d) => DateTime(d.year, d.month, d.day))
                      .toList();
                  final normalizedFirebase = bleedingDays
                      .map((d) => DateTime(d.year, d.month, d.day))
                      .toList();
                  if (normalizedOptimistic.length ==
                          normalizedFirebase.length &&
                      normalizedOptimistic.every(
                        (d) => normalizedFirebase.contains(d),
                      )) {
                    _optimisticBleedingDays.remove(selectedDayKey);
                  }
                }

                // Use optimistic values if available, otherwise use Firebase values
                final effectivePeriodLength =
                    _optimisticPeriodLengths[selectedDayKey] ??
                    currentPeriodLength;
                final effectiveBleedingDays =
                    _optimisticBleedingDays[selectedDayKey] ?? bleedingDays;

                final daysSinceStart = selectedDay.difference(startDay).inDays;
                final dayInCycle = daysSinceStart >= 0
                    ? daysSinceStart % cycleLength
                    : -1;
                final isInPeriod =
                    dayInCycle >= 0 && dayInCycle < effectivePeriodLength;

                final selectedDayNormalized = DateTime(
                  selectedDay.year,
                  selectedDay.month,
                  selectedDay.day,
                );
                final bleedingDaysNormalized = effectiveBleedingDays
                    .map((d) => DateTime(d.year, d.month, d.day))
                    .toList();
                final isBleedingDay = bleedingDaysNormalized.contains(
                  selectedDayNormalized,
                );

                // Use optimistic toggle state if available, otherwise calculate from data
                final isToggled =
                    _optimisticToggleStates[selectedDayKey] ??
                    (isInPeriod || isBleedingDay);

                return SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat(
                            'yyyy. MMMM dd.',
                            loc.localeName,
                          ).format(selectedDay),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        IconButton(
                          onPressed: () async {
                            final cycleRef = FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .collection('cycles')
                                .doc(cycleDocId);

                            // Optimistic UI update - immediately toggle the state
                            final newToggledState = !isToggled;
                            setState(() {
                              _optimisticToggleStates[selectedDayKey] =
                                  newToggledState;
                            });

                            if (isToggled) {
                              if (isInPeriod) {
                                // Shorten the period: new period length = dayInCycle
                                // This removes the deselected day and all days after it from the period
                                final newPeriodLength = dayInCycle;
                                setState(() {
                                  _optimisticPeriodLengths[selectedDayKey] =
                                      newPeriodLength;
                                  _optimisticToggleStates[selectedDayKey] =
                                      false;
                                });
                                await cycleRef.update({
                                  'periodLength': newPeriodLength,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });
                              } else if (isBleedingDay) {
                                // Remove from bleeding days if it's there
                                final updatedBleedingDays =
                                    effectiveBleedingDays.where((d) {
                                      final normalized = DateTime(
                                        d.year,
                                        d.month,
                                        d.day,
                                      );
                                      return normalized !=
                                          selectedDayNormalized;
                                    }).toList();

                                setState(() {
                                  _optimisticBleedingDays[selectedDayKey] =
                                      updatedBleedingDays;
                                  _optimisticToggleStates[selectedDayKey] =
                                      false;
                                });

                                await cycleRef.update({
                                  'bleedingDays': updatedBleedingDays
                                      .map((d) => Timestamp.fromDate(d))
                                      .toList(),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });
                              }
                            } else {
                              // Check if it's the day right after the last day of menstruation
                              final lastPeriodDay = startDay.add(
                                Duration(days: effectivePeriodLength - 1),
                              );
                              final nextDayAfterPeriod = lastPeriodDay.add(
                                const Duration(days: 1),
                              );
                              final nextDayAfterPeriodNormalized = DateTime(
                                nextDayAfterPeriod.year,
                                nextDayAfterPeriod.month,
                                nextDayAfterPeriod.day,
                              );

                              if (selectedDayNormalized ==
                                  nextDayAfterPeriodNormalized) {
                                // Extend the period
                                final newPeriodLength =
                                    effectivePeriodLength + 1;
                                setState(() {
                                  _optimisticPeriodLengths[selectedDayKey] =
                                      newPeriodLength;
                                  _optimisticToggleStates[selectedDayKey] =
                                      true;
                                });
                                await cycleRef.update({
                                  'periodLength': newPeriodLength,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });
                              } else {
                                // Check if selected day is after 7 days from start
                                final daysFromStart = selectedDay
                                    .difference(startDay)
                                    .inDays;
                                if (daysFromStart >= 7) {
                                  // Add to bleeding days array
                                  final updatedBleedingDays = [
                                    ...effectiveBleedingDays,
                                    selectedDay,
                                  ];

                                  setState(() {
                                    _optimisticBleedingDays[selectedDayKey] =
                                        updatedBleedingDays;
                                    _optimisticToggleStates[selectedDayKey] =
                                        true;
                                  });

                                  await cycleRef.update({
                                    'bleedingDays': updatedBleedingDays
                                        .map((d) => Timestamp.fromDate(d))
                                        .toList(),
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });
                                }
                              }
                            }
                          },
                          icon: Icon(
                            isToggled
                                ? Icons.water_drop
                                : Icons.water_drop_outlined,
                            color: isToggled
                                ? const Color(0xFFE56164)
                                : Colors.grey,
                          ),
                          iconSize: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc!.calendar_bleedingText.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            color: isToggled
                                ? const Color(0xFFE56164)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc!.appbar_calendarText)),
        body: const Center(child: Text('Nincs bejelentkezve felhasználó')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc!.appbar_calendarText)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cycles')
              .orderBy('startDay', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty ||
                snapshot.data!.docs.first.data() == null) {
              return const Center(child: Text('Nincs elérhető ciklus adat'));
            }

            final cycleData =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final startDayTimestamp = cycleData['startDay'] as Timestamp?;

            if (startDayTimestamp == null) {
              return const Center(
                child: Text('Nincs beállítva ciklus kezdete'),
              );
            }

            final startDay = startDayTimestamp.toDate();
            final periodLength = (cycleData['periodLength'] as int?) ?? 4;
            final cycleLength = (cycleData['cycleLength'] as int?) ?? 28;
            final ovulationStartDayTimestamp =
                cycleData['ovulationStartDay'] as Timestamp?;
            final ovulationStartDay = ovulationStartDayTimestamp?.toDate();
            final pmsStartDayTimestamp = cycleData['pmsStartDay'] as Timestamp?;
            final pmsStartDay = pmsStartDayTimestamp?.toDate();
            final bleedingDaysList =
                cycleData['bleedingDays'] as List<dynamic>? ?? [];
            final bleedingDays = bleedingDaysList
                .map((e) => (e as Timestamp).toDate())
                .map((d) => DateTime(d.year, d.month, d.day))
                .toList();

            return TableCalendar(
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
              locale: loc!.localeName,
              startingDayOfWeek: StartingDayOfWeek.monday,
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              onDaySelected: (selectedDay, focusedDay) {
                if (selectedDay.isBefore(DateTime.now())) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  final cycleDoc = snapshot.data!.docs.first;
                  final cycleDocId = cycleDoc.id;
                  _showBleedingBottomSheet(
                    context: context,
                    selectedDay: selectedDay,
                    cycleDocId: cycleDocId,
                    userId: user.uid,
                    startDay: startDay,
                    periodLength: periodLength,
                    cycleLength: cycleLength,
                    loc: loc,
                  );
                }
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, _) {
                  final phase = getCyclePhase(
                    date,
                    startDay,
                    periodLength,
                    cycleLength,
                    ovulationStartDay: ovulationStartDay,
                    pmsStartDay: pmsStartDay,
                  );
                  final dateNormalized = DateTime(
                    date.year,
                    date.month,
                    date.day,
                  );
                  final isBleedingDay = bleedingDays.contains(dateNormalized);

                  // Use lighter red for bleeding days if not in period
                  Color? color = _getDayColor(phase);
                  if (isBleedingDay && phase != CyclePhase.menstruation) {
                    color = const Color(0xFFE56164); // Lighter red
                  }

                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          color ??
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: color != null
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
                todayBuilder: (context, date, _) {
                  final phase = getCyclePhase(
                    date,
                    startDay,
                    periodLength,
                    cycleLength,
                    ovulationStartDay: ovulationStartDay,
                    pmsStartDay: pmsStartDay,
                  );
                  final dateNormalized = DateTime(
                    date.year,
                    date.month,
                    date.day,
                  );
                  final isBleedingDay = bleedingDays.contains(dateNormalized);

                  // Use lighter red for bleeding days if not in period
                  Color? color = _getDayColor(phase);
                  if (isBleedingDay && phase != CyclePhase.menstruation) {
                    color = const Color.fromARGB(
                      255,
                      107,
                      255,
                      164,
                    ).withValues(alpha: 0.6); // Lighter red
                  }

                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          color?.withValues(alpha: 0.5) ??
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: Border.all(color: color ?? Colors.grey, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: color != null
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
                selectedBuilder: (context, date, _) {
                  final phase = getCyclePhase(
                    date,
                    startDay,
                    periodLength,
                    cycleLength,
                    ovulationStartDay: ovulationStartDay,
                    pmsStartDay: pmsStartDay,
                  );
                  final dateNormalized = DateTime(
                    date.year,
                    date.month,
                    date.day,
                  );
                  final isBleedingDay = bleedingDays.contains(dateNormalized);

                  // Use lighter red for bleeding days if not in period
                  Color? color = _getDayColor(phase);
                  if (isBleedingDay && phase != CyclePhase.menstruation) {
                    color = const Color(
                      0xFFE56164,
                    ).withValues(alpha: 0.6); // Lighter red
                  }

                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color ?? Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: color != null
                              ? Colors.white
                              : Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  );
                },
                outsideBuilder: (context, date, _) {
                  final phase = getCyclePhase(
                    date,
                    startDay,
                    periodLength,
                    cycleLength,
                    ovulationStartDay: ovulationStartDay,
                    pmsStartDay: pmsStartDay,
                  );
                  final dateNormalized = DateTime(
                    date.year,
                    date.month,
                    date.day,
                  );
                  final isBleedingDay = bleedingDays.contains(dateNormalized);

                  // Use lighter red for bleeding days if not in period
                  Color? color = _getDayColor(phase);
                  if (isBleedingDay && phase != CyclePhase.menstruation) {
                    color = const Color(
                      0xFFE56164,
                    ).withValues(alpha: 0.6); // Lighter red
                  }

                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          color?.withValues(alpha: 0.3) ??
                          Theme.of(context).colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  );
                },
              ),
              calendarStyle: CalendarStyle(outsideDaysVisible: true),
            );
          },
        ),
      ),
    );
  }
}
