import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moonly/l10n/app_localizations.dart';
import 'package:moonly/utils/cycle_utils.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class CycleInfo {
  final DateTime periodStart;
  final int periodLength;
  final int cycleLength;
  final DateTime? ovulationStartDay;
  final DateTime? pmsStartDay;

  CycleInfo({
    required this.periodStart,
    required this.periodLength,
    required this.cycleLength,
    this.ovulationStartDay,
    this.pmsStartDay,
  });

  int get daysSinceStart => DateTime.now().difference(periodStart).inDays;

  int get dayInCycle => ((daysSinceStart % cycleLength) + 1);

  int get ovulationDay {
    if (ovulationStartDay != null) {
      final daysDiff = ovulationStartDay!.difference(periodStart).inDays;
      return (daysDiff % cycleLength) + 1; // Convert to 1-based
    }
    return cycleLength -
        14 +
        1; // Convert to 1-based (0-based would be cycleLength - 14)
  }

  // Fertility window: 2 days before and 2 days after ovulation (5 days total, excluding ovulation day)
  int get fertileStart => ovulationDay - 2;
  int get fertileEnd => ovulationDay + 2;

  int get pmsStartDayCalculated {
    if (pmsStartDay != null) {
      final daysDiff = pmsStartDay!.difference(periodStart).inDays;
      return (daysDiff % cycleLength) + 1; // Convert to 1-based
    }
    return cycleLength -
        3 +
        1; // Convert to 1-based (0-based would be cycleLength - 3)
  }
}

class CycleDiagram extends StatefulWidget {
  final CycleInfo cycle;
  final ValueChanged<int>? onDayChanged;

  const CycleDiagram({super.key, required this.cycle, this.onDayChanged});

  @override
  State<CycleDiagram> createState() => _CycleDiagramState();
}

class _CycleDiagramState extends State<CycleDiagram> {
  int? _draggedDay;

  CycleInfo get cycle => widget.cycle;

  int get currentDay => _draggedDay ?? cycle.dayInCycle;

  /// Calculate the DateTime for the current day in the cycle
  DateTime _getDateTimeForDay(int dayInCycle) {
    // dayInCycle is 1-based, convert to days to add
    final daysToAdd = dayInCycle - 1;
    return cycle.periodStart.add(Duration(days: daysToAdd));
  }

  CyclePhase? _getCurrentPhase() {
    // Convert 1-based currentDay to DateTime
    final currentDate = _getDateTimeForDay(currentDay);
    return getCyclePhase(
      currentDate,
      cycle.periodStart,
      cycle.periodLength,
      cycle.cycleLength,
      ovulationStartDay: cycle.ovulationStartDay,
      pmsStartDay: cycle.pmsStartDay,
    );
  }

  String _getCurrentPhaseText(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final phase = _getCurrentPhase();

    switch (phase) {
      case CyclePhase.menstruation:
        return localizations.cycleDiagramPeriodCurrent;
      case CyclePhase.ovulation:
      case CyclePhase.fertility:
        return localizations.cycleDiagramFertileWindowCurrent;
      case CyclePhase.pms:
        return localizations.cycleDiagramPmsCurrent;
      case CyclePhase.normal:
      case null:
        return localizations.cycleDiagramFollicularPhaseCurrent;
    }
  }

  Color _getCurrentPhaseColor() {
    final phase = _getCurrentPhase();

    switch (phase) {
      case CyclePhase.menstruation:
        return const Color(0xFFE56164);
      case CyclePhase.ovulation:
        return Colors.amber;
      case CyclePhase.fertility:
        return const Color(0xFFDA93E2);
      case CyclePhase.pms:
        return const Color(0xFF6165E5);
      case CyclePhase.normal:
      case null:
        return const Color(0xFF624266);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    const double indicatorRadius = 150;
    const double dotRadius = indicatorRadius - 40;
    return SizedBox(
      width: 300,
      height: 300,
      child: GestureDetector(
        onPanStart: (details) {
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final localPosition = box.globalToLocal(details.globalPosition);
            _updateDayFromPosition(localPosition);
          }
        },
        onPanUpdate: (details) {
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final localPosition = box.globalToLocal(details.globalPosition);
            _updateDayFromPosition(localPosition);
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              painter: DottedCirclePainter(
                cycleLength: cycle.cycleLength,
                dotColor: Colors.grey, // Lighter color for background dots
                radius: dotRadius,
              ),
              // We use the full size of the container for the canvas
              size: const Size(300, 300),
            ),
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
              percent: 3 / cycle.cycleLength,
              backgroundColor: Colors.transparent,
              progressColor: Color(0xFF6165E5),
              circularStrokeCap: CircularStrokeCap.round,
              startAngle:
                  360 / cycle.cycleLength * (cycle.pmsStartDayCalculated - 1),
            ),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getCurrentPhaseText(context).toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getCurrentPhaseColor() == Color(0xFF624266)
                        ? Colors.white
                        : _getCurrentPhaseColor(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    "${loc?.cycleDiagramCurrentDayCounter(currentDay)}",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),

            _buildOvulationMarker(),
            _buildTodayMarker(),
            _buildMarker(),
            _buildDraggedDateText(),
          ],
        ),
      ),
    );
  }

  void _updateDayFromPosition(Offset position) {
    const center = Offset(150, 150); // Center of the 300x300 widget
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;

    // Calculate angle from center (in radians)
    double angle = atan2(dy, dx);
    // Convert to degrees and adjust to start from top (0° = top)
    double angleDegrees = (angle * 180 / pi + 90) % 360;
    if (angleDegrees < 0) angleDegrees += 360;

    // Convert angle to day in cycle
    // 0° = day 1, 360° = day cycleLength
    int day = ((angleDegrees / 360) * cycle.cycleLength).round();
    if (day == 0) day = cycle.cycleLength;
    if (day > cycle.cycleLength) day = cycle.cycleLength;

    if (_draggedDay != day) {
      setState(() {
        _draggedDay = day;
      });
      widget.onDayChanged?.call(day);
    }
  }

  Widget _buildMarker() {
    final percent = currentDay / cycle.cycleLength;

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
          border: Border.all(width: 8, color: _getCurrentPhaseColor()),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayMarker() {
    final percent = cycle.dayInCycle / cycle.cycleLength;

    final radius = 140.0;
    final angle = (percent * 360 - 90) * pi / 180;

    final dx = radius * cos(angle);
    final dy = radius * sin(angle);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }

  Widget _buildOvulationMarker() {
    final percent = cycle.ovulationDay / cycle.cycleLength;

    final radius = 140.0;
    final angle = (percent * 360 - 90) * pi / 180;

    final dx = radius * cos(angle);
    final dy = radius * sin(angle);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.amberAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildDraggedDateText() {
    final loc = AppLocalizations.of(context);
    if (_draggedDay == null) {
      return const SizedBox.shrink();
    }

    // Don't show date if handle is on today's date
    if (_draggedDay == cycle.dayInCycle) {
      return const SizedBox.shrink();
    }

    final percent = currentDay / cycle.cycleLength;
    final angleOffset = 25;
    final angle = (percent * 360 - 90) * pi / 180;
    final degrees = angle * 180 / pi;
    final radius =
        ((degrees >= -angleOffset && degrees <= angleOffset) ||
            (degrees >= 180 - angleOffset && degrees <= 180 + angleOffset))
        ? 60.0
        : 150.0;

    // Calculate position below the marker (further from center)
    final textRadius = radius + 35.0; // Position text below the marker
    final textDx = textRadius * cos(angle);
    final textDy = textRadius * sin(angle);

    // Get the date for the dragged day
    final draggedDate = _getDateTimeForDay(_draggedDay!);
    final dateFormatter = DateFormat.MMMd(loc!.localeName).format(draggedDate);

    return Transform.translate(
      offset: Offset(textDx, textDy),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          dateFormatter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class DottedCirclePainter extends CustomPainter {
  final int cycleLength;
  final Color dotColor;
  final double radius;

  DottedCirclePainter({
    required this.cycleLength,
    required this.dotColor,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Define the center of the canvas
    final center = Offset(size.width / 2, size.height / 2);

    // 2. Define the Paint object for the dots
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    // 3. Loop through each day (dot)
    for (int i = 0; i < cycleLength; i++) {
      // Calculate the angle for the current dot.
      // We use i / cycleLength to get the fraction of the circle,
      // multiply by 2 * pi (360 degrees in radians), and subtract
      // pi / 2 to start the cycle at the top (12 o'clock position).
      final double angle = (i / cycleLength) * 2 * pi - (pi / 2);

      // Calculate the position (x, y) of the dot on the circle's circumference
      final double dx = radius * cos(angle);
      final double dy = radius * sin(angle);

      // 4. Draw the dot (a small circle)
      canvas.drawCircle(
        center + Offset(dx, dy), // Dot's position
        2.5, // Dot's size (radius)
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DottedCirclePainter oldDelegate) {
    // Repaint only if the cycle length or color changes
    return oldDelegate.cycleLength != cycleLength ||
        oldDelegate.dotColor != dotColor;
  }
}
