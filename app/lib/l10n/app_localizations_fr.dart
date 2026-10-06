// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'NALVIUM';

  @override
  String get navHome => 'Accueil';

  @override
  String get navHouse => 'Maison';

  @override
  String get navRepair => 'Dépannage';

  @override
  String get navCommunity => 'Communauté';

  @override
  String get navCamera => 'Caméra';

  @override
  String get history => 'Historique';

  @override
  String get settings => 'Réglages';

  @override
  String get homeGreeting => 'Bonjour';

  @override
  String get homeTitle => 'Un problème à la maison ?';

  @override
  String get homeSubtitle =>
      'Montrez-le à Nalvium.\nOn vous aide à comprendre quoi faire.';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get describeProblem => 'Décrire le problème';

  @override
  String get film => 'Filmer';

  @override
  String get houseTitle => 'Ma maison';

  @override
  String get repairTitle => 'Dépannage';

  @override
  String get repairEmptyTitle => 'Aucune demande en cours';

  @override
  String get communityTitle => 'Communauté';

  @override
  String get historyEmptyTitle => 'Aucun historique';

  @override
  String get historyEmptyBody => 'Vos dépannages précédents apparaîtront ici.';

  @override
  String get settingsEmptyTitle => 'Réglages';

  @override
  String get settingsEmptyBody =>
      'Les réglages arriveront dans une prochaine version.';

  @override
  String get retake => 'Reprendre';

  @override
  String get usePhoto => 'Utiliser cette photo';

  @override
  String get analyzingTitle => 'J\'analyse le problème…';

  @override
  String get backHome => 'Retour à l\'accueil';

  @override
  String get cameraError =>
      'Impossible d\'ouvrir la caméra. Vérifiez l\'autorisation dans les réglages du téléphone.';

  @override
  String get close => 'Fermer';

  @override
  String get analyzingSlow =>
      'Cela prend un peu plus de temps que d\'habitude…';

  @override
  String get cancel => 'Annuler';

  @override
  String get retry => 'Réessayer';

  @override
  String get errNetworkTitle => 'Impossible de joindre Nalvium';

  @override
  String get errNetworkBody =>
      'Vérifiez votre connexion internet, puis réessayez.';

  @override
  String get errTimeoutTitle => 'L\'analyse prend trop de temps';

  @override
  String get errTimeoutBody => 'Rien n\'est perdu : vous pouvez réessayer.';

  @override
  String get errUnavailableTitle =>
      'L\'analyse n\'est pas disponible pour le moment';

  @override
  String get errUnavailableBody =>
      'Votre demande est enregistrée. Réessayez dans quelques instants.';

  @override
  String get errGenericTitle => 'Un problème est survenu';

  @override
  String get errGenericBody => 'Réessayez dans un instant.';

  @override
  String get errNotConfiguredTitle => 'Connexion à Nalvium non configurée';

  @override
  String get errNotConfiguredBody =>
      'L\'adresse du serveur est absente de cette version de l\'application.';

  @override
  String stepLabel(int n) {
    return 'Étape $n';
  }

  @override
  String get actionDone => 'C\'est fait';

  @override
  String get actionCannot => 'Je n\'y arrive pas';

  @override
  String get actionMismatch => 'Ce n\'est pas ce que je vois';

  @override
  String get answerYes => 'Oui';

  @override
  String get answerNo => 'Non';

  @override
  String get answerDontKnow => 'Je ne sais pas';

  @override
  String get answerOtherwise => 'Répondre autrement';

  @override
  String get typeAnswer => 'Votre réponse';

  @override
  String get send => 'Envoyer';

  @override
  String get takeAPhoto => 'Prendre une photo';

  @override
  String get cannotTakePhoto => 'Je ne peux pas prendre cette photo';

  @override
  String get cannotTakePhotoAnswer => 'Je ne peux pas prendre cette photo.';

  @override
  String get understood => 'J\'ai compris';

  @override
  String get proTitle => 'Cette intervention nécessite un professionnel.';

  @override
  String get seeRepairOptions => 'Voir les options de dépannage';

  @override
  String get resolvedTitle => 'Problème résolu';

  @override
  String get finish => 'Terminer';

  @override
  String get describeTitle => 'Que se passe-t-il ?';

  @override
  String get describeHint => 'Décrivez ce que vous voyez ou entendez…';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get resumeSection => 'À reprendre';

  @override
  String get resumeButton => 'Continuer';

  @override
  String get untitledProblem => 'Problème en cours';

  @override
  String get stateAskQuestion => 'Nalvium attend votre réponse';

  @override
  String get stateRequestPhoto => 'Une photo est attendue';

  @override
  String get stateInstruction => 'Une étape vous attend';

  @override
  String get stateVerification => 'À vérifier';

  @override
  String get statusResolved => 'Résolu';

  @override
  String get statusStopped => 'Arrêt de sécurité';

  @override
  String get historyLoadError => 'Impossible de charger l\'historique.';

  @override
  String get sessionLoadError => 'Impossible de charger cette session.';

  @override
  String get takePhotoHint => 'Le moyen le plus rapide';

  @override
  String get describeShort => 'Décrire';

  @override
  String get filmShort => 'Filmer';

  @override
  String get resumeLastStep => 'Dernière étape';

  @override
  String get houseEmptyTitle => 'Votre maison';

  @override
  String get houseEmptyBody =>
      'Ajoutez vos équipements pour que Nalvium se souvienne de ce qu\'il y a chez vous.';

  @override
  String get repairEmptyBody =>
      'Si un problème demande un professionnel, vous pourrez le demander ici.';

  @override
  String get communityEmptyTitle => 'Les réparations des autres, bientôt ici';

  @override
  String get communityEmptyBody =>
      'Vous verrez ici des problèmes réellement résolus par d\'autres personnes.';

  @override
  String get previewSharp => 'La photo est-elle assez nette ?';

  @override
  String get previewTip => 'Cadrez surtout la zone où vous voyez le problème.';

  @override
  String get previewSemantics => 'Aperçu de la photo prise';

  @override
  String get waitLooking => 'Je regarde ce qui pourrait provoquer ça.';

  @override
  String get waitObserving => 'J\'observe les éléments visibles.';

  @override
  String get waitChecking => 'Je vérifie ce qui mérite votre attention.';

  @override
  String get titleAsk => 'J\'ai besoin de vérifier un point';

  @override
  String get titleRequestPhoto => 'Montrez-moi ce point';

  @override
  String get titleInstruction => 'Essayez ceci';

  @override
  String get titleVerification => 'Vérifions';

  @override
  String get titleResolved => 'C\'est réglé';

  @override
  String get titleProfessional => 'Cette intervention demande un professionnel';

  @override
  String get safetyTitle => 'Arrêtez-vous ici';

  @override
  String get phaseObservation => 'Observation';

  @override
  String get phaseAction => 'Action';

  @override
  String get phaseControl => 'Contrôle';

  @override
  String get takeThePhoto => 'Prendre la photo';

  @override
  String get askForHelp => 'Demander de l\'aide';

  @override
  String get understoodShort => 'Compris';

  @override
  String get findProfessional => 'Trouver un professionnel';

  @override
  String get seeSummary => 'Voir le récapitulatif';

  @override
  String get backToHome => 'Retour à l\'accueil';

  @override
  String get answerALittle => 'Un peu';

  @override
  String get catPlumbing => 'Plomberie';

  @override
  String get catAppliance => 'Électroménager';

  @override
  String get catHandyman => 'Bricolage';

  @override
  String get catElectrical => 'Électricité';

  @override
  String get catOther => 'Autre';

  @override
  String get statusReferred => 'Professionnel recommandé';

  @override
  String get statusActive => 'À reprendre';

  @override
  String get stateAwaiting => 'Analyse à relancer';

  @override
  String get relToday => 'Aujourd\'hui';

  @override
  String get relYesterday => 'Hier';

  @override
  String get summaryTitle => 'Récapitulatif';

  @override
  String get summaryObserved => 'Ce que j\'ai observé';

  @override
  String get summaryTried => 'Ce que vous avez essayé';

  @override
  String get summaryConclusion => 'Conclusion';

  @override
  String get stepDone => 'Fait';

  @override
  String get stepFailed => 'Pas réussi';

  @override
  String get stepMismatch => 'Différent de ce que vous voyez';

  @override
  String get stepPending => 'Pas encore fait';

  @override
  String get photoSemantics => 'Photo du problème';

  @override
  String get videoSemantics => 'Vidéo du problème';

  @override
  String get sessionClosed => 'Session terminée';

  @override
  String get youNeed => 'Vous aurez besoin de';

  @override
  String get verifyWithPhoto => 'Montrer avec une photo';

  @override
  String get analyzingDescription => 'J\'analyse votre description…';

  @override
  String get summaryProblem => 'Problème';

  @override
  String get summaryDone => 'Ce qu\'on a fait';

  @override
  String get summaryResult => 'Résultat';

  @override
  String get historyIntro => 'Les problèmes que Nalvium vous a aidé à traiter.';

  @override
  String get yourPhoto => 'Votre photo';

  @override
  String get photoToTake => 'À prendre';

  @override
  String get videoMaxHint => '15 secondes maximum';

  @override
  String videoRemaining(int s) {
    return '$s s restantes';
  }

  @override
  String get videoStart => 'Démarrer l\'enregistrement';

  @override
  String get videoStop => 'Arrêter l\'enregistrement';

  @override
  String get videoSwitchCamera => 'Changer de caméra';

  @override
  String get videoNoSound => 'Sans son';

  @override
  String get videoPreviewTitle => 'La vidéo est-elle assez claire ?';

  @override
  String get videoPreviewTip =>
      'Montrez bien la zone du problème : quelques secondes suffisent.';

  @override
  String get useVideo => 'Utiliser cette vidéo';

  @override
  String get refilm => 'Refilmer';

  @override
  String get videoNoAudioNote => 'Cette vidéo n\'a pas de son.';

  @override
  String get videoPlay => 'Lire la vidéo';

  @override
  String get videoPause => 'Mettre en pause';

  @override
  String get videoPreviewSemantics => 'Aperçu de la vidéo';

  @override
  String get videoCannotPlay =>
      'Impossible de lire l\'aperçu, mais la vidéo est bien enregistrée.';

  @override
  String get analyzingVideo => 'J\'analyse votre vidéo…';

  @override
  String get waitVideo => 'J\'observe ce qui change dans la vidéo.';

  @override
  String get videoPosterSemantics => 'Aperçu de la vidéo';

  @override
  String get errCameraDeniedTitle => 'L\'accès à la caméra est nécessaire';

  @override
  String get errCameraDeniedBody =>
      'Autorisez la caméra dans les réglages du téléphone, ou montrez le problème autrement.';

  @override
  String get errCameraUnavailableTitle => 'La caméra n\'est pas disponible';

  @override
  String get errCameraUnavailableBody =>
      'Une autre application l\'utilise peut-être. Réessayez, ou montrez le problème autrement.';

  @override
  String get errVideoTooShortTitle => 'Vidéo trop courte';

  @override
  String get errVideoTooShortBody =>
      'Filmez au moins une seconde, en montrant bien le problème.';

  @override
  String get errVideoTooLargeTitle => 'Cette vidéo est trop lourde';

  @override
  String get errVideoTooLargeBody =>
      'Refaites une vidéo plus courte, ou prenez une photo.';

  @override
  String get errVideoTooLongTitle => 'Cette vidéo est trop longue';

  @override
  String get errVideoTooLongBody =>
      '15 secondes maximum. Refaites une vidéo plus courte.';

  @override
  String get errVideoInvalidTitle => 'Format de vidéo non pris en charge';

  @override
  String get errVideoInvalidBody =>
      'Refaites la vidéo avec l\'appareil photo de Nalvium, ou prenez une photo.';

  @override
  String get yourVideo => 'Votre vidéo';

  @override
  String get houseEmptyHint =>
      'Vos diagnostics pourront ensuite être rattachés automatiquement à vos équipements.';

  @override
  String get houseAdd => 'Ajouter un équipement';

  @override
  String get houseNoRoom => 'Sans pièce';

  @override
  String get houseNoIssue => 'Aucun problème';

  @override
  String get houseDiagnosticsOne => '1 diagnostic';

  @override
  String get houseLoadError => 'Impossible d\'afficher votre maison';

  @override
  String get eqAddTitle => 'Ajouter un équipement';

  @override
  String get eqEditTitle => 'Modifier l\'équipement';

  @override
  String get eqStepType => 'Quel équipement ?';

  @override
  String get eqSearchHint => 'Rechercher un équipement';

  @override
  String get eqSearchEmpty =>
      'Aucun équipement ne correspond. Choisissez « Autre » pour le nommer vous-même.';

  @override
  String get eqIdentifyPhoto => 'Identifier avec une photo';

  @override
  String get eqStepRoom => 'Où se trouve-t-il ?';

  @override
  String get eqRoomSkip => 'Je ne sais pas / Passer';

  @override
  String get eqStepDetails => 'Quelques précisions';

  @override
  String get eqDetailsHint =>
      'Tout est facultatif : vous pourrez compléter plus tard.';

  @override
  String get eqName => 'Nom';

  @override
  String get eqNameHint => 'Ex. Lave-vaisselle du fond';

  @override
  String get eqBrand => 'Marque';

  @override
  String get eqBrandHint => 'Facultatif';

  @override
  String get eqModel => 'Modèle / référence';

  @override
  String get eqModelHint => 'Facultatif';

  @override
  String get eqPhoto => 'Photo';

  @override
  String get eqPhotoAdd => 'Ajouter une photo';

  @override
  String get eqPhotoChange => 'Changer la photo';

  @override
  String get eqPhotoRemove => 'Retirer la photo';

  @override
  String get eqPhotoPrivate => 'Votre photo reste privée.';

  @override
  String get eqPhotoFail =>
      'La photo n\'a pas pu être enregistrée. Votre saisie est conservée : réessayez.';

  @override
  String get eqSave => 'Enregistrer';

  @override
  String get eqSaveFail =>
      'L\'équipement n\'a pas pu être enregistré. Votre saisie est conservée : réessayez.';

  @override
  String get eqNext => 'Continuer';

  @override
  String get eqRoomLabel => 'Pièce';

  @override
  String get eqType => 'Type';

  @override
  String get eqNoBrand => 'Marque non renseignée';

  @override
  String get eqIdentifyTitle => 'Identifier avec une photo';

  @override
  String get eqIdentifyTip =>
      'Photographiez l\'équipement entier, ou son étiquette si vous la trouvez.';

  @override
  String get eqIdentifyTake => 'Prendre la photo';

  @override
  String get eqIdentifyWorking => 'Nalvium regarde votre photo…';

  @override
  String get eqIdentifyNotSure =>
      'Nalvium n\'en est pas certain : vérifiez avant de confirmer.';

  @override
  String get eqIdentifyConfirm => 'Oui, c\'est ça';

  @override
  String get eqIdentifyCorrect => 'Corriger';

  @override
  String get eqIdentifyUnknownTitle => 'Nalvium n\'a pas pu l\'identifier';

  @override
  String get eqIdentifyUnknownBody =>
      'Ce n\'est pas grave : choisissez vous-même le type d\'équipement. Votre photo est conservée.';

  @override
  String get eqIdentifyChoose => 'Choisir moi-même';

  @override
  String get eqIdentifyFailTitle => 'L\'identification n\'est pas disponible';

  @override
  String get eqIdentifyFailBody =>
      'Vous pouvez continuer sans : votre photo est conservée.';

  @override
  String get eqIdentifyContinue => 'Continuer sans identification';

  @override
  String get eqIdentifyReadable => 'Texte lu sur l\'appareil';

  @override
  String get eqDetailTitle => 'Équipement';

  @override
  String get eqProblems => 'Problèmes traités';

  @override
  String get eqNoProblems => 'Aucun problème enregistré pour cet équipement.';

  @override
  String get eqDiagnose => 'Diagnostiquer un problème';

  @override
  String get eqDiagnoseHow => 'Comment voulez-vous montrer le problème ?';

  @override
  String get eqEdit => 'Modifier';

  @override
  String get eqDelete => 'Supprimer';

  @override
  String get eqDeleteTitle => 'Supprimer cet équipement ?';

  @override
  String get eqDeleteBody =>
      'Ses diagnostics ne seront pas supprimés : ils seront simplement détachés de cet équipement. Sa photo sera supprimée.';

  @override
  String get eqDeleteConfirm => 'Supprimer l\'équipement';

  @override
  String get eqDeleteFail =>
      'L\'équipement n\'a pas pu être supprimé. Réessayez.';

  @override
  String get eqGone => 'Cet équipement n\'existe plus.';

  @override
  String get eqBackToHouse => 'Retour à la maison';

  @override
  String get eqLinkAdd => 'Ajouter à votre maison';

  @override
  String get eqLinkSave => 'Enregistrer cet équipement';

  @override
  String get eqLinkTitle => 'Ajouter à votre maison';

  @override
  String get eqLinkChoose => 'Choisir un équipement existant';

  @override
  String get eqLinkNew => 'Créer un nouvel équipement';

  @override
  String get eqLinkYes => 'Oui, c\'est lui';

  @override
  String get eqLinkNo => 'Non';

  @override
  String get eqLinkDone => 'Ce diagnostic est rattaché à votre équipement.';

  @override
  String get eqLinkFail =>
      'Le rattachement n\'a pas pu être enregistré. Réessayez.';

  @override
  String get eqLinkedTo => 'Équipement';

  @override
  String get eqLinkDetach => 'Détacher de cet équipement';

  @override
  String get eqLinkNothing =>
      'Vous n\'avez pas encore d\'équipement enregistré.';

  @override
  String get eqSessionGone => 'Ce diagnostic est introuvable.';

  @override
  String eqDiagnosticsCount(int count) {
    return '$count diagnostics';
  }

  @override
  String eqLinkAsk(String name) {
    return 'Est-ce votre $name ?';
  }

  @override
  String eqIdentifyResult(String what) {
    return 'Cela ressemble à $what.';
  }

  @override
  String eqSemanticsEquipment(String name, String where) {
    return '$name, $where';
  }

  @override
  String get eqRefLabel => 'Référence';

  @override
  String get eqRefNone => 'Référence non renseignée';

  @override
  String get eqRefWhere => 'Où trouver la référence ?';

  @override
  String get eqRefHelpTitle => 'Où trouver la référence ?';

  @override
  String get eqRefHelpBody =>
      'C\'est une série de lettres et de chiffres (par exemple SMS46GI01E). Elle figure sur la plaque signalétique : à l\'intérieur de la porte d\'un lave-vaisselle ou d\'un lave-linge, sur le côté ou au dos d\'un four ou d\'un réfrigérateur, sous ou sur le côté d\'une chaudière. Elle est aussi dans la notice et sur la facture. Si vous ne la trouvez pas, ce n\'est pas grave : elle reste facultative.';

  @override
  String get eqRefHelpClose => 'J\'ai compris';

  @override
  String get eqIdentifyCloser =>
      'Pour la référence, photographiez la plaque signalétique de plus près : Nalvium n\'invente jamais les caractères illisibles.';

  @override
  String get manualTitle => 'Notice';

  @override
  String get manualZone => 'Notice constructeur';

  @override
  String get manualNeedRef => 'Référence nécessaire';

  @override
  String get manualNeedRefBody =>
      'Ajoutez la marque et la référence pour que Nalvium cherche la notice exacte de votre appareil.';

  @override
  String get manualSearch => 'Rechercher la notice';

  @override
  String get manualSearching => 'Recherche en cours';

  @override
  String get manualSearchingBody =>
      'Nalvium cherche la notice officielle de votre appareil. Cela peut prendre une minute.';

  @override
  String get manualAvailable => 'Notice disponible';

  @override
  String get manualAvailableBody =>
      'Nalvium s\'appuiera sur cette notice pour les prochains diagnostics de cet équipement.';

  @override
  String get manualConsult => 'Consulter';

  @override
  String get manualUpdate => 'Mettre à jour';

  @override
  String get manualNotFound => 'Notice exacte introuvable';

  @override
  String get manualNotFoundBody =>
      'Aucune notice officielle correspondant exactement à cette référence n\'a été trouvée. Vous pouvez utiliser l\'équipement normalement.';

  @override
  String get manualError => 'Erreur de récupération';

  @override
  String get manualErrorBody =>
      'La notice n\'a pas pu être récupérée pour le moment. Réessayez plus tard.';

  @override
  String get manualApprox => 'Une notice proche a été trouvée';

  @override
  String get manualApproxBody =>
      'Sa référence est légèrement différente de la vôtre. Nalvium ne l\'utilisera que si vous confirmez qu\'elle convient.';

  @override
  String get manualApproxYes => 'Elle convient';

  @override
  String get manualApproxNo => 'Ignorer cette notice';

  @override
  String get manualOfficial => 'Source officielle du fabricant';

  @override
  String get manualRetry => 'Réessayer';

  @override
  String get manualUpToDate => 'La notice est déjà à jour.';

  @override
  String get manualKept =>
      'La recherche a échoué : votre notice actuelle est conservée.';

  @override
  String get manualPrivate =>
      'Cette notice reste privée : elle n\'est accessible que depuis votre appareil.';

  @override
  String get manualPageNext => 'Page suivante';

  @override
  String get manualPagePrev => 'Page précédente';

  @override
  String get manualPageEmpty =>
      'Cette page ne contient pas de texte exploitable.';

  @override
  String get manualLoadFail => 'La page n\'a pas pu être chargée.';

  @override
  String get manualConfirmFail =>
      'L\'action n\'a pas pu être enregistrée. Réessayez.';

  @override
  String manualPages(int count) {
    return '$count pages';
  }

  @override
  String manualSource(String domain) {
    return 'Source : $domain';
  }

  @override
  String manualPageOf(int page, int total) {
    return 'Page $page sur $total';
  }

  @override
  String manualCite(String brand) {
    return 'D\'après la notice $brand de votre appareil';
  }

  @override
  String get manualCiteGeneric => 'D\'après la notice de votre appareil';

  @override
  String manualCitePage(String pages) {
    return 'Notice · page $pages';
  }

  @override
  String manualCitePages(String pages) {
    return 'Notice · pages $pages';
  }

  @override
  String get manualIdle => 'Notice non récupérée';

  @override
  String get manualIdleBody =>
      'Nalvium peut chercher la notice officielle de votre appareil.';

  @override
  String get repairHeadline => 'Besoin d\'un coup de main ?';

  @override
  String get repairHeadlineBody =>
      'Nalvium peut préparer votre demande pour que vous n\'ayez pas à tout réexpliquer.';

  @override
  String get repairAsk => 'Demander une intervention';

  @override
  String get repairYourRequests => 'Vos demandes';

  @override
  String get repairNoRequests => 'Vous n\'avez aucune demande pour le moment.';

  @override
  String get repairLoadFail => 'Vos demandes n\'ont pas pu être chargées';

  @override
  String get helpAsk => 'Demander de l\'aide';

  @override
  String get helpNewTitle => 'Votre demande d\'intervention';

  @override
  String get helpIntro =>
      'Nalvium a déjà compris le problème : vous n\'avez pas à tout réexpliquer. Vérifiez et corrigez si besoin.';

  @override
  String get helpSectionProblem => 'Problème';

  @override
  String get helpProblemHint => 'Décrivez le problème en quelques mots';

  @override
  String get helpCategory => 'Type de problème';

  @override
  String get helpCatPlumbing => 'Plomberie';

  @override
  String get helpCatAppliance => 'Électroménager';

  @override
  String get helpCatHandyman => 'Bricolage';

  @override
  String get helpCatElectrical => 'Électricité';

  @override
  String get helpCatOther => 'Autre';

  @override
  String get helpSectionEquipment => 'Équipement';

  @override
  String get helpEquipmentNone => 'Aucun équipement';

  @override
  String get helpSectionTried => 'Déjà essayé';

  @override
  String get helpTriedDone => 'fait';

  @override
  String get helpTriedFailed => 'impossible';

  @override
  String get helpTriedMismatch => 'ne correspondait pas';

  @override
  String get helpTriedProposed => 'proposé';

  @override
  String get helpHypothesisNote =>
      'Hypothèse de Nalvium, non confirmée par un professionnel :';

  @override
  String get helpSafetyReason => 'Pourquoi une aide est recommandée';

  @override
  String get helpManualUsed => 'Notice constructeur consultée';

  @override
  String get helpSectionMedia => 'Photos et vidéos';

  @override
  String get helpMediaPrivacy =>
      'Seuls les éléments sélectionnés seront transmis avec votre demande. Les autres restent privés.';

  @override
  String get helpMediaNone => 'Aucune photo ou vidéo jointe.';

  @override
  String get helpMediaAdd => 'Ajouter une photo';

  @override
  String get helpMediaJoin => 'Joindre à ma demande';

  @override
  String get helpMediaVideo => 'Vidéo';

  @override
  String get helpSectionContact => 'Vos informations';

  @override
  String get helpFirstName => 'Prénom';

  @override
  String get helpPhone => 'Téléphone';

  @override
  String get helpCity => 'Ville';

  @override
  String get helpPostal => 'Code postal';

  @override
  String get helpEmail => 'E-mail (facultatif)';

  @override
  String get helpNoAddress =>
      'Pas d\'adresse précise : seulement votre ville et votre code postal.';

  @override
  String get helpSectionWhen => 'Disponibilité';

  @override
  String get helpWhenNote => 'C\'est une préférence, pas une réservation.';

  @override
  String get helpAsap => 'Dès que possible';

  @override
  String get helpToday => 'Aujourd\'hui';

  @override
  String get helpTomorrow => 'Demain';

  @override
  String get helpThisWeek => 'Cette semaine';

  @override
  String get helpCustom => 'Choisir un créneau';

  @override
  String get helpPickDate => 'Choisir une date';

  @override
  String get helpMorning => 'Matin';

  @override
  String get helpAfternoon => 'Après-midi';

  @override
  String get helpEvening => 'Soir';

  @override
  String get helpConsent =>
      'J\'accepte que les informations sélectionnées dans cette demande soient transmises à un professionnel susceptible de m\'aider.';

  @override
  String get helpSend => 'Envoyer ma demande';

  @override
  String get helpSending => 'Envoi en cours';

  @override
  String get helpErrRequired => 'Ce champ est nécessaire.';

  @override
  String get helpErrPhone =>
      'Entrez un numéro valide, par exemple 06 12 34 56 78.';

  @override
  String get helpErrPostal => 'Entrez un code postal à 5 chiffres.';

  @override
  String get helpErrEmail => 'Cette adresse e-mail semble incorrecte.';

  @override
  String get helpErrDate => 'Choisissez une date et une plage horaire.';

  @override
  String get helpErrConsent => 'Vous devez accepter pour envoyer la demande.';

  @override
  String get helpErrSend =>
      'La demande n\'a pas pu être envoyée. Vos informations sont conservées : réessayez.';

  @override
  String get helpErrPrepare => 'La demande n\'a pas pu être préparée.';

  @override
  String get helpEmergency =>
      'En cas de danger immédiat, appelez les secours (18 ou 112). Une demande Nalvium ne les remplace pas.';

  @override
  String get helpDoneTitle => 'Votre demande est envoyée';

  @override
  String get helpDoneBody =>
      'Nous avons enregistré votre demande avec les informations que vous avez choisies de partager. Elle pourra être transmise à un professionnel adapté lorsqu\'il sera disponible.';

  @override
  String get helpSeeRequest => 'Voir ma demande';

  @override
  String get helpBackHome => 'Retour à l\'accueil';

  @override
  String get requestTitle => 'Ma demande';

  @override
  String get requestStatusSubmitted => 'Demande envoyée';

  @override
  String get requestStatusPending => 'En attente de contact';

  @override
  String get requestStatusContacted => 'Contact pris';

  @override
  String get requestStatusClosed => 'Clôturée';

  @override
  String get requestStatusCancelled => 'Annulée';

  @override
  String get requestStatusDraft => 'Brouillon';

  @override
  String get requestShared => 'Informations partagées';

  @override
  String get requestCancel => 'Annuler la demande';

  @override
  String get requestCancelTitle => 'Annuler cette demande ?';

  @override
  String get requestCancelBody =>
      'Elle ne sera plus transmise à un professionnel.';

  @override
  String get requestCancelConfirm => 'Annuler la demande';

  @override
  String get requestKeep => 'Conserver';

  @override
  String get requestCancelFail =>
      'La demande n\'a pas pu être annulée. Réessayez.';

  @override
  String get requestMedia => 'Médias joints';

  @override
  String get requestSentOn => 'Envoyée le';

  @override
  String get requestHonest =>
      'Nalvium n\'a pas encore transmis votre demande à un professionnel : elle est enregistrée avec les informations que vous avez choisies.';

  @override
  String requestMediaCount(int count) {
    return '$count élément(s)';
  }

  @override
  String helpManualPages(String pages) {
    return 'pages $pages';
  }

  @override
  String get helpIntroDirect =>
      'Dites-nous simplement ce qui se passe : quelques informations suffisent. Pas besoin de faire d\'abord un diagnostic.';

  @override
  String get helpSectionNoticed => 'Ce que Nalvium a constaté';

  @override
  String get cmTitle => 'Communauté';

  @override
  String get cmIntro => 'Les solutions partagées par la communauté Nalvium.';

  @override
  String get cmShare => 'Partager une solution';

  @override
  String get cmSaved => 'Enregistrés';

  @override
  String get cmEmptyTitle => 'Les premières solutions arriveront bientôt.';

  @override
  String get cmEmptyBody =>
      'Vous avez réglé un problème chez vous ? Votre expérience peut aider quelqu\'un d\'autre.';

  @override
  String get cmSavedEmpty => 'Vous n\'avez encore enregistré aucune solution.';

  @override
  String get cmLoadFail => 'Impossible de charger la Communauté';

  @override
  String get cmLoadMore => 'Voir plus';

  @override
  String get cmEnd => 'Vous avez tout vu.';

  @override
  String get cmHelpful => 'Utile';

  @override
  String get cmComment => 'Commenter';

  @override
  String get cmSave => 'Enregistrer';

  @override
  String get cmUnsave => 'Retirer des enregistrés';

  @override
  String get cmMember => 'Membre Nalvium';

  @override
  String get cmNotOfficial =>
      'Solution partagée par un membre de la communauté.';

  @override
  String get cmMaterials => 'Matériel';

  @override
  String get cmComments => 'Commentaires';

  @override
  String get cmNoComments => 'Aucun commentaire pour le moment.';

  @override
  String get cmCommentHint => 'Ajouter un commentaire';

  @override
  String get cmCommentSend => 'Envoyer';

  @override
  String get cmCommentDelete => 'Supprimer mon commentaire';

  @override
  String get cmCommentFail =>
      'Le commentaire n\'a pas pu être envoyé. Réessayez.';

  @override
  String get cmCommentTooLong =>
      'Commentaire trop long (500 caractères maximum).';

  @override
  String get cmCommentUnsafe =>
      'Ce commentaire ne peut pas être publié : il touche à un sujet dangereux.';

  @override
  String get cmActionFail =>
      'L\'action n\'a pas pu être enregistrée. Réessayez.';

  @override
  String get cmReport => 'Signaler';

  @override
  String get cmReportTitle => 'Pourquoi signalez-vous ceci ?';

  @override
  String get cmReasonDangerous => 'Contenu dangereux';

  @override
  String get cmReasonSpam => 'Spam / publicité';

  @override
  String get cmReasonInappropriate => 'Contenu inapproprié';

  @override
  String get cmReasonPersonal => 'Informations personnelles';

  @override
  String get cmReasonOther => 'Autre';

  @override
  String get cmReported => 'Merci. Votre signalement a été enregistré.';

  @override
  String get cmReportedAlready => 'Vous avez déjà signalé ceci. Merci.';

  @override
  String get cmEdit => 'Modifier';

  @override
  String get cmDelete => 'Supprimer';

  @override
  String get cmDeleteTitle => 'Supprimer cette publication ?';

  @override
  String get cmDeleteBody =>
      'Elle disparaîtra de la Communauté. Cette action est définitive.';

  @override
  String get cmDeleteConfirm => 'Supprimer la publication';

  @override
  String get cmDeleteFail =>
      'La publication n\'a pas pu être supprimée. Réessayez.';

  @override
  String get cmGone => 'Cette publication n\'existe plus.';

  @override
  String get cmBack => 'Retour';

  @override
  String get cmNewTitle => 'Partager une solution';

  @override
  String get cmEditTitle => 'Modifier ma publication';

  @override
  String get cmFieldTitle => 'Titre';

  @override
  String get cmFieldTitleHint => 'Ex. Mon lave-vaisselle ne vidangeait plus';

  @override
  String get cmFieldSolution => 'Solution';

  @override
  String get cmFieldSolutionHint =>
      'Ex. J\'ai nettoyé le filtre et retiré un morceau de verre qui bloquait la pompe.';

  @override
  String get cmFieldCategory => 'Catégorie';

  @override
  String get cmFieldMaterials => 'Matériel utilisé (facultatif)';

  @override
  String get cmFieldMaterialsHint => 'Ex. Tournevis cruciforme, chiffon';

  @override
  String get cmCatPlumbing => 'Plomberie';

  @override
  String get cmCatAppliance => 'Électroménager';

  @override
  String get cmCatHandyman => 'Bricolage';

  @override
  String get cmCatOther => 'Autre';

  @override
  String get cmPhoto => 'Photo';

  @override
  String get cmPhotoRecommended => 'Recommandée mais facultative.';

  @override
  String get cmPhotoTake => 'Prendre une photo';

  @override
  String get cmPhotoFromDiagnostic => 'Utiliser une photo de mon diagnostic';

  @override
  String get cmPhotoPublicNotice =>
      'Cette photo sera visible publiquement dans la Communauté Nalvium.';

  @override
  String get cmPhotoRemove => 'Retirer la photo';

  @override
  String get cmPhotoConfirmTitle => 'Rendre cette photo publique ?';

  @override
  String get cmPhotoConfirmBody =>
      'Une copie nettoyée de cette photo (sans localisation) sera visible publiquement dans la Communauté Nalvium. L\'original reste privé.';

  @override
  String get cmPhotoConfirmYes => 'Oui, utiliser cette photo';

  @override
  String get cmPhotoFail => 'La photo n\'a pas pu être préparée. Réessayez.';

  @override
  String get cmReview =>
      'Relisez avant de publier : n\'ajoutez aucune information personnelle (nom, adresse, téléphone).';

  @override
  String get cmPreview => 'Aperçu';

  @override
  String get cmPreviewTitle => 'Voici votre publication';

  @override
  String get cmConsent =>
      'Je comprends que cette publication sera visible publiquement dans la Communauté Nalvium.';

  @override
  String get cmPublish => 'Publier';

  @override
  String get cmContinue => 'Voir l\'aperçu';

  @override
  String get cmBackEdit => 'Modifier';

  @override
  String get cmErrTitle => 'Ajoutez un titre (3 caractères minimum).';

  @override
  String get cmErrSolution => 'Décrivez la solution (10 caractères minimum).';

  @override
  String get cmErrConsent => 'Vous devez accepter pour publier.';

  @override
  String get cmErrUnsafe =>
      'Cette solution touche à un sujet dangereux (gaz, électricité, produits chimiques…). Elle ne peut pas être publiée.';

  @override
  String get cmErrPublish =>
      'La publication n\'a pas pu être envoyée. Votre texte est conservé : réessayez.';

  @override
  String get cmPublished => 'Votre solution est publiée.';

  @override
  String get cmShareSolution => 'Partager cette solution';

  @override
  String cmHelpfulCount(int count) {
    return '$count Utile';
  }

  @override
  String cmCommentCount(int count) {
    return '$count commentaire(s)';
  }

  @override
  String get oozTitle => 'Nalvium arrive bientôt dans votre secteur';

  @override
  String get oozContinue => 'Continuer avec Nalvium';

  @override
  String get oozBack => 'Retour';

  @override
  String get oozSafety =>
      'Nalvium ne peut actuellement pas organiser d\'intervention dans votre secteur.';

  @override
  String get helpErrCityPostal =>
      'Cette ville et ce code postal ne correspondent pas.';

  @override
  String get helpErrCityUnknown =>
      'Nous ne trouvons pas cette ville. Vérifiez son orthographe.';

  @override
  String get helpErrPostalUnknown => 'Ce code postal est inconnu.';

  @override
  String helpAreaNote(String name, int km) {
    return 'Service actuellement disponible à $name et dans un rayon de $km km.';
  }

  @override
  String oozBody(String name, int km) {
    return 'Les interventions sont actuellement disponibles à $name et dans un rayon de $km km. Vous pouvez continuer à utiliser gratuitement le diagnostic Nalvium.';
  }

  @override
  String get stTitle => 'Réglages';

  @override
  String get stSecData => 'Mes données';

  @override
  String get stSecPrivacy => 'Confidentialité et publicité';

  @override
  String get stSecHelp => 'Aide';

  @override
  String get stSecLegal => 'Légal';

  @override
  String get stSecApp => 'Application';

  @override
  String get stHistory => 'Historique des diagnostics';

  @override
  String get stHouse => 'Maison';

  @override
  String get stRequests => 'Demandes d\'intervention';

  @override
  String get stCommunity => 'Publications Communauté';

  @override
  String get stDeleteData => 'Supprimer mes données';

  @override
  String get stPrivacy => 'Confidentialité';

  @override
  String get stAdChoices => 'Choix publicitaires';

  @override
  String get stAbout => 'À propos et limites de Nalvium';

  @override
  String get stContact => 'Contacter Nalvium';

  @override
  String get stPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get stTerms => 'Conditions d\'utilisation';

  @override
  String get stLegalNotice => 'Mentions légales';

  @override
  String get stAiInfo => 'Informations relatives à l\'IA';

  @override
  String get stVersion => 'Version';

  @override
  String get stProvisional =>
      'Texte provisoire, en cours de relecture avant publication.';

  @override
  String get stContactBody =>
      'Écrivez-nous. Nous lisons chaque message, sans engagement de délai de réponse.';

  @override
  String get stContactCopy => 'Copier l\'adresse';

  @override
  String get stContactCopied => 'Adresse copiée.';

  @override
  String get stAdsTitle => 'Confidentialité et publicité';

  @override
  String get stAdsBody =>
      'Nalvium est gratuit grâce à la publicité. Dans l\'Espace économique européen, vous pouvez choisir quelles données sont utilisées pour personnaliser les annonces. Aucune donnée de diagnostic n\'est transmise aux annonceurs.';

  @override
  String get stAdsManage => 'Gérer mes choix publicitaires';

  @override
  String get stAdsNone =>
      'Aucun choix à gérer actuellement. Si un choix vous est demandé, il apparaîtra ici.';

  @override
  String get stDataTitle => 'Mes données';

  @override
  String get stDataBody =>
      'Nalvium fonctionne sans compte : vos données sont rattachées à un identifiant anonyme propre à ce téléphone. Elles comprennent vos diagnostics, vos photos et vidéos privées, votre Maison, vos demandes d\'intervention et votre activité dans la Communauté.';

  @override
  String get stDataDelete => 'Supprimer mes données';

  @override
  String get stDelTitle => 'Supprimer mes données ?';

  @override
  String get stDelIntro =>
      'Cette action est définitive. Elle supprimera de nos serveurs :';

  @override
  String get stDelItem1 => 'vos diagnostics et leurs échanges ;';

  @override
  String get stDelItem2 => 'vos photos et vidéos privées ;';

  @override
  String get stDelItem3 => 'votre Maison, vos équipements et leurs notices ;';

  @override
  String get stDelItem4 => 'vos demandes d\'intervention ;';

  @override
  String get stDelItem5 =>
      'vos publications et commentaires dans la Communauté, vos « Utile » et vos enregistrements ;';

  @override
  String get stDelItem6 => 'vos signalements.';

  @override
  String get stDelStays =>
      'Ne peut pas être rappelé : un message déjà envoyé à l\'exploitant à la suite d\'une demande d\'intervention. Vos publications seront supprimées, pas anonymisées.';

  @override
  String get stDelAfter =>
      'Ensuite, Nalvium repart à zéro avec une nouvelle identité anonyme.';

  @override
  String get stDelCheck =>
      'Je comprends que mes données seront supprimées définitivement.';

  @override
  String get stDelConfirm => 'Supprimer définitivement';

  @override
  String get stDelWorking => 'Suppression en cours';

  @override
  String get stDelFail =>
      'La suppression n\'a pas pu être effectuée. Rien n\'a été modifié : réessayez.';

  @override
  String get stDelDoneTitle => 'Vos données ont été supprimées';

  @override
  String get stDelDoneBody =>
      'Nalvium repart à zéro avec une nouvelle identité anonyme.';

  @override
  String get stDelHome => 'Retour à l\'accueil';

  @override
  String get stDataRow => 'Consulter et supprimer mes données';

  @override
  String get preparingNext => 'Je prépare la suite…';

  @override
  String get cmPreviewNote =>
      'Seul ce qui apparaît ci-dessous sera publié, et visible par les autres utilisateurs de Nalvium.';
}
