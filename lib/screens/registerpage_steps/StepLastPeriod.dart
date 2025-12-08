import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonly/l10n/app_localizations.dart';
import 'package:table_calendar/table_calendar.dart';

class StepLastPeriod extends StatefulWidget {
  final DateTime? initialValue;
  final void Function(DateTime value) onNext;
  final VoidCallback onBack;

  const StepLastPeriod({
    super.key,
    this.initialValue,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<StepLastPeriod> createState() => _StepLastPeriodState();
}

class _StepLastPeriodState extends State<StepLastPeriod> {
  DateTime? selectedDate;
  late DateTime focusedDay;
  late DateTime firstDay;
  late DateTime lastDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDate = widget.initialValue;
    focusedDay = selectedDate ?? now;

    firstDay = DateTime(now.year - 2, now.month, now.day);
    lastDay = DateTime(now.year, now.month, now.day);
  }

  bool isSameDaySafe(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              spacing: 12,
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Icon(
                    LucideIcons.droplets,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  localizations.registerPage_selectLastPeriodTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  localizations.registerPage_selectLastPeriodDescription,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Calendar area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TableCalendar(
              locale: localizations.localeName,
              firstDay: firstDay,
              lastDay: lastDay,
              focusedDay: focusedDay,
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) => isSameDaySafe(selectedDate, day),
              onDaySelected: (day, focus) {
                setState(() {
                  selectedDate = day;
                  focusedDay = focus;
                });
              },
              onPageChanged: (focus) {
                focusedDay = focus;
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                // Make weekends appear the same as other weekdays (default style)
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                weekendTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                outsideDaysVisible: false,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              enabledDayPredicate: (day) {
                final today = DateTime.now();
                final d = DateTime(day.year, day.month, day.day);
                final t = DateTime(today.year, today.month, today.day);
                return !d.isAfter(t); // disable future days
              },
            ),
          ),

          const Spacer(),

          // Bottom buttons (same style as first page)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: widget.onBack,
                    child: Text(
                      localizations.registerPage_backButtonText,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: selectedDate != null
                        ? () => widget.onNext(selectedDate!)
                        : null,
                    child: Text(
                      localizations.registerPage_continueButtonText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
