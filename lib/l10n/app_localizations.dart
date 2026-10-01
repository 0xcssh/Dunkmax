import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('fr')
  ];

  /// Default label of the pinned primary CTA at the bottom of every onboarding quiz step, and of the plan-reveal screen's CTA.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get commonContinue;

  /// Dismiss button of the small alert shown on the paywall when a legal page is not published yet.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// A length (a vertical, a standing reach, a dunk target) with its unit: the standing-reach and dunk-target values in the onboarding gap screen's summary rows, the big number on the Analyze result and Progress cards, the badge on a jump thumbnail, the trend chart's gridlines, the standing-reach value in Settings. {unit} is 'metric' (value is whole centimetres) or 'imperial' (value is whole inches); the value is already converted. In locales that do not use the inch symbol, spell the imperial unit out.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{{value} cm} other{{value}\"}}'**
  String length(String unit, int value);

  /// An approximate length, used for the big TODAY and DUNK numbers on the onboarding gap meter and the projected vertical on the jump-potential screen. {unit} is 'metric' (centimetres) or 'imperial' (inches); the value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{~{value} cm} other{~{value}\"}}'**
  String lengthApprox(String unit, int value);

  /// The length still missing to dunk, shown as the middle EST. GAP number on the onboarding gap meter. The leading minus is part of the design. {unit} is 'metric' (centimetres) or 'imperial' (inches); the value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{-{value} cm} other{-{value}\"}}'**
  String lengthGap(String unit, int value);

  /// The vertical an athlete has beyond what a dunk needs, shown as the middle EST. MARGIN number on the onboarding gap meter in place of the gap, only when they are estimated to already clear the dunk. The leading plus is part of the design. {unit} is 'metric' (centimetres) or 'imperial' (inches); the value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{+{value} cm} other{+{value}\"}}'**
  String lengthMargin(String unit, int value);

  /// Headline of the first panel of the opening intro carousel. The line break is deliberate — keep two short lines.
  ///
  /// In en, this message translates to:
  /// **'SEE YOUR REAL\nVERTICAL'**
  String get introPanel1Headline;

  /// Supporting paragraph under the first intro carousel headline (jump analysis). {unit} is 'metric' (the app will show centimetres) or 'imperial' (inches).
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{Film one jump. We time your flight frame by frame and turn it into centimetres — no tape measure, no guessing.} other{Film one jump. We time your flight frame by frame and turn it into inches — no tape measure, no guessing.}}'**
  String introPanel1Support(String unit);

  /// Headline of the second panel of the intro carousel (training plan). Keep two short lines.
  ///
  /// In en, this message translates to:
  /// **'TRAIN WITH A\nREAL PLAN'**
  String get introPanel2Headline;

  /// Supporting paragraph under the second intro carousel headline.
  ///
  /// In en, this message translates to:
  /// **'A week-by-week program matched to your level, your schedule and the gear you actually have.'**
  String get introPanel2Support;

  /// Headline of the third panel of the intro carousel (progress tracking). Keep two short lines.
  ///
  /// In en, this message translates to:
  /// **'WATCH THE\nINCHES ADD UP'**
  String get introPanel3Headline;

  /// Supporting paragraph under the third intro carousel headline.
  ///
  /// In en, this message translates to:
  /// **'Every jump you film and every session you finish is logged, so progress is a number instead of a feeling.'**
  String get introPanel3Support;

  /// Button at the bottom of the intro carousel that opens the first quiz question.
  ///
  /// In en, this message translates to:
  /// **'LET\'S START'**
  String get introStartCta;

  /// Title of onboarding quiz question 1 (dunk goal, multi-select).
  ///
  /// In en, this message translates to:
  /// **'WHAT\'S YOUR\nDUNK GOAL?'**
  String get goalTitle;

  /// Subtitle of onboarding quiz question 1 (dunk goal). Goals are stored and shown back but never reach the program catalog, so this must not promise a goal-shaped plan.
  ///
  /// In en, this message translates to:
  /// **'Pick every goal that fires you up. They go on your profile — your plan itself comes from your level, your schedule and where you train.'**
  String get goalSubtitle;

  /// Title of one goal card on onboarding quiz question 1, and of each goal listed in the gap screen's Goals row. Keyed on the DunkGoal enum name from core/models/dunk_goal.dart (whose English getters stay for tests).
  ///
  /// In en, this message translates to:
  /// **'{goal, select, firstDunk{First Dunk Ever} dunkInGames{Dunk in Games} windmillsAnd360s{Windmills & 360s} alleyOopFinishing{Alley-Oop Finishing} maxVertical{Max Vertical} other{{goal}}}'**
  String dunkGoalTitle(String goal);

  /// Subtitle of one goal card on onboarding quiz question 1. Keyed on the DunkGoal enum name.
  ///
  /// In en, this message translates to:
  /// **'{goal, select, firstDunk{Unlock your first slam} dunkInGames{Finish when it counts} windmillsAnd360s{Style and flair} alleyOopFinishing{Catch and finish} maxVertical{Add inches to your leap} other{{goal}}}'**
  String dunkGoalSubtitle(String goal);

  /// Title of onboarding quiz question 2 (jump-training experience). Three short lines.
  ///
  /// In en, this message translates to:
  /// **'HOW EXPERIENCED\nARE YOU\nWITH JUMP TRAINING?'**
  String get experienceTitle;

  /// Subtitle of onboarding quiz question 2 (experience).
  ///
  /// In en, this message translates to:
  /// **'No ego here. Be honest so we can push you right.'**
  String get experienceSubtitle;

  /// Title of one card on onboarding quiz question 2. Keyed on the ExperienceLevel enum name from core/models/experience_level.dart (whose English getters stay for tests).
  ///
  /// In en, this message translates to:
  /// **'{level, select, beginner{Beginner} intermediate{Intermediate} advanced{Advanced} other{{level}}}'**
  String experienceLevelTitle(String level);

  /// Subtitle of one card on onboarding quiz question 2. Keyed on the ExperienceLevel enum name.
  ///
  /// In en, this message translates to:
  /// **'{level, select, beginner{I\'ve got hops but no plan} intermediate{I\'ve trained, ready to level up} advanced{I\'m chasing inches} other{{level}}}'**
  String experienceLevelSubtitle(String level);

  /// Title of onboarding quiz question 3 (basketball position on court).
  ///
  /// In en, this message translates to:
  /// **'WHAT POSITION DO\nYOU PLAY?'**
  String get positionTitle;

  /// Name of one basketball position card on onboarding quiz question 3. Keyed on the CourtPosition enum name from core/models/court_position.dart.
  ///
  /// In en, this message translates to:
  /// **'{position, select, pointGuard{Point Guard} shootingGuard{Shooting Guard} smallForward{Small Forward} powerForward{Power Forward} center{Center} other{{position}}}'**
  String courtPositionLabel(String position);

  /// Title of onboarding quiz question 4 (training days per week). Three short lines.
  ///
  /// In en, this message translates to:
  /// **'HOW MANY DAYS\nPER WEEK\nCAN YOU TRAIN?'**
  String get daysTitle;

  /// Subtitle of onboarding quiz question 4 (days per week).
  ///
  /// In en, this message translates to:
  /// **'We\'ll keep it realistic. Consistency beats intensity.'**
  String get daysSubtitle;

  /// Highlighted note above the day-count chips on onboarding quiz question 4. Deliberately claims no measured result — do not add statistics.
  ///
  /// In en, this message translates to:
  /// **'More sessions a week means more volume — pick what you can actually keep up.'**
  String get daysBanner;

  /// Lowercase unit printed under the big number inside each day-count chip on onboarding quiz question 4.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysChipUnit;

  /// Title of onboarding quiz question 5 (home / gym / both).
  ///
  /// In en, this message translates to:
  /// **'WHERE WILL YOU\nBE TRAINING?'**
  String get locationTitle;

  /// Subtitle of onboarding quiz question 5 (training location).
  ///
  /// In en, this message translates to:
  /// **'We\'ll recommend programs that fit your setup.'**
  String get locationSubtitle;

  /// Title of one card on onboarding quiz question 5, and (upper-cased) the location badge on the plan-reveal program card. Keyed on the TrainingLocation enum name from core/models/training_location.dart.
  ///
  /// In en, this message translates to:
  /// **'{location, select, home{Home Only} gym{Gym Only} both{Both} other{{location}}}'**
  String trainingLocationTitle(String location);

  /// Subtitle of one card on onboarding quiz question 5. Keyed on the TrainingLocation enum name.
  ///
  /// In en, this message translates to:
  /// **'{location, select, home{Bodyweight & minimal equipment} gym{Full access to weights & machines} both{Train anywhere, anytime} other{{location}}}'**
  String trainingLocationSubtitle(String location);

  /// Title of onboarding quiz question 6 (current jumping ability, from below-rim to dunking consistently). 'Hops' is basketball slang for jumping ability.
  ///
  /// In en, this message translates to:
  /// **'WHERE ARE YOUR\nHOPS TODAY?'**
  String get hopsTitle;

  /// Subtitle of onboarding quiz question 6 (current hops). It must not promise more than the answer does: hops only sets the estimated vertical and the gap, not the programme.
  ///
  /// In en, this message translates to:
  /// **'Be honest — this sets your starting estimate.'**
  String get hopsSubtitle;

  /// Title of one rung on onboarding quiz question 6 (current hops), and the value of the gap screen's Hops row. Keyed on the HopsLevel enum name from core/models/hops_level.dart (whose English getters stay for tests).
  ///
  /// In en, this message translates to:
  /// **'{level, select, dunkConsistently{Dunk consistently} dunkOnGoodDay{Dunk on a good day} grabRim{Grab the rim} touchRim{Touch the rim} belowRim{Below the rim} other{{level}}}'**
  String hopsLevelTitle(String level);

  /// Subtitle of one rung on onboarding quiz question 6. Keyed on the HopsLevel enum name.
  ///
  /// In en, this message translates to:
  /// **'{level, select, dunkConsistently{Chasing bigger finishes} dunkOnGoodDay{It\'s in you — not consistent yet} grabRim{Palming iron on a good day} touchRim{Fingertips on iron} belowRim{Building from the ground up} other{{level}}}'**
  String hopsLevelSubtitle(String level);

  /// Title of onboarding quiz question 7 (height, picked on two wheels).
  ///
  /// In en, this message translates to:
  /// **'YOUR HEIGHT'**
  String get heightTitle;

  /// Subtitle of onboarding quiz question 7 (height). Height only feeds the estimated standing reach (height x 1.33) and hence the dunk target; it does not touch the jump analysis or the program, so do not claim either. 'Vert' is short for vertical jump.
  ///
  /// In en, this message translates to:
  /// **'Sets your estimated standing reach — and from it, the vert you need to dunk.'**
  String get heightSubtitle;

  /// Small caps label under the big height readout on onboarding quiz question 7. {unit} is 'metric' (one centimetre wheel) or 'imperial' (feet and inches wheels).
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{CENTIMETRES} other{FEET & INCHES}}'**
  String heightUnitLabel(String unit);

  /// The big height readout on onboarding quiz question 7. {unit} is 'metric' (only {cm} is set) or 'imperial' (only {feet} and {inches} are set; the unused numbers are zero).
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{{cm} cm} other{{feet}\' {inches}\"}}'**
  String heightValue(String unit, int feet, int inches, int cm);

  /// The athlete's height written inline in running text, e.g. in the onboarding gap screen's opening sentence and its summary list, and on a global leaderboard row. Tighter than heightValue, which sits alone on a picker. {unit} is 'metric' (only {cm} is set) or 'imperial' (only {feet} and {inches} are set; the unused numbers are zero).
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{{cm} cm} other{{feet}\'{inches}\"}}'**
  String heightValueCompact(String unit, int feet, int inches, int cm);

  /// One entry of the centimetre wheel on onboarding quiz question 7 (metric regions only).
  ///
  /// In en, this message translates to:
  /// **'{cm} cm'**
  String heightCmOption(int cm);

  /// One entry of the feet wheel on onboarding quiz question 7.
  ///
  /// In en, this message translates to:
  /// **'{feet} ft'**
  String heightFeetOption(int feet);

  /// One entry of the inches wheel on onboarding quiz question 7.
  ///
  /// In en, this message translates to:
  /// **'{inches} in'**
  String heightInchesOption(int inches);

  /// Title of onboarding quiz question 8 (body weight slider).
  ///
  /// In en, this message translates to:
  /// **'YOUR WEIGHT'**
  String get weightTitle;

  /// Subtitle shared by onboarding quiz questions 3 (position), 8 (weight) and 9 (age): the answer is stored but does not change the program.
  ///
  /// In en, this message translates to:
  /// **'Saved to your athlete profile.'**
  String get savedToAthleteProfile;

  /// Small caps unit under the big weight readout on onboarding quiz question 8. {unit} is 'metric' (kilograms) or 'imperial' (pounds).
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{KG} other{LBS}}'**
  String weightUnitLabel(String unit);

  /// Title of onboarding quiz question 9 (age wheel).
  ///
  /// In en, this message translates to:
  /// **'YOUR AGE'**
  String get ageTitle;

  /// Small caps unit under the big age readout on onboarding quiz question 9.
  ///
  /// In en, this message translates to:
  /// **'YEARS'**
  String get ageUnitLabel;

  /// One entry of the age wheel on onboarding quiz question 9.
  ///
  /// In en, this message translates to:
  /// **'{years} years'**
  String ageOption(int years);

  /// Title of onboarding quiz question 10 (left / right / both hands).
  ///
  /// In en, this message translates to:
  /// **'WHICH HAND DO\nYOU DUNK WITH?'**
  String get dunkHandTitle;

  /// Subtitle of onboarding quiz question 10. Deliberately does NOT promise an approach-angle analysis — nothing in the app analyses approach angle.
  ///
  /// In en, this message translates to:
  /// **'It sets how much room over the rim your finish needs.'**
  String get dunkHandSubtitle;

  /// Footnote under the hand cards on onboarding quiz question 10, explaining why a two-hand finish raises the required vertical. {unit} is 'metric' ({value} in centimetres) or 'imperial' ({value} in inches); the value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{A one-hand dunk needs the ball and one hand over the ring. Both forearms over it is about {value} cm more, so a two-hand finish raises your target.} other{A one-hand dunk needs the ball and one hand over the ring. Both forearms over it is about {value}\" more, so a two-hand finish raises your target.}}'**
  String dunkHandClearanceNote(String unit, int value);

  /// Title of one hand card on onboarding quiz question 10. Keyed on the DunkHand enum name from core/models/dunk_hand.dart.
  ///
  /// In en, this message translates to:
  /// **'{hand, select, left{Left Hand} right{Right Hand} both{Both Hands} other{{hand}}}'**
  String dunkHandOptionTitle(String hand);

  /// Caption of one hand card on onboarding quiz question 10. The left/right cards are square with a fixed height, so keep those two to one short line. Keyed on the DunkHand enum name.
  ///
  /// In en, this message translates to:
  /// **'{hand, select, left{One-hand finish} right{One-hand finish} both{Needs more room over the rim} other{{hand}}}'**
  String dunkHandOptionSubtitle(String hand);

  /// Title of onboarding quiz question 11 (commitment level).
  ///
  /// In en, this message translates to:
  /// **'HOW COMMITTED ARE\nYOU TO YOUR GOAL?'**
  String get commitmentTitle;

  /// Subtitle of onboarding quiz question 11 (commitment). The answer is stored and nothing reads it, so this must neither promise an adapted plan nor claim a result about committed athletes (there is no data behind such a claim).
  ///
  /// In en, this message translates to:
  /// **'This one doesn\'t change your plan. It\'s a promise to yourself — saved to your profile.'**
  String get commitmentSubtitle;

  /// Title of one card on onboarding quiz question 11. Keyed on the CommitmentLevel enum name from core/models/commitment_level.dart.
  ///
  /// In en, this message translates to:
  /// **'{level, select, extremely{Extremely Committed} very{Very Committed} needHelp{I Need Help Staying Consistent} other{{level}}}'**
  String commitmentLevelTitle(String level);

  /// Subtitle of one card on onboarding quiz question 11. Keyed on the CommitmentLevel enum name.
  ///
  /// In en, this message translates to:
  /// **'{level, select, extremely{I\'m ready to do what it takes} very{I want a clear plan and accountability} needHelp{Keep me locked in week after week} other{{level}}}'**
  String commitmentLevelSubtitle(String level);

  /// Eyebrow label above the gap headline, shown when the athlete has entered a measured standing reach.
  ///
  /// In en, this message translates to:
  /// **'BASED ON YOUR REACH + HOPS'**
  String get gapBasedOnReach;

  /// Eyebrow label above the gap headline, shown when the standing reach is still estimated from height.
  ///
  /// In en, this message translates to:
  /// **'BASED ON YOUR HEIGHT + HOPS'**
  String get gapBasedOnHeight;

  /// Headline of the first onboarding sell screen: how many inches are missing to dunk.
  ///
  /// In en, this message translates to:
  /// **'HERE\'S THE GAP.'**
  String get gapTitle;

  /// Headline of the first onboarding sell screen, replacing the 'here's the gap' headline when the athlete's estimated vertical already meets what a dunk needs, so there is no gap to show.
  ///
  /// In en, this message translates to:
  /// **'YOU\'VE GOT THE VERTICAL.'**
  String get gapTitleCanDunk;

  /// Paragraph under the gap headline. {height} is already formatted like 6'1" or 185 cm; {current} and {target} are verticals, already converted to the athlete's unit: {unit} is 'metric' (centimetres) or 'imperial' (inches).
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{You\'re {height}. About {current} cm today. Dunking usually takes ~{target} cm.} other{You\'re {height}. About {current}\" today. Dunking usually takes ~{target}\".}}'**
  String gapIntro(String unit, String height, int current, int target);

  /// Paragraph under the gap screen's headline when the athlete's estimated vertical already meets what a dunk needs. {height} is already formatted like 6'1" or 185 cm; {current} and {target} are verticals, already converted to the athlete's unit: {unit} is 'metric' (centimetres) or 'imperial' (inches).
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{You\'re {height}. About {current} cm today, and dunking usually takes ~{target} cm. From here the plan is about adding margin and consistency.} other{You\'re {height}. About {current}\" today, and dunking usually takes ~{target}\". From here the plan is about adding margin and consistency.}}'**
  String gapIntroCanDunk(String unit, String height, int current, int target);

  /// Note on the gap screen, shown only when the athlete answered 'both hands' on quiz question 10. {unit} is 'metric' ({value} in centimetres) or 'imperial' ({value} in inches); the value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{You picked a two-hand finish, which asks for both forearms over the ring — about {value} cm more than a one-hand dunk. Your target reflects that.} other{You picked a two-hand finish, which asks for both forearms over the ring — about {value}\" more than a one-hand dunk. Your target reflects that.}}'**
  String gapTwoHandNote(String unit, int value);

  /// Caveat on the gap screen, shown only while the standing reach is estimated rather than measured. {unit} is 'metric' ({reach} in centimetres) or 'imperial' ({reach} in inches); the value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{Based on an estimated {reach} cm standing reach from your height. Measure your real reach — in Settings any time — for an exact target.} other{Based on an estimated {reach}\" standing reach from your height. Measure your real reach — in Settings any time — for an exact target.}}'**
  String gapEstimatedReachNote(String unit, int reach);

  /// Caption under the left number of the gap meter (estimated vertical today).
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get gapMeterToday;

  /// Caption under the middle number of the gap meter (inches still missing).
  ///
  /// In en, this message translates to:
  /// **'EST. GAP'**
  String get gapMeterGap;

  /// Caption under the middle number of the gap meter when the athlete is estimated to already clear the dunk: the inches they have to spare. Replaces the EST. GAP caption. Keep it very short, it sits under a narrow figure.
  ///
  /// In en, this message translates to:
  /// **'EST. MARGIN'**
  String get gapMeterMargin;

  /// Caption under the right number of the gap meter (vertical needed to dunk).
  ///
  /// In en, this message translates to:
  /// **'DUNK'**
  String get gapMeterDunk;

  /// Label of the height row in the gap screen's summary list.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get gapRowHeight;

  /// Label of the standing-reach row in the gap screen's summary list.
  ///
  /// In en, this message translates to:
  /// **'Standing reach'**
  String get gapRowStandingReach;

  /// Label of the estimated-current-vertical row in the gap screen's summary list.
  ///
  /// In en, this message translates to:
  /// **'Est. today'**
  String get gapRowEstToday;

  /// Label of the required-vertical row in the gap screen's summary list.
  ///
  /// In en, this message translates to:
  /// **'Dunk target'**
  String get gapRowDunkTarget;

  /// Label of the weight row in the gap screen's summary list.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get gapRowWeight;

  /// Label of the current-jumping-ability row in the gap screen's summary list.
  ///
  /// In en, this message translates to:
  /// **'Hops'**
  String get gapRowHops;

  /// Label of the goals row in the gap screen's summary list. Lists every goal the athlete picked (multi-select), not just the first one.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get gapRowGoals;

  /// Separator placed between two goal titles in the gap screen's Goals row, e.g. the ', ' in 'First Dunk Ever, Max Vertical'. Keep the trailing space if the language needs one.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get gapGoalsSeparator;

  /// Label of the sessions-per-week row in the gap screen's summary list.
  ///
  /// In en, this message translates to:
  /// **'Training days'**
  String get gapRowTrainingDays;

  /// Value of the standing-reach row in the gap screen's summary list while the reach is estimated rather than measured. {unit} is 'metric' ({reach} in centimetres) or 'imperial' ({reach} in inches); the value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{{reach} cm (est.)} other{{reach}\" (est.)}}'**
  String gapReachEstimatedSuffix(String unit, int reach);

  /// Value of the weight row in the gap screen's summary list. {unit} is 'metric' ({value} in kilograms) or 'imperial' ({value} in pounds); the value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{{value} kg} other{{value} lbs}}'**
  String gapWeightValue(String unit, int value);

  /// Value of the training-days row in the gap screen's summary list.
  ///
  /// In en, this message translates to:
  /// **'{days}/week'**
  String gapTrainingDaysValue(int days);

  /// Fallback value of the goals row in the gap screen's summary list when the athlete selected no goal.
  ///
  /// In en, this message translates to:
  /// **'Your First Dunk'**
  String get gapDefaultGoal;

  /// Button at the bottom of the gap screen, leading to the jump-potential projection.
  ///
  /// In en, this message translates to:
  /// **'CLOSE THE GAP'**
  String get gapCta;

  /// Button at the bottom of the gap screen when the athlete is estimated to already clear the dunk (no gap to close). Leads to the jump-potential projection.
  ///
  /// In en, this message translates to:
  /// **'BUILD MORE MARGIN'**
  String get gapCtaCanDunk;

  /// Headline of the second onboarding sell screen: the projected vertical over eight weeks.
  ///
  /// In en, this message translates to:
  /// **'YOUR JUMP POTENTIAL'**
  String get potentialTitle;

  /// Subtitle of the jump-potential screen. The projection is a fixed diminishing-returns curve whose ceiling depends on age only, applied to the onboarding estimate; it ignores schedule, experience and goals, so the copy must not claim it is tailored to them.
  ///
  /// In en, this message translates to:
  /// **'A typical progression curve for your age, starting from today\'s estimate — not a promise. Your logged jumps will tell the real story.'**
  String get potentialSubtitle;

  /// Caption under one bar of the projection chart on the jump-potential screen. Abbreviated 'week' — keep it short, it sits under a narrow bar.
  ///
  /// In en, this message translates to:
  /// **'WK {week}'**
  String potentialWeekLabel(int week);

  /// Small caps label above the projected vertical on the jump-potential screen. {weeks} is the length of the recommended program (8 for the beginner and intermediate programs, 10 for the advanced one), so the window matches the plan revealed two screens later.
  ///
  /// In en, this message translates to:
  /// **'PROJECTED {weeks}-WEEK WINDOW'**
  String potentialWindowLabel(int weeks);

  /// Line under the projected end-of-program vertical, naming the estimated vertical it starts from. {unit} is 'metric' ({value} in centimetres) or 'imperial' ({value} in inches); the value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{Potential from an est. ~{value} cm today.} other{Potential from an est. ~{value}\" today.}}'**
  String potentialFromToday(String unit, int value);

  /// Button at the bottom of the jump-potential screen.
  ///
  /// In en, this message translates to:
  /// **'SEE MY PLAN'**
  String get potentialCta;

  /// Headline of the third onboarding sell screen, which sells the measurement method. Keep two short lines.
  ///
  /// In en, this message translates to:
  /// **'HOW YOUR VERT\nGETS MEASURED'**
  String get howItWorksTitle;

  /// Subtitle of the how-it-works screen.
  ///
  /// In en, this message translates to:
  /// **'No wearables, no markers on the floor. Just physics and your phone camera.'**
  String get howItWorksSubtitle;

  /// Small caps label at the top of the physics card on the how-it-works screen. 'Hang time' is the airborne duration of a jump.
  ///
  /// In en, this message translates to:
  /// **'HANG TIME'**
  String get hangTimeLabel;

  /// Second line of the physics card headline on the how-it-works screen; reads as one sentence with the HANG TIME label above it.
  ///
  /// In en, this message translates to:
  /// **'decides your height'**
  String get hangTimeDecides;

  /// Pill inside the physics card on the how-it-works screen. The double spaces around the equals sign are intentional.
  ///
  /// In en, this message translates to:
  /// **'longer in the air  =  higher jump'**
  String get hangTimeFormula;

  /// Closing sentence of the physics card on the how-it-works screen.
  ///
  /// In en, this message translates to:
  /// **'Two athletes with the same hang time jumped the same height. That is what we measure.'**
  String get hangTimeNote;

  /// Title of the first bullet card on the how-it-works screen (on-device pose tracking).
  ///
  /// In en, this message translates to:
  /// **'We watch your body, not the pixels'**
  String get howItWorksPoint1Title;

  /// Body of the first bullet card on the how-it-works screen.
  ///
  /// In en, this message translates to:
  /// **'On-device tracking follows your feet frame by frame and finds the exact instants they leave the floor and meet it again.'**
  String get howItWorksPoint1Body;

  /// Title of the second bullet card on the how-it-works screen (physics, not estimation).
  ///
  /// In en, this message translates to:
  /// **'Measured, not guessed'**
  String get howItWorksPoint2Title;

  /// Body of the second bullet card on the how-it-works screen.
  ///
  /// In en, this message translates to:
  /// **'Your hang time gives your height through gravity alone — no camera calibration, no markers, no eyeballing.'**
  String get howItWorksPoint2Body;

  /// Title of the third bullet card on the how-it-works screen (program fits the athlete's real setup).
  ///
  /// In en, this message translates to:
  /// **'A plan you can actually run'**
  String get howItWorksPoint3Title;

  /// Body of the third bullet card on the how-it-works screen. Names exactly the three answers that reach the program catalog — do not add height or age, they do not.
  ///
  /// In en, this message translates to:
  /// **'Your experience, your training days and whether you have a gym decide your programme — no barbell drills if you train at home.'**
  String get howItWorksPoint3Body;

  /// Title of the fourth bullet card on the how-it-works screen (everything is logged).
  ///
  /// In en, this message translates to:
  /// **'Progress you can check'**
  String get howItWorksPoint4Title;

  /// Body of the fourth bullet card on the how-it-works screen.
  ///
  /// In en, this message translates to:
  /// **'Every session and every analysed jump is logged, so the trend you see is your own history, not a motivational number.'**
  String get howItWorksPoint4Body;

  /// Button at the bottom of the how-it-works screen.
  ///
  /// In en, this message translates to:
  /// **'START MY PLAN'**
  String get howItWorksCta;

  /// Headline of the short loading beat shown between the quiz and the plan reveal.
  ///
  /// In en, this message translates to:
  /// **'BUILDING YOUR PLAN'**
  String get buildingPlanTitle;

  /// Line under the loading spinner while the plan is revealed. {program} is a program name such as 'Vertical Foundation' — these names come from the untranslated program catalog.
  ///
  /// In en, this message translates to:
  /// **'Matching you to the {program}'**
  String buildingPlanSubtitle(String program);

  /// Headline of the plan-reveal screen, the last onboarding step before the free analysis.
  ///
  /// In en, this message translates to:
  /// **'HERE\'S YOUR PLAN'**
  String get planRevealTitle;

  /// Subtitle of the plan-reveal screen. Names only what really shapes the program — do not add goals or position, which are collected but never reach the catalog.
  ///
  /// In en, this message translates to:
  /// **'Matched to your level, your schedule and where you train.'**
  String get planRevealSubtitle;

  /// Badge on the program card of the plan-reveal screen: sessions per week.
  ///
  /// In en, this message translates to:
  /// **'{days} DAYS'**
  String planBadgeDays(int days);

  /// Badge on the program card of the plan-reveal screen: program length.
  ///
  /// In en, this message translates to:
  /// **'{weeks} WEEKS'**
  String planBadgeWeeks(int weeks);

  /// Section heading above the seven-day layout on the plan-reveal screen.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK'**
  String get planThisWeek;

  /// Upper-case name of a training day in the plan-reveal screen's week layout, keyed on the authored day focus from core/program_catalog.dart ('Power', 'Strength', 'Speed', 'Control'). An unknown focus is printed as authored.
  ///
  /// In en, this message translates to:
  /// **'{focus, select, Power{POWER} Strength{STRENGTH} Speed{SPEED} Control{CONTROL} other{{focus}}}'**
  String programDayFocus(String focus);

  /// Label of a non-training day in the plan-reveal screen's week layout.
  ///
  /// In en, this message translates to:
  /// **'REST'**
  String get planDayRest;

  /// Screen label inside the phone mockup on intro carousel panel 1. Illustrative UI, not real data.
  ///
  /// In en, this message translates to:
  /// **'JUMP ANALYSIS'**
  String get mockJumpAnalysis;

  /// Card label inside the phone mockup on intro carousel panel 1: estimated vertical jump.
  ///
  /// In en, this message translates to:
  /// **'EST. VERT'**
  String get mockEstVert;

  /// Length-to-dunk pill inside the phone mockup on intro carousel panel 1. {unit} is 'metric' ({value} in centimetres) or 'imperial' ({value} in inches); the sample value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{{value} cm TO DUNK} other{{value}\" TO DUNK}}'**
  String mockToDunk(String unit, int value);

  /// Section label inside the phone mockup on intro carousel panel 1, above the four technique score tiles.
  ///
  /// In en, this message translates to:
  /// **'FORM SCORES'**
  String get mockFormScores;

  /// Card label inside the phone mockup on intro carousel panel 1, above the written coaching text.
  ///
  /// In en, this message translates to:
  /// **'JUMP BREAKDOWN'**
  String get mockJumpBreakdown;

  /// Where-you-are label inside the phone mockup on intro carousel panel 2. Illustrative sample values.
  ///
  /// In en, this message translates to:
  /// **'WEEK 2 · DAY 2 OF 3'**
  String get mockWeekDay;

  /// Today's session label inside the phone mockup on intro carousel panel 2.
  ///
  /// In en, this message translates to:
  /// **'TODAY · POWER'**
  String get mockTodayPower;

  /// Badge on the sample program card inside the phone mockup on intro carousel panel 2.
  ///
  /// In en, this message translates to:
  /// **'3 DAYS'**
  String get mockMiniBadgeDays;

  /// Badge on the sample program card inside the phone mockup on intro carousel panel 2: trains at a gym.
  ///
  /// In en, this message translates to:
  /// **'GYM'**
  String get mockMiniBadgeGym;

  /// Badge on the sample program card inside the phone mockup on intro carousel panel 2.
  ///
  /// In en, this message translates to:
  /// **'8 WEEKS'**
  String get mockMiniBadgeWeeks;

  /// Screen label inside the phone mockup on intro carousel panel 3.
  ///
  /// In en, this message translates to:
  /// **'PROGRESS'**
  String get mockProgress;

  /// Card label inside the phone mockup on intro carousel panel 3.
  ///
  /// In en, this message translates to:
  /// **'CURRENT VERTICAL'**
  String get mockCurrentVertical;

  /// Trend line inside the phone mockup on intro carousel panel 3. {unit} is 'metric' ({value} in centimetres) or 'imperial' ({value} in inches); the sample value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{+{value} cm SINCE FIRST TEST} other{+{value}\" SINCE FIRST TEST}}'**
  String mockSinceFirstTest(String unit, int value);

  /// Stat tile inside the phone mockup on intro carousel panel 3: sessions completed out of the program total.
  ///
  /// In en, this message translates to:
  /// **'WORKOUTS'**
  String get mockWorkouts;

  /// Stat tile inside the phone mockup on intro carousel panel 3: consecutive training days.
  ///
  /// In en, this message translates to:
  /// **'DAY STREAK'**
  String get mockDayStreak;

  /// Headline of the paywall. Keep two short lines.
  ///
  /// In en, this message translates to:
  /// **'GET YOUR\nFIRST DUNK.'**
  String get paywallHeadline;

  /// Paragraph under the paywall headline when the selected plan has no free trial. {days} is sessions per week.
  ///
  /// In en, this message translates to:
  /// **'Your {days}-day plan is built. Cancel anytime.'**
  String paywallPlanBuilt(int days);

  /// Paragraph under the paywall headline when the selected plan includes a free trial. {trial} is the trial length as the store reports it, already capitalized (e.g. '3 days').
  ///
  /// In en, this message translates to:
  /// **'Your {days}-day plan is built. {trial} free. Cancel anytime.'**
  String paywallPlanBuiltWithTrial(int days, String trial);

  /// Title of the first benefit row on the paywall.
  ///
  /// In en, this message translates to:
  /// **'Your Vert, Measured'**
  String get paywallBenefit1Title;

  /// Body of the first benefit row on the paywall.
  ///
  /// In en, this message translates to:
  /// **'Full jump breakdown — vert estimate, gap to your goal & coaching'**
  String get paywallBenefit1Body;

  /// Title of the second benefit row on the paywall.
  ///
  /// In en, this message translates to:
  /// **'Week 1, Ready Now'**
  String get paywallBenefit2Title;

  /// Body of the second benefit row on the paywall.
  ///
  /// In en, this message translates to:
  /// **'Your personalized plan starts the moment you unlock'**
  String get paywallBenefit2Body;

  /// Title of the third benefit row on the paywall.
  ///
  /// In en, this message translates to:
  /// **'Every Inch Tracked'**
  String get paywallBenefit3Title;

  /// Body of the third benefit row on the paywall.
  ///
  /// In en, this message translates to:
  /// **'Watch your progress toward your goal, week over week'**
  String get paywallBenefit3Body;

  /// Small line under the paywall CTA when the selected plan has no free trial.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime.'**
  String get paywallCancelAnytime;

  /// Small line under the paywall CTA when the selected plan includes a free trial.
  ///
  /// In en, this message translates to:
  /// **'No commitment required. Cancel anytime.'**
  String get paywallNoCommitment;

  /// Paywall CTA in a non-release build with no purchase configuration — the deliberate dev/preview escape hatch.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WITHOUT PURCHASE'**
  String get paywallCtaContinueWithoutPurchase;

  /// Paywall CTA when there is nothing to sell and no escape hatch; the button is disabled.
  ///
  /// In en, this message translates to:
  /// **'UNAVAILABLE'**
  String get paywallCtaUnavailable;

  /// Small line under the paywall CTA in a preview build with no purchase configuration.
  ///
  /// In en, this message translates to:
  /// **'Preview build — purchases are not set up yet, so this unlocks the app without charging anything.'**
  String get paywallPreviewBuildNote;

  /// Small line under the paywall CTA in a debug build with no purchase configuration.
  ///
  /// In en, this message translates to:
  /// **'Debug build — nothing will be charged.'**
  String get paywallDebugBuildNote;

  /// Small line under the disabled paywall CTA when purchases cannot be offered.
  ///
  /// In en, this message translates to:
  /// **'Purchases are not available in this build.'**
  String get paywallNoPurchasesInBuild;

  /// Fine print under the paywall CTA in a build with no purchase configuration, in place of Apple's renewal disclosure.
  ///
  /// In en, this message translates to:
  /// **'This build has no purchase configuration, so nothing is for sale and nothing will be charged.'**
  String get paywallDisclosureNoConfig;

  /// Fine print under the paywall CTA when the store offering could not be fetched.
  ///
  /// In en, this message translates to:
  /// **'Subscription plans could not be loaded. Nothing has been charged.'**
  String get paywallDisclosureLoadFailed;

  /// Fine print under the paywall CTA when the app was built without purchase credentials.
  ///
  /// In en, this message translates to:
  /// **'Purchases are unavailable in this build.'**
  String get paywallDisclosureUnavailable;

  /// Title of the card shown in place of the paywall's plan cards when the store offering could not be fetched.
  ///
  /// In en, this message translates to:
  /// **'Plans unavailable'**
  String get paywallPlansUnavailableTitle;

  /// Title of the card shown in place of the paywall's plan cards when the app has no purchase credentials.
  ///
  /// In en, this message translates to:
  /// **'Purchases unavailable in this build'**
  String get paywallPurchasesUnavailableTitle;

  /// Body of the card shown in place of the paywall's plan cards when the store offering could not be fetched.
  ///
  /// In en, this message translates to:
  /// **'We could not reach the App Store to load subscription prices. Nothing has been charged.'**
  String get paywallPlansUnavailableBody;

  /// Body of the card shown in place of the paywall's plan cards when the app has no purchase credentials.
  ///
  /// In en, this message translates to:
  /// **'This build was made without purchase credentials, so there is nothing to buy here.'**
  String get paywallPurchasesUnavailableBody;

  /// Link that re-fetches the store offering on the paywall's unavailable card.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get paywallTryAgain;

  /// Badge on the cheapest-per-week plan card on the paywall.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get paywallBestValue;

  /// Savings badge on a paywall plan card, derived from the real store prices.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String paywallSavePercent(int percent);

  /// Link on the paywall that reveals the plan cards hidden below the headline plan.
  ///
  /// In en, this message translates to:
  /// **'View other plans'**
  String get paywallViewOtherPlans;

  /// Footer link on the paywall that restores a previous subscription. Apple requires this to be present.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get paywallRestorePurchases;

  /// Footer link on the paywall opening the privacy policy. Keep it short — it sits in a row of three.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get paywallPrivacy;

  /// Footer link on the paywall opening the terms of use. Keep it short — it sits in a row of three.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get paywallTerms;

  /// Full name of the privacy page, used in the paywall's not-published dialog and its failure message.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get paywallPrivacyPolicyTitle;

  /// Full name of the terms page, used in the paywall's not-published dialog and its failure message.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get paywallTermsOfUseTitle;

  /// Body of the dialog shown when the athlete taps a paywall legal link whose page is not online yet.
  ///
  /// In en, this message translates to:
  /// **'This page is not published yet.'**
  String get paywallPageNotPublished;

  /// Error shown on the paywall when the device could not open a legal link in a browser; falls back to showing the address.
  ///
  /// In en, this message translates to:
  /// **'Could not open {title}. The address is {url}'**
  String paywallCouldNotOpenLegal(String title, String url);

  /// Paywall error when a purchase succeeded at the store but granted no entitlement (usually a mismatched entitlement id).
  ///
  /// In en, this message translates to:
  /// **'That purchase went through but did not unlock DunkIt. Try Restore Purchases, or contact support — you have not lost it.'**
  String get paywallErrorNotEntitled;

  /// Paywall error when the purchase could not even be attempted.
  ///
  /// In en, this message translates to:
  /// **'Purchases are unavailable right now. Try again later.'**
  String get paywallErrorUnavailable;

  /// Paywall error when a purchase attempt failed.
  ///
  /// In en, this message translates to:
  /// **'The purchase could not be completed. Check your connection and try again.'**
  String get paywallErrorFailed;

  /// Paywall message after Restore Purchases found no active subscription.
  ///
  /// In en, this message translates to:
  /// **'No active DunkIt subscription found on this Apple ID.'**
  String get paywallErrorNothingToRestore;

  /// Dismiss button of the retake-onboarding confirmation and of the standing-reach dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Confirm button of the standing-reach dialog opened from Settings.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Seven single-letter weekday initials, Monday first, comma-separated. Used by the Home tab's five-day strip and by the week strip inside the intro carousel's phone mockup. Must contain exactly seven comma-separated entries.
  ///
  /// In en, this message translates to:
  /// **'M,T,W,T,F,S,S'**
  String get weekdayInitials;

  /// A gain in vertical, e.g. the green delta badge next to the latest vertical on Home. {unit} is 'metric' ({value} in centimetres) or 'imperial' ({value} in inches); the value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{+{value} cm} other{+{value}\"}}'**
  String lengthPlus(String unit, int value);

  /// Bottom navigation bar label for the Home tab. Very tight — five labels share the bar width.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get tabHome;

  /// Bottom navigation bar label for the Analyze (film and measure a jump) tab. Very tight — five labels share the bar width.
  ///
  /// In en, this message translates to:
  /// **'ANALYZE'**
  String get tabAnalyze;

  /// Bottom navigation bar label for the Train (workout program) tab. Very tight — five labels share the bar width.
  ///
  /// In en, this message translates to:
  /// **'TRAIN'**
  String get tabTrain;

  /// Bottom navigation bar label for the Feed (leaderboards) tab. Very tight — five labels share the bar width.
  ///
  /// In en, this message translates to:
  /// **'FEED'**
  String get tabFeed;

  /// Bottom navigation bar label for the Progress tab. Very tight — five labels share the bar width.
  ///
  /// In en, this message translates to:
  /// **'PROGRESS'**
  String get tabProgress;

  /// Heading of the settings bottom sheet, opened from the gear icon on Home.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsTitle;

  /// Settings sheet row that sets the name shown on the global leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard name'**
  String get settingsLeaderboardName;

  /// Settings sheet row that sets the measured standing reach; also the title of the dialog it opens.
  ///
  /// In en, this message translates to:
  /// **'Standing reach'**
  String get settingsStandingReach;

  /// Settings sheet row that clears the profile and restarts the onboarding quiz.
  ///
  /// In en, this message translates to:
  /// **'Retake onboarding'**
  String get settingsRetakeOnboarding;

  /// Value shown on a settings sheet row the athlete has not filled in yet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsNotSet;

  /// Title of the confirmation dialog before restarting the onboarding quiz.
  ///
  /// In en, this message translates to:
  /// **'Retake onboarding?'**
  String get retakeOnboardingTitle;

  /// Body of the confirmation dialog before restarting the onboarding quiz.
  ///
  /// In en, this message translates to:
  /// **'This clears your current profile and takes you back through the quiz from the start.'**
  String get retakeOnboardingBody;

  /// Confirm button of the retake-onboarding dialog.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retakeOnboardingConfirm;

  /// Instructions at the top of the standing-reach dialog, explaining how to measure it.
  ///
  /// In en, this message translates to:
  /// **'Stand flat against a wall, reach one arm as high as it goes, mark your fingertips, then measure from the floor. Your dunk target is built on this number.'**
  String get standingReachHowTo;

  /// One reading in the standing-reach dialog (the big current value and every wheel entry). Imperial shows the same measurement in feet-and-inches ({label}, already formatted like 8'1") and in plain inches ({value}); metric shows centimetres only ({value}, {label} is empty). The double spaces around the separator are intentional. {unit} is 'metric' or 'imperial'.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{{value} cm} other{{label}  ·  {value} in}}'**
  String standingReachValue(String unit, String label, int value);

  /// Note at the bottom of the standing-reach dialog, shown only while no real measurement exists. {label} is a formatted reach such as 7'8" or 234 cm.
  ///
  /// In en, this message translates to:
  /// **'Currently estimated at {label} from your height.'**
  String standingReachEstimateNote(String label);

  /// Label above the Home tab's five-day strip: which session of the program is next.
  ///
  /// In en, this message translates to:
  /// **'DAY {session}/{total}'**
  String homeDayCounter(int session, int total);

  /// Pill next to the day counter on the Home tab.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get homeTodayBadge;

  /// Headline of the Home tab hero card once every session of the program is done.
  ///
  /// In en, this message translates to:
  /// **'PROGRAM COMPLETE'**
  String get homeProgramComplete;

  /// Line under the Home tab hero headline once the program is complete.
  ///
  /// In en, this message translates to:
  /// **'You\'ve finished every session — nice work.'**
  String get homeProgramCompleteBody;

  /// Headline of the Home tab hero card naming today's session focus. {focus} is an upper-cased focus name (POWER, STRENGTH, SPEED) from the untranslated program catalog.
  ///
  /// In en, this message translates to:
  /// **'{focus} DAY'**
  String homeFocusDay(String focus);

  /// Line under the Home tab hero headline: where the athlete is in the program.
  ///
  /// In en, this message translates to:
  /// **'Week {week} • Session {session}/{total}'**
  String homeWeekSession(int week, int session, int total);

  /// Home tab hero button once the program is complete; opens the Train tab.
  ///
  /// In en, this message translates to:
  /// **'VIEW TRAIN'**
  String get homeCtaViewTrain;

  /// Home tab hero button that starts today's workout.
  ///
  /// In en, this message translates to:
  /// **'START SESSION'**
  String get homeCtaStartSession;

  /// Label of the Home tab stat card showing the most recently measured vertical.
  ///
  /// In en, this message translates to:
  /// **'LATEST VERT'**
  String get homeLatestVert;

  /// Label of the Home tab stat card showing consecutive training days.
  ///
  /// In en, this message translates to:
  /// **'DAY STREAK'**
  String get homeDayStreak;

  /// A jump's date in its tightest form (month and day), used under the Progress trend chart and on the recent-analysis thumbnails. Formatted by intl, so the order follows the locale.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String jumpDateShort(DateTime date);

  /// A jump's full date, used in the jump-history list. Formatted by intl, so the order follows the locale.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String jumpDateFull(DateTime date);

  /// Heading at the top of the Progress tab.
  ///
  /// In en, this message translates to:
  /// **'PROGRESS'**
  String get progressTitle;

  /// Title of the Progress tab card holding the vertical-over-time line chart.
  ///
  /// In en, this message translates to:
  /// **'VERTICAL JUMP TREND'**
  String get progressTrendTitle;

  /// Shown instead of the Progress trend chart while fewer than two jumps have been logged.
  ///
  /// In en, this message translates to:
  /// **'Log a few more jumps to see your trend'**
  String get progressTrendEmpty;

  /// Title of the Progress tab row of recently analysed jump thumbnails.
  ///
  /// In en, this message translates to:
  /// **'RECENT ANALYSES'**
  String get progressRecentAnalyses;

  /// Link at the end of the Progress recent-analyses title row; opens the full jump history.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get progressViewAll;

  /// Label above the big number on the Progress tab's headline card.
  ///
  /// In en, this message translates to:
  /// **'CURRENT VERTICAL'**
  String get progressCurrentVertical;

  /// Unit shown after the em dash on the Progress headline card while no jump has been measured yet. The two leading spaces are intentional. {unit} is 'metric' (centimetres) or 'imperial' (inches).
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{  cm} other{  in}}'**
  String progressVertUnitSuffix(String unit);

  /// Empty state on the Progress headline card, before any jump has been analysed.
  ///
  /// In en, this message translates to:
  /// **'Log your first jump test to start tracking'**
  String get progressLogFirstJump;

  /// Button on the Progress empty state that switches to the Analyze tab.
  ///
  /// In en, this message translates to:
  /// **'Go to Analyze'**
  String get progressGoToAnalyze;

  /// Trend line on the Progress headline card when the vertical has improved. {unit} is 'metric' ({value} in centimetres) or 'imperial' ({value} in inches); the value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{+{value} cm since your first test} other{+{value}\" since your first test}}'**
  String progressSinceFirstGain(String unit, int value);

  /// Trend line on the Progress headline card when the vertical has dropped. {value} is already negative, so it arrives with its own minus sign, and already converted: {unit} is 'metric' (centimetres) or 'imperial' (inches).
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{{value} cm since your first test} other{{value}\" since your first test}}'**
  String progressSinceFirstLoss(String unit, int value);

  /// Trend line on the Progress headline card when the vertical is unchanged.
  ///
  /// In en, this message translates to:
  /// **'No change since your first test'**
  String get progressSinceFirstNoChange;

  /// Title of the Progress tab card counting completed program sessions.
  ///
  /// In en, this message translates to:
  /// **'WORKOUTS'**
  String get progressWorkouts;

  /// Label under the count of finished sessions on the Progress workouts card.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get progressCompleted;

  /// Label under the count of sessions left on the Progress workouts card.
  ///
  /// In en, this message translates to:
  /// **'REMAINING'**
  String get progressRemaining;

  /// Label under the percentage on the Progress workouts card.
  ///
  /// In en, this message translates to:
  /// **'COMPLETE'**
  String get progressCompleteLabel;

  /// Percentage of the program finished, on the Progress workouts card.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String progressPercent(int percent);

  /// Second line of the Progress workouts card, under the completed count: sessions left in the program and the percentage done, on one short line. All caps like the labels around it.
  ///
  /// In en, this message translates to:
  /// **'{remaining, plural, =1{1 REMAINING · {percent}% COMPLETE} other{{remaining} REMAINING · {percent}% COMPLETE}}'**
  String progressRemainingAndPercent(int remaining, int percent);

  /// Title of the Progress tab card counting consecutive training days.
  ///
  /// In en, this message translates to:
  /// **'DAY STREAK'**
  String get progressDayStreak;

  /// Unit printed after the big streak number on the Progress streak card. The two leading spaces are intentional.
  ///
  /// In en, this message translates to:
  /// **'  days'**
  String get progressStreakDaysSuffix;

  /// App bar title of the full jump-history list, opened from Progress's View All.
  ///
  /// In en, this message translates to:
  /// **'Jump History'**
  String get jumpHistoryTitle;

  /// Empty state of the full jump-history list.
  ///
  /// In en, this message translates to:
  /// **'No jumps logged yet.'**
  String get jumpHistoryEmpty;

  /// App bar title of the full-screen jump-clip player: the measured vertical and when it was filmed. {unit} is 'metric' ({value} in centimetres) or 'imperial' ({value} in inches); the value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{{value} cm · {date}} other{{value}\" · {date}}}'**
  String jumpVideoTitle(String unit, int value, DateTime date);

  /// Shown in the jump-clip player when the video fails to open.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this clip.'**
  String get jumpVideoLoadError;

  /// Snackbar in the jump-clip player when Share is tapped but the file has been deleted.
  ///
  /// In en, this message translates to:
  /// **'This clip is no longer on your device.'**
  String get jumpVideoMissing;

  /// Snackbar in the jump-clip player when the native share sheet fails to open.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the share sheet. Please try again.'**
  String get jumpVideoShareFailed;

  /// Caption attached to a jump clip handed to the native share sheet. 'Dunk It' is the app name and stays as is. {unit} is 'metric' ({value} in centimetres) or 'imperial' ({value} in inches); the value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{{value} cm vertical — Dunk It} other{{value}\" vertical — Dunk It}}'**
  String jumpShareText(String unit, int value);

  /// Seven abbreviated weekday names, Monday first, comma-separated, for the Train tab's week strip and the plan-reveal screen's week layout. Keep each to about three characters — they sit under narrow chips. Must contain exactly seven comma-separated entries.
  ///
  /// In en, this message translates to:
  /// **'MON,TUE,WED,THU,FRI,SAT,SUN'**
  String get weekdayLabels;

  /// Heading at the top of the Train tab.
  ///
  /// In en, this message translates to:
  /// **'TRAIN'**
  String get trainTitle;

  /// Small caps label above the program name on the Train tab.
  ///
  /// In en, this message translates to:
  /// **'ENROLLED PROGRAM'**
  String get trainEnrolledProgram;

  /// Where this session sits in the program — shown under the program name on Train and at the top of the warm-up screen.
  ///
  /// In en, this message translates to:
  /// **'WEEK {week} · DAY {day} OF {sessionsPerWeek}'**
  String trainPositionLabel(int week, int day, int sessionsPerWeek);

  /// Line under the program name on the Train tab: the week/day position followed by the program length.
  ///
  /// In en, this message translates to:
  /// **'{position} • {weeks} WEEKS'**
  String trainProgramMeta(String position, int weeks);

  /// Pill on the Train tab program card marking a planned lighter week.
  ///
  /// In en, this message translates to:
  /// **'DELOAD'**
  String get trainDeloadPill;

  /// Paragraph on the Train tab program card during a deload week.
  ///
  /// In en, this message translates to:
  /// **'Deload week: less volume on purpose. Lighter weeks are when the work you already did turns into new hops.'**
  String get trainDeloadExplainer;

  /// Title of the Train tab week strip.
  ///
  /// In en, this message translates to:
  /// **'WEEK {week}'**
  String trainWeekNumber(int week);

  /// Counts on the right of the Train tab week strip title: training days and rest days this week.
  ///
  /// In en, this message translates to:
  /// **'{sessions} sessions • {rest} rest'**
  String trainWeekSummary(int sessions, int rest);

  /// Title of the Train tab card shown once a session has already been logged today.
  ///
  /// In en, this message translates to:
  /// **'REST DAY'**
  String get trainRestDayTitle;

  /// Line under the rest-day title on the Train tab.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already trained today.'**
  String get trainRestDaySubtitle;

  /// Paragraph of the Train tab rest-day card.
  ///
  /// In en, this message translates to:
  /// **'Jumps are built between sessions, not during them. Sleep, eat, and let the tendons recover.'**
  String get trainRestDayBody;

  /// Footer of the Train tab rest-day card naming the next session. {focus} is an upper-cased focus name (POWER, STRENGTH, SPEED) from the untranslated program catalog.
  ///
  /// In en, this message translates to:
  /// **'Up next: {focus} DAY'**
  String trainUpNext(String focus);

  /// Title of the Train tab card listing today's drills.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S EXERCISES'**
  String get trainTodaysExercises;

  /// Pill on the Train tab exercise card counting today's drills.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} exercise} other{{count} exercises}}'**
  String trainExerciseCount(num count);

  /// Line under the Train tab exercise-card title: today's focus and its warm-up prescription, both from the untranslated program catalog.
  ///
  /// In en, this message translates to:
  /// **'{focus} • {warmUp}'**
  String trainFocusAndWarmUp(String focus, String warmUp);

  /// Note on the Train tab exercise card during a deload week.
  ///
  /// In en, this message translates to:
  /// **'Volume is dialled back this week — same movements, fewer sets.'**
  String get trainDeloadVolumeNote;

  /// Title of the Train tab progress card.
  ///
  /// In en, this message translates to:
  /// **'PROGRAM PROGRESS'**
  String get trainProgramProgress;

  /// Disabled Train tab button once every session is done.
  ///
  /// In en, this message translates to:
  /// **'PROGRAM COMPLETE'**
  String get trainCtaProgramComplete;

  /// Muted Train tab button on a rest day — recovery is recommended, never enforced.
  ///
  /// In en, this message translates to:
  /// **'TRAIN ANYWAY'**
  String get trainCtaTrainAnyway;

  /// Train tab button that opens the session flow.
  ///
  /// In en, this message translates to:
  /// **'START TODAY\'S SESSION'**
  String get trainCtaStartSession;

  /// Header of the first step of a training session.
  ///
  /// In en, this message translates to:
  /// **'WARM UP'**
  String get warmUpHeader;

  /// Headline of the warm-up screen. {focus} is an upper-cased focus name (POWER, STRENGTH, SPEED) from the untranslated program catalog.
  ///
  /// In en, this message translates to:
  /// **'{focus} DAY'**
  String warmUpFocusDay(String focus);

  /// Banner on the warm-up screen during a deload week.
  ///
  /// In en, this message translates to:
  /// **'DELOAD WEEK — fewer sets on purpose. This is when adaptation happens.'**
  String get warmUpDeloadNote;

  /// Small caps label on the warm-up prescription card.
  ///
  /// In en, this message translates to:
  /// **'WARM-UP'**
  String get warmUpCardLabel;

  /// Button at the bottom of the warm-up screen.
  ///
  /// In en, this message translates to:
  /// **'START EXERCISES'**
  String get warmUpCta;

  /// Label at the top of the set-logging screen: which drill of the session this is.
  ///
  /// In en, this message translates to:
  /// **'EXERCISE {index}/{total}'**
  String logExerciseCounter(int index, int total);

  /// Title of the card on the set-logging screen that opens the drill's coaching guide.
  ///
  /// In en, this message translates to:
  /// **'HOW TO DO IT'**
  String get logGuideTitle;

  /// Subtitle of the coaching-guide card on the set-logging screen.
  ///
  /// In en, this message translates to:
  /// **'{steps} steps, common mistakes and what it trains.'**
  String logGuideSubtitle(int steps);

  /// Subtitle of the coaching-guide card when the drill has no authored guide.
  ///
  /// In en, this message translates to:
  /// **'No coaching notes yet for this drill.'**
  String get logGuideNone;

  /// Note on the set-logging screen when the prescribed drill was substituted for a bodyweight one, and the original drill has no authored name to quote.
  ///
  /// In en, this message translates to:
  /// **'Swapped for your home setup'**
  String get logSwappedForHome;

  /// Note on the set-logging screen when the prescribed drill was substituted for a bodyweight one. {original} is the replaced drill's name, which comes from the untranslated exercise library.
  ///
  /// In en, this message translates to:
  /// **'Swapped for your home setup — replaces {original}'**
  String logSwappedForHomeReplaces(String original);

  /// Label of one set row on the set-logging screen.
  ///
  /// In en, this message translates to:
  /// **'SET {number}'**
  String logSetNumber(int number);

  /// Placeholder of the repetitions field on a set row.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get logRepsHint;

  /// Placeholder of the weight field on a set row. {unit} is 'metric' (the athlete types kilograms) or 'imperial' (pounds); what they type is converted to pounds before it is stored.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{kg (optional)} other{lbs (optional)}}'**
  String logWeightHint(String unit);

  /// State of the per-set toggle once the set has been checked off. Keep it short — it sits in a small pill.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get logValidated;

  /// State of the per-set toggle before the set has been checked off. Keep it short — it sits in a small pill.
  ///
  /// In en, this message translates to:
  /// **'VALIDATE'**
  String get logValidate;

  /// Button on the last drill of a session.
  ///
  /// In en, this message translates to:
  /// **'FINISH SESSION'**
  String get logCtaFinishSession;

  /// Button that advances to the next drill of a session.
  ///
  /// In en, this message translates to:
  /// **'NEXT EXERCISE'**
  String get logCtaNextExercise;

  /// Hint under the disabled advance button while some sets are still unchecked.
  ///
  /// In en, this message translates to:
  /// **'Validate every set to continue'**
  String get logValidateEverySet;

  /// Headline of the session summary screen.
  ///
  /// In en, this message translates to:
  /// **'SESSION COMPLETE'**
  String get sessionCompleteTitle;

  /// Line under the session summary headline.
  ///
  /// In en, this message translates to:
  /// **'Nice work. Here\'s what you logged.'**
  String get sessionCompleteSubtitle;

  /// One line of the session summary. {exercise} is a drill name from the untranslated exercise library.
  ///
  /// In en, this message translates to:
  /// **'{exercise}: {sets} sets, {reps} reps'**
  String sessionCompleteRow(String exercise, int sets, int reps);

  /// Button that persists the session and returns to the Train tab.
  ///
  /// In en, this message translates to:
  /// **'SAVE & FINISH'**
  String get sessionCompleteCta;

  /// Title of the confirmation dialog shown when the athlete tries to leave a training session (close icon or system back) after the warm-up, before it has been saved.
  ///
  /// In en, this message translates to:
  /// **'Discard this session?'**
  String get sessionDiscardTitle;

  /// Body of the discard-session confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Nothing from this session has been saved yet. If you leave now, the sets you logged are lost.'**
  String get sessionDiscardBody;

  /// Destructive button of the discard-session dialog: leaves the session and throws away what was logged.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get sessionDiscardConfirm;

  /// Safe button of the discard-session dialog: closes the dialog and returns to the session.
  ///
  /// In en, this message translates to:
  /// **'Keep training'**
  String get sessionDiscardKeep;

  /// Header of the full drill guide screen.
  ///
  /// In en, this message translates to:
  /// **'EXERCISE GUIDE'**
  String get exerciseGuideHeader;

  /// Section title above the drill's summary. The summary text itself comes from the untranslated exercise library.
  ///
  /// In en, this message translates to:
  /// **'WHY IT MATTERS'**
  String get exerciseGuideWhyItMatters;

  /// Section title above the drill's numbered execution steps.
  ///
  /// In en, this message translates to:
  /// **'HOW TO DO IT'**
  String get exerciseGuideHowToDoIt;

  /// Section title above the drill's list of common errors.
  ///
  /// In en, this message translates to:
  /// **'COMMON MISTAKES'**
  String get exerciseGuideCommonMistakes;

  /// Section title above the qualities and muscles the drill develops.
  ///
  /// In en, this message translates to:
  /// **'WHAT IT TRAINS'**
  String get exerciseGuideWhatItTrains;

  /// Title of the substitution note on the drill guide.
  ///
  /// In en, this message translates to:
  /// **'SWAPPED FOR YOUR HOME SETUP'**
  String get exerciseGuideSwappedTitle;

  /// Body of the substitution note when the replaced drill has no authored name to quote.
  ///
  /// In en, this message translates to:
  /// **'The authored drill needs equipment you told us you do not train with. This one trains the same quality with nothing but the floor.'**
  String get exerciseGuideSwappedBody;

  /// Body of the substitution note on the drill guide. {original} is the replaced drill's name, from the untranslated exercise library.
  ///
  /// In en, this message translates to:
  /// **'Replaces {original}, which needs equipment you told us you do not train with. This one trains the same quality with nothing but the floor.'**
  String exerciseGuideSwappedBodyNamed(String original);

  /// Shown on the drill guide when nothing has been authored for it.
  ///
  /// In en, this message translates to:
  /// **'No coaching notes are written for this drill yet.'**
  String get exerciseGuideEmpty;

  /// Title of the empty demonstration slot on the drill guide.
  ///
  /// In en, this message translates to:
  /// **'NO DEMO CLIP YET'**
  String get exerciseGuideNoDemoTitle;

  /// Body of the empty demonstration slot on the drill guide.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been filmed for this drill. The steps below are the full instruction.'**
  String get exerciseGuideNoDemoBody;

  /// Caption of a lone demonstration still on the drill guide.
  ///
  /// In en, this message translates to:
  /// **'POSITION'**
  String get exerciseGuideFramePosition;

  /// Caption of the first demonstration still (starting position) on the drill guide.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get exerciseGuideFrameStart;

  /// Caption of the second demonstration still (finishing position) on the drill guide.
  ///
  /// In en, this message translates to:
  /// **'FINISH'**
  String get exerciseGuideFrameFinish;

  /// Caption under the demonstration stills on the drill guide, making clear whose body is shown.
  ///
  /// In en, this message translates to:
  /// **'Reference photos, not a recording of your own jump.'**
  String get exerciseGuideFrameDisclaimer;

  /// A jump's date written out, used on the Feed's personal board rows. Formatted by intl, so month names and order follow the locale.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String jumpDateMedium(DateTime date);

  /// Heading at the top of the Feed tab.
  ///
  /// In en, this message translates to:
  /// **'LEADERBOARDS'**
  String get feedTitle;

  /// Title of the Feed's global leaderboard section.
  ///
  /// In en, this message translates to:
  /// **'ALL-TIME VERTICAL'**
  String get feedGlobalTitle;

  /// Subtitle of the Feed's global leaderboard section. 'DunkIt' is the app name and stays as is.
  ///
  /// In en, this message translates to:
  /// **'Every DunkIt athlete, ranked by their best measured jump.'**
  String get feedGlobalSubtitle;

  /// Title of the Feed's own-jumps board, below the global one.
  ///
  /// In en, this message translates to:
  /// **'YOUR BEST JUMPS'**
  String get feedPersonalTitle;

  /// Subtitle of the Feed's own-jumps board.
  ///
  /// In en, this message translates to:
  /// **'Every jump you have analyzed, ranked by vertical.'**
  String get feedPersonalSubtitle;

  /// Title of the Feed notice shown when the app was built without leaderboard credentials.
  ///
  /// In en, this message translates to:
  /// **'Global board is off in this build'**
  String get feedNotConfiguredTitle;

  /// Body of the Feed notice shown when the app was built without leaderboard credentials.
  ///
  /// In en, this message translates to:
  /// **'This copy of the app was built without leaderboard credentials, so there is nothing to connect to. Everything else works offline.'**
  String get feedNotConfiguredBody;

  /// Title of the Feed notice shown when the leaderboard request failed.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the global board'**
  String get feedUnavailableTitle;

  /// Body of the Feed notice shown when the leaderboard request failed.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and pull down to try again. Your own jumps below are stored on this device and are unaffected.'**
  String get feedUnavailableBody;

  /// Title of the Feed notice shown when the global board is reachable but empty.
  ///
  /// In en, this message translates to:
  /// **'No athletes ranked yet'**
  String get feedNoAthletesTitle;

  /// Body of the Feed notice shown when the global board is reachable but empty.
  ///
  /// In en, this message translates to:
  /// **'Nobody has posted a measured jump yet. Analyze one and you take the top spot.'**
  String get feedNoAthletesBody;

  /// Caption under the Feed's loading skeleton rows.
  ///
  /// In en, this message translates to:
  /// **'Loading the global board…'**
  String get feedLoading;

  /// Pill marking the athlete's own row on the global board. Keep it very short.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get feedYouBadge;

  /// The measured vertical on a Feed row, both the global board and the athlete's own. {unit} is 'metric' ({value} in centimetres) or 'imperial' ({value} in inches); the value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{{value} cm vert} other{{value}\" vert}}'**
  String feedJumpStat(String unit, int value);

  /// Suffix on a Feed personal-board row naming the kind of attempt. {attempt} comes from the untranslated attempt-type model.
  ///
  /// In en, this message translates to:
  /// **' · {attempt}'**
  String feedAttemptSeparator(String attempt);

  /// Used in place of the attempt type on a Feed personal-board row when the entry recorded none.
  ///
  /// In en, this message translates to:
  /// **'Jump'**
  String get feedAttemptFallback;

  /// Suffix on a global-board row giving the athlete's height. {height} is already formatted by heightValueCompact (6'1" or 185 cm).
  ///
  /// In en, this message translates to:
  /// **' · {height}'**
  String feedGlobalStatSeparator(String height);

  /// Badge for a board position outside the top three.
  ///
  /// In en, this message translates to:
  /// **'#{rank}'**
  String feedRankNumber(int rank);

  /// Title of the Feed's own-board empty state.
  ///
  /// In en, this message translates to:
  /// **'No jumps ranked yet'**
  String get feedEmptyPersonalTitle;

  /// Body of the Feed's own-board empty state.
  ///
  /// In en, this message translates to:
  /// **'Analyze your first jump to start your board.'**
  String get feedEmptyPersonalBody;

  /// Title of the Feed card asking the athlete to choose a board name.
  ///
  /// In en, this message translates to:
  /// **'You\'re not on the board yet'**
  String get feedNamePromptTitle;

  /// Body of the Feed card asking the athlete to choose a board name. The promise that clips never leave the device is load-bearing — keep it.
  ///
  /// In en, this message translates to:
  /// **'Pick a board name and your best measured jump gets ranked with everyone else. Only the name, the vertical and your height are shared — never your clips.'**
  String get feedNamePromptBody;

  /// Button on the Feed card that opens the board-name dialog.
  ///
  /// In en, this message translates to:
  /// **'SET MY BOARD NAME'**
  String get feedSetBoardName;

  /// Title of the dialog that sets the leaderboard display name.
  ///
  /// In en, this message translates to:
  /// **'Your board name'**
  String get displayNameTitle;

  /// Explanation in the board-name dialog. The privacy promise is load-bearing — keep it.
  ///
  /// In en, this message translates to:
  /// **'This is the only thing other athletes see. Your clips never leave this phone.'**
  String get displayNameBody;

  /// Placeholder in the board-name field. Substitute a first name that reads as ordinary in the target language.
  ///
  /// In en, this message translates to:
  /// **'e.g. Marcus'**
  String get displayNameHint;

  /// Name of the form score measuring ground-contact time / reactivity. Shown on the Analyze result and inside the intro carousel's phone mockup.
  ///
  /// In en, this message translates to:
  /// **'BOUNCE'**
  String get scoreBounce;

  /// Name of the form score measuring countermovement depth and hip drive.
  ///
  /// In en, this message translates to:
  /// **'POWER'**
  String get scorePower;

  /// Name of the form score measuring left/right symmetry and torso lean.
  ///
  /// In en, this message translates to:
  /// **'CONTROL'**
  String get scoreControl;

  /// Name of the form score measuring arm-swing amplitude and timing.
  ///
  /// In en, this message translates to:
  /// **'FORM'**
  String get scoreForm;

  /// Heading of the Analyze tab's first screen.
  ///
  /// In en, this message translates to:
  /// **'ANALYZE'**
  String get analyzeTitle;

  /// Paragraph under the Analyze heading explaining how to film a usable clip.
  ///
  /// In en, this message translates to:
  /// **'Film your jump straight-on, full body in frame. We track your feet to time the flight, then gravity gives the height — no calibration needed.'**
  String get analyzeIntro;

  /// Error shown when the camera or photo library could not be opened.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t access the camera or library.'**
  String get analyzePickError;

  /// Label of the record button while the camera or library is opening.
  ///
  /// In en, this message translates to:
  /// **'ONE SEC…'**
  String get analyzeBusyCta;

  /// Primary button that opens the camera to film a jump.
  ///
  /// In en, this message translates to:
  /// **'RECORD A JUMP'**
  String get analyzeRecordCta;

  /// Link that imports an existing clip instead of filming one.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get analyzeChooseLibrary;

  /// Skip link shown only during the pre-paywall free analysis.
  ///
  /// In en, this message translates to:
  /// **'I\'ll do this later'**
  String get analyzeSkip;

  /// Line under the skip link during the pre-paywall free analysis.
  ///
  /// In en, this message translates to:
  /// **'You can analyze anytime from the app.'**
  String get analyzeSkipSubtitle;

  /// Heading of the trim step, where the clip is narrowed to a single jump.
  ///
  /// In en, this message translates to:
  /// **'TRIM VIDEO'**
  String get trimTitle;

  /// Link in the trim step's header that abandons this clip.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get trimCancel;

  /// First instruction line under the trim preview.
  ///
  /// In en, this message translates to:
  /// **'Drag the handles on the timeline to trim.'**
  String get trimHintDrag;

  /// Second instruction line under the trim preview. Trimming to one jump is what buys measurement accuracy, so keep the point.
  ///
  /// In en, this message translates to:
  /// **'Start / End — adjust to one jump or dunk for best analysis.'**
  String get trimHintRange;

  /// Label of the trim range's start timecode.
  ///
  /// In en, this message translates to:
  /// **'START:'**
  String get trimStartLabel;

  /// Label of the trim range's end timecode.
  ///
  /// In en, this message translates to:
  /// **'END:'**
  String get trimEndLabel;

  /// Button that sends the trimmed range to the detector.
  ///
  /// In en, this message translates to:
  /// **'ANALYZE'**
  String get trimAnalyzeCta;

  /// Link under the trim button that goes back to filming.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get trimRetake;

  /// Shown when the chosen video cannot be opened for trimming.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load that clip.'**
  String get trimLoadError;

  /// Button on the trim screen's error state.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get trimTryAgain;

  /// First half of the processing screen's headline, in white. Reads as one phrase with processingHeadlineAccent.
  ///
  /// In en, this message translates to:
  /// **'ANALYZING'**
  String get processingHeadline;

  /// Second half of the processing screen's headline, in orange. The leading space is intentional — it follows processingHeadline directly.
  ///
  /// In en, this message translates to:
  /// **' YOUR JUMP'**
  String get processingHeadlineAccent;

  /// Small caps badge under the processing headline.
  ///
  /// In en, this message translates to:
  /// **'AI PROCESSING'**
  String get processingBadge;

  /// First checklist step on the processing screen. These track real stages of the pass, not a timed animation.
  ///
  /// In en, this message translates to:
  /// **'Tracking your body through the clip'**
  String get processingStepTracking;

  /// Second checklist step on the processing screen.
  ///
  /// In en, this message translates to:
  /// **'Finding your takeoff and landing'**
  String get processingStepLocating;

  /// Third checklist step on the processing screen.
  ///
  /// In en, this message translates to:
  /// **'Estimating your vertical'**
  String get processingStepEstimating;

  /// Heading of the screen shown when the detector declined to measure the clip.
  ///
  /// In en, this message translates to:
  /// **'NO MEASUREMENT'**
  String get unmeasuredTitle;

  /// Line under the no-measurement heading. The refusal to invent a number is the point — keep it.
  ///
  /// In en, this message translates to:
  /// **'We\'d rather tell you than guess a number.'**
  String get unmeasuredSubtitle;

  /// Verdict shown when no airborne window was found.
  ///
  /// In en, this message translates to:
  /// **'We tracked you, but your feet never clearly left the floor.'**
  String get unmeasuredNoWindowHeadline;

  /// First fix suggested when no airborne window was found.
  ///
  /// In en, this message translates to:
  /// **'Trim the clip so it holds the jump and a moment either side.'**
  String get unmeasuredNoWindowFix1;

  /// Second fix suggested when no airborne window was found.
  ///
  /// In en, this message translates to:
  /// **'Keep your feet in frame the whole time — they are what we time.'**
  String get unmeasuredNoWindowFix2;

  /// Third fix suggested when no airborne window was found.
  ///
  /// In en, this message translates to:
  /// **'Film from the side or straight on, not from above.'**
  String get unmeasuredNoWindowFix3;

  /// Verdict shown when too many frames had no usable pose.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t keep track of your body through the clip.'**
  String get unmeasuredLostTrackHeadline;

  /// First fix suggested when the body could not be tracked.
  ///
  /// In en, this message translates to:
  /// **'Get your whole body in frame, head to feet.'**
  String get unmeasuredLostTrackFix1;

  /// Second fix suggested when the body could not be tracked.
  ///
  /// In en, this message translates to:
  /// **'More light helps — tracking struggles in a dim gym.'**
  String get unmeasuredLostTrackFix2;

  /// Third fix suggested when the body could not be tracked.
  ///
  /// In en, this message translates to:
  /// **'Avoid a busy background directly behind you.'**
  String get unmeasuredLostTrackFix3;

  /// Verdict shown when tracking dropped out during the flight.
  ///
  /// In en, this message translates to:
  /// **'We lost you in the middle of the jump itself.'**
  String get unmeasuredGappyHeadline;

  /// First fix suggested when tracking dropped out mid-flight.
  ///
  /// In en, this message translates to:
  /// **'Step back so your whole body stays in frame at the top.'**
  String get unmeasuredGappyFix1;

  /// Second fix suggested when tracking dropped out mid-flight.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone still — panning up with the jump loses you.'**
  String get unmeasuredGappyFix2;

  /// Third fix suggested when tracking dropped out mid-flight.
  ///
  /// In en, this message translates to:
  /// **'Brighter light reduces the motion blur at takeoff.'**
  String get unmeasuredGappyFix3;

  /// Verdict shown when the measured lift was below what can be timed.
  ///
  /// In en, this message translates to:
  /// **'The jump in this clip is too small to time reliably.'**
  String get unmeasuredSmallJumpHeadline;

  /// First fix suggested when the jump was too small to time.
  ///
  /// In en, this message translates to:
  /// **'Trim to your best attempt if the clip holds several.'**
  String get unmeasuredSmallJumpFix1;

  /// Second fix suggested when the jump was too small to time.
  ///
  /// In en, this message translates to:
  /// **'Film a full-effort jump — a warm-up hop is below what we can time.'**
  String get unmeasuredSmallJumpFix2;

  /// Verdict shown when the airborne window was physically implausible.
  ///
  /// In en, this message translates to:
  /// **'The flight time we measured is outside what a real jump can be.'**
  String get unmeasuredImplausibleHeadline;

  /// First fix suggested when the flight time was implausible.
  ///
  /// In en, this message translates to:
  /// **'Trim tightly around a single jump.'**
  String get unmeasuredImplausibleFix1;

  /// Second fix suggested when the flight time was implausible.
  ///
  /// In en, this message translates to:
  /// **'Make sure the clip plays at normal speed — slow motion breaks the timing.'**
  String get unmeasuredImplausibleFix2;

  /// Verdict shown when the clip yielded too few frames to analyse.
  ///
  /// In en, this message translates to:
  /// **'The clip is too short to read.'**
  String get unmeasuredTooShortHeadline;

  /// Fix suggested when the clip was too short.
  ///
  /// In en, this message translates to:
  /// **'Include a moment before the jump and after the landing.'**
  String get unmeasuredTooShortFix1;

  /// Verdict on the no-measurement screen when no frame of the clip could be decoded or analysed at all — a problem with the file, not with the jump.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read this video.'**
  String get unmeasuredUnreadableHeadline;

  /// First fix suggested when the clip could not be read at all.
  ///
  /// In en, this message translates to:
  /// **'Try again — if it keeps happening, record a new clip with the camera.'**
  String get unmeasuredUnreadableFix1;

  /// Second fix suggested when the clip could not be read at all.
  ///
  /// In en, this message translates to:
  /// **'Videos saved from other apps sometimes can\'t be opened; one filmed on this phone will work.'**
  String get unmeasuredUnreadableFix2;

  /// Verdict shown when the detector reported no specific reason.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t measure this clip.'**
  String get unmeasuredGenericHeadline;

  /// Fix suggested when the detector reported no specific reason.
  ///
  /// In en, this message translates to:
  /// **'Trim tightly around a single jump and try again.'**
  String get unmeasuredGenericFix1;

  /// Primary button on the no-measurement screen; reopens the trim step on the same clip.
  ///
  /// In en, this message translates to:
  /// **'TRIM AND TRY AGAIN'**
  String get unmeasuredRetrimCta;

  /// Link on the no-measurement screen that starts over with another video.
  ///
  /// In en, this message translates to:
  /// **'Use a different clip'**
  String get unmeasuredNewClip;

  /// Heading of the Analyze result screen.
  ///
  /// In en, this message translates to:
  /// **'YOUR JUMP'**
  String get resultTitle;

  /// Button at the bottom of the Analyze result that restarts the flow.
  ///
  /// In en, this message translates to:
  /// **'ANALYZE ANOTHER JUMP'**
  String get resultCtaAnalyzeAnother;

  /// Label above the measured vertical on the Analyze result.
  ///
  /// In en, this message translates to:
  /// **'EST. VERT'**
  String get resultEstVert;

  /// Line under the measured vertical when it already meets the dunk target. {unit} is 'metric' ({target} in centimetres) or 'imperial' ({target} in inches); the value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{That clears your {target} cm dunk target} other{That clears your {target}\" dunk target}}'**
  String resultClearsDunk(String unit, int target);

  /// Line under the measured vertical when some vertical is still missing. {unit} is 'metric' ({gap} and {target} in centimetres) or 'imperial' (inches); both values are already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{{gap} cm to go to your {target} cm dunk target} other{{gap}\" to go to your {target}\" dunk target}}'**
  String resultGapToDunk(String unit, int gap, int target);

  /// Caveat on the Analyze result while the standing reach is still estimated. The measured vertical is real; only the target it is compared against is not. {unit} is 'metric' ({reach} in centimetres) or 'imperial' ({reach} in inches); the value is already converted.
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{Target assumes an estimated {reach} cm standing reach. Set your real reach in Settings for an exact one.} other{Target assumes an estimated {reach}\" standing reach. Set your real reach in Settings for an exact one.}}'**
  String resultEstimatedReachNote(String unit, int reach);

  /// Quiet line on the Analyze result's vert card, shown only on the athlete's first logged jump: the measured vertical replaces the self-reported 'today' figure the onboarding gap and potential screens showed. {value} is that onboarding estimate, already converted: {unit} is 'metric' (centimetres) or 'imperial' (inches).
  ///
  /// In en, this message translates to:
  /// **'{unit, select, metric{This measurement now stands in for your onboarding estimate of ~{value} cm.} other{This measurement now stands in for your onboarding estimate of ~{value}\".}}'**
  String resultReplacesOnboardingEstimate(String unit, int value);

  /// Pill on the Analyze result's form-scores card saying whether the athlete took off from one foot or two (shown upper-cased). Keyed on the TakeoffType enum name from core/jump_form_scores.dart.
  ///
  /// In en, this message translates to:
  /// **'{type, select, oneFoot{One-foot takeoff} twoFoot{Two-foot takeoff} other{{type}}}'**
  String takeoffTypeLabel(String type);

  /// Title of one clip-type chip on the Analyze source screen (shown upper-cased): is the clip a dunk attempt or a plain jump. Keyed on the VideoAttemptType enum name from core/models/video_attempt_type.dart.
  ///
  /// In en, this message translates to:
  /// **'{type, select, dunkAttempt{Dunk Attempt} jumpAttempt{Jump Attempt} other{{type}}}'**
  String videoAttemptTypeTitle(String type);

  /// Caption of one clip-type chip on the Analyze source screen. Keyed on the VideoAttemptType enum name.
  ///
  /// In en, this message translates to:
  /// **'{type, select, dunkAttempt{Rim or ball in frame} jumpAttempt{No rim needed} other{{type}}}'**
  String videoAttemptTypeSubtitle(String type);

  /// Title of the four-score card on the Analyze result.
  ///
  /// In en, this message translates to:
  /// **'FORM SCORES'**
  String get resultFormScoresTitle;

  /// Subtitle of the score card when body tracking never located the jump.
  ///
  /// In en, this message translates to:
  /// **'Scoring your form needs body tracking, and it could not follow you through this clip.'**
  String get resultScoresUnavailable;

  /// Subtitle of the score card when scores were measured.
  ///
  /// In en, this message translates to:
  /// **'Scored from your body in this clip — nothing is filled in where it could not be measured.'**
  String get resultScoresIntro;

  /// Footnote of the score card. There is no user base to compare against, and the copy must not imply one.
  ///
  /// In en, this message translates to:
  /// **'Scores rate your technique against coaching guidelines, not against other athletes.'**
  String get resultScoresDisclaimer;

  /// Shown on a score tile the clip could not support. Never a zero or a filler number.
  ///
  /// In en, this message translates to:
  /// **'Not measured'**
  String get resultNotMeasured;

  /// Reason on a score tile when body tracking never ran at all. Lowercase — the app capitalises the first letter itself.
  ///
  /// In en, this message translates to:
  /// **'body tracking did not run'**
  String get resultNoTrackingReason;

  /// Suffix after a score value on a score tile.
  ///
  /// In en, this message translates to:
  /// **'/100'**
  String get resultScoreDenominator;

  /// Score pill on a strongest/weakest row of the jump breakdown.
  ///
  /// In en, this message translates to:
  /// **'{score}/100'**
  String resultScoreOutOf(int score);

  /// Title of the written coaching card on the Analyze result.
  ///
  /// In en, this message translates to:
  /// **'JUMP BREAKDOWN'**
  String get resultBreakdownTitle;

  /// Caption of the best-scoring aspect row in the jump breakdown.
  ///
  /// In en, this message translates to:
  /// **'STRONGEST'**
  String get resultStrongest;

  /// Caption of the worst-scoring aspect row in the jump breakdown.
  ///
  /// In en, this message translates to:
  /// **'WEAKEST'**
  String get resultWeakest;

  /// Header of a strongest/weakest row. {aspect} is the score name, which comes from untranslated core code.
  ///
  /// In en, this message translates to:
  /// **'{caption} · {aspect}'**
  String resultAspectCaption(String caption, String aspect);

  /// The raw observation behind a strongest/weakest row. {measurement} comes from untranslated core code.
  ///
  /// In en, this message translates to:
  /// **'Measured: {measurement}'**
  String resultMeasuredPrefix(String measurement);

  /// Heading above the coaching tips when a weakness could be ranked.
  ///
  /// In en, this message translates to:
  /// **'HOW TO WORK ON IT'**
  String get resultHowToWorkOnIt;

  /// Heading above the coaching tips when nothing could be ranked.
  ///
  /// In en, this message translates to:
  /// **'GENERAL TIPS TO CLOSE THE GAP'**
  String get resultGeneralTips;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
