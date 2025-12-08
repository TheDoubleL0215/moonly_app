import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hu'),
  ];

  /// No description provided for @loginScreen_subtitle.
  ///
  /// In hu, this message translates to:
  /// **'A legbarátságosabb cikluskövető'**
  String get loginScreen_subtitle;

  /// No description provided for @loginScreen_googleLoginButtonText.
  ///
  /// In hu, this message translates to:
  /// **'Bejelentkezés Google-lal'**
  String get loginScreen_googleLoginButtonText;

  /// No description provided for @loginScreen_loadingButtonText.
  ///
  /// In hu, this message translates to:
  /// **'Bejelentkezés...'**
  String get loginScreen_loadingButtonText;

  /// No description provided for @registerPage_selectYearOfBirth.
  ///
  /// In hu, this message translates to:
  /// **'Mikor születtél?'**
  String get registerPage_selectYearOfBirth;

  /// No description provided for @registerPage_selectYearOfBirthDescription.
  ///
  /// In hu, this message translates to:
  /// **'A ciklusok idővel változhatnak, ha tudjuk hány éves vagy az segít nekünk abban, hogy az alkalmazást személyre szabjuk neked!'**
  String get registerPage_selectYearOfBirthDescription;

  /// No description provided for @registerPage_continueButtonText.
  ///
  /// In hu, this message translates to:
  /// **'Tovább'**
  String get registerPage_continueButtonText;

  /// No description provided for @registerPage_backButtonText.
  ///
  /// In hu, this message translates to:
  /// **'Vissza'**
  String get registerPage_backButtonText;

  /// No description provided for @registerPage_selectLastPeriodTitle.
  ///
  /// In hu, this message translates to:
  /// **'Mikor volt az előző menstruációd első napja?'**
  String get registerPage_selectLastPeriodTitle;

  /// No description provided for @registerPage_selectLastPeriodDescription.
  ///
  /// In hu, this message translates to:
  /// **'Így meg tudjuk határozni a következő menstruációdat'**
  String get registerPage_selectLastPeriodDescription;

  /// No description provided for @registerPage_overviewTitle.
  ///
  /// In hu, this message translates to:
  /// **'Utolsó lépés'**
  String get registerPage_overviewTitle;

  /// No description provided for @registerPage_overviewSubtitle.
  ///
  /// In hu, this message translates to:
  /// **'Tekintsd át a megadott adatokat hogy biztosan helyesek-e!'**
  String get registerPage_overviewSubtitle;

  /// No description provided for @registerPage_yearOfBirth.
  ///
  /// In hu, this message translates to:
  /// **'Születési év'**
  String get registerPage_yearOfBirth;

  /// No description provided for @registerPage_lastPeriodStart.
  ///
  /// In hu, this message translates to:
  /// **'Utolsó menstruáció kezdete'**
  String get registerPage_lastPeriodStart;

  /// No description provided for @registerPage_acceptTerms.
  ///
  /// In hu, this message translates to:
  /// **'Elfogadom a feltételeket'**
  String get registerPage_acceptTerms;

  /// No description provided for @registerPage_acceptTermsDescription.
  ///
  /// In hu, this message translates to:
  /// **'Az alkalmazás használatával elfogadom a felhasználási feltételeket és az adatvédelmi irányelveket'**
  String get registerPage_acceptTermsDescription;

  /// No description provided for @registerPage_finishButtonText.
  ///
  /// In hu, this message translates to:
  /// **'Befejezés'**
  String get registerPage_finishButtonText;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hu':
      return AppLocalizationsHu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
