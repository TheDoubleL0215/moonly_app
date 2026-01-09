import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moonly/l10n/app_localizations.dart';
import 'package:moonly/ui/CycleDiagram.dart';
import 'package:moonly/utils/cycle_config.dart';
import 'package:moonly/utils/cycle_phase_helper.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Nincs bejelentkezve felhasználó')),
      );
    }

    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
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
            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
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
              if (bleedingSnapshot.connectionState == ConnectionState.waiting) {
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
                    bleedingDays.add(DateTime(date.year, date.month, date.day));
                  }
                }
              }

              // Get cycle start date and period length from CyclePhaseHelper
              DateTime? currentPeriodStart;
              CyclePhaseHelper? phaseHelper;
              int currentCycleLength = 30; // Default fallback

              final cycleConfig = CycleConfig(
                averageCycleLength: averageCycleLength,
                averagePeriodLength: averagePeriodLength,
              );
              if (bleedingDays.isNotEmpty) {
                phaseHelper = CyclePhaseHelper(
                  bleedingDays: bleedingDays,
                  cycleConfig: cycleConfig,
                );
                currentCycleLength = phaseHelper.getCycleLength();
                currentPeriodStart = phaseHelper.getPeriodStarts().last;
              }

              // Collect phase information by looping through the cycle
              Map<String, dynamic>? phaseInfo;
              if (phaseHelper != null && currentPeriodStart != null) {
                phaseInfo = _collectPhaseInfo(
                  phaseHelper,
                  currentPeriodStart,
                  currentCycleLength,
                );
              }

              if (bleedingDays.isEmpty && currentPeriodStart == null) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text(
                      DateFormat.yMMMMd(loc?.localeName).format(DateTime.now()),
                    ),
                  ),
                  body: const Center(
                    child: Text('Nincs elérhető bleeding adat'),
                  ),
                );
              }

              return Scaffold(
                appBar: AppBar(
                  title: Text(
                    DateFormat.yMMMMd(loc?.localeName).format(DateTime.now()),
                  ),
                ),
                body: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: CycleDiagram(
                          phaseInfo: phaseInfo,
                          bleedingDays: bleedingDays,
                          currentPeriodStart: currentPeriodStart,
                          currentCycleLength: currentCycleLength,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Collects phase information by looping through the cycle from currentPeriodStart.
  /// Returns a map containing start days and durations for period, ovulation, and PMS.
  static Map<String, dynamic> _collectPhaseInfo(
    CyclePhaseHelper phaseHelper,
    DateTime currentPeriodStart,
    int cycleLength,
  ) {
    int? periodStartDay;
    int periodDuration = 0;
    int? ovulationStartDay;
    int ovulationDuration = 0;
    int? pmsStartDay;
    int pmsDuration = 0;

    // Loop through the cycle, starting from currentPeriodStart
    for (int day = 0; day < cycleLength; day++) {
      final currentDate = currentPeriodStart.add(Duration(days: day));
      final currentPhase = phaseHelper.getPhase(currentDate);
      final dayInCycle = day + 1; // 1-based day in cycle

      // Track period
      if (currentPhase == CyclePhase.menstruation) {
        periodStartDay ??= dayInCycle;
        periodDuration++;
      }

      // Track ovulation (single day)
      if (currentPhase == CyclePhase.ovulation) {
        ovulationStartDay ??= dayInCycle;
        ovulationDuration = 1;
      }

      // Track PMS
      if (currentPhase == CyclePhase.pms) {
        pmsStartDay ??= dayInCycle;
        pmsDuration++;
      }
    }

    return {
      'period': {
        'startDay': periodStartDay != null ? periodStartDay - 1 : null,
        'duration': periodDuration,
      },
      'ovulation': {
        'startDay': ovulationStartDay != null ? ovulationStartDay - 1 : null,
        'duration': ovulationDuration,
      },
      'pms': {
        'startDay': pmsStartDay != null ? pmsStartDay - 1 : null,
        'duration': pmsDuration,
      },
    };
  }
}
