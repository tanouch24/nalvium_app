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
  String get comingSoon => 'Bientôt disponible';

  @override
  String get houseTitle => 'Ma maison';

  @override
  String get houseEmptyTitle => 'Votre maison est vide pour l\'instant';

  @override
  String get houseEmptyBody =>
      'Vos équipements et vos interventions apparaîtront ici.';

  @override
  String get repairTitle => 'Dépannage';

  @override
  String get repairEmptyTitle => 'Aucune demande en cours';

  @override
  String get repairEmptyBody =>
      'Si un problème demande un professionnel, vous pourrez le demander ici.';

  @override
  String get communityTitle => 'Communauté';

  @override
  String get communityEmptyTitle => 'La communauté arrive bientôt';

  @override
  String get communityEmptyBody =>
      'Vous pourrez y voir des problèmes réellement résolus par d\'autres personnes.';

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
  String get previewTitle => 'Votre photo';

  @override
  String get previewQuestion => 'Est-ce que le problème est bien visible ?';

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
  String get analyzingSubtitle => 'Je regarde ce qui pourrait provoquer ça.';

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
  String youWillNeed(String items) {
    return 'Vous aurez besoin de : $items';
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
  String get safetyTitle => 'Arrêtez-vous ici';

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
  String get stateAwaiting => 'L\'analyse est à relancer';

  @override
  String get statusResolved => 'Résolu';

  @override
  String get statusStopped => 'Arrêt de sécurité';

  @override
  String get statusReferred => 'Professionnel conseillé';

  @override
  String get statusActive => 'En cours';

  @override
  String get historyLoadError => 'Impossible de charger l\'historique.';

  @override
  String get sessionLoadError => 'Impossible de charger cette session.';
}
