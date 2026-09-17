import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Vector Crisis: Arrow Puzzle'**
  String get appTitle;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'ARROW PUZZLE  •  THINK  •  ESCAPE'**
  String get splashTagline;

  /// No description provided for @bootErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to start the app'**
  String get bootErrorTitle;

  /// No description provided for @bootErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Close the app and try opening it again.'**
  String get bootErrorBody;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get retry;

  /// No description provided for @testModeBanner.
  ///
  /// In en, this message translates to:
  /// **'TEST MODE'**
  String get testModeBanner;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @homeTagline.
  ///
  /// In en, this message translates to:
  /// **'Read every arrow. Solve the order. Clear the chaos.'**
  String get homeTagline;

  /// No description provided for @startNewGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new game?'**
  String get startNewGameTitle;

  /// No description provided for @startNewGameBody.
  ///
  /// In en, this message translates to:
  /// **'Your current progress and all stars will be erased.'**
  String get startNewGameBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'NEW GAME'**
  String get newGame;

  /// No description provided for @continueLevel.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE  •  LEVEL {level}'**
  String continueLevel(int level);

  /// No description provided for @selectLevel.
  ///
  /// In en, this message translates to:
  /// **'SELECT LEVEL'**
  String get selectLevel;

  /// No description provided for @handcraftedPuzzles.
  ///
  /// In en, this message translates to:
  /// **'300 TRICKY PUZZLES'**
  String get handcraftedPuzzles;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get completed;

  /// No description provided for @stars.
  ///
  /// In en, this message translates to:
  /// **'STARS'**
  String get stars;

  /// No description provided for @unlockedLevel.
  ///
  /// In en, this message translates to:
  /// **'UNLOCKED'**
  String get unlockedLevel;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used in the app'**
  String get languageSubtitle;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get haptics;

  /// No description provided for @hapticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use vibration for moves'**
  String get hapticsSubtitle;

  /// No description provided for @adPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy preferences'**
  String get adPrivacy;

  /// No description provided for @adPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage consent and personalization choices'**
  String get adPrivacySubtitle;

  /// No description provided for @privacyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Privacy options are unavailable right now.'**
  String get privacyUnavailable;

  /// No description provided for @adConfiguration.
  ///
  /// In en, this message translates to:
  /// **'AD CONFIGURATION'**
  String get adConfiguration;

  /// No description provided for @interstitial.
  ///
  /// In en, this message translates to:
  /// **'Interstitial'**
  String get interstitial;

  /// No description provided for @rewarded.
  ///
  /// In en, this message translates to:
  /// **'Rewarded'**
  String get rewarded;

  /// No description provided for @adConfigurationWarning.
  ///
  /// In en, this message translates to:
  /// **'Replace these temporary values with your AdMob ad unit IDs before release.'**
  String get adConfigurationWarning;

  /// No description provided for @rewardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The rewarded ad isn\'t ready yet. Please try again.'**
  String get rewardUnavailable;

  /// No description provided for @gamePaused.
  ///
  /// In en, this message translates to:
  /// **'GAME PAUSED'**
  String get gamePaused;

  /// No description provided for @gamePausedBody.
  ///
  /// In en, this message translates to:
  /// **'The board will wait for you.'**
  String get gamePausedBody;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get resume;

  /// No description provided for @restartLevel.
  ///
  /// In en, this message translates to:
  /// **'RESTART LEVEL'**
  String get restartLevel;

  /// No description provided for @mainMenu.
  ///
  /// In en, this message translates to:
  /// **'MAIN MENU'**
  String get mainMenu;

  /// No description provided for @homeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Main menu'**
  String get homeTooltip;

  /// No description provided for @restartTooltip.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restartTooltip;

  /// No description provided for @hintTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hintTooltip;

  /// No description provided for @pauseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseTooltip;

  /// No description provided for @levelNumber.
  ///
  /// In en, this message translates to:
  /// **'LEVEL {level}'**
  String levelNumber(int level);

  /// No description provided for @arrowsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{NO ARROWS LEFT} =1{1 ARROW LEFT} other{{count} ARROWS LEFT}}'**
  String arrowsRemaining(int count);

  /// No description provided for @arrowsAndMoves.
  ///
  /// In en, this message translates to:
  /// **'{remaining} ARROWS  •  {moves}/{limit} MOVES'**
  String arrowsAndMoves(int remaining, int moves, int limit);

  /// No description provided for @movesEnded.
  ///
  /// In en, this message translates to:
  /// **'OUT OF MOVES'**
  String get movesEnded;

  /// No description provided for @allLevelsCompleted.
  ///
  /// In en, this message translates to:
  /// **'300 LEVELS COMPLETE'**
  String get allLevelsCompleted;

  /// No description provided for @boardClear.
  ///
  /// In en, this message translates to:
  /// **'BOARD CLEAR'**
  String get boardClear;

  /// No description provided for @failedDescription.
  ///
  /// In en, this message translates to:
  /// **'Rethink the order or watch an ad to earn 3 extra moves.'**
  String get failedDescription;

  /// No description provided for @allDoneDescription.
  ///
  /// In en, this message translates to:
  /// **'You brought the entire chaos under control.'**
  String get allDoneDescription;

  /// No description provided for @completedInMoves.
  ///
  /// In en, this message translates to:
  /// **'Completed in {moves} moves.'**
  String completedInMoves(int moves);

  /// No description provided for @watchAdBonus.
  ///
  /// In en, this message translates to:
  /// **'WATCH AD  •  +3 MOVES'**
  String get watchAdBonus;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'RESTART'**
  String get restart;

  /// No description provided for @returnToMainMenu.
  ///
  /// In en, this message translates to:
  /// **'RETURN TO MAIN MENU'**
  String get returnToMainMenu;

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'NEXT LEVEL'**
  String get nextLevel;

  /// No description provided for @frozenArrowBlocked.
  ///
  /// In en, this message translates to:
  /// **'Frozen arrow: remove an adjacent arrow.'**
  String get frozenArrowBlocked;

  /// No description provided for @rotatorTurned.
  ///
  /// In en, this message translates to:
  /// **'Rotator turned 90°.'**
  String get rotatorTurned;

  /// No description provided for @pathBlocked.
  ///
  /// In en, this message translates to:
  /// **'Path blocked.'**
  String get pathBlocked;

  /// No description provided for @noAvailableMove.
  ///
  /// In en, this message translates to:
  /// **'No playable move right now.'**
  String get noAvailableMove;

  /// No description provided for @hintRotate.
  ///
  /// In en, this message translates to:
  /// **'Hint: rotate the orange arrow.'**
  String get hintRotate;

  /// No description provided for @hintMarked.
  ///
  /// In en, this message translates to:
  /// **'Hint highlighted.'**
  String get hintMarked;

  /// No description provided for @bonusMovesGranted.
  ///
  /// In en, this message translates to:
  /// **'+{count} moves granted!'**
  String bonusMovesGranted(int count);

  /// No description provided for @bombResult.
  ///
  /// In en, this message translates to:
  /// **'BOOM! +{count}'**
  String bombResult(int count);

  /// No description provided for @campaignCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Campaign complete!'**
  String get campaignCompletedMessage;

  /// No description provided for @boardClearMessage.
  ///
  /// In en, this message translates to:
  /// **'Board clear!'**
  String get boardClearMessage;

  /// No description provided for @moveLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Move limit reached.'**
  String get moveLimitReached;

  /// No description provided for @introTapArrow.
  ///
  /// In en, this message translates to:
  /// **'Tap an arrow to send it off the board.'**
  String get introTapArrow;

  /// No description provided for @introRotator.
  ///
  /// In en, this message translates to:
  /// **'Orange: turns 90° when its path is blocked.'**
  String get introRotator;

  /// No description provided for @introFrozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen: thaws when an adjacent arrow leaves.'**
  String get introFrozen;

  /// No description provided for @introBomb.
  ///
  /// In en, this message translates to:
  /// **'Red bomb: blasts adjacent arrows.'**
  String get introBomb;

  /// No description provided for @introRotatorClockwise.
  ///
  /// In en, this message translates to:
  /// **'Orange turns clockwise while its path is blocked.'**
  String get introRotatorClockwise;

  /// No description provided for @introStone.
  ///
  /// In en, this message translates to:
  /// **'Grey stone: slides to the first obstacle and becomes a wall. Mind where it lands!'**
  String get introStone;

  /// No description provided for @boardJammed.
  ///
  /// In en, this message translates to:
  /// **'A wall closed the only way out.'**
  String get boardJammed;

  /// No description provided for @boardJammedTitle.
  ///
  /// In en, this message translates to:
  /// **'Board jammed'**
  String get boardJammedTitle;

  /// No description provided for @boardJammedDescription.
  ///
  /// In en, this message translates to:
  /// **'A stone blocked a path for good. Change the order and try again.'**
  String get boardJammedDescription;
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
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
