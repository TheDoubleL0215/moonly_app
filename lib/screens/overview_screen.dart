import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moonly/l10n/app_localizations.dart';
import 'package:moonly/ui/CycleDiagram.dart';

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
      body: StreamBuilder<QuerySnapshot>(
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
            return const Center(child: Text('Nincs beállítva ciklus kezdete'));
          }

          final startDay = startDayTimestamp.toDate();
          final periodLength = (cycleData['periodLength'] as int?) ?? 4;
          final cycleLength = (cycleData['cycleLength'] as int?) ?? 28;
          final cycleInfo = CycleInfo(
            periodStart: startDay,
            periodLength:
                periodLength, // Default value, can be fetched from Firestore if needed
            cycleLength:
                cycleLength, // Default value, can be fetched from Firestore if needed
          );

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
                    child: CycleDiagram(cycle: cycleInfo),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
