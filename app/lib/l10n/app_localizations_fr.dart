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
  String get houseEmptyTitle => 'Votre maison prendra forme ici';

  @override
  String get houseEmptyBody =>
      'Les équipements que vous ajoutez apparaîtront ici.';

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
}
