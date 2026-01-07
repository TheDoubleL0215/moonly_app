import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonly/l10n/app_localizations.dart';

class StepLegalAgreement extends StatefulWidget {
  final bool initialValue;
  final DateTime? dateOfBirth;
  final DateTime? lastPeriodStart;
  final int? cycleLength;
  final void Function(bool value) onFinish;
  final VoidCallback onBack;

  const StepLegalAgreement({
    super.key,
    required this.initialValue,
    this.dateOfBirth,
    this.lastPeriodStart,
    this.cycleLength,
    required this.onFinish,
    required this.onBack,
  });

  @override
  State<StepLegalAgreement> createState() => _StepLegalAgreementState();
}

class _StepLegalAgreementState extends State<StepLegalAgreement> {
  late bool accepted;

  @override
  void initState() {
    super.initState();
    accepted = widget.initialValue;
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
                    LucideIcons.fileCheck,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  localizations.registerPage_overviewTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  localizations.registerPage_overviewSubtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Overview section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.dateOfBirth != null)
                    Card(
                      child: ListTile(
                        leading: Icon(LucideIcons.cake),
                        title: Text(
                          localizations.registerPage_yearOfBirth,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(widget.dateOfBirth!.year.toString()),
                      ),
                    ),
                  if (widget.lastPeriodStart != null)
                    Card(
                      child: ListTile(
                        leading: Icon(LucideIcons.droplets),
                        title: Text(
                          localizations.registerPage_lastPeriodStart,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          DateFormat.yMMMMd(
                            localizations.localeName,
                          ).format(widget.lastPeriodStart!),
                        ),
                      ),
                    ),
                  Card(
                    child: ListTile(
                      leading: Icon(LucideIcons.calendarDays),
                      title: Text(
                        localizations.registerPage_cycleLength,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${widget.cycleLength!} ${localizations.registerPage_cycleLengthDays}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Card(
                      child: CheckboxListTile(
                        title: Text(
                          localizations.registerPage_acceptTerms,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          localizations.registerPage_acceptTermsDescription,
                        ),
                        value: accepted,
                        onChanged: (value) {
                          setState(() {
                            accepted = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

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
                    onPressed: accepted
                        ? () => widget.onFinish(accepted)
                        : null,
                    child: Text(
                      localizations.registerPage_finishButtonText,
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
