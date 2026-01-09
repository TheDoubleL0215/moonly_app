import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonly/l10n/app_localizations.dart';

class StepPeriodLength extends StatefulWidget {
  final int? initialValue;
  final void Function(int? value) onNext;
  final VoidCallback onBack;

  const StepPeriodLength({
    super.key,
    this.initialValue,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<StepPeriodLength> createState() => _StepPeriodLengthState();
}

class _StepPeriodLengthState extends State<StepPeriodLength> {
  bool _isUnknownSelected = false;
  int _periodLength = 5;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _periodLength = widget.initialValue!;
    }
  }

  void _increment() {
    setState(() {
      _isUnknownSelected = false;
      if (_periodLength < 10) {
        _periodLength++;
      }
    });
  }

  void _decrement() {
    setState(() {
      _isUnknownSelected = false;
      if (_periodLength > 1) {
        _periodLength--;
      }
    });
  }

  void _handleUnknownSelected() {
    setState(() {
      _isUnknownSelected = true;
      _periodLength = 5;
    });
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
                  localizations.registerPage_selectPeriodLengthTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  localizations.registerPage_selectPeriodLengthDescription,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Counter with increment/decrement buttons
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSecondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decrement button
                      IconButton(
                        onPressed: _decrement,
                        icon: Icon(LucideIcons.minus),
                        iconSize: 32,
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Counter display
                      Opacity(
                        opacity: _isUnknownSelected ? 0.75 : 1,
                        child: Column(
                          children: [
                            Text(
                              '$_periodLength',
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 64,
                                  ),
                            ),
                            Text(
                              localizations.registerPage_periodLengthDays,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Increment button
                      IconButton(
                        onPressed: _increment,
                        icon: Icon(LucideIcons.plus),
                        iconSize: 32,
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // "I don't know" option
                OutlinedButton(
                  onPressed: _handleUnknownSelected,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: BorderSide(
                      color: _isUnknownSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: _isUnknownSelected ? 2 : 1,
                    ),
                    backgroundColor: _isUnknownSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: Text(
                    localizations.registerPage_periodLengthUnknown,
                    style: TextStyle(
                      fontSize: 16,
                      color: _isUnknownSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: _isUnknownSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isUnknownSelected)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                localizations.registerPage_periodLengthDefaultInfo,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const Spacer(),
          // Bottom buttons
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
                      style: const TextStyle(fontSize: 18),
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
                    onPressed: () => widget.onNext(_periodLength),
                    child: Text(
                      localizations.registerPage_continueButtonText,
                      style: const TextStyle(
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
