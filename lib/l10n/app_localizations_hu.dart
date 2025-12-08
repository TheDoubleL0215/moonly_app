// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get loginScreen_subtitle => 'A legbarátságosabb cikluskövető';

  @override
  String get loginScreen_googleLoginButtonText => 'Bejelentkezés Google-lal';

  @override
  String get loginScreen_loadingButtonText => 'Bejelentkezés...';

  @override
  String get registerPage_selectYearOfBirth => 'Mikor születtél?';

  @override
  String get registerPage_selectYearOfBirthDescription =>
      'A ciklusok idővel változhatnak, ha tudjuk hány éves vagy az segít nekünk abban, hogy az alkalmazást személyre szabjuk neked!';

  @override
  String get registerPage_continueButtonText => 'Tovább';

  @override
  String get registerPage_backButtonText => 'Vissza';

  @override
  String get registerPage_selectLastPeriodTitle =>
      'Mikor volt az előző menstruációd első napja?';

  @override
  String get registerPage_selectLastPeriodDescription =>
      'Így meg tudjuk határozni a következő menstruációdat';

  @override
  String get registerPage_overviewTitle => 'Utolsó lépés';

  @override
  String get registerPage_overviewSubtitle =>
      'Tekintsd át a megadott adatokat hogy biztosan helyesek-e!';

  @override
  String get registerPage_yearOfBirth => 'Születési év';

  @override
  String get registerPage_lastPeriodStart => 'Utolsó menstruáció kezdete';

  @override
  String get registerPage_acceptTerms => 'Elfogadom a feltételeket';

  @override
  String get registerPage_acceptTermsDescription =>
      'Az alkalmazás használatával elfogadom a felhasználási feltételeket és az adatvédelmi irányelveket';

  @override
  String get registerPage_finishButtonText => 'Befejezés';
}
