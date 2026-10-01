// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get commonContinue => 'CONTINUER';

  @override
  String get commonClose => 'Fermer';

  @override
  String length(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$value cm',
        'other': '$value po',
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
        'other': '~$value po',
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
        'other': '-$value po',
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
        'other': '+$value po',
      },
    );
    return '$_temp0';
  }

  @override
  String get introPanel1Headline => 'DÉCOUVRE TA\nVRAIE DÉTENTE';

  @override
  String introPanel1Support(String unit) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric':
            'Filme un saut. On chronomètre ton temps de suspension image par image et on le convertit en centimètres — pas de mètre ruban, pas d\'approximation.',
        'other':
            'Filme un saut. On chronomètre ton temps de suspension image par image et on le convertit en pouces — pas de mètre ruban, pas d\'approximation.',
      },
    );
    return '$_temp0';
  }

  @override
  String get introPanel2Headline => 'ENTRAÎNE-TOI AVEC\nUN VRAI PLAN';

  @override
  String get introPanel2Support =>
      'Un programme semaine par semaine adapté à ton niveau, à ton emploi du temps et au matériel que tu as vraiment.';

  @override
  String get introPanel3Headline => 'REGARDE TA\nDÉTENTE MONTER';

  @override
  String get introPanel3Support =>
      'Chaque saut filmé et chaque séance terminée sont enregistrés : ta progression devient un chiffre, plus une impression.';

  @override
  String get introStartCta => 'C\'EST PARTI';

  @override
  String get goalTitle => 'QUEL EST TON\nOBJECTIF DUNK ?';

  @override
  String get goalSubtitle =>
      'Choisis tous les objectifs qui te motivent. Ils vont dans ton profil — ton plan, lui, dépend de ton niveau, de ton emploi du temps et de l\'endroit où tu t\'entraînes.';

  @override
  String dunkGoalTitle(String goal) {
    String _temp0 = intl.Intl.selectLogic(
      goal,
      {
        'firstDunk': 'Premier dunk',
        'dunkInGames': 'Dunker en match',
        'windmillsAnd360s': 'Windmills & 360',
        'alleyOopFinishing': 'Finir les alley-oops',
        'maxVertical': 'Détente max',
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
        'firstDunk': 'Décroche ton premier dunk',
        'dunkInGames': 'Conclure quand ça compte',
        'windmillsAnd360s': 'Du style et du flair',
        'alleyOopFinishing': 'Attraper et finir',
        'maxVertical': 'Gagne des pouces de détente',
        'other': '$goal',
      },
    );
    return '$_temp0';
  }

  @override
  String get experienceTitle =>
      'QUELLE EST TON\nEXPÉRIENCE EN\nTRAVAIL DE DÉTENTE ?';

  @override
  String get experienceSubtitle =>
      'Pas d\'ego ici. Sois honnête pour qu\'on te pousse au bon niveau.';

  @override
  String experienceLevelTitle(String level) {
    String _temp0 = intl.Intl.selectLogic(
      level,
      {
        'beginner': 'Débutant',
        'intermediate': 'Intermédiaire',
        'advanced': 'Avancé',
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
        'beginner': 'J\'ai de la détente mais pas de plan',
        'intermediate': 'J\'ai déjà bossé, prêt à passer un cap',
        'advanced': 'Je cherche les derniers pouces',
        'other': '$level',
      },
    );
    return '$_temp0';
  }

  @override
  String get positionTitle => 'À QUEL POSTE\nJOUES-TU ?';

  @override
  String courtPositionLabel(String position) {
    String _temp0 = intl.Intl.selectLogic(
      position,
      {
        'pointGuard': 'Meneur',
        'shootingGuard': 'Arrière',
        'smallForward': 'Ailier',
        'powerForward': 'Ailier fort',
        'center': 'Pivot',
        'other': '$position',
      },
    );
    return '$_temp0';
  }

  @override
  String get daysTitle =>
      'COMBIEN DE JOURS\nPAR SEMAINE\nPEUX-TU T\'ENTRAÎNER ?';

  @override
  String get daysSubtitle =>
      'On reste réaliste. La régularité bat l\'intensité.';

  @override
  String get daysBanner =>
      'Plus de séances par semaine, c\'est plus de volume — choisis ce que tu peux vraiment tenir.';

  @override
  String get daysChipUnit => 'jours';

  @override
  String get locationTitle => 'OÙ VAS-TU\nT\'ENTRAÎNER ?';

  @override
  String get locationSubtitle =>
      'On te proposera des programmes adaptés à ton matériel.';

  @override
  String trainingLocationTitle(String location) {
    String _temp0 = intl.Intl.selectLogic(
      location,
      {
        'home': 'À la maison',
        'gym': 'En salle',
        'both': 'Les deux',
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
        'home': 'Poids du corps & matériel minimal',
        'gym': 'Accès complet aux charges & machines',
        'both': 'Entraîne-toi n\'importe où, n\'importe quand',
        'other': '$location',
      },
    );
    return '$_temp0';
  }

  @override
  String get hopsTitle => 'OÙ EN EST TA\nDÉTENTE AUJOURD\'HUI ?';

  @override
  String get hopsSubtitle =>
      'Sois honnête — c\'est ce qui fixe ton estimation de départ.';

  @override
  String hopsLevelTitle(String level) {
    String _temp0 = intl.Intl.selectLogic(
      level,
      {
        'dunkConsistently': 'Je dunke régulièrement',
        'dunkOnGoodDay': 'Je dunke les bons jours',
        'grabRim': 'J\'attrape le cercle',
        'touchRim': 'Je touche le cercle',
        'belowRim': 'Sous le cercle',
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
        'dunkConsistently': 'En quête de finishes plus gros',
        'dunkOnGoodDay': 'C\'est en toi — pas encore régulier',
        'grabRim': 'Les doigts accrochés à l\'arceau les bons jours',
        'touchRim': 'Le bout des doigts sur l\'arceau',
        'belowRim': 'On construit depuis le sol',
        'other': '$level',
      },
    );
    return '$_temp0';
  }

  @override
  String get heightTitle => 'TA TAILLE';

  @override
  String get heightSubtitle =>
      'Elle fixe ton extension debout estimée — et, à partir de là, la détente qu\'il te faut pour dunker.';

  @override
  String heightUnitLabel(String unit) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': 'CENTIMÈTRES',
        'other': 'PIEDS & POUCES',
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
    return '$feet pi';
  }

  @override
  String heightInchesOption(int inches) {
    return '$inches po';
  }

  @override
  String get weightTitle => 'TON POIDS';

  @override
  String get savedToAthleteProfile => 'Enregistré dans ton profil athlète.';

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
  String get ageTitle => 'TON ÂGE';

  @override
  String get ageUnitLabel => 'ANS';

  @override
  String ageOption(int years) {
    return '$years ans';
  }

  @override
  String get dunkHandTitle => 'AVEC QUELLE MAIN\nDUNKES-TU ?';

  @override
  String get dunkHandSubtitle =>
      'Cela fixe la marge au-dessus de l\'arceau dont ton finish a besoin.';

  @override
  String dunkHandClearanceNote(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric':
            'Un dunk à une main demande de passer le ballon et une main au-dessus de l\'arceau. Les deux avant-bras au-dessus, c\'est environ $value cm de plus : un finish à deux mains relève ta cible.',
        'other':
            'Un dunk à une main demande de passer le ballon et une main au-dessus de l\'arceau. Les deux avant-bras au-dessus, c\'est environ $value po de plus : un finish à deux mains relève ta cible.',
      },
    );
    return '$_temp0';
  }

  @override
  String dunkHandOptionTitle(String hand) {
    String _temp0 = intl.Intl.selectLogic(
      hand,
      {
        'left': 'Main gauche',
        'right': 'Main droite',
        'both': 'Les deux mains',
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
        'left': 'Finish à une main',
        'right': 'Finish à une main',
        'both': 'Demande plus de marge au-dessus du cercle',
        'other': '$hand',
      },
    );
    return '$_temp0';
  }

  @override
  String get commitmentTitle =>
      'À QUEL POINT ES-TU\nENGAGÉ DANS TON OBJECTIF ?';

  @override
  String get commitmentSubtitle =>
      'Celle-ci ne change pas ton plan. C\'est une promesse que tu te fais — enregistrée dans ton profil.';

  @override
  String commitmentLevelTitle(String level) {
    String _temp0 = intl.Intl.selectLogic(
      level,
      {
        'extremely': 'À fond',
        'very': 'Très engagé',
        'needHelp': 'J\'ai besoin d\'aide pour rester régulier',
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
        'extremely': 'Prêt à faire ce qu\'il faut',
        'very': 'Je veux un plan clair et un cadre',
        'needHelp': 'Garde-moi dedans semaine après semaine',
        'other': '$level',
      },
    );
    return '$_temp0';
  }

  @override
  String get gapBasedOnReach => 'D\'APRÈS TON EXTENSION + TA DÉTENTE';

  @override
  String get gapBasedOnHeight => 'D\'APRÈS TA TAILLE + TA DÉTENTE';

  @override
  String get gapTitle => 'VOILÀ L\'ÉCART.';

  @override
  String get gapTitleCanDunk => 'TU AS DÉJÀ LA DÉTENTE.';

  @override
  String gapIntro(String unit, String height, int current, int target) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric':
            'Tu mesures $height. Environ $current cm aujourd\'hui. Dunker demande en général ~$target cm.',
        'other':
            'Tu mesures $height. Environ $current po aujourd\'hui. Dunker demande en général ~$target po.',
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
            'Tu mesures $height. Environ $current cm aujourd\'hui, et dunker demande en général ~$target cm. À partir de là, le plan sert à prendre de la marge et à gagner en régularité.',
        'other':
            'Tu mesures $height. Environ $current po aujourd\'hui, et dunker demande en général ~$target po. À partir de là, le plan sert à prendre de la marge et à gagner en régularité.',
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
            'Tu as choisi un finish à deux mains, qui demande les deux avant-bras au-dessus de l\'arceau — environ $value cm de plus qu\'un dunk à une main. Ta cible en tient compte.',
        'other':
            'Tu as choisi un finish à deux mains, qui demande les deux avant-bras au-dessus de l\'arceau — environ $value po de plus qu\'un dunk à une main. Ta cible en tient compte.',
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
            'Basé sur une extension debout estimée à $reach cm d\'après ta taille. Mesure ta vraie extension — dans les Réglages, à tout moment — pour une cible exacte.',
        'other':
            'Basé sur une extension debout estimée à $reach po d\'après ta taille. Mesure ta vraie extension — dans les Réglages, à tout moment — pour une cible exacte.',
      },
    );
    return '$_temp0';
  }

  @override
  String get gapMeterToday => 'AUJOURD\'HUI';

  @override
  String get gapMeterGap => 'ÉCART EST.';

  @override
  String get gapMeterMargin => 'MARGE EST.';

  @override
  String get gapMeterDunk => 'DUNK';

  @override
  String get gapRowHeight => 'Taille';

  @override
  String get gapRowStandingReach => 'Extension debout';

  @override
  String get gapRowEstToday => 'Est. aujourd\'hui';

  @override
  String get gapRowDunkTarget => 'Cible dunk';

  @override
  String get gapRowWeight => 'Poids';

  @override
  String get gapRowHops => 'Détente';

  @override
  String get gapRowGoals => 'Objectifs';

  @override
  String get gapGoalsSeparator => ', ';

  @override
  String get gapRowTrainingDays => 'Jours d\'entraînement';

  @override
  String gapReachEstimatedSuffix(String unit, int reach) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$reach cm (est.)',
        'other': '$reach po (est.)',
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
        'other': '$value lb',
      },
    );
    return '$_temp0';
  }

  @override
  String gapTrainingDaysValue(int days) {
    return '$days/semaine';
  }

  @override
  String get gapDefaultGoal => 'Ton premier dunk';

  @override
  String get gapCta => 'COMBLER L\'ÉCART';

  @override
  String get gapCtaCanDunk => 'PRENDRE DE LA MARGE';

  @override
  String get potentialTitle => 'TON POTENTIEL DE DÉTENTE';

  @override
  String get potentialSubtitle =>
      'Une courbe de progression typique pour ton âge, à partir de ton estimation d\'aujourd\'hui — pas une promesse. Ce sont tes sauts enregistrés qui diront la vérité.';

  @override
  String potentialWeekLabel(int week) {
    return 'SEM $week';
  }

  @override
  String potentialWindowLabel(int weeks) {
    return 'PROJECTION SUR $weeks SEMAINES';
  }

  @override
  String potentialFromToday(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': 'Potentiel à partir d\'une est. de ~$value cm aujourd\'hui.',
        'other': 'Potentiel à partir d\'une est. de ~$value po aujourd\'hui.',
      },
    );
    return '$_temp0';
  }

  @override
  String get potentialCta => 'VOIR MON PLAN';

  @override
  String get howItWorksTitle => 'COMMENT TA DÉTENTE\nEST MESURÉE';

  @override
  String get howItWorksSubtitle =>
      'Pas de capteur, pas de repère au sol. Juste la physique et l\'appareil photo de ton téléphone.';

  @override
  String get hangTimeLabel => 'TEMPS DE SUSPENSION';

  @override
  String get hangTimeDecides => 'détermine ta hauteur';

  @override
  String get hangTimeFormula => 'plus longtemps en l\'air  =  saut plus haut';

  @override
  String get hangTimeNote =>
      'Deux athlètes avec le même temps de suspension ont sauté à la même hauteur. C\'est exactement ce qu\'on mesure.';

  @override
  String get howItWorksPoint1Title => 'On suit ton corps, pas les pixels';

  @override
  String get howItWorksPoint1Body =>
      'Le suivi sur ton appareil traque tes pieds image par image et repère les instants précis où ils quittent le sol puis le retrouvent.';

  @override
  String get howItWorksPoint2Title => 'Mesuré, pas deviné';

  @override
  String get howItWorksPoint2Body =>
      'Ton temps de suspension donne ta hauteur par la seule gravité — sans calibrage de caméra, sans repère, sans estimation à l\'œil.';

  @override
  String get howItWorksPoint3Title => 'Un plan que tu peux vraiment suivre';

  @override
  String get howItWorksPoint3Body =>
      'Ton expérience, tes jours d\'entraînement et le fait d\'avoir une salle ou non déterminent ton programme — aucun exercice à la barre si tu t\'entraînes chez toi.';

  @override
  String get howItWorksPoint4Title => 'Une progression vérifiable';

  @override
  String get howItWorksPoint4Body =>
      'Chaque séance et chaque saut analysé sont enregistrés : la tendance que tu vois est ton propre historique, pas un chiffre de motivation.';

  @override
  String get howItWorksCta => 'LANCER MON PLAN';

  @override
  String get buildingPlanTitle => 'CONSTRUCTION DE TON PLAN';

  @override
  String buildingPlanSubtitle(String program) {
    return 'On t\'associe au programme $program';
  }

  @override
  String get planRevealTitle => 'VOILÀ TON PLAN';

  @override
  String get planRevealSubtitle =>
      'Adapté à ton niveau, à ton emploi du temps et à l\'endroit où tu t\'entraînes.';

  @override
  String planBadgeDays(int days) {
    return '$days JOURS';
  }

  @override
  String planBadgeWeeks(int weeks) {
    return '$weeks SEMAINES';
  }

  @override
  String get planThisWeek => 'CETTE SEMAINE';

  @override
  String programDayFocus(String focus) {
    String _temp0 = intl.Intl.selectLogic(
      focus,
      {
        'Power': 'PUISSANCE',
        'Strength': 'FORCE',
        'Speed': 'VITESSE',
        'Control': 'CONTRÔLE',
        'other': '$focus',
      },
    );
    return '$_temp0';
  }

  @override
  String get planDayRest => 'REPOS';

  @override
  String get mockJumpAnalysis => 'ANALYSE DE SAUT';

  @override
  String get mockEstVert => 'DÉTENTE EST.';

  @override
  String mockToDunk(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$value CM POUR DUNKER',
        'other': '$value PO POUR DUNKER',
      },
    );
    return '$_temp0';
  }

  @override
  String get mockFormScores => 'SCORES TECHNIQUES';

  @override
  String get mockJumpBreakdown => 'ANALYSE DÉTAILLÉE';

  @override
  String get mockWeekDay => 'SEMAINE 2 · JOUR 2 SUR 3';

  @override
  String get mockTodayPower => 'AUJOURD\'HUI · PUISSANCE';

  @override
  String get mockMiniBadgeDays => '3 JOURS';

  @override
  String get mockMiniBadgeGym => 'SALLE';

  @override
  String get mockMiniBadgeWeeks => '8 SEMAINES';

  @override
  String get mockProgress => 'PROGRESSION';

  @override
  String get mockCurrentVertical => 'DÉTENTE ACTUELLE';

  @override
  String mockSinceFirstTest(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '+$value CM DEPUIS LE 1ER TEST',
        'other': '+$value PO DEPUIS LE 1ER TEST',
      },
    );
    return '$_temp0';
  }

  @override
  String get mockWorkouts => 'SÉANCES';

  @override
  String get mockDayStreak => 'JOURS D\'AFFILÉE';

  @override
  String get paywallHeadline => 'DÉCROCHE TON\nPREMIER DUNK.';

  @override
  String paywallPlanBuilt(int days) {
    return 'Ton plan de $days jours est prêt. Annulable à tout moment.';
  }

  @override
  String paywallPlanBuiltWithTrial(int days, String trial) {
    return 'Ton plan de $days jours est prêt. $trial offert. Annulable à tout moment.';
  }

  @override
  String get paywallBenefit1Title => 'Ta détente, mesurée';

  @override
  String get paywallBenefit1Body =>
      'Analyse complète du saut — estimation de détente, écart jusqu\'à ton objectif et conseils';

  @override
  String get paywallBenefit2Title => 'Semaine 1, prête tout de suite';

  @override
  String get paywallBenefit2Body =>
      'Ton plan personnalisé démarre dès que tu débloques l\'app';

  @override
  String get paywallBenefit3Title => 'Chaque pouce suivi';

  @override
  String get paywallBenefit3Body =>
      'Suis ta progression vers ton objectif, semaine après semaine';

  @override
  String get paywallCancelAnytime => 'Annulable à tout moment.';

  @override
  String get paywallNoCommitment => 'Sans engagement. Annulable à tout moment.';

  @override
  String get paywallCtaContinueWithoutPurchase => 'CONTINUER SANS ACHAT';

  @override
  String get paywallCtaUnavailable => 'INDISPONIBLE';

  @override
  String get paywallPreviewBuildNote =>
      'Version de démonstration — les achats ne sont pas encore configurés : l\'app se débloque sans aucun paiement.';

  @override
  String get paywallDebugBuildNote =>
      'Version de développement — rien ne sera facturé.';

  @override
  String get paywallNoPurchasesInBuild =>
      'Les achats ne sont pas disponibles dans cette version.';

  @override
  String get paywallDisclosureNoConfig =>
      'Cette version n\'a aucune configuration d\'achat : rien n\'est en vente et rien ne sera facturé.';

  @override
  String get paywallDisclosureLoadFailed =>
      'Les formules d\'abonnement n\'ont pas pu être chargées. Rien n\'a été facturé.';

  @override
  String get paywallDisclosureUnavailable =>
      'Les achats sont indisponibles dans cette version.';

  @override
  String get paywallPlansUnavailableTitle => 'Formules indisponibles';

  @override
  String get paywallPurchasesUnavailableTitle =>
      'Achats indisponibles dans cette version';

  @override
  String get paywallPlansUnavailableBody =>
      'Impossible de joindre l\'App Store pour charger les prix des abonnements. Rien n\'a été facturé.';

  @override
  String get paywallPurchasesUnavailableBody =>
      'Cette version a été compilée sans identifiants d\'achat : il n\'y a rien à acheter ici.';

  @override
  String get paywallTryAgain => 'Réessayer';

  @override
  String get paywallBestValue => 'MEILLEURE OFFRE';

  @override
  String paywallSavePercent(int percent) {
    return 'Économise $percent %';
  }

  @override
  String get paywallViewOtherPlans => 'Voir les autres formules';

  @override
  String get paywallRestorePurchases => 'Restaurer les achats';

  @override
  String get paywallPrivacy => 'Confidentialité';

  @override
  String get paywallTerms => 'Conditions';

  @override
  String get paywallPrivacyPolicyTitle => 'Politique de confidentialité';

  @override
  String get paywallTermsOfUseTitle => 'Conditions d\'utilisation';

  @override
  String get paywallPageNotPublished => 'Cette page n\'est pas encore publiée.';

  @override
  String paywallCouldNotOpenLegal(String title, String url) {
    return 'Impossible d\'ouvrir $title. L\'adresse est $url';
  }

  @override
  String get paywallErrorNotEntitled =>
      'L\'achat a bien été effectué mais n\'a pas débloqué DunkIt. Essaie « Restaurer les achats », ou contacte le support — rien n\'est perdu.';

  @override
  String get paywallErrorUnavailable =>
      'Les achats sont indisponibles pour le moment. Réessaie plus tard.';

  @override
  String get paywallErrorFailed =>
      'L\'achat n\'a pas pu aboutir. Vérifie ta connexion et réessaie.';

  @override
  String get paywallErrorNothingToRestore =>
      'Aucun abonnement DunkIt actif trouvé sur cet identifiant Apple.';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get weekdayInitials => 'L,M,M,J,V,S,D';

  @override
  String lengthPlus(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '+$value cm',
        'other': '+$value po',
      },
    );
    return '$_temp0';
  }

  @override
  String get tabHome => 'ACCUEIL';

  @override
  String get tabAnalyze => 'ANALYSE';

  @override
  String get tabTrain => 'SÉANCE';

  @override
  String get tabFeed => 'CLASSEMENT';

  @override
  String get tabProgress => 'PROGRÈS';

  @override
  String get settingsTitle => 'RÉGLAGES';

  @override
  String get settingsLeaderboardName => 'Nom au classement';

  @override
  String get settingsStandingReach => 'Extension debout';

  @override
  String get settingsRetakeOnboarding => 'Refaire le questionnaire';

  @override
  String get settingsNotSet => 'Non renseigné';

  @override
  String get retakeOnboardingTitle => 'Refaire le questionnaire ?';

  @override
  String get retakeOnboardingBody =>
      'Cela efface ton profil actuel et te fait reprendre le questionnaire depuis le début.';

  @override
  String get retakeOnboardingConfirm => 'Refaire';

  @override
  String get standingReachHowTo =>
      'Colle-toi bien droit contre un mur, tends un bras le plus haut possible, marque le bout de tes doigts, puis mesure depuis le sol. Ta cible de dunk repose sur ce chiffre.';

  @override
  String standingReachValue(String unit, String label, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$value cm',
        'other': '$label  ·  $value po',
      },
    );
    return '$_temp0';
  }

  @override
  String standingReachEstimateNote(String label) {
    return 'Actuellement estimée à $label d\'après ta taille.';
  }

  @override
  String homeDayCounter(int session, int total) {
    return 'JOUR $session/$total';
  }

  @override
  String get homeTodayBadge => 'AUJOURD\'HUI';

  @override
  String get homeProgramComplete => 'PROGRAMME TERMINÉ';

  @override
  String get homeProgramCompleteBody =>
      'Tu as bouclé toutes les séances — beau travail.';

  @override
  String homeFocusDay(String focus) {
    return 'JOUR $focus';
  }

  @override
  String homeWeekSession(int week, int session, int total) {
    return 'Semaine $week • Séance $session/$total';
  }

  @override
  String get homeCtaViewTrain => 'VOIR LES SÉANCES';

  @override
  String get homeCtaStartSession => 'LANCER LA SÉANCE';

  @override
  String get homeLatestVert => 'DERNIÈRE DÉTENTE';

  @override
  String get homeDayStreak => 'JOURS D\'AFFILÉE';

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
  String get progressTitle => 'PROGRESSION';

  @override
  String get progressTrendTitle => 'ÉVOLUTION DE LA DÉTENTE';

  @override
  String get progressTrendEmpty =>
      'Enregistre quelques sauts de plus pour voir ta tendance';

  @override
  String get progressRecentAnalyses => 'ANALYSES RÉCENTES';

  @override
  String get progressViewAll => 'Tout voir';

  @override
  String get progressCurrentVertical => 'DÉTENTE ACTUELLE';

  @override
  String progressVertUnitSuffix(String unit) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '  cm',
        'other': '  po',
      },
    );
    return '$_temp0';
  }

  @override
  String get progressLogFirstJump =>
      'Enregistre ton premier test pour commencer le suivi';

  @override
  String get progressGoToAnalyze => 'Aller à Analyse';

  @override
  String progressSinceFirstGain(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '+$value cm depuis ton premier test',
        'other': '+$value po depuis ton premier test',
      },
    );
    return '$_temp0';
  }

  @override
  String progressSinceFirstLoss(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$value cm depuis ton premier test',
        'other': '$value po depuis ton premier test',
      },
    );
    return '$_temp0';
  }

  @override
  String get progressSinceFirstNoChange =>
      'Aucun changement depuis ton premier test';

  @override
  String get progressWorkouts => 'SÉANCES';

  @override
  String get progressCompleted => 'TERMINÉES';

  @override
  String get progressRemaining => 'RESTANTES';

  @override
  String get progressCompleteLabel => 'ACCOMPLI';

  @override
  String progressPercent(int percent) {
    return '$percent %';
  }

  @override
  String progressRemainingAndPercent(int remaining, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining RESTANTES · $percent % ACCOMPLI',
      one: '1 RESTANTE · $percent % ACCOMPLI',
    );
    return '$_temp0';
  }

  @override
  String get progressDayStreak => 'JOURS D\'AFFILÉE';

  @override
  String get progressStreakDaysSuffix => '  jours';

  @override
  String get jumpHistoryTitle => 'Historique des sauts';

  @override
  String get jumpHistoryEmpty => 'Aucun saut enregistré pour l\'instant.';

  @override
  String jumpVideoTitle(String unit, int value, DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$value cm · $dateString',
        'other': '$value po · $dateString',
      },
    );
    return '$_temp0';
  }

  @override
  String get jumpVideoLoadError => 'Impossible de charger cette vidéo.';

  @override
  String get jumpVideoMissing => 'Cette vidéo n\'est plus sur ton appareil.';

  @override
  String get jumpVideoShareFailed =>
      'Impossible d\'ouvrir le menu de partage. Réessaie.';

  @override
  String jumpShareText(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$value cm de détente — Dunk It',
        'other': '$value po de détente — Dunk It',
      },
    );
    return '$_temp0';
  }

  @override
  String get weekdayLabels => 'LUN,MAR,MER,JEU,VEN,SAM,DIM';

  @override
  String get trainTitle => 'SÉANCE';

  @override
  String get trainEnrolledProgram => 'PROGRAMME EN COURS';

  @override
  String trainPositionLabel(int week, int day, int sessionsPerWeek) {
    return 'SEMAINE $week · JOUR $day SUR $sessionsPerWeek';
  }

  @override
  String trainProgramMeta(String position, int weeks) {
    return '$position • $weeks SEMAINES';
  }

  @override
  String get trainDeloadPill => 'DÉCHARGE';

  @override
  String get trainDeloadExplainer =>
      'Semaine de décharge : moins de volume, volontairement. C\'est pendant les semaines allégées que le travail déjà fait se transforme en détente.';

  @override
  String trainWeekNumber(int week) {
    return 'SEMAINE $week';
  }

  @override
  String trainWeekSummary(int sessions, int rest) {
    return '$sessions séances • $rest repos';
  }

  @override
  String get trainRestDayTitle => 'JOUR DE REPOS';

  @override
  String get trainRestDaySubtitle => 'Tu t\'es déjà entraîné aujourd\'hui.';

  @override
  String get trainRestDayBody =>
      'La détente se construit entre les séances, pas pendant. Dors, mange, et laisse les tendons récupérer.';

  @override
  String trainUpNext(String focus) {
    return 'Prochaine séance : JOUR $focus';
  }

  @override
  String get trainTodaysExercises => 'EXERCICES DU JOUR';

  @override
  String trainExerciseCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercices',
      one: '$count exercice',
    );
    return '$_temp0';
  }

  @override
  String trainFocusAndWarmUp(String focus, String warmUp) {
    return '$focus • $warmUp';
  }

  @override
  String get trainDeloadVolumeNote =>
      'Le volume est réduit cette semaine — mêmes mouvements, moins de séries.';

  @override
  String get trainProgramProgress => 'AVANCEMENT DU PROGRAMME';

  @override
  String get trainCtaProgramComplete => 'PROGRAMME TERMINÉ';

  @override
  String get trainCtaTrainAnyway => 'M\'ENTRAÎNER QUAND MÊME';

  @override
  String get trainCtaStartSession => 'LANCER LA SÉANCE DU JOUR';

  @override
  String get warmUpHeader => 'ÉCHAUFFEMENT';

  @override
  String warmUpFocusDay(String focus) {
    return 'JOUR $focus';
  }

  @override
  String get warmUpDeloadNote =>
      'SEMAINE DE DÉCHARGE — moins de séries, volontairement. C\'est là que l\'adaptation se fait.';

  @override
  String get warmUpCardLabel => 'ÉCHAUFFEMENT';

  @override
  String get warmUpCta => 'COMMENCER LES EXERCICES';

  @override
  String logExerciseCounter(int index, int total) {
    return 'EXERCICE $index/$total';
  }

  @override
  String get logGuideTitle => 'COMMENT L\'EXÉCUTER';

  @override
  String logGuideSubtitle(int steps) {
    return '$steps étapes, erreurs fréquentes et ce que ça travaille.';
  }

  @override
  String get logGuideNone => 'Pas encore de consignes pour cet exercice.';

  @override
  String get logSwappedForHome => 'Adapté à ton matériel à la maison';

  @override
  String logSwappedForHomeReplaces(String original) {
    return 'Adapté à ton matériel à la maison — remplace $original';
  }

  @override
  String logSetNumber(int number) {
    return 'SÉRIE $number';
  }

  @override
  String get logRepsHint => 'reps';

  @override
  String logWeightHint(String unit) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': 'kg (facultatif)',
        'other': 'lb (facultatif)',
      },
    );
    return '$_temp0';
  }

  @override
  String get logValidated => 'FAIT';

  @override
  String get logValidate => 'VALIDER';

  @override
  String get logCtaFinishSession => 'TERMINER LA SÉANCE';

  @override
  String get logCtaNextExercise => 'EXERCICE SUIVANT';

  @override
  String get logValidateEverySet => 'Valide chaque série pour continuer';

  @override
  String get sessionCompleteTitle => 'SÉANCE TERMINÉE';

  @override
  String get sessionCompleteSubtitle =>
      'Beau travail. Voici ce que tu as enregistré.';

  @override
  String sessionCompleteRow(String exercise, int sets, int reps) {
    return '$exercise : $sets séries, $reps reps';
  }

  @override
  String get sessionCompleteCta => 'ENREGISTRER ET TERMINER';

  @override
  String get sessionDiscardTitle => 'Abandonner cette séance ?';

  @override
  String get sessionDiscardBody =>
      'Rien n\'est encore enregistré pour cette séance. Si tu quittes maintenant, les séries que tu as notées sont perdues.';

  @override
  String get sessionDiscardConfirm => 'Abandonner';

  @override
  String get sessionDiscardKeep => 'Continuer la séance';

  @override
  String get exerciseGuideHeader => 'FICHE EXERCICE';

  @override
  String get exerciseGuideWhyItMatters => 'POURQUOI C\'EST IMPORTANT';

  @override
  String get exerciseGuideHowToDoIt => 'COMMENT L\'EXÉCUTER';

  @override
  String get exerciseGuideCommonMistakes => 'ERREURS FRÉQUENTES';

  @override
  String get exerciseGuideWhatItTrains => 'CE QUE ÇA TRAVAILLE';

  @override
  String get exerciseGuideSwappedTitle => 'ADAPTÉ À TON MATÉRIEL À LA MAISON';

  @override
  String get exerciseGuideSwappedBody =>
      'L\'exercice prévu demande du matériel que tu n\'as pas indiqué. Celui-ci travaille la même qualité avec rien d\'autre que le sol.';

  @override
  String exerciseGuideSwappedBodyNamed(String original) {
    return 'Remplace $original, qui demande du matériel que tu n\'as pas indiqué. Celui-ci travaille la même qualité avec rien d\'autre que le sol.';
  }

  @override
  String get exerciseGuideEmpty =>
      'Aucune consigne n\'a encore été rédigée pour cet exercice.';

  @override
  String get exerciseGuideNoDemoTitle => 'PAS ENCORE DE VIDÉO';

  @override
  String get exerciseGuideNoDemoBody =>
      'Rien n\'a été filmé pour cet exercice. Les étapes ci-dessous constituent l\'intégralité des consignes.';

  @override
  String get exerciseGuideFramePosition => 'POSITION';

  @override
  String get exerciseGuideFrameStart => 'DÉPART';

  @override
  String get exerciseGuideFrameFinish => 'FIN';

  @override
  String get exerciseGuideFrameDisclaimer =>
      'Photos de référence, pas un enregistrement de ton propre saut.';

  @override
  String jumpDateMedium(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get feedTitle => 'CLASSEMENTS';

  @override
  String get feedGlobalTitle => 'MEILLEURES DÉTENTES';

  @override
  String get feedGlobalSubtitle =>
      'Tous les athlètes DunkIt, classés selon leur meilleur saut mesuré.';

  @override
  String get feedPersonalTitle => 'TES MEILLEURS SAUTS';

  @override
  String get feedPersonalSubtitle =>
      'Tous tes sauts analysés, classés par détente.';

  @override
  String get feedNotConfiguredTitle =>
      'Classement mondial désactivé dans cette version';

  @override
  String get feedNotConfiguredBody =>
      'Cette version de l\'app a été compilée sans identifiants de classement : il n\'y a rien à joindre. Tout le reste fonctionne hors ligne.';

  @override
  String get feedUnavailableTitle => 'Classement mondial injoignable';

  @override
  String get feedUnavailableBody =>
      'Vérifie ta connexion et tire vers le bas pour réessayer. Tes propres sauts ci-dessous sont stockés sur cet appareil et ne sont pas affectés.';

  @override
  String get feedNoAthletesTitle => 'Aucun athlète classé pour l\'instant';

  @override
  String get feedNoAthletesBody =>
      'Personne n\'a encore publié de saut mesuré. Analyse le tien et tu prends la première place.';

  @override
  String get feedLoading => 'Chargement du classement mondial…';

  @override
  String get feedYouBadge => 'TOI';

  @override
  String feedJumpStat(String unit, int value) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$value cm de détente',
        'other': '$value po de détente',
      },
    );
    return '$_temp0';
  }

  @override
  String feedAttemptSeparator(String attempt) {
    return ' · $attempt';
  }

  @override
  String get feedAttemptFallback => 'Saut';

  @override
  String feedGlobalStatSeparator(String height) {
    return ' · $height';
  }

  @override
  String feedRankNumber(int rank) {
    return 'n°$rank';
  }

  @override
  String get feedEmptyPersonalTitle => 'Aucun saut classé pour l\'instant';

  @override
  String get feedEmptyPersonalBody =>
      'Analyse ton premier saut pour lancer ton classement.';

  @override
  String get feedNamePromptTitle => 'Tu n\'es pas encore au classement';

  @override
  String get feedNamePromptBody =>
      'Choisis un nom et ton meilleur saut mesuré sera classé avec tous les autres. Seuls le nom, la détente et ta taille sont partagés — jamais tes vidéos.';

  @override
  String get feedSetBoardName => 'CHOISIR MON NOM';

  @override
  String get displayNameTitle => 'Ton nom au classement';

  @override
  String get displayNameBody =>
      'C\'est la seule chose que les autres athlètes voient. Tes vidéos ne quittent jamais ce téléphone.';

  @override
  String get displayNameHint => 'ex. Marcus';

  @override
  String get scoreBounce => 'REBOND';

  @override
  String get scorePower => 'PUISSANCE';

  @override
  String get scoreControl => 'CONTRÔLE';

  @override
  String get scoreForm => 'TECHNIQUE';

  @override
  String get analyzeTitle => 'ANALYSE';

  @override
  String get analyzeIntro =>
      'Filme ton saut de face, corps entier dans le cadre. On suit tes pieds pour chronométrer le vol, puis la gravité donne la hauteur — aucun calibrage nécessaire.';

  @override
  String get analyzePickError =>
      'Impossible d\'accéder à l\'appareil photo ou à la galerie.';

  @override
  String get analyzeBusyCta => 'UNE SECONDE…';

  @override
  String get analyzeRecordCta => 'FILMER UN SAUT';

  @override
  String get analyzeChooseLibrary => 'Choisir dans la galerie';

  @override
  String get analyzeSkip => 'Je ferai ça plus tard';

  @override
  String get analyzeSkipSubtitle =>
      'Tu peux analyser un saut à tout moment depuis l\'app.';

  @override
  String get trimTitle => 'DÉCOUPER LA VIDÉO';

  @override
  String get trimCancel => 'ANNULER';

  @override
  String get trimHintDrag =>
      'Fais glisser les poignées sur la timeline pour découper.';

  @override
  String get trimHintRange =>
      'Début / Fin — ajuste sur un seul saut ou dunk pour une meilleure analyse.';

  @override
  String get trimStartLabel => 'DÉBUT :';

  @override
  String get trimEndLabel => 'FIN :';

  @override
  String get trimAnalyzeCta => 'ANALYSER';

  @override
  String get trimRetake => 'Refilmer';

  @override
  String get trimLoadError => 'Impossible de charger cette vidéo.';

  @override
  String get trimTryAgain => 'RÉESSAYER';

  @override
  String get processingHeadline => 'ANALYSE';

  @override
  String get processingHeadlineAccent => ' DE TON SAUT';

  @override
  String get processingBadge => 'TRAITEMENT IA';

  @override
  String get processingStepTracking => 'Suivi de ton corps sur la vidéo';

  @override
  String get processingStepLocating =>
      'Repérage de l\'impulsion et de la réception';

  @override
  String get processingStepEstimating => 'Estimation de ta détente';

  @override
  String get unmeasuredTitle => 'AUCUNE MESURE';

  @override
  String get unmeasuredSubtitle =>
      'On préfère te le dire plutôt que d\'inventer un chiffre.';

  @override
  String get unmeasuredNoWindowHeadline =>
      'On t\'a bien suivi, mais tes pieds n\'ont jamais clairement quitté le sol.';

  @override
  String get unmeasuredNoWindowFix1 =>
      'Découpe la vidéo pour ne garder que le saut et un instant de chaque côté.';

  @override
  String get unmeasuredNoWindowFix2 =>
      'Garde tes pieds dans le cadre du début à la fin — c\'est eux qu\'on chronomètre.';

  @override
  String get unmeasuredNoWindowFix3 =>
      'Filme de profil ou de face, pas en plongée.';

  @override
  String get unmeasuredLostTrackHeadline =>
      'On n\'a pas réussi à te suivre sur toute la vidéo.';

  @override
  String get unmeasuredLostTrackFix1 =>
      'Mets tout ton corps dans le cadre, de la tête aux pieds.';

  @override
  String get unmeasuredLostTrackFix2 =>
      'Plus de lumière aide — le suivi galère dans un gymnase sombre.';

  @override
  String get unmeasuredLostTrackFix3 =>
      'Évite un arrière-plan chargé juste derrière toi.';

  @override
  String get unmeasuredGappyHeadline =>
      'On t\'a perdu en plein milieu du saut.';

  @override
  String get unmeasuredGappyFix1 =>
      'Recule pour que tout ton corps reste dans le cadre au point haut.';

  @override
  String get unmeasuredGappyFix2 =>
      'Garde le téléphone immobile — suivre le saut vers le haut te fait sortir du cadre.';

  @override
  String get unmeasuredGappyFix3 =>
      'Plus de lumière réduit le flou de mouvement à l\'impulsion.';

  @override
  String get unmeasuredSmallJumpHeadline =>
      'Le saut de cette vidéo est trop petit pour être chronométré de façon fiable.';

  @override
  String get unmeasuredSmallJumpFix1 =>
      'Découpe sur ton meilleur essai si la vidéo en contient plusieurs.';

  @override
  String get unmeasuredSmallJumpFix2 =>
      'Filme un saut à pleine intensité — un petit saut d\'échauffement est sous notre seuil de mesure.';

  @override
  String get unmeasuredImplausibleHeadline =>
      'Le temps de vol mesuré sort de ce qu\'un vrai saut peut donner.';

  @override
  String get unmeasuredImplausibleFix1 =>
      'Découpe au plus près d\'un seul saut.';

  @override
  String get unmeasuredImplausibleFix2 =>
      'Vérifie que la vidéo est en vitesse normale — le ralenti fausse le chronométrage.';

  @override
  String get unmeasuredTooShortHeadline =>
      'La vidéo est trop courte pour être analysée.';

  @override
  String get unmeasuredTooShortFix1 =>
      'Inclus un instant avant le saut et après la réception.';

  @override
  String get unmeasuredUnreadableHeadline =>
      'On n\'a pas réussi à lire cette vidéo.';

  @override
  String get unmeasuredUnreadableFix1 =>
      'Réessaie — si ça se reproduit, filme une nouvelle vidéo avec la caméra.';

  @override
  String get unmeasuredUnreadableFix2 =>
      'Les vidéos enregistrées depuis d\'autres applis ne s\'ouvrent pas toujours ; une vidéo filmée avec ce téléphone passera.';

  @override
  String get unmeasuredGenericHeadline => 'On n\'a pas pu mesurer cette vidéo.';

  @override
  String get unmeasuredGenericFix1 =>
      'Découpe au plus près d\'un seul saut et réessaie.';

  @override
  String get unmeasuredRetrimCta => 'DÉCOUPER ET RÉESSAYER';

  @override
  String get unmeasuredNewClip => 'Utiliser une autre vidéo';

  @override
  String get resultTitle => 'TON SAUT';

  @override
  String get resultCtaAnalyzeAnother => 'ANALYSER UN AUTRE SAUT';

  @override
  String get resultEstVert => 'DÉTENTE EST.';

  @override
  String resultClearsDunk(String unit, int target) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': 'Ça dépasse ta cible de $target cm pour dunker',
        'other': 'Ça dépasse ta cible de $target po pour dunker',
      },
    );
    return '$_temp0';
  }

  @override
  String resultGapToDunk(String unit, int gap, int target) {
    String _temp0 = intl.Intl.selectLogic(
      unit,
      {
        'metric': '$gap cm avant ta cible de $target cm pour dunker',
        'other': '$gap po avant ta cible de $target po pour dunker',
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
            'La cible suppose une extension debout estimée à $reach cm. Renseigne ta vraie extension dans les Réglages pour une cible exacte.',
        'other':
            'La cible suppose une extension debout estimée à $reach po. Renseigne ta vraie extension dans les Réglages pour une cible exacte.',
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
            'Cette mesure remplace désormais ton estimation de départ de ~$value cm.',
        'other':
            'Cette mesure remplace désormais ton estimation de départ de ~$value po.',
      },
    );
    return '$_temp0';
  }

  @override
  String takeoffTypeLabel(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'oneFoot': 'Impulsion à un pied',
        'twoFoot': 'Impulsion à deux pieds',
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
        'dunkAttempt': 'Tentative de dunk',
        'jumpAttempt': 'Saut simple',
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
        'dunkAttempt': 'Cercle ou ballon dans le cadre',
        'jumpAttempt': 'Pas besoin de cercle',
        'other': '$type',
      },
    );
    return '$_temp0';
  }

  @override
  String get resultFormScoresTitle => 'SCORES TECHNIQUES';

  @override
  String get resultScoresUnavailable =>
      'Noter ta technique demande le suivi corporel, et il n\'a pas pu te suivre sur cette vidéo.';

  @override
  String get resultScoresIntro =>
      'Noté à partir de ton corps sur cette vidéo — rien n\'est inventé là où la mesure était impossible.';

  @override
  String get resultScoresDisclaimer =>
      'Les scores évaluent ta technique par rapport à des repères d\'entraîneur, pas par rapport aux autres athlètes.';

  @override
  String get resultNotMeasured => 'Non mesuré';

  @override
  String get resultNoTrackingReason => 'le suivi corporel n\'a pas fonctionné';

  @override
  String get resultScoreDenominator => '/100';

  @override
  String resultScoreOutOf(int score) {
    return '$score/100';
  }

  @override
  String get resultBreakdownTitle => 'ANALYSE DÉTAILLÉE';

  @override
  String get resultStrongest => 'POINT FORT';

  @override
  String get resultWeakest => 'POINT FAIBLE';

  @override
  String resultAspectCaption(String caption, String aspect) {
    return '$caption · $aspect';
  }

  @override
  String resultMeasuredPrefix(String measurement) {
    return 'Mesuré : $measurement';
  }

  @override
  String get resultHowToWorkOnIt => 'COMMENT TRAVAILLER ÇA';

  @override
  String get resultGeneralTips => 'CONSEILS GÉNÉRAUX POUR COMBLER L\'ÉCART';
}
