// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginScreen_subtitle => 'The friendliest cycle tracker';

  @override
  String get loginScreen_googleLoginButtonText => 'Sign in with Google';

  @override
  String get loginScreen_loadingButtonText => 'Signing in...';

  @override
  String get registerPage_selectYearOfBirth => 'When were you born?';

  @override
  String get registerPage_selectYearOfBirthDescription =>
      'Since cycles can change over time, this helps us tailor the app to your individual needs!';

  @override
  String get registerPage_continueButtonText => 'Continue';

  @override
  String get registerPage_backButtonText => 'Back';

  @override
  String get registerPage_selectLastPeriodTitle =>
      'When was the first day of your last period?';

  @override
  String get registerPage_selectLastPeriodDescription =>
      'This helps us determine your next period';

  @override
  String get registerPage_overviewTitle => 'Final step';

  @override
  String get registerPage_overviewSubtitle =>
      'Review the information you provided to make sure it\'s correct!';

  @override
  String get registerPage_yearOfBirth => 'Year of birth';

  @override
  String get registerPage_lastPeriodStart => 'Last period start';

  @override
  String get registerPage_acceptTerms => 'I accept the terms';

  @override
  String get registerPage_acceptTermsDescription =>
      'By using the app, I accept the terms of use and privacy policy';

  @override
  String get registerPage_finishButtonText => 'Finish';

  @override
  String get appbar_mainpageText => 'Mainpage';

  @override
  String get appbar_calendarText => 'Calendar';

  @override
  String get appbar_knowledgeText => 'Knowledge';

  @override
  String get appbar_profile => 'Profile';

  @override
  String cycleDiagramCurrentDayCounter(Object day) {
    return 'Day $day';
  }

  @override
  String cycleDiagramNextDayCounter(Object day) {
    return 'After $day days';
  }

  @override
  String get cycleDiagramPeriodCurrent => 'period';

  @override
  String get cycleDiagramOvulationCurrent => 'ovulation';

  @override
  String get cycleDiagramPmsCurrent => 'pms period';

  @override
  String get cycleDiagramFertileWindowCurrent => 'fertile window';

  @override
  String get cycleDiagramFollicularPhaseCurrent => 'follicular phase';

  @override
  String get calendar_bleedingText => 'bleeding';
}
