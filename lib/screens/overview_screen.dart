import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:moonly/ui/CycleDiagram.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  CycleInfo data = CycleInfo(
    periodStart: DateTime(2025, 1, 5),
    periodLength: 5,
    cycleLength: 28,
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CycleDiagram(cycle: data)),
    );
  }
}
