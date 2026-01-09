import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moonly/l10n/app_localizations.dart';
import 'package:moonly/utils/cycle_config.dart';
import 'package:moonly/utils/cycle_phase_helper.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();

  /// Returns the color for a given cycle phase
  Color? _getColorForPhase(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstruation:
        return const Color(0xFFE56164); // Red for menstruation
      case CyclePhase.ovulation:
        return Colors.amber; // Orange for ovulation
      case CyclePhase.fertile:
        return const Color(0xFFDA93E2); // Light pink for fertile window
      case CyclePhase.pms:
        return const Color(0xFF9FA8DA); // Light purple for PMS
      case CyclePhase.none:
        return null; // No color for normal days
    }
  }

  void _showBleedingBottomSheet({
    required BuildContext context,
    required DateTime selectedDay,
    required String userId,
    required AppLocalizations loc,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      builder: (context) {
        final selectedDayNormalized = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
        );
        final bleedingDocId =
            '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';

        return StatefulBuilder(
          builder: (context, setState) {
            return StreamBuilder<DocumentSnapshot?>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('bleedings')
                  .doc(bleedingDocId)
                  .snapshots(),
              builder: (context, bleedingSnapshot) {
                // Check if bleeding document exists
                final isBleedingDay =
                    bleedingSnapshot.hasData && bleedingSnapshot.data!.exists;

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
                            final bleedingsRef = FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .collection('bleedings');

                            if (isBleedingDay) {
                              // Remove bleeding document
                              await bleedingsRef.doc(bleedingDocId).delete();
                              // Update firstStartDay and currentPeriodStart after deletion
                            } else {
                              // Add bleeding document
                              await bleedingsRef.doc(bleedingDocId).set({
                                'date': Timestamp.fromDate(
                                  selectedDayNormalized,
                                ),
                                'createdAt': FieldValue.serverTimestamp(),
                                'updatedAt': FieldValue.serverTimestamp(),
                              });
                              // Update firstStartDay and currentPeriodStart after addition
                            }
                          },
                          icon: Icon(
                            isBleedingDay
                                ? Icons.water_drop
                                : Icons.water_drop_outlined,
                            color: isBleedingDay
                                ? const Color(0xFFE56164)
                                : Colors.grey,
                          ),
                          iconSize: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.calendar_bleedingText.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            color: isBleedingDay
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
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Get averageCycleLength from user document
            int averageCycleLength = 28; // Default fallback
            int averagePeriodLength = 5; // Default fallback
            if (userSnapshot.hasData) {
              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>?;
              averageCycleLength =
                  (userData?['averageCycleLength'] as int?) ?? 28;
              averagePeriodLength =
                  (userData?['averagePeriodLength'] as int?) ?? 5;
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('bleedings')
                  .snapshots(),
              builder: (context, bleedingSnapshot) {
                if (bleedingSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Extract bleeding days from documents
                final bleedingDays = <DateTime>[];
                if (bleedingSnapshot.hasData) {
                  for (final doc in bleedingSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final dateTimestamp = data['date'] as Timestamp?;
                    if (dateTimestamp != null) {
                      final date = dateTimestamp.toDate();
                      bleedingDays.add(
                        DateTime(date.year, date.month, date.day),
                      );
                    }
                  }
                }

                // Create CyclePhaseHelper instance
                final cyclePhaseHelper = CyclePhaseHelper(
                  bleedingDays: bleedingDays,
                  cycleConfig: CycleConfig(
                    averageCycleLength: averageCycleLength,
                    averagePeriodLength: averagePeriodLength,
                  ),
                );

                return TableCalendar(
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                  ),
                  locale: loc.localeName,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  onDaySelected: (selectedDay, focusedDay) {
                    if (selectedDay.isBefore(DateTime.now())) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                      _showBleedingBottomSheet(
                        context: context,
                        selectedDay: selectedDay,
                        userId: user.uid,
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
                      final phase = cyclePhaseHelper.getPhase(date);
                      final color = _getColorForPhase(phase);

                      final dateNormalized = DateTime(
                        date.year,
                        date.month,
                        date.day,
                      );
                      final isActualBleedingDay = bleedingDays.contains(
                        dateNormalized,
                      );

                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              color ??
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            Center(
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
                            if (isActualBleedingDay)
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    todayBuilder: (context, date, _) {
                      final phase = cyclePhaseHelper.getPhase(date);
                      final color = _getColorForPhase(phase);

                      final dateNormalized = DateTime(
                        date.year,
                        date.month,
                        date.day,
                      );
                      final isActualBleedingDay = bleedingDays.contains(
                        dateNormalized,
                      );

                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              color?.withValues(alpha: 0.5) ??
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: color ?? Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
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
                            if (isActualBleedingDay)
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    outsideBuilder: (context, date, _) {
                      final phase = cyclePhaseHelper.getPhase(date);
                      final color = _getColorForPhase(phase);

                      final dateNormalized = DateTime(
                        date.year,
                        date.month,
                        date.day,
                      );
                      final isActualBleedingDay = bleedingDays.contains(
                        dateNormalized,
                      );

                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              color?.withValues(alpha: 0.3) ??
                              Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            if (isActualBleedingDay)
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  calendarStyle: CalendarStyle(outsideDaysVisible: true),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
