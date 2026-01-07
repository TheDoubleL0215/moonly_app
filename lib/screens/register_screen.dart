import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:moonly/screens/mainpages_holder.dart';
import 'package:moonly/screens/registerpage_steps/StepCycleLength.dart';
import 'package:moonly/screens/registerpage_steps/StepDate.dart';
import 'package:moonly/screens/registerpage_steps/StepLegal.dart';
import 'package:moonly/screens/registerpage_steps/SteplastPeriod.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late PageController _pageController;
  int _currentStep = 0;

  DateTime? dateOfBirth;
  DateTime? lastPeriodStart;
  int? cycleLength;

  bool acceptedLegal = false;
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  void nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> finish() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Save user data
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'yearOfBirth': dateOfBirth?.year,
      'acceptedLegal': acceptedLegal,
      'averageCycleLength': cycleLength,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Create a bleeding document with date-based ID
    if (lastPeriodStart != null) {
      final lastPeriodNormalized = DateTime(
        lastPeriodStart!.year,
        lastPeriodStart!.month,
        lastPeriodStart!.day,
      );
      final bleedingDocId =
          '${lastPeriodNormalized.year}-${lastPeriodNormalized.month.toString().padLeft(2, '0')}-${lastPeriodNormalized.day.toString().padLeft(2, '0')}';

      final bleedingsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('bleedings');

      await bleedingsRef.doc(bleedingDocId).set({
        'date': Timestamp.fromDate(lastPeriodNormalized),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPagesHolder()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // <-- disables user swipe
        children: [
          StepDateOfBirth(
            initialValue: dateOfBirth,
            onNext: (val) {
              dateOfBirth = val;
              nextStep();
            },
          ),
          StepLastPeriod(
            initialValue: lastPeriodStart,
            onNext: (val) {
              lastPeriodStart = val;
              nextStep();
            },
            onBack: prevStep,
          ),
          StepCycleLength(
            initialValue: cycleLength,
            onNext: (val) {
              cycleLength = val;
              nextStep();
            },
            onBack: prevStep,
          ),
          StepLegalAgreement(
            cycleLength: cycleLength,
            initialValue: acceptedLegal,
            dateOfBirth: dateOfBirth,
            lastPeriodStart: lastPeriodStart,
            onFinish: (val) {
              acceptedLegal = val;
              finish();
            },
            onBack: prevStep,
          ),
        ],
      ),
    );
  }
}
