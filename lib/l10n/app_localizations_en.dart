// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonContinue => 'CONTINUE';

  @override
  String get commonClose => 'Close';

  @override
  String length(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$value cm',
        'other': '$value\"',
      },
    );
    return '$_temp0';
  }

  @override
  String lengthApprox(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '~$value cm',
        'other': '~$value\"',
      },
    );
    return '$_temp0';
  }

  @override
  String lengthGap(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '-$value cm',
        'other': '-$value\"',
      },
    );
    return '$_temp0';
  }

  @override
  String lengthMargin(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '+$value cm',
        'other': '+$value\"',
      },
    );
    return '$_temp0';
  }

  @override
  String get introPanel1Headline => 'SEE YOUR REAL\nVERTICAL';

  @override
  String introPanel1Support(String unit) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric':
            'Film one jump. We time your flight frame by frame and turn it into centimetres — no tape measure, no guessing.',
        'other':
            'Film one jump. We time your flight frame by frame and turn it into inches — no tape measure, no guessing.',
      },
    );
    return '$_temp0';
  }

  @override
  String get introPanel2Headline => 'TRAIN WITH A\nREAL PLAN';

  @override
  String get introPanel2Support =>
      'A week-by-week program matched to your level, your schedule and the gear you actually have.';

  @override
  String get introPanel3Headline => 'WATCH THE\nINCHES ADD UP';

  @override
  String get introPanel3Support =>
      'Every jump you film and every session you finish is logged, so progress is a number instead of a feeling.';

  @override
  String get introStartCta => 'LET\'S START';

  @override
  String get goalTitle => 'WHAT\'S YOUR\nDUNK GOAL?';

  @override
  String get goalSubtitle =>
      'Pick every goal that fires you up. They go on your profile — your plan itself comes from your level, your schedule and where you train.';

  @override
  String dunkGoalTitle(String goal) {
    String _temp0 = intl.Intl.selectLogic(
      goal,
      {
        'firstDunk': 'First Dunk Ever',
        'dunkInGames': 'Dunk in Games',
        'windmillsAnd360s': 'Windmills & 360s',
        'alleyOopFinishing': 'Alley-Oop Finishing',
        'maxVertical': 'Max Vertical',
        'other': '$goal',
      },
    );
    return '$_temp0';
  }

  @override
  String dunkGoalSubtitle(String goal) {
    String _temp0 = intl.Intl.selectLogic(
      goal,
      {
        'firstDunk': 'Unlock your first slam',
        'dunkInGames': 'Finish when it counts',
        'windmillsAnd360s': 'Style and flair',
        'alleyOopFinishing': 'Catch and finish',
        'maxVertical': 'Add inches to your leap',
        'other': '$goal',
      },
    );
    return '$_temp0';
  }

  @override
  String get experienceTitle => 'HOW EXPERIENCED\nARE YOU\nWITH JUMP TRAINING?';

  @override
  String get experienceSubtitle =>
      'No ego here. Be honest so we can push you right.';

  @override
  String experienceLevelTitle(String level) {
    String _temp0 = intl.Intl.selectLogic(
      level,
      {
        'beginner': 'Beginner',
        'intermediate': 'Intermediate',
        'advanced': 'Advanced',
        'other': '$level',
      },
    );
    return '$_temp0';
  }

  @override
  String experienceLevelSubtitle(String level) {
    String _temp0 = intl.Intl.selectLogic(
      level,
      {
        'beginner': 'I\'ve got hops but no plan',
        'intermediate': 'I\'ve trained, ready to level up',
        'advanced': 'I\'m chasing inches',
        'other': '$level',
      },
    );
    return '$_temp0';
  }

  @override
  String get positionTitle => 'WHAT POSITION DO\nYOU PLAY?';

  @override
  String courtPositionLabel(String position) {
    String _temp0 = intl.Intl.selectLogic(
      position,
      {
        'pointGuard': 'Point Guard',
        'shootingGuard': 'Shooting Guard',
        'smallForward': 'Small Forward',
        'powerForward': 'Power Forward',
        'center': 'Center',
        'other': '$position',
      },
    );
    return '$_temp0';
  }

  @override
  String get daysTitle => 'HOW MANY DAYS\nPER WEEK\nCAN YOU TRAIN?';

  @override
  String get daysSubtitle =>
      'We\'ll keep it realistic. Consistency beats intensity.';

  @override
  String get daysBanner =>
      'More sessions a week means more volume — pick what you can actually keep up.';

  @override
  String get daysChipUnit => 'days';

  @override
  String get locationTitle => 'WHERE WILL YOU\nBE TRAINING?';

  @override
  String get locationSubtitle =>
      'We\'ll recommend programs that fit your setup.';

  @override
  String trainingLocationTitle(String location) {
    String _temp0 = intl.Intl.selectLogic(
      location,
      {
        'home': 'Home Only',
        'gym': 'Gym Only',
        'both': 'Both',
        'other': '$location',
      },
    );
    return '$_temp0';
  }

  @override
  String trainingLocationSubtitle(String location) {
    String _temp0 = intl.Intl.selectLogic(
      location,
      {
        'home': 'Bodyweight & minimal equipment',
        'gym': 'Full access to weights & machines',
        'both': 'Train anywhere, anytime',
        'other': '$location',
      },
    );
    return '$_temp0';
  }

  @override
  String get hopsTitle => 'WHERE ARE YOUR\nHOPS TODAY?';

  @override
  String get hopsSubtitle => 'Be honest — this sets your starting estimate.';

  @override
  String hopsLevelTitle(String level) {
    String _temp0 = intl.Intl.selectLogic(
      level,
      {
        'dunkConsistently': 'Dunk consistently',
        'dunkOnGoodDay': 'Dunk on a good day',
        'grabRim': 'Grab the rim',
        'touchRim': 'Touch the rim',
        'belowRim': 'Below the rim',
        'other': '$level',
      },
    );
    return '$_temp0';
  }

  @override
  String hopsLevelSubtitle(String level) {
    String _temp0 = intl.Intl.selectLogic(
      level,
      {
        'dunkConsistently': 'Chasing bigger finishes',
        'dunkOnGoodDay': 'It\'s in you — not consistent yet',
        'grabRim': 'Palming iron on a good day',
        'touchRim': 'Fingertips on iron',
        'belowRim': 'Building from the ground up',
        'other': '$level',
      },
    );
    return '$_temp0';
  }

  @override
  String get heightTitle => 'YOUR HEIGHT';

  @override
  String get heightSubtitle =>
      'Sets your estimated standing reach — and from it, the vert you need to dunk.';

  @override
  String heightUnitLabel(String unit) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': 'CENTIMETRES',
        'other': 'FEET & INCHES',
      },
    );
    return '$_temp0';
  }

  @override
  String heightValue(String unit, int feet, int inches, int cm) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$cm cm',
        'other': '$feet\' $inches\"',
      },
    );
    return '$_temp0';
  }

  @override
  String heightValueCompact(String unit, int feet, int inches, int cm) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$cm cm',
        'other': '$feet\'$inches\"',
      },
    );
    return '$_temp0';
  }

  @override
  String heightCmOption(int cm) {
    return '$cm cm';
  }

  @override
  String heightFeetOption(int feet) {
    return '$feet ft';
  }

  @override
  String heightInchesOption(int inches) {
    return '$inches in';
  }

  @override
  String get weightTitle => 'YOUR WEIGHT';

  @override
  String get savedToAthleteProfile => 'Saved to your athlete profile.';

  @override
  String weightUnitLabel(String unit) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': 'KG',
        'other': 'LBS',
      },
    );
    return '$_temp0';
  }

  @override
  String get ageTitle => 'YOUR AGE';

  @override
  String get ageUnitLabel => 'YEARS';

  @override
  String ageOption(int years) {
    return '$years years';
  }

  @override
  String get dunkHandTitle => 'WHICH HAND DO\nYOU DUNK WITH?';

  @override
  String get dunkHandSubtitle =>
      'It sets how much room over the rim your finish needs.';

  @override
  String dunkHandClearanceNote(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric':
            'A one-hand dunk needs the ball and one hand over the ring. Both forearms over it is about $value cm more, so a two-hand finish raises your target.',
        'other':
            'A one-hand dunk needs the ball and one hand over the ring. Both forearms over it is about $value\" more, so a two-hand finish raises your target.',
      },
    );
    return '$_temp0';
  }

  @override
  String dunkHandOptionTitle(String hand) {
    String _temp0 = intl.Intl.selectLogic(
      hand,
      {
        'left': 'Left Hand',
        'right': 'Right Hand',
        'both': 'Both Hands',
        'other': '$hand',
      },
    );
    return '$_temp0';
  }

  @override
  String dunkHandOptionSubtitle(String hand) {
    String _temp0 = intl.Intl.selectLogic(
      hand,
      {
        'left': 'One-hand finish',
        'right': 'One-hand finish',
        'both': 'Needs more room over the rim',
        'other': '$hand',
      },
    );
    return '$_temp0';
  }

  @override
  String get commitmentTitle => 'HOW COMMITTED ARE\nYOU TO YOUR GOAL?';

  @override
  String get commitmentSubtitle =>
      'This one doesn\'t change your plan. It\'s a promise to yourself — saved to your profile.';

  @override
  String commitmentLevelTitle(String level) {
    String _temp0 = intl.Intl.selectLogic(
      level,
      {
        'extremely': 'Extremely Committed',
        'very': 'Very Committed',
        'needHelp': 'I Need Help Staying Consistent',
        'other': '$level',
      },
    );
    return '$_temp0';
  }

  @override
  String commitmentLevelSubtitle(String level) {
    String _temp0 = intl.Intl.selectLogic(
      level,
      {
        'extremely': 'I\'m ready to do what it takes',
        'very': 'I want a clear plan and accountability',
        'needHelp': 'Keep me locked in week after week',
        'other': '$level',
      },
    );
    return '$_temp0';
  }

  @override
  String get gapBasedOnReach => 'BASED ON YOUR REACH + HOPS';

  @override
  String get gapBasedOnHeight => 'BASED ON YOUR HEIGHT + HOPS';

  @override
  String get gapTitle => 'HERE\'S THE GAP.';

  @override
  String get gapTitleCanDunk => 'YOU\'VE GOT THE VERTICAL.';

  @override
  String gapIntro(String unit, String height, int current, int target) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric':
            'You\'re $height. About $current cm today. Dunking usually takes ~$target cm.',
        'other':
            'You\'re $height. About $current\" today. Dunking usually takes ~$target\".',
      },
    );
    return '$_temp0';
  }

  @override
  String gapIntroCanDunk(String unit, String height, int current, int target) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric':
            'You\'re $height. About $current cm today, and dunking usually takes ~$target cm. From here the plan is about adding margin and consistency.',
        'other':
            'You\'re $height. About $current\" today, and dunking usually takes ~$target\". From here the plan is about adding margin and consistency.',
      },
    );
    return '$_temp0';
  }

  @override
  String gapTwoHandNote(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric':
            'You picked a two-hand finish, which asks for both forearms over the ring — about $value cm more than a one-hand dunk. Your target reflects that.',
        'other':
            'You picked a two-hand finish, which asks for both forearms over the ring — about $value\" more than a one-hand dunk. Your target reflects that.',
      },
    );
    return '$_temp0';
  }

  @override
  String gapEstimatedReachNote(String unit, int reach) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric':
            'Based on an estimated $reach cm standing reach from your height. Measure your real reach — in Settings any time — for an exact target.',
        'other':
            'Based on an estimated $reach\" standing reach from your height. Measure your real reach — in Settings any time — for an exact target.',
      },
    );
    return '$_temp0';
  }

  @override
  String get gapMeterToday => 'TODAY';

  @override
  String get gapMeterGap => 'EST. GAP';

  @override
  String get gapMeterMargin => 'EST. MARGIN';

  @override
  String get gapMeterDunk => 'DUNK';

  @override
  String get gapRowHeight => 'Height';

  @override
  String get gapRowStandingReach => 'Standing reach';

  @override
  String get gapRowEstToday => 'Est. today';

  @override
  String get gapRowDunkTarget => 'Dunk target';

  @override
  String get gapRowWeight => 'Weight';

  @override
  String get gapRowHops => 'Hops';

  @override
  String get gapRowGoals => 'Goals';

  @override
  String get gapGoalsSeparator => ', ';

  @override
  String get gapRowTrainingDays => 'Training days';

  @override
  String gapReachEstimatedSuffix(String unit, int reach) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$reach cm (est.)',
        'other': '$reach\" (est.)',
      },
    );
    return '$_temp0';
  }

  @override
  String gapWeightValue(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$value kg',
        'other': '$value lbs',
      },
    );
    return '$_temp0';
  }

  @override
  String gapTrainingDaysValue(int days) {
    return '$days/week';
  }

  @override
  String get gapDefaultGoal => 'Your First Dunk';

  @override
  String get gapCta => 'CLOSE THE GAP';

  @override
  String get gapCtaCanDunk => 'BUILD MORE MARGIN';

  @override
  String get potentialTitle => 'YOUR JUMP POTENTIAL';

  @override
  String get potentialSubtitle =>
      'A typical progression curve for your age, starting from today\'s estimate — not a promise. Your logged jumps will tell the real story.';

  @override
  String potentialWeekLabel(int week) {
    return 'WK $week';
  }

  @override
  String potentialWindowLabel(int weeks) {
    return 'PROJECTED $weeks-WEEK WINDOW';
  }

  @override
  String potentialFromToday(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': 'Potential from an est. ~$value cm today.',
        'other': 'Potential from an est. ~$value\" today.',
      },
    );
    return '$_temp0';
  }

  @override
  String get potentialCta => 'SEE MY PLAN';

  @override
  String get howItWorksTitle => 'HOW YOUR VERT\nGETS MEASURED';

  @override
  String get howItWorksSubtitle =>
      'No wearables, no markers on the floor. Just physics and your phone camera.';

  @override
  String get hangTimeLabel => 'HANG TIME';

  @override
  String get hangTimeDecides => 'decides your height';

  @override
  String get hangTimeFormula => 'longer in the air  =  higher jump';

  @override
  String get hangTimeNote =>
      'Two athletes with the same hang time jumped the same height. That is what we measure.';

  @override
  String get howItWorksPoint1Title => 'We watch your body, not the pixels';

  @override
  String get howItWorksPoint1Body =>
      'On-device tracking follows your feet frame by frame and finds the exact instants they leave the floor and meet it again.';

  @override
  String get howItWorksPoint2Title => 'Measured, not guessed';

  @override
  String get howItWorksPoint2Body =>
      'Your hang time gives your height through gravity alone — no camera calibration, no markers, no eyeballing.';

  @override
  String get howItWorksPoint3Title => 'A plan you can actually run';

  @override
  String get howItWorksPoint3Body =>
      'Your experience, your training days and whether you have a gym decide your programme — no barbell drills if you train at home.';

  @override
  String get howItWorksPoint4Title => 'Progress you can check';

  @override
  String get howItWorksPoint4Body =>
      'Every session and every analysed jump is logged, so the trend you see is your own history, not a motivational number.';

  @override
  String get howItWorksCta => 'START MY PLAN';

  @override
  String get buildingPlanTitle => 'BUILDING YOUR PLAN';

  @override
  String buildingPlanSubtitle(String program) {
    return 'Matching you to the $program';
  }

  @override
  String get planRevealTitle => 'HERE\'S YOUR PLAN';

  @override
  String get planRevealSubtitle =>
      'Matched to your level, your schedule and where you train.';

  @override
  String planBadgeDays(int days) {
    return '$days DAYS';
  }

  @override
  String planBadgeWeeks(int weeks) {
    return '$weeks WEEKS';
  }

  @override
  String get planThisWeek => 'THIS WEEK';

  @override
  String programDayFocus(String focus) {
    String _temp0 = intl.Intl.selectLogic(
      focus,
      {
        'Power': 'POWER',
        'Strength': 'STRENGTH',
        'Speed': 'SPEED',
        'Control': 'CONTROL',
        'other': '$focus',
      },
    );
    return '$_temp0';
  }

  @override
  String get planDayRest => 'REST';

  @override
  String get mockJumpAnalysis => 'JUMP ANALYSIS';

  @override
  String get mockEstVert => 'EST. VERT';

  @override
  String mockToDunk(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$value cm TO DUNK',
        'other': '$value\" TO DUNK',
      },
    );
    return '$_temp0';
  }

  @override
  String get mockFormScores => 'FORM SCORES';

  @override
  String get mockJumpBreakdown => 'JUMP BREAKDOWN';

  @override
  String get mockWeekDay => 'WEEK 2 · DAY 2 OF 3';

  @override
  String get mockTodayPower => 'TODAY · POWER';

  @override
  String get mockMiniBadgeDays => '3 DAYS';

  @override
  String get mockMiniBadgeGym => 'GYM';

  @override
  String get mockMiniBadgeWeeks => '8 WEEKS';

  @override
  String get mockProgress => 'PROGRESS';

  @override
  String get mockCurrentVertical => 'CURRENT VERTICAL';

  @override
  String mockSinceFirstTest(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '+$value cm SINCE FIRST TEST',
        'other': '+$value\" SINCE FIRST TEST',
      },
    );
    return '$_temp0';
  }

  @override
  String get mockWorkouts => 'WORKOUTS';

  @override
  String get mockDayStreak => 'DAY STREAK';

  @override
  String get paywallHeadline => 'GET YOUR\nFIRST DUNK.';

  @override
  String paywallPlanBuilt(int days) {
    return 'Your $days-day plan is built. Cancel anytime.';
  }

  @override
  String paywallPlanBuiltWithTrial(int days, String trial) {
    return 'Your $days-day plan is built. $trial free. Cancel anytime.';
  }

  @override
  String get paywallBenefit1Title => 'Your Vert, Measured';

  @override
  String get paywallBenefit1Body =>
      'Full jump breakdown — vert estimate, gap to your goal & coaching';

  @override
  String get paywallBenefit2Title => 'Week 1, Ready Now';

  @override
  String get paywallBenefit2Body =>
      'Your personalized plan starts the moment you unlock';

  @override
  String get paywallBenefit3Title => 'Every Inch Tracked';

  @override
  String get paywallBenefit3Body =>
      'Watch your progress toward your goal, week over week';

  @override
  String get paywallCancelAnytime => 'Cancel anytime.';

  @override
  String get paywallNoCommitment => 'No commitment required. Cancel anytime.';

  @override
  String get paywallCtaContinueWithoutPurchase => 'CONTINUE WITHOUT PURCHASE';

  @override
  String get paywallCtaUnavailable => 'UNAVAILABLE';

  @override
  String get paywallPreviewBuildNote =>
      'Preview build — purchases are not set up yet, so this unlocks the app without charging anything.';

  @override
  String get paywallDebugBuildNote => 'Debug build — nothing will be charged.';

  @override
  String get paywallNoPurchasesInBuild =>
      'Purchases are not available in this build.';

  @override
  String get paywallDisclosureNoConfig =>
      'This build has no purchase configuration, so nothing is for sale and nothing will be charged.';

  @override
  String get paywallDisclosureLoadFailed =>
      'Subscription plans could not be loaded. Nothing has been charged.';

  @override
  String get paywallDisclosureUnavailable =>
      'Purchases are unavailable in this build.';

  @override
  String get paywallPlansUnavailableTitle => 'Plans unavailable';

  @override
  String get paywallPurchasesUnavailableTitle =>
      'Purchases unavailable in this build';

  @override
  String get paywallPlansUnavailableBody =>
      'We could not reach the App Store to load subscription prices. Nothing has been charged.';

  @override
  String get paywallPurchasesUnavailableBody =>
      'This build was made without purchase credentials, so there is nothing to buy here.';

  @override
  String get paywallTryAgain => 'Try again';

  @override
  String get paywallBestValue => 'BEST VALUE';

  @override
  String paywallSavePercent(int percent) {
    return 'Save $percent%';
  }

  @override
  String get paywallViewOtherPlans => 'View other plans';

  @override
  String get paywallRestorePurchases => 'Restore Purchases';

  @override
  String get paywallPrivacy => 'Privacy';

  @override
  String get paywallTerms => 'Terms';

  @override
  String get paywallPrivacyPolicyTitle => 'Privacy Policy';

  @override
  String get paywallTermsOfUseTitle => 'Terms of Use';

  @override
  String get paywallPageNotPublished => 'This page is not published yet.';

  @override
  String paywallCouldNotOpenLegal(String title, String url) {
    return 'Could not open $title. The address is $url';
  }

  @override
  String get paywallErrorNotEntitled =>
      'That purchase went through but did not unlock DunkIt. Try Restore Purchases, or contact support — you have not lost it.';

  @override
  String get paywallErrorUnavailable =>
      'Purchases are unavailable right now. Try again later.';

  @override
  String get paywallErrorFailed =>
      'The purchase could not be completed. Check your connection and try again.';

  @override
  String get paywallErrorNothingToRestore =>
      'No active DunkIt subscription found on this Apple ID.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get weekdayInitials => 'M,T,W,T,F,S,S';

  @override
  String lengthPlus(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '+$value cm',
        'other': '+$value\"',
      },
    );
    return '$_temp0';
  }

  @override
  String get tabHome => 'HOME';

  @override
  String get tabAnalyze => 'ANALYZE';

  @override
  String get tabTrain => 'TRAIN';

  @override
  String get tabFeed => 'FEED';

  @override
  String get tabProgress => 'PROGRESS';

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get settingsLeaderboardName => 'Leaderboard name';

  @override
  String get settingsStandingReach => 'Standing reach';

  @override
  String get settingsRetakeOnboarding => 'Retake onboarding';

  @override
  String get settingsNotSet => 'Not set';

  @override
  String get retakeOnboardingTitle => 'Retake onboarding?';

  @override
  String get retakeOnboardingBody =>
      'This clears your current profile and takes you back through the quiz from the start.';

  @override
  String get retakeOnboardingConfirm => 'Retake';

  @override
  String get standingReachHowTo =>
      'Stand flat against a wall, reach one arm as high as it goes, mark your fingertips, then measure from the floor. Your dunk target is built on this number.';

  @override
  String standingReachValue(String unit, String label, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$value cm',
        'other': '$label  ·  $value in',
      },
    );
    return '$_temp0';
  }

  @override
  String standingReachEstimateNote(String label) {
    return 'Currently estimated at $label from your height.';
  }

  @override
  String homeDayCounter(int session, int total) {
    return 'DAY $session/$total';
  }

  @override
  String get homeTodayBadge => 'TODAY';

  @override
  String get homeProgramComplete => 'PROGRAM COMPLETE';

  @override
  String get homeProgramCompleteBody =>
      'You\'ve finished every session — nice work.';

  @override
  String homeFocusDay(String focus) {
    return '$focus DAY';
  }

  @override
  String homeWeekSession(int week, int session, int total) {
    return 'Week $week • Session $session/$total';
  }

  @override
  String get homeCtaViewTrain => 'VIEW TRAIN';

  @override
  String get homeCtaStartSession => 'START SESSION';

  @override
  String get homeLatestVert => 'LATEST VERT';

  @override
  String get homeDayStreak => 'DAY STREAK';

  @override
  String jumpDateShort(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String jumpDateFull(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get progressTitle => 'PROGRESS';

  @override
  String get progressTrendTitle => 'VERTICAL JUMP TREND';

  @override
  String get progressTrendEmpty => 'Log a few more jumps to see your trend';

  @override
  String get progressRecentAnalyses => 'RECENT ANALYSES';

  @override
  String get progressViewAll => 'View All';

  @override
  String get progressCurrentVertical => 'CURRENT VERTICAL';

  @override
  String progressVertUnitSuffix(String unit) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '  cm',
        'other': '  in',
      },
    );
    return '$_temp0';
  }

  @override
  String get progressLogFirstJump =>
      'Log your first jump test to start tracking';

  @override
  String get progressGoToAnalyze => 'Go to Analyze';

  @override
  String progressSinceFirstGain(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '+$value cm since your first test',
        'other': '+$value\" since your first test',
      },
    );
    return '$_temp0';
  }

  @override
  String progressSinceFirstLoss(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$value cm since your first test',
        'other': '$value\" since your first test',
      },
    );
    return '$_temp0';
  }

  @override
  String get progressSinceFirstNoChange => 'No change since your first test';

  @override
  String get progressWorkouts => 'WORKOUTS';

  @override
  String get progressCompleted => 'COMPLETED';

  @override
  String get progressRemaining => 'REMAINING';

  @override
  String get progressCompleteLabel => 'COMPLETE';

  @override
  String progressPercent(int percent) {
    return '$percent%';
  }

  @override
  String progressRemainingAndPercent(int remaining, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining REMAINING · $percent% COMPLETE',
      one: '1 REMAINING · $percent% COMPLETE',
    );
    return '$_temp0';
  }

  @override
  String get progressDayStreak => 'DAY STREAK';

  @override
  String get progressStreakDaysSuffix => '  days';

  @override
  String get jumpHistoryTitle => 'Jump History';

  @override
  String get jumpHistoryEmpty => 'No jumps logged yet.';

  @override
  String jumpVideoTitle(String unit, int value, DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$value cm · $dateString',
        'other': '$value\" · $dateString',
      },
    );
    return '$_temp0';
  }

  @override
  String get jumpVideoLoadError => 'Couldn\'t load this clip.';

  @override
  String get jumpVideoMissing => 'This clip is no longer on your device.';

  @override
  String get jumpVideoShareFailed =>
      'Couldn\'t open the share sheet. Please try again.';

  @override
  String jumpShareText(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$value cm vertical — Dunk It',
        'other': '$value\" vertical — Dunk It',
      },
    );
    return '$_temp0';
  }

  @override
  String get weekdayLabels => 'MON,TUE,WED,THU,FRI,SAT,SUN';

  @override
  String get trainTitle => 'TRAIN';

  @override
  String get trainEnrolledProgram => 'ENROLLED PROGRAM';

  @override
  String trainPositionLabel(int week, int day, int sessionsPerWeek) {
    return 'WEEK $week · DAY $day OF $sessionsPerWeek';
  }

  @override
  String trainProgramMeta(String position, int weeks) {
    return '$position • $weeks WEEKS';
  }

  @override
  String get trainDeloadPill => 'DELOAD';

  @override
  String get trainDeloadExplainer =>
      'Deload week: less volume on purpose. Lighter weeks are when the work you already did turns into new hops.';

  @override
  String trainWeekNumber(int week) {
    return 'WEEK $week';
  }

  @override
  String trainWeekSummary(int sessions, int rest) {
    return '$sessions sessions • $rest rest';
  }

  @override
  String get trainRestDayTitle => 'REST DAY';

  @override
  String get trainRestDaySubtitle => 'You\'ve already trained today.';

  @override
  String get trainRestDayBody =>
      'Jumps are built between sessions, not during them. Sleep, eat, and let the tendons recover.';

  @override
  String trainUpNext(String focus) {
    return 'Up next: $focus DAY';
  }

  @override
  String get trainTodaysExercises => 'TODAY\'S EXERCISES';

  @override
  String trainExerciseCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '$count exercise',
    );
    return '$_temp0';
  }

  @override
  String trainFocusAndWarmUp(String focus, String warmUp) {
    return '$focus • $warmUp';
  }

  @override
  String get trainDeloadVolumeNote =>
      'Volume is dialled back this week — same movements, fewer sets.';

  @override
  String get trainProgramProgress => 'PROGRAM PROGRESS';

  @override
  String get trainCtaProgramComplete => 'PROGRAM COMPLETE';

  @override
  String get trainCtaTrainAnyway => 'TRAIN ANYWAY';

  @override
  String get trainCtaStartSession => 'START TODAY\'S SESSION';

  @override
  String get warmUpHeader => 'WARM UP';

  @override
  String warmUpFocusDay(String focus) {
    return '$focus DAY';
  }

  @override
  String get warmUpDeloadNote =>
      'DELOAD WEEK — fewer sets on purpose. This is when adaptation happens.';

  @override
  String get warmUpCardLabel => 'WARM-UP';

  @override
  String get warmUpCta => 'START EXERCISES';

  @override
  String logExerciseCounter(int index, int total) {
    return 'EXERCISE $index/$total';
  }

  @override
  String get logGuideTitle => 'HOW TO DO IT';

  @override
  String logGuideSubtitle(int steps) {
    return '$steps steps, common mistakes and what it trains.';
  }

  @override
  String get logGuideNone => 'No coaching notes yet for this drill.';

  @override
  String get logSwappedForHome => 'Swapped for your home setup';

  @override
  String logSwappedForHomeReplaces(String original) {
    return 'Swapped for your home setup — replaces $original';
  }

  @override
  String logSetNumber(int number) {
    return 'SET $number';
  }

  @override
  String get logRepsHint => 'reps';

  @override
  String logWeightHint(String unit) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': 'kg (optional)',
        'other': 'lbs (optional)',
      },
    );
    return '$_temp0';
  }

  @override
  String get logValidated => 'DONE';

  @override
  String get logValidate => 'VALIDATE';

  @override
  String get logCtaFinishSession => 'FINISH SESSION';

  @override
  String get logCtaNextExercise => 'NEXT EXERCISE';

  @override
  String get logValidateEverySet => 'Validate every set to continue';

  @override
  String get sessionCompleteTitle => 'SESSION COMPLETE';

  @override
  String get sessionCompleteSubtitle => 'Nice work. Here\'s what you logged.';

  @override
  String sessionCompleteRow(String exercise, int sets, int reps) {
    return '$exercise: $sets sets, $reps reps';
  }

  @override
  String get sessionCompleteCta => 'SAVE & FINISH';

  @override
  String get sessionDiscardTitle => 'Discard this session?';

  @override
  String get sessionDiscardBody =>
      'Nothing from this session has been saved yet. If you leave now, the sets you logged are lost.';

  @override
  String get sessionDiscardConfirm => 'Discard';

  @override
  String get sessionDiscardKeep => 'Keep training';

  @override
  String get exerciseGuideHeader => 'EXERCISE GUIDE';

  @override
  String get exerciseGuideWhyItMatters => 'WHY IT MATTERS';

  @override
  String get exerciseGuideHowToDoIt => 'HOW TO DO IT';

  @override
  String get exerciseGuideCommonMistakes => 'COMMON MISTAKES';

  @override
  String get exerciseGuideWhatItTrains => 'WHAT IT TRAINS';

  @override
  String get exerciseGuideSwappedTitle => 'SWAPPED FOR YOUR HOME SETUP';

  @override
  String get exerciseGuideSwappedBody =>
      'The authored drill needs equipment you told us you do not train with. This one trains the same quality with nothing but the floor.';

  @override
  String exerciseGuideSwappedBodyNamed(String original) {
    return 'Replaces $original, which needs equipment you told us you do not train with. This one trains the same quality with nothing but the floor.';
  }

  @override
  String get exerciseGuideEmpty =>
      'No coaching notes are written for this drill yet.';

  @override
  String get exerciseGuideNoDemoTitle => 'NO DEMO CLIP YET';

  @override
  String get exerciseGuideNoDemoBody =>
      'Nothing has been filmed for this drill. The steps below are the full instruction.';

  @override
  String get exerciseGuideFramePosition => 'POSITION';

  @override
  String get exerciseGuideFrameStart => 'START';

  @override
  String get exerciseGuideFrameFinish => 'FINISH';

  @override
  String get exerciseGuideFrameDisclaimer =>
      'Reference photos, not a recording of your own jump.';

  @override
  String jumpDateMedium(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get feedTitle => 'LEADERBOARDS';

  @override
  String get feedGlobalTitle => 'ALL-TIME VERTICAL';

  @override
  String get feedGlobalSubtitle =>
      'Every DunkIt athlete, ranked by their best measured jump.';

  @override
  String get feedPersonalTitle => 'YOUR BEST JUMPS';

  @override
  String get feedPersonalSubtitle =>
      'Every jump you have analyzed, ranked by vertical.';

  @override
  String get feedNotConfiguredTitle => 'Global board is off in this build';

  @override
  String get feedNotConfiguredBody =>
      'This copy of the app was built without leaderboard credentials, so there is nothing to connect to. Everything else works offline.';

  @override
  String get feedUnavailableTitle => 'Can\'t reach the global board';

  @override
  String get feedUnavailableBody =>
      'Check your connection and pull down to try again. Your own jumps below are stored on this device and are unaffected.';

  @override
  String get feedNoAthletesTitle => 'No athletes ranked yet';

  @override
  String get feedNoAthletesBody =>
      'Nobody has posted a measured jump yet. Analyze one and you take the top spot.';

  @override
  String get feedLoading => 'Loading the global board…';

  @override
  String get feedYouBadge => 'YOU';

  @override
  String feedJumpStat(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$value cm vert',
        'other': '$value\" vert',
      },
    );
    return '$_temp0';
  }

  @override
  String feedAttemptSeparator(String attempt) {
    return ' · $attempt';
  }

  @override
  String get feedAttemptFallback => 'Jump';

  @override
  String feedGlobalStatSeparator(String height) {
    return ' · $height';
  }

  @override
  String feedRankNumber(int rank) {
    return '#$rank';
  }

  @override
  String get feedEmptyPersonalTitle => 'No jumps ranked yet';

  @override
  String get feedEmptyPersonalBody =>
      'Analyze your first jump to start your board.';

  @override
  String get feedNamePromptTitle => 'You\'re not on the board yet';

  @override
  String get feedNamePromptBody =>
      'Pick a board name and your best measured jump gets ranked with everyone else. Only the name, the vertical and your height are shared — never your clips.';

  @override
  String get feedSetBoardName => 'SET MY BOARD NAME';

  @override
  String get displayNameTitle => 'Your board name';

  @override
  String get displayNameBody =>
      'This is the only thing other athletes see. Your clips never leave this phone.';

  @override
  String get displayNameHint => 'e.g. Marcus';

  @override
  String get scoreBounce => 'BOUNCE';

  @override
  String get scorePower => 'POWER';

  @override
  String get scoreControl => 'CONTROL';

  @override
  String get scoreForm => 'FORM';

  @override
  String get analyzeTitle => 'ANALYZE';

  @override
  String get analyzeIntro =>
      'Film your jump straight-on, full body in frame. We track your feet to time the flight, then gravity gives the height — no calibration needed.';

  @override
  String get analyzePickError => 'Couldn\'t access the camera or library.';

  @override
  String get analyzeBusyCta => 'ONE SEC…';

  @override
  String get analyzeRecordCta => 'RECORD A JUMP';

  @override
  String get analyzeChooseLibrary => 'Choose from library';

  @override
  String get analyzeSkip => 'I\'ll do this later';

  @override
  String get analyzeSkipSubtitle => 'You can analyze anytime from the app.';

  @override
  String get trimTitle => 'TRIM VIDEO';

  @override
  String get trimCancel => 'CANCEL';

  @override
  String get trimHintDrag => 'Drag the handles on the timeline to trim.';

  @override
  String get trimHintRange =>
      'Start / End — adjust to one jump or dunk for best analysis.';

  @override
  String get trimStartLabel => 'START:';

  @override
  String get trimEndLabel => 'END:';

  @override
  String get trimAnalyzeCta => 'ANALYZE';

  @override
  String get trimRetake => 'Retake';

  @override
  String get trimLoadError => 'Couldn\'t load that clip.';

  @override
  String get trimTryAgain => 'TRY AGAIN';

  @override
  String get processingHeadline => 'ANALYZING';

  @override
  String get processingHeadlineAccent => ' YOUR JUMP';

  @override
  String get processingBadge => 'AI PROCESSING';

  @override
  String get processingStepTracking => 'Tracking your body through the clip';

  @override
  String get processingStepLocating => 'Finding your takeoff and landing';

  @override
  String get processingStepEstimating => 'Estimating your vertical';

  @override
  String get unmeasuredTitle => 'NO MEASUREMENT';

  @override
  String get unmeasuredSubtitle => 'We\'d rather tell you than guess a number.';

  @override
  String get unmeasuredNoWindowHeadline =>
      'We tracked you, but your feet never clearly left the floor.';

  @override
  String get unmeasuredNoWindowFix1 =>
      'Trim the clip so it holds the jump and a moment either side.';

  @override
  String get unmeasuredNoWindowFix2 =>
      'Keep your feet in frame the whole time — they are what we time.';

  @override
  String get unmeasuredNoWindowFix3 =>
      'Film from the side or straight on, not from above.';

  @override
  String get unmeasuredLostTrackHeadline =>
      'We couldn\'t keep track of your body through the clip.';

  @override
  String get unmeasuredLostTrackFix1 =>
      'Get your whole body in frame, head to feet.';

  @override
  String get unmeasuredLostTrackFix2 =>
      'More light helps — tracking struggles in a dim gym.';

  @override
  String get unmeasuredLostTrackFix3 =>
      'Avoid a busy background directly behind you.';

  @override
  String get unmeasuredGappyHeadline =>
      'We lost you in the middle of the jump itself.';

  @override
  String get unmeasuredGappyFix1 =>
      'Step back so your whole body stays in frame at the top.';

  @override
  String get unmeasuredGappyFix2 =>
      'Hold the phone still — panning up with the jump loses you.';

  @override
  String get unmeasuredGappyFix3 =>
      'Brighter light reduces the motion blur at takeoff.';

  @override
  String get unmeasuredSmallJumpHeadline =>
      'The jump in this clip is too small to time reliably.';

  @override
  String get unmeasuredSmallJumpFix1 =>
      'Trim to your best attempt if the clip holds several.';

  @override
  String get unmeasuredSmallJumpFix2 =>
      'Film a full-effort jump — a warm-up hop is below what we can time.';

  @override
  String get unmeasuredImplausibleHeadline =>
      'The flight time we measured is outside what a real jump can be.';

  @override
  String get unmeasuredImplausibleFix1 => 'Trim tightly around a single jump.';

  @override
  String get unmeasuredImplausibleFix2 =>
      'Make sure the clip plays at normal speed — slow motion breaks the timing.';

  @override
  String get unmeasuredTooShortHeadline => 'The clip is too short to read.';

  @override
  String get unmeasuredTooShortFix1 =>
      'Include a moment before the jump and after the landing.';

  @override
  String get unmeasuredUnreadableHeadline => 'We couldn\'t read this video.';

  @override
  String get unmeasuredUnreadableFix1 =>
      'Try again — if it keeps happening, record a new clip with the camera.';

  @override
  String get unmeasuredUnreadableFix2 =>
      'Videos saved from other apps sometimes can\'t be opened; one filmed on this phone will work.';

  @override
  String get unmeasuredGenericHeadline => 'We couldn\'t measure this clip.';

  @override
  String get unmeasuredGenericFix1 =>
      'Trim tightly around a single jump and try again.';

  @override
  String get unmeasuredRetrimCta => 'TRIM AND TRY AGAIN';

  @override
  String get unmeasuredNewClip => 'Use a different clip';

  @override
  String get resultTitle => 'YOUR JUMP';

  @override
  String get resultCtaAnalyzeAnother => 'ANALYZE ANOTHER JUMP';

  @override
  String get resultEstVert => 'EST. VERT';

  @override
  String resultClearsDunk(String unit, int target) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': 'That clears your $target cm dunk target',
        'other': 'That clears your $target\" dunk target',
      },
    );
    return '$_temp0';
  }

  @override
  String resultGapToDunk(String unit, int gap, int target) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$gap cm to go to your $target cm dunk target',
        'other': '$gap\" to go to your $target\" dunk target',
      },
    );
    return '$_temp0';
  }

  @override
  String resultEstimatedReachNote(String unit, int reach) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric':
            'Target assumes an estimated $reach cm standing reach. Set your real reach in Settings for an exact one.',
        'other':
            'Target assumes an estimated $reach\" standing reach. Set your real reach in Settings for an exact one.',
      },
    );
    return '$_temp0';
  }

  @override
  String resultReplacesOnboardingEstimate(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric':
            'This measurement now stands in for your onboarding estimate of ~$value cm.',
        'other':
            'This measurement now stands in for your onboarding estimate of ~$value\".',
      },
    );
    return '$_temp0';
  }

  @override
  String takeoffTypeLabel(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'oneFoot': 'One-foot takeoff',
        'twoFoot': 'Two-foot takeoff',
        'other': '$type',
      },
    );
    return '$_temp0';
  }

  @override
  String videoAttemptTypeTitle(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'dunkAttempt': 'Dunk Attempt',
        'jumpAttempt': 'Jump Attempt',
        'other': '$type',
      },
    );
    return '$_temp0';
  }

  @override
  String videoAttemptTypeSubtitle(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'dunkAttempt': 'Rim or ball in frame',
        'jumpAttempt': 'No rim needed',
        'other': '$type',
      },
    );
    return '$_temp0';
  }

  @override
  String get resultFormScoresTitle => 'FORM SCORES';

  @override
  String get resultScoresUnavailable =>
      'Scoring your form needs body tracking, and it could not follow you through this clip.';

  @override
  String get resultScoresIntro =>
      'Scored from your body in this clip — nothing is filled in where it could not be measured.';

  @override
  String get resultScoresDisclaimer =>
      'Scores rate your technique against coaching guidelines, not against other athletes.';

  @override
  String get resultNotMeasured => 'Not measured';

  @override
  String get resultNoTrackingReason => 'body tracking did not run';

  @override
  String get resultScoreDenominator => '/100';

  @override
  String resultScoreOutOf(int score) {
    return '$score/100';
  }

  @override
  String get resultBreakdownTitle => 'JUMP BREAKDOWN';

  @override
  String get resultStrongest => 'STRONGEST';

  @override
  String get resultWeakest => 'WEAKEST';

  @override
  String resultAspectCaption(String caption, String aspect) {
    return '$caption · $aspect';
  }

  @override
  String resultMeasuredPrefix(String measurement) {
    return 'Measured: $measurement';
  }

  @override
  String get resultHowToWorkOnIt => 'HOW TO WORK ON IT';

  @override
  String get resultGeneralTips => 'GENERAL TIPS TO CLOSE THE GAP';
}
