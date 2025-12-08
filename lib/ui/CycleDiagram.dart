import 'dart:math';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class CycleInfo {
  final DateTime periodStart;
  final int periodLength;
  final int cycleLength;

  CycleInfo({
    required this.periodStart,
    required this.periodLength,
    required this.cycleLength,
  });

  int get daysSinceStart => DateTime.now().difference(periodStart).inDays;

  int get dayInCycle => ((daysSinceStart % cycleLength) + 1);

  int get ovulationDay => cycleLength - 14;

  int get fertileStart => ovulationDay - 5;
  int get fertileEnd => ovulationDay;

  int get pmsStartDay => cycleLength - 7;
}

class CycleDiagram extends StatelessWidget {
  final CycleInfo cycle;

  const CycleDiagram({super.key, required this.cycle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularPercentIndicator(
            radius: 150,
            lineWidth: 20,
            percent: 0,
            backgroundColor: Color(0xFF624266),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          CircularPercentIndicator(
            radius: 150,
            lineWidth: 20,
            percent: cycle.periodLength / cycle.cycleLength,
            backgroundColor: Colors.transparent,
            progressColor: Color(0xFFE56164),
            circularStrokeCap: CircularStrokeCap.round,
            startAngle: 0,
          ),
          CircularPercentIndicator(
            radius: 150,
            lineWidth: 20,
            percent:
                (cycle.fertileEnd - cycle.fertileStart) / cycle.cycleLength,
            backgroundColor: Colors.transparent,
            progressColor: Color(0xFFDA93E2),
            circularStrokeCap: CircularStrokeCap.round,
            startAngle: 360 / cycle.cycleLength * cycle.fertileStart,
          ),

          CircularPercentIndicator(
            radius: 150,
            lineWidth: 20,
            percent:
                (cycle.pmsStartDay + 3 - cycle.pmsStartDay) / cycle.cycleLength,
            backgroundColor: Colors.transparent,
            progressColor: Color(0xFF61A7E5),
            circularStrokeCap: CircularStrokeCap.round,
            startAngle: 360 / cycle.cycleLength * cycle.pmsStartDay,
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Day ${cycle.dayInCycle}",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "of your cycle",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              ),
            ],
          ),

          _buildMarker(),
        ],
      ),
    );
  }

  Widget _buildMarker() {
    final percent = cycle.dayInCycle / cycle.cycleLength;

    final radius = 140.0;
    final angle = (percent * 360 - 90) * pi / 180;

    final dx = radius * cos(angle);
    final dy = radius * sin(angle);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(width: 8, color: Color(0xFFE56164)),
        ),
      ),
    );
  }
}
