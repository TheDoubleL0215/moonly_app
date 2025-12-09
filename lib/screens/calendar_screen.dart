import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Calendar')),
        body: const Center(child: Text('Nincs bejelentkezve felhasználó')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Calendar')),
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
              onDaySelected: (day, focusedDay) {
                print(day);
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
                  final color = _getDayColor(phase);

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
                  final color = _getDayColor(phase);

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
                  final color = _getDayColor(phase);

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
                  final color = _getDayColor(phase);

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
