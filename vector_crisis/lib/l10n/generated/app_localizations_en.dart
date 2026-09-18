// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vector Crisis: Arrow Puzzle';

  @override
  String get splashTagline => 'ARROW PUZZLE  •  THINK  •  ESCAPE';

  @override
  String get bootErrorTitle => 'Unable to start the app';

  @override
  String get bootErrorBody => 'Close the app and try opening it again.';

  @override
  String get retry => 'TRY AGAIN';

  @override
  String get testModeBanner => 'TEST MODE';

  @override
  String get settings => 'Settings';

  @override
  String get homeTagline =>
      'Read every arrow. Solve the order. Clear the chaos.';

  @override
  String get startNewGameTitle => 'Start a new game?';

  @override
  String get startNewGameBody =>
      'Your current progress and all stars will be erased.';

  @override
  String get cancel => 'CANCEL';

  @override
  String get newGame => 'NEW GAME';

  @override
  String continueLevel(int level) {
    return 'CONTINUE  •  LEVEL $level';
  }

  @override
  String get selectLevel => 'SELECT LEVEL';

  @override
  String get handcraftedPuzzles => '300 TRICKY PUZZLES';

  @override
  String get completed => 'COMPLETED';

  @override
  String get stars => 'STARS';

  @override
  String get unlockedLevel => 'UNLOCKED';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Choose the language used in the app';

  @override
  String get systemLanguage => 'System default';

  @override
  String get english => 'English';

  @override
  String get turkish => 'Turkish';

  @override
  String get haptics => 'Haptic feedback';

  @override
  String get hapticsSubtitle => 'Use vibration for moves';

  @override
  String get adPrivacy => 'Ad privacy preferences';

  @override
  String get adPrivacySubtitle => 'Manage consent and personalization choices';

  @override
  String get privacyUnavailable => 'Privacy options are unavailable right now.';

  @override
  String get adConfiguration => 'AD CONFIGURATION';

  @override
  String get interstitial => 'Interstitial';

  @override
  String get rewarded => 'Rewarded';

  @override
  String get adConfigurationWarning =>
      'Replace these temporary values with your AdMob ad unit IDs before release.';

  @override
  String get rewardUnavailable =>
      'The rewarded ad isn\'t ready yet. Please try again.';

  @override
  String get rewardAdLoading => 'AD IS LOADING...';

  @override
  String get rewardAlreadyUsedDescription =>
      'The extra-move rescue has already been used for this attempt. Restart and rethink the order.';

  @override
  String get gamePaused => 'GAME PAUSED';

  @override
  String get gamePausedBody => 'The board will wait for you.';

  @override
  String get resume => 'RESUME';

  @override
  String get restartLevel => 'RESTART LEVEL';

  @override
  String get mainMenu => 'MAIN MENU';

  @override
  String get homeTooltip => 'Main menu';

  @override
  String get restartTooltip => 'Restart';

  @override
  String get hintTooltip => 'Hint';

  @override
  String get noHintsRemaining => 'No hints left for this attempt.';

  @override
  String get hintRewardTitle => 'OUT OF HINTS';

  @override
  String get hintRewardDescription =>
      'Watch one optional ad to get 2 more hints for this attempt.';

  @override
  String get watchAdHints => 'WATCH AD  •  +2 HINTS';

  @override
  String get pauseTooltip => 'Pause';

  @override
  String levelNumber(int level) {
    return 'LEVEL $level';
  }

  @override
  String arrowsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ARROWS LEFT',
      one: '1 ARROW LEFT',
      zero: 'NO ARROWS LEFT',
    );
    return '$_temp0';
  }

  @override
  String arrowsAndMoves(int remaining, int moves, int limit) {
    return '$remaining ARROWS  •  $moves/$limit MOVES';
  }

  @override
  String get movesEnded => 'OUT OF MOVES';

  @override
  String get allLevelsCompleted => '300 LEVELS COMPLETE';

  @override
  String get boardClear => 'BOARD CLEAR';

  @override
  String get failedDescription =>
      'Rethink the order or watch one optional ad to continue with 3 extra moves.';

  @override
  String get allDoneDescription =>
      'You brought the entire chaos under control.';

  @override
  String completedInMoves(int moves) {
    return 'Completed in $moves moves.';
  }

  @override
  String get watchAdBonus => 'WATCH AD  •  CONTINUE +3';

  @override
  String get restart => 'RESTART';

  @override
  String get returnToMainMenu => 'RETURN TO MAIN MENU';

  @override
  String get nextLevel => 'NEXT LEVEL';

  @override
  String get frozenArrowBlocked => 'Frozen arrow: remove an adjacent arrow.';

  @override
  String get rotatorTurned => 'Rotator turned 90°.';

  @override
  String get pathBlocked => 'Path blocked.';

  @override
  String get noAvailableMove => 'No playable move right now.';

  @override
  String get hintRotate => 'Hint: rotate the orange arrow.';

  @override
  String get hintMarked => 'Hint highlighted.';

  @override
  String bonusMovesGranted(int count) {
    return '+$count moves granted!';
  }

  @override
  String bombResult(int count) {
    return 'BOOM! +$count';
  }

  @override
  String get campaignCompletedMessage => 'Campaign complete!';

  @override
  String get boardClearMessage => 'Board clear!';

  @override
  String get moveLimitReached => 'Move limit reached.';

  @override
  String get introTapArrow => 'Tap an arrow to send it off the board.';

  @override
  String get introRotator => 'Orange: turns 90° when its path is blocked.';

  @override
  String get introFrozen => 'Frozen: thaws when an adjacent arrow leaves.';

  @override
  String get introBomb => 'Red bomb: blasts adjacent arrows.';

  @override
  String get introRotatorClockwise =>
      'Orange turns clockwise while its path is blocked.';

  @override
  String get introStone =>
      'Grey stone: slides to the first obstacle and becomes a wall. Mind where it lands!';

  @override
  String get boardJammed => 'A wall closed the only way out.';

  @override
  String get boardJammedTitle => 'Board jammed';

  @override
  String get boardJammedDescription =>
      'A stone blocked a path for good. Change the order and try again.';

  @override
  String get introGear =>
      'Green gear: turns 90° after every move. Time its exit.';

  @override
  String get waited => 'Waited a move; the gears turned.';

  @override
  String get hintWait => 'Hint: wait a move to line the gears up.';

  @override
  String get waitButton => 'WAIT';
}
