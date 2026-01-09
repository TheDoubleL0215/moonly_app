import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonly/l10n/app_localizations.dart';

class StepDateOfBirth extends StatefulWidget {
  final DateTime? initialValue;
  final void Function(DateTime value) onNext;

  const StepDateOfBirth({super.key, this.initialValue, required this.onNext});

  @override
  State<StepDateOfBirth> createState() => _StepDateOfBirthState();
}

class _StepDateOfBirthState extends State<StepDateOfBirth> {
  late DateTime selectedDate;
  late int selectedYear;
  late FixedExtentScrollController scrollController;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialValue ?? DateTime.now();
    selectedYear = selectedDate.year;
    final currentYear = DateTime.now().year;
    final years = List.generate(
      currentYear - 1900 + 1,
      (i) => 1900 + i,
    ).reversed.toList();
    final initialIndex = years.indexOf(selectedYear);
    scrollController = FixedExtentScrollController(
      initialItem: initialIndex >= 0 ? initialIndex : 0,
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final currentYear = DateTime.now().year;
    final years = List.generate(
      currentYear - 1900 + 1,
      (i) => 1900 + i,
    ).reversed.toList();

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              spacing: 12,
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Icon(LucideIcons.cake, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  localizations.registerPage_selectYearOfBirth,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  localizations.registerPage_selectYearOfBirthDescription,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              height: 150,
              child: Center(
                child: CupertinoPicker(
                  scrollController: scrollController,
                  itemExtent: 35,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      selectedYear = years[index];
                      selectedDate = DateTime(selectedYear, 1, 1);
                    });
                  },
                  children: years.map((year) {
                    return Center(
                      child: Text(
                        year.toString(),
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => widget.onNext(selectedDate),
                child: Text(
                  localizations.registerPage_continueButtonText,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
