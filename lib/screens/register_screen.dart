import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moonly/screens/mainpages_holder.dart';
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
  bool acceptedLegal = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  void nextStep() {
    if (_currentStep < 2) {
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
      'periodStart': lastPeriodStart,
      'acceptedLegal': acceptedLegal,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Create a new cycle in the cycles subcollection
    if (lastPeriodStart != null) {
      final cyclesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cycles');

      await cyclesRef.add({
        'startDay': Timestamp.fromDate(lastPeriodStart!),
        'cycleLength': 28,
        'periodLength': 3,
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
          StepLegalAgreement(
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
