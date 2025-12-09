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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Nincs elérhető adat'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final periodStart = userData['periodStart'] as Timestamp?;

          if (periodStart == null) {
            return const Center(
              child: Text('Nincs beállítva utolsó menstruáció kezdete'),
            );
          }

          final periodStartDate = periodStart.toDate();
          final cycleInfo = CycleInfo(
            periodStart: periodStartDate,
            periodLength:
                5, // Default value, can be fetched from Firestore if needed
            cycleLength:
                28, // Default value, can be fetched from Firestore if needed
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
