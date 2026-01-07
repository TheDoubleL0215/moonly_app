import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moonly/l10n/app_localizations.dart';
import 'package:moonly/ui/CycleDiagram.dart';
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
          if (userSnapshot.hasData) {
            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
            averageCycleLength =
                (userData?['averageCycleLength'] as int?) ?? 28;
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
              int periodLength = 5; // Default fallback
              CyclePhaseHelper? phaseHelper;
              if (bleedingDays.isNotEmpty) {
                phaseHelper = CyclePhaseHelper(bleedingDays: bleedingDays);
                final periodStarts = phaseHelper.getPeriodStarts();
                if (periodStarts.isNotEmpty) {
                  currentPeriodStart = periodStarts.last;
                  // Calculate period length using the helper's internal method
                  // We need to access it through a public method or calculate it ourselves
                  // For now, we'll use a simple calculation based on bleeding days
                  final sortedBleedingDays = List<DateTime>.from(bleedingDays)
                    ..sort();
                  int calculatedLength = 1; // Start with period start day
                  DateTime currentDay = currentPeriodStart;

                  while (true) {
                    final nextDay = currentDay.add(const Duration(days: 1));
                    final dayAfterNext = currentDay.add(
                      const Duration(days: 2),
                    );

                    if (sortedBleedingDays.contains(nextDay)) {
                      calculatedLength++;
                      currentDay = nextDay;
                    } else if (sortedBleedingDays.contains(dayAfterNext)) {
                      calculatedLength += 2;
                      currentDay = dayAfterNext;
                    } else {
                      break;
                    }
                  }

                  periodLength = calculatedLength.clamp(1, 10);
                }
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
                          periodLength: periodLength,
                          bleedingDays: bleedingDays,
                          currentPeriodStart: currentPeriodStart,
                          averageCycleLength: averageCycleLength,
                          phaseHelper: phaseHelper,
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
}
