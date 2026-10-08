import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'NALVIUM'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navHouse.
  ///
  /// In fr, this message translates to:
  /// **'Ma maison'**
  String get navHouse;

  /// No description provided for @navRepair.
  ///
  /// In fr, this message translates to:
  /// **'Dépannage'**
  String get navRepair;

  /// No description provided for @navHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get navHistory;

  /// No description provided for @navCamera.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un problème'**
  String get navCamera;

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settings;

  /// No description provided for @homeGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get homeGreeting;

  /// No description provided for @homeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Un problème à la maison ?'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Montrez-le à Nalvium.\nOn vous aide à comprendre quoi faire.'**
  String get homeSubtitle;

  /// No description provided for @takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get takePhoto;

  /// No description provided for @describeProblem.
  ///
  /// In fr, this message translates to:
  /// **'Décrire le problème'**
  String get describeProblem;

  /// No description provided for @film.
  ///
  /// In fr, this message translates to:
  /// **'Filmer'**
  String get film;

  /// No description provided for @houseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ma maison'**
  String get houseTitle;

  /// No description provided for @repairTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dépannage'**
  String get repairTitle;

  /// No description provided for @repairEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande en cours'**
  String get repairEmptyTitle;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun historique'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Vos dépannages précédents apparaîtront ici.'**
  String get historyEmptyBody;

  /// No description provided for @settingsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsEmptyTitle;

  /// No description provided for @settingsEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Les réglages arriveront dans une prochaine version.'**
  String get settingsEmptyBody;

  /// No description provided for @retake.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get retake;

  /// No description provided for @usePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser cette photo'**
  String get usePhoto;

  /// No description provided for @analyzingTitle.
  ///
  /// In fr, this message translates to:
  /// **'J\'analyse le problème…'**
  String get analyzingTitle;

  /// No description provided for @backHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backHome;

  /// No description provided for @cameraError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir la caméra. Vérifiez l\'autorisation dans les réglages du téléphone.'**
  String get cameraError;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @analyzingSlow.
  ///
  /// In fr, this message translates to:
  /// **'Cela prend un peu plus de temps que d\'habitude…'**
  String get analyzingSlow;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @errNetworkTitle.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de joindre Nalvium'**
  String get errNetworkTitle;

  /// No description provided for @errNetworkBody.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre connexion internet, puis réessayez.'**
  String get errNetworkBody;

  /// No description provided for @errTimeoutTitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'analyse prend trop de temps'**
  String get errTimeoutTitle;

  /// No description provided for @errTimeoutBody.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'est perdu : vous pouvez réessayer.'**
  String get errTimeoutBody;

  /// No description provided for @errUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'analyse n\'est pas disponible pour le moment'**
  String get errUnavailableTitle;

  /// No description provided for @errUnavailableBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande est enregistrée. Réessayez dans quelques instants.'**
  String get errUnavailableBody;

  /// No description provided for @errGenericTitle.
  ///
  /// In fr, this message translates to:
  /// **'Un problème est survenu'**
  String get errGenericTitle;

  /// No description provided for @errGenericBody.
  ///
  /// In fr, this message translates to:
  /// **'Réessayez dans un instant.'**
  String get errGenericBody;

  /// No description provided for @errNotConfiguredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion à Nalvium non configurée'**
  String get errNotConfiguredTitle;

  /// No description provided for @errNotConfiguredBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'adresse du serveur est absente de cette version de l\'application.'**
  String get errNotConfiguredBody;

  /// No description provided for @stepLabel.
  ///
  /// In fr, this message translates to:
  /// **'Étape {n}'**
  String stepLabel(int n);

  /// No description provided for @actionDone.
  ///
  /// In fr, this message translates to:
  /// **'C\'est fait'**
  String get actionDone;

  /// No description provided for @actionCannot.
  ///
  /// In fr, this message translates to:
  /// **'Je n\'y arrive pas'**
  String get actionCannot;

  /// No description provided for @actionMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Ce n\'est pas ce que je vois'**
  String get actionMismatch;

  /// No description provided for @answerYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get answerYes;

  /// No description provided for @answerNo.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get answerNo;

  /// No description provided for @answerDontKnow.
  ///
  /// In fr, this message translates to:
  /// **'Je ne sais pas'**
  String get answerDontKnow;

  /// No description provided for @answerOtherwise.
  ///
  /// In fr, this message translates to:
  /// **'Répondre autrement'**
  String get answerOtherwise;

  /// No description provided for @typeAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse'**
  String get typeAnswer;

  /// No description provided for @send.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get send;

  /// No description provided for @takeAPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get takeAPhoto;

  /// No description provided for @cannotTakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Je ne peux pas prendre cette photo'**
  String get cannotTakePhoto;

  /// No description provided for @cannotTakePhotoAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Je ne peux pas prendre cette photo.'**
  String get cannotTakePhotoAnswer;

  /// No description provided for @understood.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai compris'**
  String get understood;

  /// No description provided for @proTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cette intervention nécessite un professionnel.'**
  String get proTitle;

  /// No description provided for @seeRepairOptions.
  ///
  /// In fr, this message translates to:
  /// **'Voir les options de dépannage'**
  String get seeRepairOptions;

  /// No description provided for @resolvedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Problème résolu'**
  String get resolvedTitle;

  /// No description provided for @finish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get finish;

  /// No description provided for @describeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Que se passe-t-il ?'**
  String get describeTitle;

  /// No description provided for @describeHint.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez ce que vous voyez ou entendez…'**
  String get describeHint;

  /// No description provided for @continueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueLabel;

  /// No description provided for @resumeSection.
  ///
  /// In fr, this message translates to:
  /// **'À reprendre'**
  String get resumeSection;

  /// No description provided for @resumeButton.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get resumeButton;

  /// No description provided for @untitledProblem.
  ///
  /// In fr, this message translates to:
  /// **'Problème en cours'**
  String get untitledProblem;

  /// No description provided for @stateAskQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Nalvium attend votre réponse'**
  String get stateAskQuestion;

  /// No description provided for @stateRequestPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Une photo est attendue'**
  String get stateRequestPhoto;

  /// No description provided for @stateInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Une étape vous attend'**
  String get stateInstruction;

  /// No description provided for @stateVerification.
  ///
  /// In fr, this message translates to:
  /// **'À vérifier'**
  String get stateVerification;

  /// No description provided for @statusResolved.
  ///
  /// In fr, this message translates to:
  /// **'Résolu'**
  String get statusResolved;

  /// No description provided for @statusStopped.
  ///
  /// In fr, this message translates to:
  /// **'Arrêt de sécurité'**
  String get statusStopped;

  /// No description provided for @historyLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'historique.'**
  String get historyLoadError;

  /// No description provided for @sessionLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger cette session.'**
  String get sessionLoadError;

  /// No description provided for @takePhotoHint.
  ///
  /// In fr, this message translates to:
  /// **'Le moyen le plus rapide'**
  String get takePhotoHint;

  /// No description provided for @describeShort.
  ///
  /// In fr, this message translates to:
  /// **'Décrire'**
  String get describeShort;

  /// No description provided for @filmShort.
  ///
  /// In fr, this message translates to:
  /// **'Filmer'**
  String get filmShort;

  /// No description provided for @resumeLastStep.
  ///
  /// In fr, this message translates to:
  /// **'Dernière étape'**
  String get resumeLastStep;

  /// No description provided for @houseEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre maison'**
  String get houseEmptyTitle;

  /// No description provided for @houseEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos équipements pour que Nalvium se souvienne de ce qu\'il y a chez vous.'**
  String get houseEmptyBody;

  /// No description provided for @repairEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Si un problème demande un professionnel, vous pourrez le demander ici.'**
  String get repairEmptyBody;

  /// No description provided for @communityEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les réparations des autres, bientôt ici'**
  String get communityEmptyTitle;

  /// No description provided for @communityEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous verrez ici des problèmes réellement résolus par d\'autres personnes.'**
  String get communityEmptyBody;

  /// No description provided for @previewSharp.
  ///
  /// In fr, this message translates to:
  /// **'La photo est-elle assez nette ?'**
  String get previewSharp;

  /// No description provided for @previewTip.
  ///
  /// In fr, this message translates to:
  /// **'Cadrez surtout la zone où vous voyez le problème.'**
  String get previewTip;

  /// No description provided for @previewSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu de la photo prise'**
  String get previewSemantics;

  /// No description provided for @waitLooking.
  ///
  /// In fr, this message translates to:
  /// **'Je regarde ce qui pourrait provoquer ça.'**
  String get waitLooking;

  /// No description provided for @waitObserving.
  ///
  /// In fr, this message translates to:
  /// **'J\'observe les éléments visibles.'**
  String get waitObserving;

  /// No description provided for @waitChecking.
  ///
  /// In fr, this message translates to:
  /// **'Je vérifie ce qui mérite votre attention.'**
  String get waitChecking;

  /// No description provided for @titleAsk.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai besoin de vérifier un point'**
  String get titleAsk;

  /// No description provided for @titleRequestPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Montrez-moi ce point'**
  String get titleRequestPhoto;

  /// No description provided for @titleInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Essayez ceci'**
  String get titleInstruction;

  /// No description provided for @titleVerification.
  ///
  /// In fr, this message translates to:
  /// **'Vérifions'**
  String get titleVerification;

  /// No description provided for @titleResolved.
  ///
  /// In fr, this message translates to:
  /// **'C\'est réglé'**
  String get titleResolved;

  /// No description provided for @titleProfessional.
  ///
  /// In fr, this message translates to:
  /// **'Cette intervention demande un professionnel'**
  String get titleProfessional;

  /// No description provided for @safetyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Arrêtez-vous ici'**
  String get safetyTitle;

  /// No description provided for @phaseObservation.
  ///
  /// In fr, this message translates to:
  /// **'Observation'**
  String get phaseObservation;

  /// No description provided for @phaseAction.
  ///
  /// In fr, this message translates to:
  /// **'Action'**
  String get phaseAction;

  /// No description provided for @phaseControl.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle'**
  String get phaseControl;

  /// No description provided for @takeThePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre la photo'**
  String get takeThePhoto;

  /// No description provided for @askForHelp.
  ///
  /// In fr, this message translates to:
  /// **'Demander de l\'aide'**
  String get askForHelp;

  /// No description provided for @understoodShort.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get understoodShort;

  /// No description provided for @findProfessional.
  ///
  /// In fr, this message translates to:
  /// **'Trouver un professionnel'**
  String get findProfessional;

  /// No description provided for @seeSummary.
  ///
  /// In fr, this message translates to:
  /// **'Voir le récapitulatif'**
  String get seeSummary;

  /// No description provided for @backToHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backToHome;

  /// No description provided for @answerALittle.
  ///
  /// In fr, this message translates to:
  /// **'Un peu'**
  String get answerALittle;

  /// No description provided for @catPlumbing.
  ///
  /// In fr, this message translates to:
  /// **'Plomberie'**
  String get catPlumbing;

  /// No description provided for @catAppliance.
  ///
  /// In fr, this message translates to:
  /// **'Électroménager'**
  String get catAppliance;

  /// No description provided for @catHandyman.
  ///
  /// In fr, this message translates to:
  /// **'Bricolage'**
  String get catHandyman;

  /// No description provided for @catElectrical.
  ///
  /// In fr, this message translates to:
  /// **'Électricité'**
  String get catElectrical;

  /// No description provided for @catOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get catOther;

  /// No description provided for @statusReferred.
  ///
  /// In fr, this message translates to:
  /// **'Professionnel recommandé'**
  String get statusReferred;

  /// No description provided for @statusActive.
  ///
  /// In fr, this message translates to:
  /// **'À reprendre'**
  String get statusActive;

  /// No description provided for @stateAwaiting.
  ///
  /// In fr, this message translates to:
  /// **'Analyse à relancer'**
  String get stateAwaiting;

  /// No description provided for @relToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get relToday;

  /// No description provided for @relYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get relYesterday;

  /// No description provided for @summaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get summaryTitle;

  /// No description provided for @summaryObserved.
  ///
  /// In fr, this message translates to:
  /// **'Ce que j\'ai observé'**
  String get summaryObserved;

  /// No description provided for @summaryTried.
  ///
  /// In fr, this message translates to:
  /// **'Ce que vous avez essayé'**
  String get summaryTried;

  /// No description provided for @summaryConclusion.
  ///
  /// In fr, this message translates to:
  /// **'Conclusion'**
  String get summaryConclusion;

  /// No description provided for @stepDone.
  ///
  /// In fr, this message translates to:
  /// **'Fait'**
  String get stepDone;

  /// No description provided for @stepFailed.
  ///
  /// In fr, this message translates to:
  /// **'Pas réussi'**
  String get stepFailed;

  /// No description provided for @stepMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Différent de ce que vous voyez'**
  String get stepMismatch;

  /// No description provided for @stepPending.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore fait'**
  String get stepPending;

  /// No description provided for @photoSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Photo du problème'**
  String get photoSemantics;

  /// No description provided for @videoSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo du problème'**
  String get videoSemantics;

  /// No description provided for @sessionClosed.
  ///
  /// In fr, this message translates to:
  /// **'Session terminée'**
  String get sessionClosed;

  /// No description provided for @youNeed.
  ///
  /// In fr, this message translates to:
  /// **'Vous aurez besoin de'**
  String get youNeed;

  /// No description provided for @verifyWithPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Montrer avec une photo'**
  String get verifyWithPhoto;

  /// No description provided for @analyzingDescription.
  ///
  /// In fr, this message translates to:
  /// **'J\'analyse votre description…'**
  String get analyzingDescription;

  /// No description provided for @summaryProblem.
  ///
  /// In fr, this message translates to:
  /// **'Problème'**
  String get summaryProblem;

  /// No description provided for @summaryDone.
  ///
  /// In fr, this message translates to:
  /// **'Ce qu\'on a fait'**
  String get summaryDone;

  /// No description provided for @summaryResult.
  ///
  /// In fr, this message translates to:
  /// **'Résultat'**
  String get summaryResult;

  /// No description provided for @historyIntro.
  ///
  /// In fr, this message translates to:
  /// **'Les problèmes que Nalvium vous a aidé à traiter.'**
  String get historyIntro;

  /// No description provided for @yourPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Votre photo'**
  String get yourPhoto;

  /// No description provided for @photoToTake.
  ///
  /// In fr, this message translates to:
  /// **'À prendre'**
  String get photoToTake;

  /// No description provided for @videoMaxHint.
  ///
  /// In fr, this message translates to:
  /// **'15 secondes maximum'**
  String get videoMaxHint;

  /// No description provided for @videoRemaining.
  ///
  /// In fr, this message translates to:
  /// **'{s} s restantes'**
  String videoRemaining(int s);

  /// No description provided for @videoStart.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer l\'enregistrement'**
  String get videoStart;

  /// No description provided for @videoStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter l\'enregistrement'**
  String get videoStop;

  /// No description provided for @videoSwitchCamera.
  ///
  /// In fr, this message translates to:
  /// **'Changer de caméra'**
  String get videoSwitchCamera;

  /// No description provided for @videoNoSound.
  ///
  /// In fr, this message translates to:
  /// **'Sans son'**
  String get videoNoSound;

  /// No description provided for @videoPreviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'La vidéo est-elle assez claire ?'**
  String get videoPreviewTitle;

  /// No description provided for @videoPreviewTip.
  ///
  /// In fr, this message translates to:
  /// **'Montrez bien la zone du problème : quelques secondes suffisent.'**
  String get videoPreviewTip;

  /// No description provided for @useVideo.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser cette vidéo'**
  String get useVideo;

  /// No description provided for @refilm.
  ///
  /// In fr, this message translates to:
  /// **'Refilmer'**
  String get refilm;

  /// No description provided for @videoNoAudioNote.
  ///
  /// In fr, this message translates to:
  /// **'Cette vidéo n\'a pas de son.'**
  String get videoNoAudioNote;

  /// No description provided for @videoPlay.
  ///
  /// In fr, this message translates to:
  /// **'Lire la vidéo'**
  String get videoPlay;

  /// No description provided for @videoPause.
  ///
  /// In fr, this message translates to:
  /// **'Mettre en pause'**
  String get videoPause;

  /// No description provided for @videoPreviewSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu de la vidéo'**
  String get videoPreviewSemantics;

  /// No description provided for @videoCannotPlay.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire l\'aperçu, mais la vidéo est bien enregistrée.'**
  String get videoCannotPlay;

  /// No description provided for @analyzingVideo.
  ///
  /// In fr, this message translates to:
  /// **'J\'analyse votre vidéo…'**
  String get analyzingVideo;

  /// No description provided for @waitVideo.
  ///
  /// In fr, this message translates to:
  /// **'J\'observe ce qui change dans la vidéo.'**
  String get waitVideo;

  /// No description provided for @videoPosterSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu de la vidéo'**
  String get videoPosterSemantics;

  /// No description provided for @errCameraDeniedTitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'accès à la caméra est nécessaire'**
  String get errCameraDeniedTitle;

  /// No description provided for @errCameraDeniedBody.
  ///
  /// In fr, this message translates to:
  /// **'Autorisez la caméra dans les réglages du téléphone, ou montrez le problème autrement.'**
  String get errCameraDeniedBody;

  /// No description provided for @errCameraUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'La caméra n\'est pas disponible'**
  String get errCameraUnavailableTitle;

  /// No description provided for @errCameraUnavailableBody.
  ///
  /// In fr, this message translates to:
  /// **'Une autre application l\'utilise peut-être. Réessayez, ou montrez le problème autrement.'**
  String get errCameraUnavailableBody;

  /// No description provided for @errVideoTooShortTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo trop courte'**
  String get errVideoTooShortTitle;

  /// No description provided for @errVideoTooShortBody.
  ///
  /// In fr, this message translates to:
  /// **'Filmez au moins une seconde, en montrant bien le problème.'**
  String get errVideoTooShortBody;

  /// No description provided for @errVideoTooLargeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cette vidéo est trop lourde'**
  String get errVideoTooLargeTitle;

  /// No description provided for @errVideoTooLargeBody.
  ///
  /// In fr, this message translates to:
  /// **'Refaites une vidéo plus courte, ou prenez une photo.'**
  String get errVideoTooLargeBody;

  /// No description provided for @errVideoTooLongTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cette vidéo est trop longue'**
  String get errVideoTooLongTitle;

  /// No description provided for @errVideoTooLongBody.
  ///
  /// In fr, this message translates to:
  /// **'15 secondes maximum. Refaites une vidéo plus courte.'**
  String get errVideoTooLongBody;

  /// No description provided for @errVideoInvalidTitle.
  ///
  /// In fr, this message translates to:
  /// **'Format de vidéo non pris en charge'**
  String get errVideoInvalidTitle;

  /// No description provided for @errVideoInvalidBody.
  ///
  /// In fr, this message translates to:
  /// **'Refaites la vidéo avec l\'appareil photo de Nalvium, ou prenez une photo.'**
  String get errVideoInvalidBody;

  /// No description provided for @yourVideo.
  ///
  /// In fr, this message translates to:
  /// **'Votre vidéo'**
  String get yourVideo;

  /// No description provided for @houseEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Vos diagnostics pourront ensuite être rattachés automatiquement à vos équipements.'**
  String get houseEmptyHint;

  /// No description provided for @houseAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un équipement'**
  String get houseAdd;

  /// No description provided for @houseNoRoom.
  ///
  /// In fr, this message translates to:
  /// **'Sans pièce'**
  String get houseNoRoom;

  /// No description provided for @houseNoIssue.
  ///
  /// In fr, this message translates to:
  /// **'Aucun problème'**
  String get houseNoIssue;

  /// No description provided for @houseDiagnosticsOne.
  ///
  /// In fr, this message translates to:
  /// **'1 diagnostic'**
  String get houseDiagnosticsOne;

  /// No description provided for @houseLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'afficher votre maison'**
  String get houseLoadError;

  /// No description provided for @eqAddTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un équipement'**
  String get eqAddTitle;

  /// No description provided for @eqEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'équipement'**
  String get eqEditTitle;

  /// No description provided for @eqStepType.
  ///
  /// In fr, this message translates to:
  /// **'Quel équipement ?'**
  String get eqStepType;

  /// No description provided for @eqSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un équipement'**
  String get eqSearchHint;

  /// No description provided for @eqSearchEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun équipement ne correspond. Choisissez « Autre » pour le nommer vous-même.'**
  String get eqSearchEmpty;

  /// No description provided for @eqIdentifyPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Identifier avec une photo'**
  String get eqIdentifyPhoto;

  /// No description provided for @eqStepRoom.
  ///
  /// In fr, this message translates to:
  /// **'Où se trouve-t-il ?'**
  String get eqStepRoom;

  /// No description provided for @eqRoomSkip.
  ///
  /// In fr, this message translates to:
  /// **'Je ne sais pas / Passer'**
  String get eqRoomSkip;

  /// No description provided for @eqStepDetails.
  ///
  /// In fr, this message translates to:
  /// **'Quelques précisions'**
  String get eqStepDetails;

  /// No description provided for @eqDetailsHint.
  ///
  /// In fr, this message translates to:
  /// **'Tout est facultatif : vous pourrez compléter plus tard.'**
  String get eqDetailsHint;

  /// No description provided for @eqName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get eqName;

  /// No description provided for @eqNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Lave-vaisselle du fond'**
  String get eqNameHint;

  /// No description provided for @eqBrand.
  ///
  /// In fr, this message translates to:
  /// **'Marque'**
  String get eqBrand;

  /// No description provided for @eqBrandHint.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif'**
  String get eqBrandHint;

  /// No description provided for @eqModel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle / référence'**
  String get eqModel;

  /// No description provided for @eqModelHint.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif'**
  String get eqModelHint;

  /// No description provided for @eqPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get eqPhoto;

  /// No description provided for @eqPhotoAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get eqPhotoAdd;

  /// No description provided for @eqPhotoChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get eqPhotoChange;

  /// No description provided for @eqPhotoRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la photo'**
  String get eqPhotoRemove;

  /// No description provided for @eqPhotoPrivate.
  ///
  /// In fr, this message translates to:
  /// **'Votre photo reste privée.'**
  String get eqPhotoPrivate;

  /// No description provided for @eqPhotoFail.
  ///
  /// In fr, this message translates to:
  /// **'La photo n\'a pas pu être enregistrée. Votre saisie est conservée : réessayez.'**
  String get eqPhotoFail;

  /// No description provided for @eqSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get eqSave;

  /// No description provided for @eqSaveFail.
  ///
  /// In fr, this message translates to:
  /// **'L\'équipement n\'a pas pu être enregistré. Votre saisie est conservée : réessayez.'**
  String get eqSaveFail;

  /// No description provided for @eqNext.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get eqNext;

  /// No description provided for @eqRoomLabel.
  ///
  /// In fr, this message translates to:
  /// **'Pièce'**
  String get eqRoomLabel;

  /// No description provided for @eqType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get eqType;

  /// No description provided for @eqNoBrand.
  ///
  /// In fr, this message translates to:
  /// **'Marque non renseignée'**
  String get eqNoBrand;

  /// No description provided for @eqIdentifyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Identifier avec une photo'**
  String get eqIdentifyTitle;

  /// No description provided for @eqIdentifyTip.
  ///
  /// In fr, this message translates to:
  /// **'Photographiez l\'équipement entier, ou son étiquette si vous la trouvez.'**
  String get eqIdentifyTip;

  /// No description provided for @eqIdentifyTake.
  ///
  /// In fr, this message translates to:
  /// **'Prendre la photo'**
  String get eqIdentifyTake;

  /// No description provided for @eqIdentifyWorking.
  ///
  /// In fr, this message translates to:
  /// **'Nalvium regarde votre photo…'**
  String get eqIdentifyWorking;

  /// No description provided for @eqIdentifyNotSure.
  ///
  /// In fr, this message translates to:
  /// **'Nalvium n\'en est pas certain : vérifiez avant de confirmer.'**
  String get eqIdentifyNotSure;

  /// No description provided for @eqIdentifyConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Oui, c\'est ça'**
  String get eqIdentifyConfirm;

  /// No description provided for @eqIdentifyCorrect.
  ///
  /// In fr, this message translates to:
  /// **'Corriger'**
  String get eqIdentifyCorrect;

  /// No description provided for @eqIdentifyUnknownTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nalvium n\'a pas pu l\'identifier'**
  String get eqIdentifyUnknownTitle;

  /// No description provided for @eqIdentifyUnknownBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce n\'est pas grave : choisissez vous-même le type d\'équipement. Votre photo est conservée.'**
  String get eqIdentifyUnknownBody;

  /// No description provided for @eqIdentifyChoose.
  ///
  /// In fr, this message translates to:
  /// **'Choisir moi-même'**
  String get eqIdentifyChoose;

  /// No description provided for @eqIdentifyFailTitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'identification n\'est pas disponible'**
  String get eqIdentifyFailTitle;

  /// No description provided for @eqIdentifyFailBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez continuer sans : votre photo est conservée.'**
  String get eqIdentifyFailBody;

  /// No description provided for @eqIdentifyContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer sans identification'**
  String get eqIdentifyContinue;

  /// No description provided for @eqIdentifyReadable.
  ///
  /// In fr, this message translates to:
  /// **'Texte lu sur l\'appareil'**
  String get eqIdentifyReadable;

  /// No description provided for @eqDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Équipement'**
  String get eqDetailTitle;

  /// No description provided for @eqProblems.
  ///
  /// In fr, this message translates to:
  /// **'Problèmes traités'**
  String get eqProblems;

  /// No description provided for @eqNoProblems.
  ///
  /// In fr, this message translates to:
  /// **'Aucun problème enregistré pour cet équipement.'**
  String get eqNoProblems;

  /// No description provided for @eqDiagnose.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostiquer un problème'**
  String get eqDiagnose;

  /// No description provided for @eqDiagnoseHow.
  ///
  /// In fr, this message translates to:
  /// **'Comment voulez-vous montrer le problème ?'**
  String get eqDiagnoseHow;

  /// No description provided for @eqEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get eqEdit;

  /// No description provided for @eqDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get eqDelete;

  /// No description provided for @eqDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cet équipement ?'**
  String get eqDeleteTitle;

  /// No description provided for @eqDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Ses diagnostics ne seront pas supprimés : ils seront simplement détachés de cet équipement. Sa photo sera supprimée.'**
  String get eqDeleteBody;

  /// No description provided for @eqDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'équipement'**
  String get eqDeleteConfirm;

  /// No description provided for @eqDeleteFail.
  ///
  /// In fr, this message translates to:
  /// **'L\'équipement n\'a pas pu être supprimé. Réessayez.'**
  String get eqDeleteFail;

  /// No description provided for @eqGone.
  ///
  /// In fr, this message translates to:
  /// **'Cet équipement n\'existe plus.'**
  String get eqGone;

  /// No description provided for @eqBackToHouse.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la maison'**
  String get eqBackToHouse;

  /// No description provided for @eqLinkAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à votre maison'**
  String get eqLinkAdd;

  /// No description provided for @eqLinkSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer cet équipement'**
  String get eqLinkSave;

  /// No description provided for @eqLinkTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à votre maison'**
  String get eqLinkTitle;

  /// No description provided for @eqLinkChoose.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un équipement existant'**
  String get eqLinkChoose;

  /// No description provided for @eqLinkNew.
  ///
  /// In fr, this message translates to:
  /// **'Créer un nouvel équipement'**
  String get eqLinkNew;

  /// No description provided for @eqLinkYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui, c\'est lui'**
  String get eqLinkYes;

  /// No description provided for @eqLinkNo.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get eqLinkNo;

  /// No description provided for @eqLinkDone.
  ///
  /// In fr, this message translates to:
  /// **'Ce diagnostic est rattaché à votre équipement.'**
  String get eqLinkDone;

  /// No description provided for @eqLinkFail.
  ///
  /// In fr, this message translates to:
  /// **'Le rattachement n\'a pas pu être enregistré. Réessayez.'**
  String get eqLinkFail;

  /// No description provided for @eqLinkedTo.
  ///
  /// In fr, this message translates to:
  /// **'Équipement'**
  String get eqLinkedTo;

  /// No description provided for @eqLinkDetach.
  ///
  /// In fr, this message translates to:
  /// **'Détacher de cet équipement'**
  String get eqLinkDetach;

  /// No description provided for @eqLinkNothing.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas encore d\'équipement enregistré.'**
  String get eqLinkNothing;

  /// No description provided for @eqSessionGone.
  ///
  /// In fr, this message translates to:
  /// **'Ce diagnostic est introuvable.'**
  String get eqSessionGone;

  /// No description provided for @eqDiagnosticsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} diagnostics'**
  String eqDiagnosticsCount(int count);

  /// No description provided for @eqLinkAsk.
  ///
  /// In fr, this message translates to:
  /// **'Est-ce votre {name} ?'**
  String eqLinkAsk(String name);

  /// No description provided for @eqIdentifyResult.
  ///
  /// In fr, this message translates to:
  /// **'Cela ressemble à {what}.'**
  String eqIdentifyResult(String what);

  /// No description provided for @eqSemanticsEquipment.
  ///
  /// In fr, this message translates to:
  /// **'{name}, {where}'**
  String eqSemanticsEquipment(String name, String where);

  /// No description provided for @eqRefLabel.
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get eqRefLabel;

  /// No description provided for @eqRefNone.
  ///
  /// In fr, this message translates to:
  /// **'Référence non renseignée'**
  String get eqRefNone;

  /// No description provided for @eqRefWhere.
  ///
  /// In fr, this message translates to:
  /// **'Où trouver la référence ?'**
  String get eqRefWhere;

  /// No description provided for @eqRefHelpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Où trouver la référence ?'**
  String get eqRefHelpTitle;

  /// No description provided for @eqRefHelpBody.
  ///
  /// In fr, this message translates to:
  /// **'C\'est une série de lettres et de chiffres (par exemple SMS46GI01E). Elle figure sur la plaque signalétique : à l\'intérieur de la porte d\'un lave-vaisselle ou d\'un lave-linge, sur le côté ou au dos d\'un four ou d\'un réfrigérateur, sous ou sur le côté d\'une chaudière. Elle est aussi dans la notice et sur la facture. Si vous ne la trouvez pas, ce n\'est pas grave : elle reste facultative.'**
  String get eqRefHelpBody;

  /// No description provided for @eqRefHelpClose.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai compris'**
  String get eqRefHelpClose;

  /// No description provided for @eqIdentifyCloser.
  ///
  /// In fr, this message translates to:
  /// **'Pour la référence, photographiez la plaque signalétique de plus près : Nalvium n\'invente jamais les caractères illisibles.'**
  String get eqIdentifyCloser;

  /// No description provided for @manualTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notice'**
  String get manualTitle;

  /// No description provided for @manualZone.
  ///
  /// In fr, this message translates to:
  /// **'Notice constructeur'**
  String get manualZone;

  /// No description provided for @manualNeedRef.
  ///
  /// In fr, this message translates to:
  /// **'Référence nécessaire'**
  String get manualNeedRef;

  /// No description provided for @manualNeedRefBody.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez la marque et la référence pour que Nalvium cherche la notice exacte de votre appareil.'**
  String get manualNeedRefBody;

  /// No description provided for @manualSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher la notice'**
  String get manualSearch;

  /// No description provided for @manualSearching.
  ///
  /// In fr, this message translates to:
  /// **'Recherche en cours'**
  String get manualSearching;

  /// No description provided for @manualSearchingBody.
  ///
  /// In fr, this message translates to:
  /// **'Nalvium cherche la notice officielle de votre appareil. Cela peut prendre une minute.'**
  String get manualSearchingBody;

  /// No description provided for @manualAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Notice disponible'**
  String get manualAvailable;

  /// No description provided for @manualAvailableBody.
  ///
  /// In fr, this message translates to:
  /// **'Nalvium s\'appuiera sur cette notice pour les prochains diagnostics de cet équipement.'**
  String get manualAvailableBody;

  /// No description provided for @manualConsult.
  ///
  /// In fr, this message translates to:
  /// **'Consulter'**
  String get manualConsult;

  /// No description provided for @manualUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get manualUpdate;

  /// No description provided for @manualNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Notice exacte introuvable'**
  String get manualNotFound;

  /// No description provided for @manualNotFoundBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notice officielle correspondant exactement à cette référence n\'a été trouvée. Vous pouvez utiliser l\'équipement normalement.'**
  String get manualNotFoundBody;

  /// No description provided for @manualError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de récupération'**
  String get manualError;

  /// No description provided for @manualErrorBody.
  ///
  /// In fr, this message translates to:
  /// **'La notice n\'a pas pu être récupérée pour le moment. Réessayez plus tard.'**
  String get manualErrorBody;

  /// No description provided for @manualApprox.
  ///
  /// In fr, this message translates to:
  /// **'Une notice proche a été trouvée'**
  String get manualApprox;

  /// No description provided for @manualApproxBody.
  ///
  /// In fr, this message translates to:
  /// **'Sa référence est légèrement différente de la vôtre. Nalvium ne l\'utilisera que si vous confirmez qu\'elle convient.'**
  String get manualApproxBody;

  /// No description provided for @manualApproxYes.
  ///
  /// In fr, this message translates to:
  /// **'Elle convient'**
  String get manualApproxYes;

  /// No description provided for @manualApproxNo.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer cette notice'**
  String get manualApproxNo;

  /// No description provided for @manualOfficial.
  ///
  /// In fr, this message translates to:
  /// **'Source officielle du fabricant'**
  String get manualOfficial;

  /// No description provided for @manualRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get manualRetry;

  /// No description provided for @manualUpToDate.
  ///
  /// In fr, this message translates to:
  /// **'La notice est déjà à jour.'**
  String get manualUpToDate;

  /// No description provided for @manualKept.
  ///
  /// In fr, this message translates to:
  /// **'La recherche a échoué : votre notice actuelle est conservée.'**
  String get manualKept;

  /// No description provided for @manualPrivate.
  ///
  /// In fr, this message translates to:
  /// **'Cette notice reste privée : elle n\'est accessible que depuis votre appareil.'**
  String get manualPrivate;

  /// No description provided for @manualPageNext.
  ///
  /// In fr, this message translates to:
  /// **'Page suivante'**
  String get manualPageNext;

  /// No description provided for @manualPagePrev.
  ///
  /// In fr, this message translates to:
  /// **'Page précédente'**
  String get manualPagePrev;

  /// No description provided for @manualPageEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Cette page ne contient pas de texte exploitable.'**
  String get manualPageEmpty;

  /// No description provided for @manualLoadFail.
  ///
  /// In fr, this message translates to:
  /// **'La page n\'a pas pu être chargée.'**
  String get manualLoadFail;

  /// No description provided for @manualConfirmFail.
  ///
  /// In fr, this message translates to:
  /// **'L\'action n\'a pas pu être enregistrée. Réessayez.'**
  String get manualConfirmFail;

  /// No description provided for @manualPages.
  ///
  /// In fr, this message translates to:
  /// **'{count} pages'**
  String manualPages(int count);

  /// No description provided for @manualSource.
  ///
  /// In fr, this message translates to:
  /// **'Source : {domain}'**
  String manualSource(String domain);

  /// No description provided for @manualPageOf.
  ///
  /// In fr, this message translates to:
  /// **'Page {page} sur {total}'**
  String manualPageOf(int page, int total);

  /// No description provided for @manualCite.
  ///
  /// In fr, this message translates to:
  /// **'D\'après la notice {brand} de votre appareil'**
  String manualCite(String brand);

  /// No description provided for @manualCiteGeneric.
  ///
  /// In fr, this message translates to:
  /// **'D\'après la notice de votre appareil'**
  String get manualCiteGeneric;

  /// No description provided for @manualCitePage.
  ///
  /// In fr, this message translates to:
  /// **'Notice · page {pages}'**
  String manualCitePage(String pages);

  /// No description provided for @manualCitePages.
  ///
  /// In fr, this message translates to:
  /// **'Notice · pages {pages}'**
  String manualCitePages(String pages);

  /// No description provided for @manualIdle.
  ///
  /// In fr, this message translates to:
  /// **'Notice non récupérée'**
  String get manualIdle;

  /// No description provided for @manualIdleBody.
  ///
  /// In fr, this message translates to:
  /// **'Nalvium peut chercher la notice officielle de votre appareil.'**
  String get manualIdleBody;

  /// No description provided for @repairHeadline.
  ///
  /// In fr, this message translates to:
  /// **'Besoin d\'un coup de main ?'**
  String get repairHeadline;

  /// No description provided for @repairHeadlineBody.
  ///
  /// In fr, this message translates to:
  /// **'Nalvium peut préparer votre demande pour que vous n\'ayez pas à tout réexpliquer.'**
  String get repairHeadlineBody;

  /// No description provided for @repairAsk.
  ///
  /// In fr, this message translates to:
  /// **'Demander une intervention'**
  String get repairAsk;

  /// No description provided for @repairYourRequests.
  ///
  /// In fr, this message translates to:
  /// **'Vos demandes'**
  String get repairYourRequests;

  /// No description provided for @repairNoRequests.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez aucune demande pour le moment.'**
  String get repairNoRequests;

  /// No description provided for @repairLoadFail.
  ///
  /// In fr, this message translates to:
  /// **'Vos demandes n\'ont pas pu être chargées'**
  String get repairLoadFail;

  /// No description provided for @helpAsk.
  ///
  /// In fr, this message translates to:
  /// **'Demander de l\'aide'**
  String get helpAsk;

  /// No description provided for @helpNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande d\'intervention'**
  String get helpNewTitle;

  /// No description provided for @helpIntro.
  ///
  /// In fr, this message translates to:
  /// **'Nalvium a déjà compris le problème : vous n\'avez pas à tout réexpliquer. Vérifiez et corrigez si besoin.'**
  String get helpIntro;

  /// No description provided for @helpSectionProblem.
  ///
  /// In fr, this message translates to:
  /// **'Problème'**
  String get helpSectionProblem;

  /// No description provided for @helpProblemHint.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez le problème en quelques mots'**
  String get helpProblemHint;

  /// No description provided for @helpCategory.
  ///
  /// In fr, this message translates to:
  /// **'Type de problème'**
  String get helpCategory;

  /// No description provided for @helpCatPlumbing.
  ///
  /// In fr, this message translates to:
  /// **'Plomberie'**
  String get helpCatPlumbing;

  /// No description provided for @helpCatAppliance.
  ///
  /// In fr, this message translates to:
  /// **'Électroménager'**
  String get helpCatAppliance;

  /// No description provided for @helpCatHandyman.
  ///
  /// In fr, this message translates to:
  /// **'Bricolage'**
  String get helpCatHandyman;

  /// No description provided for @helpCatElectrical.
  ///
  /// In fr, this message translates to:
  /// **'Électricité'**
  String get helpCatElectrical;

  /// No description provided for @helpCatOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get helpCatOther;

  /// No description provided for @helpSectionEquipment.
  ///
  /// In fr, this message translates to:
  /// **'Équipement'**
  String get helpSectionEquipment;

  /// No description provided for @helpEquipmentNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun équipement'**
  String get helpEquipmentNone;

  /// No description provided for @helpSectionTried.
  ///
  /// In fr, this message translates to:
  /// **'Déjà essayé'**
  String get helpSectionTried;

  /// No description provided for @helpTriedDone.
  ///
  /// In fr, this message translates to:
  /// **'fait'**
  String get helpTriedDone;

  /// No description provided for @helpTriedFailed.
  ///
  /// In fr, this message translates to:
  /// **'impossible'**
  String get helpTriedFailed;

  /// No description provided for @helpTriedMismatch.
  ///
  /// In fr, this message translates to:
  /// **'ne correspondait pas'**
  String get helpTriedMismatch;

  /// No description provided for @helpTriedProposed.
  ///
  /// In fr, this message translates to:
  /// **'proposé'**
  String get helpTriedProposed;

  /// No description provided for @helpHypothesisNote.
  ///
  /// In fr, this message translates to:
  /// **'Hypothèse de Nalvium, non confirmée par un professionnel :'**
  String get helpHypothesisNote;

  /// No description provided for @helpSafetyReason.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi une aide est recommandée'**
  String get helpSafetyReason;

  /// No description provided for @helpManualUsed.
  ///
  /// In fr, this message translates to:
  /// **'Notice constructeur consultée'**
  String get helpManualUsed;

  /// No description provided for @helpSectionMedia.
  ///
  /// In fr, this message translates to:
  /// **'Photos et vidéos'**
  String get helpSectionMedia;

  /// No description provided for @helpMediaPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les éléments sélectionnés seront transmis avec votre demande. Les autres restent privés.'**
  String get helpMediaPrivacy;

  /// No description provided for @helpMediaNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune photo ou vidéo jointe.'**
  String get helpMediaNone;

  /// No description provided for @helpMediaAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get helpMediaAdd;

  /// No description provided for @helpMediaJoin.
  ///
  /// In fr, this message translates to:
  /// **'Joindre à ma demande'**
  String get helpMediaJoin;

  /// No description provided for @helpMediaVideo.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get helpMediaVideo;

  /// No description provided for @helpSectionContact.
  ///
  /// In fr, this message translates to:
  /// **'Vos informations'**
  String get helpSectionContact;

  /// No description provided for @helpFirstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get helpFirstName;

  /// No description provided for @helpPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get helpPhone;

  /// No description provided for @helpCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get helpCity;

  /// No description provided for @helpPostal.
  ///
  /// In fr, this message translates to:
  /// **'Code postal'**
  String get helpPostal;

  /// No description provided for @helpEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail (facultatif)'**
  String get helpEmail;

  /// No description provided for @helpNoAddress.
  ///
  /// In fr, this message translates to:
  /// **'Pas d\'adresse précise : seulement votre ville et votre code postal.'**
  String get helpNoAddress;

  /// No description provided for @helpSectionWhen.
  ///
  /// In fr, this message translates to:
  /// **'Disponibilité'**
  String get helpSectionWhen;

  /// No description provided for @helpWhenNote.
  ///
  /// In fr, this message translates to:
  /// **'C\'est une préférence, pas une réservation.'**
  String get helpWhenNote;

  /// No description provided for @helpAsap.
  ///
  /// In fr, this message translates to:
  /// **'Dès que possible'**
  String get helpAsap;

  /// No description provided for @helpToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get helpToday;

  /// No description provided for @helpTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get helpTomorrow;

  /// No description provided for @helpThisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get helpThisWeek;

  /// No description provided for @helpCustom.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un créneau'**
  String get helpCustom;

  /// No description provided for @helpPickDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get helpPickDate;

  /// No description provided for @helpMorning.
  ///
  /// In fr, this message translates to:
  /// **'Matin'**
  String get helpMorning;

  /// No description provided for @helpAfternoon.
  ///
  /// In fr, this message translates to:
  /// **'Après-midi'**
  String get helpAfternoon;

  /// No description provided for @helpEvening.
  ///
  /// In fr, this message translates to:
  /// **'Soir'**
  String get helpEvening;

  /// No description provided for @helpConsent.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte que les informations sélectionnées dans cette demande soient transmises à un professionnel susceptible de m\'aider.'**
  String get helpConsent;

  /// No description provided for @helpSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer ma demande'**
  String get helpSend;

  /// No description provided for @helpSending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours'**
  String get helpSending;

  /// No description provided for @helpErrRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est nécessaire.'**
  String get helpErrRequired;

  /// No description provided for @helpErrPhone.
  ///
  /// In fr, this message translates to:
  /// **'Entrez un numéro valide, par exemple 06 12 34 56 78.'**
  String get helpErrPhone;

  /// No description provided for @helpErrPostal.
  ///
  /// In fr, this message translates to:
  /// **'Entrez un code postal à 5 chiffres.'**
  String get helpErrPostal;

  /// No description provided for @helpErrEmail.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse e-mail semble incorrecte.'**
  String get helpErrEmail;

  /// No description provided for @helpErrDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une date et une plage horaire.'**
  String get helpErrDate;

  /// No description provided for @helpErrConsent.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez accepter pour envoyer la demande.'**
  String get helpErrConsent;

  /// No description provided for @helpErrSend.
  ///
  /// In fr, this message translates to:
  /// **'La demande n\'a pas pu être envoyée. Vos informations sont conservées : réessayez.'**
  String get helpErrSend;

  /// No description provided for @helpErrPrepare.
  ///
  /// In fr, this message translates to:
  /// **'La demande n\'a pas pu être préparée.'**
  String get helpErrPrepare;

  /// No description provided for @helpEmergency.
  ///
  /// In fr, this message translates to:
  /// **'En cas de danger immédiat, appelez les secours (18 ou 112). Une demande Nalvium ne les remplace pas.'**
  String get helpEmergency;

  /// No description provided for @helpDoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande est envoyée'**
  String get helpDoneTitle;

  /// No description provided for @helpDoneBody.
  ///
  /// In fr, this message translates to:
  /// **'Nous avons enregistré votre demande avec les informations que vous avez choisies de partager. Elle pourra être transmise à un professionnel adapté lorsqu\'il sera disponible.'**
  String get helpDoneBody;

  /// No description provided for @helpSeeRequest.
  ///
  /// In fr, this message translates to:
  /// **'Voir ma demande'**
  String get helpSeeRequest;

  /// No description provided for @helpBackHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get helpBackHome;

  /// No description provided for @requestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ma demande'**
  String get requestTitle;

  /// No description provided for @requestStatusSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée'**
  String get requestStatusSubmitted;

  /// No description provided for @requestStatusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente de contact'**
  String get requestStatusPending;

  /// No description provided for @requestStatusContacted.
  ///
  /// In fr, this message translates to:
  /// **'Contact pris'**
  String get requestStatusContacted;

  /// No description provided for @requestStatusClosed.
  ///
  /// In fr, this message translates to:
  /// **'Clôturée'**
  String get requestStatusClosed;

  /// No description provided for @requestStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get requestStatusCancelled;

  /// No description provided for @requestStatusDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get requestStatusDraft;

  /// No description provided for @requestShared.
  ///
  /// In fr, this message translates to:
  /// **'Informations partagées'**
  String get requestShared;

  /// No description provided for @requestCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la demande'**
  String get requestCancel;

  /// No description provided for @requestCancelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler cette demande ?'**
  String get requestCancelTitle;

  /// No description provided for @requestCancelBody.
  ///
  /// In fr, this message translates to:
  /// **'Elle ne sera plus transmise à un professionnel.'**
  String get requestCancelBody;

  /// No description provided for @requestCancelConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la demande'**
  String get requestCancelConfirm;

  /// No description provided for @requestKeep.
  ///
  /// In fr, this message translates to:
  /// **'Conserver'**
  String get requestKeep;

  /// No description provided for @requestCancelFail.
  ///
  /// In fr, this message translates to:
  /// **'La demande n\'a pas pu être annulée. Réessayez.'**
  String get requestCancelFail;

  /// No description provided for @requestMedia.
  ///
  /// In fr, this message translates to:
  /// **'Médias joints'**
  String get requestMedia;

  /// No description provided for @requestSentOn.
  ///
  /// In fr, this message translates to:
  /// **'Envoyée le'**
  String get requestSentOn;

  /// No description provided for @requestHonest.
  ///
  /// In fr, this message translates to:
  /// **'Nalvium n\'a pas encore transmis votre demande à un professionnel : elle est enregistrée avec les informations que vous avez choisies.'**
  String get requestHonest;

  /// No description provided for @requestMediaCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} élément(s)'**
  String requestMediaCount(int count);

  /// No description provided for @helpManualPages.
  ///
  /// In fr, this message translates to:
  /// **'pages {pages}'**
  String helpManualPages(String pages);

  /// No description provided for @helpIntroDirect.
  ///
  /// In fr, this message translates to:
  /// **'Dites-nous simplement ce qui se passe : quelques informations suffisent. Pas besoin de faire d\'abord un diagnostic.'**
  String get helpIntroDirect;

  /// No description provided for @helpSectionNoticed.
  ///
  /// In fr, this message translates to:
  /// **'Ce que Nalvium a constaté'**
  String get helpSectionNoticed;

  /// No description provided for @oozTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nalvium arrive bientôt dans votre secteur'**
  String get oozTitle;

  /// No description provided for @oozContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Nalvium'**
  String get oozContinue;

  /// No description provided for @oozBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get oozBack;

  /// No description provided for @oozSafety.
  ///
  /// In fr, this message translates to:
  /// **'Nalvium ne peut actuellement pas organiser d\'intervention dans votre secteur.'**
  String get oozSafety;

  /// No description provided for @helpErrCityPostal.
  ///
  /// In fr, this message translates to:
  /// **'Cette ville et ce code postal ne correspondent pas.'**
  String get helpErrCityPostal;

  /// No description provided for @helpErrCityUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Nous ne trouvons pas cette ville. Vérifiez son orthographe.'**
  String get helpErrCityUnknown;

  /// No description provided for @helpErrPostalUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Ce code postal est inconnu.'**
  String get helpErrPostalUnknown;

  /// No description provided for @helpAreaNote.
  ///
  /// In fr, this message translates to:
  /// **'Service actuellement disponible à {name} et dans un rayon de {km} km.'**
  String helpAreaNote(String name, int km);

  /// No description provided for @oozBody.
  ///
  /// In fr, this message translates to:
  /// **'Les interventions sont actuellement disponibles à {name} et dans un rayon de {km} km. Vous pouvez continuer à utiliser gratuitement le diagnostic Nalvium.'**
  String oozBody(String name, int km);

  /// No description provided for @stTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get stTitle;

  /// No description provided for @stSecData.
  ///
  /// In fr, this message translates to:
  /// **'Mes données'**
  String get stSecData;

  /// No description provided for @stSecPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get stSecPrivacy;

  /// No description provided for @stSecHelp.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get stSecHelp;

  /// No description provided for @stSecLegal.
  ///
  /// In fr, this message translates to:
  /// **'Légal'**
  String get stSecLegal;

  /// No description provided for @stSecApp.
  ///
  /// In fr, this message translates to:
  /// **'Application'**
  String get stSecApp;

  /// No description provided for @stHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des diagnostics'**
  String get stHistory;

  /// No description provided for @stHouse.
  ///
  /// In fr, this message translates to:
  /// **'Maison'**
  String get stHouse;

  /// No description provided for @stRequests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes d\'intervention'**
  String get stRequests;

  /// No description provided for @stDeleteData.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mes données'**
  String get stDeleteData;

  /// No description provided for @stPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get stPrivacy;

  /// No description provided for @stAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos et limites de Nalvium'**
  String get stAbout;

  /// No description provided for @stContact.
  ///
  /// In fr, this message translates to:
  /// **'Contacter Nalvium'**
  String get stContact;

  /// No description provided for @stPrivacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get stPrivacyPolicy;

  /// No description provided for @stTerms.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get stTerms;

  /// No description provided for @stLegalNotice.
  ///
  /// In fr, this message translates to:
  /// **'Mentions légales'**
  String get stLegalNotice;

  /// No description provided for @stAiInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations relatives à l\'IA'**
  String get stAiInfo;

  /// No description provided for @stVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get stVersion;

  /// No description provided for @stContactBody.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez-nous. Nous lisons chaque message, sans engagement de délai de réponse.'**
  String get stContactBody;

  /// No description provided for @stContactCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier l\'adresse'**
  String get stContactCopy;

  /// No description provided for @stContactCopied.
  ///
  /// In fr, this message translates to:
  /// **'Adresse copiée.'**
  String get stContactCopied;

  /// No description provided for @stDataTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes données'**
  String get stDataTitle;

  /// No description provided for @stDataBody.
  ///
  /// In fr, this message translates to:
  /// **'Nalvium fonctionne sans compte : vos données sont rattachées à un identifiant anonyme propre à ce téléphone. Elles comprennent vos diagnostics, vos photos et vidéos privées, votre Maison et vos demandes d\'intervention.'**
  String get stDataBody;

  /// No description provided for @stDataDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mes données'**
  String get stDataDelete;

  /// No description provided for @stDelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mes données ?'**
  String get stDelTitle;

  /// No description provided for @stDelIntro.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive. Elle supprimera de nos serveurs :'**
  String get stDelIntro;

  /// No description provided for @stDelItem1.
  ///
  /// In fr, this message translates to:
  /// **'vos diagnostics et leurs échanges ;'**
  String get stDelItem1;

  /// No description provided for @stDelItem2.
  ///
  /// In fr, this message translates to:
  /// **'vos photos et vidéos privées ;'**
  String get stDelItem2;

  /// No description provided for @stDelItem3.
  ///
  /// In fr, this message translates to:
  /// **'votre Maison, vos équipements et leurs notices ;'**
  String get stDelItem3;

  /// No description provided for @stDelItem4.
  ///
  /// In fr, this message translates to:
  /// **'vos demandes d\'intervention ;'**
  String get stDelItem4;

  /// No description provided for @stDelItem6.
  ///
  /// In fr, this message translates to:
  /// **'vos signalements.'**
  String get stDelItem6;

  /// No description provided for @stDelStays.
  ///
  /// In fr, this message translates to:
  /// **'Ne peut pas être rappelée : une demande déjà transmise à un opérateur ou partenaire à la suite d\'une demande d\'intervention. Vos publications seront supprimées, pas anonymisées.'**
  String get stDelStays;

  /// No description provided for @stDelAfter.
  ///
  /// In fr, this message translates to:
  /// **'Ensuite, Nalvium repart à zéro avec une nouvelle identité anonyme.'**
  String get stDelAfter;

  /// No description provided for @stDelCheck.
  ///
  /// In fr, this message translates to:
  /// **'Je comprends que mes données seront supprimées définitivement.'**
  String get stDelCheck;

  /// No description provided for @stDelConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get stDelConfirm;

  /// No description provided for @stDelWorking.
  ///
  /// In fr, this message translates to:
  /// **'Suppression en cours'**
  String get stDelWorking;

  /// No description provided for @stDelFail.
  ///
  /// In fr, this message translates to:
  /// **'La suppression n\'a pas pu être effectuée. Rien n\'a été modifié : réessayez.'**
  String get stDelFail;

  /// No description provided for @stDelDoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos données ont été supprimées'**
  String get stDelDoneTitle;

  /// No description provided for @stDelDoneBody.
  ///
  /// In fr, this message translates to:
  /// **'Nalvium repart à zéro avec une nouvelle identité anonyme.'**
  String get stDelDoneBody;

  /// No description provided for @stDelHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get stDelHome;

  /// No description provided for @stDataRow.
  ///
  /// In fr, this message translates to:
  /// **'Consulter et supprimer mes données'**
  String get stDataRow;

  /// No description provided for @preparingNext.
  ///
  /// In fr, this message translates to:
  /// **'Je prépare la suite…'**
  String get preparingNext;

  /// No description provided for @historyRepairTitle.
  ///
  /// In fr, this message translates to:
  /// **'Besoin d\'un artisan ?'**
  String get historyRepairTitle;

  /// No description provided for @historyRepairBody.
  ///
  /// In fr, this message translates to:
  /// **'Vos demandes d\'intervention et l\'aide d\'un professionnel.'**
  String get historyRepairBody;

  /// No description provided for @historySessions.
  ///
  /// In fr, this message translates to:
  /// **'Vos diagnostics'**
  String get historySessions;

  /// No description provided for @errDailyLimitTitle.
  ///
  /// In fr, this message translates to:
  /// **'Beaucoup de diagnostics aujourd\'hui'**
  String get errDailyLimitTitle;

  /// No description provided for @errDailyLimitBody.
  ///
  /// In fr, this message translates to:
  /// **'Pour que Nalvium reste gratuit, le nombre de nouveaux diagnostics est limité par jour. Revenez demain : vos diagnostics en cours restent accessibles.'**
  String get errDailyLimitBody;

  /// No description provided for @estTitle.
  ///
  /// In fr, this message translates to:
  /// **'Estimation'**
  String get estTitle;

  /// No description provided for @estFeasible.
  ///
  /// In fr, this message translates to:
  /// **'Faisable'**
  String get estFeasible;

  /// No description provided for @estDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get estDuration;

  /// No description provided for @estLevel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get estLevel;

  /// No description provided for @estEasy.
  ///
  /// In fr, this message translates to:
  /// **'Facile'**
  String get estEasy;

  /// No description provided for @estMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get estMedium;

  /// No description provided for @estHard.
  ///
  /// In fr, this message translates to:
  /// **'Difficile'**
  String get estHard;

  /// No description provided for @estYourself.
  ///
  /// In fr, this message translates to:
  /// **'Vous-même'**
  String get estYourself;

  /// No description provided for @estPro.
  ///
  /// In fr, this message translates to:
  /// **'Artisan'**
  String get estPro;

  /// No description provided for @estDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Estimation indicative, prix moyens en France. Ce n\'est pas un devis.'**
  String get estDisclaimer;

  /// No description provided for @estParts.
  ///
  /// In fr, this message translates to:
  /// **'À acheter'**
  String get estParts;

  /// No description provided for @estNotDiy.
  ///
  /// In fr, this message translates to:
  /// **'À confier à un professionnel'**
  String get estNotDiy;

  /// No description provided for @estSavedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez économisé environ {amount}'**
  String estSavedTitle(String amount);

  /// No description provided for @reportResult.
  ///
  /// In fr, this message translates to:
  /// **'Signaler ce résultat'**
  String get reportResult;

  /// No description provided for @reportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce qui ne va pas ?'**
  String get reportTitle;

  /// No description provided for @reportWrong.
  ///
  /// In fr, this message translates to:
  /// **'La réponse est fausse'**
  String get reportWrong;

  /// No description provided for @reportDangerous.
  ///
  /// In fr, this message translates to:
  /// **'Le conseil me semble dangereux'**
  String get reportDangerous;

  /// No description provided for @reportOffensive.
  ///
  /// In fr, this message translates to:
  /// **'Contenu choquant ou inapproprié'**
  String get reportOffensive;

  /// No description provided for @reportOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre chose'**
  String get reportOther;

  /// No description provided for @reportDetailsHint.
  ///
  /// In fr, this message translates to:
  /// **'Précisez si vous le souhaitez (facultatif)'**
  String get reportDetailsHint;

  /// No description provided for @reportSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le signalement'**
  String get reportSend;

  /// No description provided for @reportThanks.
  ///
  /// In fr, this message translates to:
  /// **'Merci, votre signalement a été envoyé. Il nous aide à améliorer Nalvium.'**
  String get reportThanks;

  /// No description provided for @reportFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le signalement n\'a pas pu être envoyé. Vous pouvez aussi écrire à contact@nalvium.com.'**
  String get reportFailed;

  /// No description provided for @obWelcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre assistant maison'**
  String get obWelcomeTitle;

  /// No description provided for @obWelcomeBody.
  ///
  /// In fr, this message translates to:
  /// **'Montrez un problème, Nalvium vous guide pas à pas. Et il garde en mémoire ce qui compte chez vous.'**
  String get obWelcomeBody;

  /// No description provided for @obWelcomeBullet1.
  ///
  /// In fr, this message translates to:
  /// **'Un diagnostic en photo, en vidéo ou en quelques mots'**
  String get obWelcomeBullet1;

  /// No description provided for @obWelcomeBullet2.
  ///
  /// In fr, this message translates to:
  /// **'Ce que ça coûte vous-même, et chez un artisan'**
  String get obWelcomeBullet2;

  /// No description provided for @obWelcomeBullet3.
  ///
  /// In fr, this message translates to:
  /// **'Vos points vitaux et vos entretiens, au même endroit'**
  String get obWelcomeBullet3;

  /// No description provided for @obStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get obStart;

  /// No description provided for @obSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get obSkip;

  /// No description provided for @obContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get obContinue;

  /// No description provided for @obLater.
  ///
  /// In fr, this message translates to:
  /// **'Je ne sais pas, plus tard'**
  String get obLater;

  /// No description provided for @consentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avant votre premier diagnostic'**
  String get consentTitle;

  /// No description provided for @consentIntro.
  ///
  /// In fr, this message translates to:
  /// **'Pour analyser votre problème, Nalvium envoie à un fournisseur d\'intelligence artificielle, OpenAI :'**
  String get consentIntro;

  /// No description provided for @consentItem1.
  ///
  /// In fr, this message translates to:
  /// **'votre description et vos réponses ;'**
  String get consentItem1;

  /// No description provided for @consentItem2.
  ///
  /// In fr, this message translates to:
  /// **'les photos, ou quelques images extraites de vos vidéos ;'**
  String get consentItem2;

  /// No description provided for @consentItem3.
  ///
  /// In fr, this message translates to:
  /// **'l\'équipement concerné (marque, référence), si vous l\'avez indiqué.'**
  String get consentItem3;

  /// No description provided for @consentNoIdentity.
  ///
  /// In fr, this message translates to:
  /// **'Ni votre nom, ni votre numéro, ni votre position ne sont envoyés. Nous demandons à OpenAI de ne pas conserver la conversation.'**
  String get consentNoIdentity;

  /// No description provided for @consentLimits.
  ///
  /// In fr, this message translates to:
  /// **'Nalvium peut se tromper et ne remplace pas un professionnel. En cas de danger, appelez le 18 ou le 112.'**
  String get consentLimits;

  /// No description provided for @consentAccept.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte et je continue'**
  String get consentAccept;

  /// No description provided for @consentDecline.
  ///
  /// In fr, this message translates to:
  /// **'Pas maintenant'**
  String get consentDecline;

  /// No description provided for @consentPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Lire la politique de confidentialité'**
  String get consentPrivacy;

  /// No description provided for @consentRequiredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre accord est nécessaire'**
  String get consentRequiredTitle;

  /// No description provided for @consentRequiredBody.
  ///
  /// In fr, this message translates to:
  /// **'Sans votre accord, Nalvium ne peut pas analyser de photo ni de description. Vous pouvez toujours utiliser Ma maison.'**
  String get consentRequiredBody;

  /// No description provided for @obHousingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous vivez dans…'**
  String get obHousingTitle;

  /// No description provided for @obHousingApartment.
  ///
  /// In fr, this message translates to:
  /// **'Un appartement'**
  String get obHousingApartment;

  /// No description provided for @obHousingHouse.
  ///
  /// In fr, this message translates to:
  /// **'Une maison'**
  String get obHousingHouse;

  /// No description provided for @obTenureTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes…'**
  String get obTenureTitle;

  /// No description provided for @obTenureTenant.
  ///
  /// In fr, this message translates to:
  /// **'Locataire'**
  String get obTenureTenant;

  /// No description provided for @obTenureOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get obTenureOwner;

  /// No description provided for @obHeatingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre chauffage'**
  String get obHeatingTitle;

  /// No description provided for @obHeatingGas.
  ///
  /// In fr, this message translates to:
  /// **'Gaz'**
  String get obHeatingGas;

  /// No description provided for @obHeatingElectric.
  ///
  /// In fr, this message translates to:
  /// **'Électrique'**
  String get obHeatingElectric;

  /// No description provided for @obHeatingHeatPump.
  ///
  /// In fr, this message translates to:
  /// **'Pompe à chaleur'**
  String get obHeatingHeatPump;

  /// No description provided for @obHeatingOilWood.
  ///
  /// In fr, this message translates to:
  /// **'Fioul ou bois'**
  String get obHeatingOilWood;

  /// No description provided for @obUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Je ne sais pas'**
  String get obUnknown;

  /// No description provided for @obHotWaterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre eau chaude vient…'**
  String get obHotWaterTitle;

  /// No description provided for @obHotWaterBoiler.
  ///
  /// In fr, this message translates to:
  /// **'D\'une chaudière'**
  String get obHotWaterBoiler;

  /// No description provided for @obHotWaterTank.
  ///
  /// In fr, this message translates to:
  /// **'D\'un ballon électrique'**
  String get obHotWaterTank;

  /// No description provided for @obDiyTitle.
  ///
  /// In fr, this message translates to:
  /// **'En bricolage, vous êtes…'**
  String get obDiyTitle;

  /// No description provided for @obDiyBeginner.
  ///
  /// In fr, this message translates to:
  /// **'Débutant'**
  String get obDiyBeginner;

  /// No description provided for @obDiyHandy.
  ///
  /// In fr, this message translates to:
  /// **'Je me débrouille'**
  String get obDiyHandy;

  /// No description provided for @obDiyConfident.
  ///
  /// In fr, this message translates to:
  /// **'À l\'aise'**
  String get obDiyConfident;

  /// No description provided for @obProfileHint.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif. Cela aide Nalvium à vous proposer les bons entretiens.'**
  String get obProfileHint;

  /// No description provided for @vitalsOptional.
  ///
  /// In fr, this message translates to:
  /// **'FACULTATIF'**
  String get vitalsOptional;

  /// No description provided for @vitalsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous savez où sont vos points vitaux ?'**
  String get vitalsTitle;

  /// No description provided for @vitalsBody.
  ///
  /// In fr, this message translates to:
  /// **'En cas d\'urgence, Nalvium vous les montre en une seconde. Pas de souci si vous ne savez pas : vous pourrez les ajouter plus tard dans Ma maison.'**
  String get vitalsBody;

  /// No description provided for @vitalWaterValve.
  ///
  /// In fr, this message translates to:
  /// **'Vanne d\'arrêt d\'eau'**
  String get vitalWaterValve;

  /// No description provided for @vitalElectricalPanel.
  ///
  /// In fr, this message translates to:
  /// **'Tableau électrique'**
  String get vitalElectricalPanel;

  /// No description provided for @vitalGasMeter.
  ///
  /// In fr, this message translates to:
  /// **'Compteur ou robinet de gaz'**
  String get vitalGasMeter;

  /// No description provided for @vitalTakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get vitalTakePhoto;

  /// No description provided for @vitalAdded.
  ///
  /// In fr, this message translates to:
  /// **'Photo ajoutée'**
  String get vitalAdded;

  /// No description provided for @vitalNoGas.
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai pas le gaz'**
  String get vitalNoGas;

  /// No description provided for @vitalAbsent.
  ///
  /// In fr, this message translates to:
  /// **'Pas de gaz chez moi'**
  String get vitalAbsent;

  /// No description provided for @vitalRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get vitalRemove;

  /// No description provided for @obReadyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre carnet maison est prêt'**
  String get obReadyTitle;

  /// No description provided for @obReadyBody.
  ///
  /// In fr, this message translates to:
  /// **'Vos entretiens à venir et vos points vitaux sont rangés dans Ma maison. Quand un problème arrive, appuyez sur le bouton noir.'**
  String get obReadyBody;

  /// No description provided for @obReadyGo.
  ///
  /// In fr, this message translates to:
  /// **'C\'est parti'**
  String get obReadyGo;

  /// No description provided for @dashFollowUp.
  ///
  /// In fr, this message translates to:
  /// **'Suivi de votre maison'**
  String get dashFollowUp;

  /// No description provided for @dashFollowUpGood.
  ///
  /// In fr, this message translates to:
  /// **'Bien suivie'**
  String get dashFollowUpGood;

  /// No description provided for @dashFollowUpMid.
  ///
  /// In fr, this message translates to:
  /// **'En bonne voie'**
  String get dashFollowUpMid;

  /// No description provided for @dashFollowUpLow.
  ///
  /// In fr, this message translates to:
  /// **'À compléter'**
  String get dashFollowUpLow;

  /// No description provided for @dashTasksDue.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Tous vos entretiens sont à jour} =1{1 entretien à prévoir} other{{count} entretiens à prévoir}}'**
  String dashTasksDue(int count);

  /// No description provided for @dashAddVitals.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos points vitaux dans Ma maison'**
  String get dashAddVitals;

  /// No description provided for @dashSaved.
  ///
  /// In fr, this message translates to:
  /// **'Économisé avec Nalvium'**
  String get dashSaved;

  /// No description provided for @dashSavedRepairs.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 réparation faite vous-même} other{{count} réparations faites vous-même}}'**
  String dashSavedRepairs(int count);

  /// No description provided for @dashSavedEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Vos économies s\'afficheront ici après votre première réparation.'**
  String get dashSavedEmpty;

  /// No description provided for @dashNextTask.
  ///
  /// In fr, this message translates to:
  /// **'Prochain entretien'**
  String get dashNextTask;

  /// No description provided for @dashInDays.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aujourd\'hui} =1{Demain} other{Dans {count} jours}}'**
  String dashInDays(int count);

  /// No description provided for @dashOverdue.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get dashOverdue;

  /// No description provided for @dashToPlan.
  ///
  /// In fr, this message translates to:
  /// **'À planifier'**
  String get dashToPlan;

  /// No description provided for @emergency.
  ///
  /// In fr, this message translates to:
  /// **'Urgence'**
  String get emergency;

  /// No description provided for @emergencyHint.
  ///
  /// In fr, this message translates to:
  /// **'Fuite, odeur de gaz, plus de courant'**
  String get emergencyHint;

  /// No description provided for @emTitle.
  ///
  /// In fr, this message translates to:
  /// **'Que se passe-t-il ?'**
  String get emTitle;

  /// No description provided for @emIntro.
  ///
  /// In fr, this message translates to:
  /// **'En cas de danger immédiat (feu, fumée, personne blessée), sortez et appelez le 18 ou le 112.'**
  String get emIntro;

  /// No description provided for @emLeakTitle.
  ///
  /// In fr, this message translates to:
  /// **'Une fuite d\'eau'**
  String get emLeakTitle;

  /// No description provided for @emLeak1.
  ///
  /// In fr, this message translates to:
  /// **'Coupez l\'eau à la vanne d\'arrêt.'**
  String get emLeak1;

  /// No description provided for @emLeak2.
  ///
  /// In fr, this message translates to:
  /// **'Si l\'eau approche des prises ou des appareils, coupez le courant au tableau, sans marcher dans l\'eau.'**
  String get emLeak2;

  /// No description provided for @emLeak3.
  ///
  /// In fr, this message translates to:
  /// **'Épongez et protégez ce qui peut l\'être.'**
  String get emLeak3;

  /// No description provided for @emLeak4.
  ///
  /// In fr, this message translates to:
  /// **'Prenez des photos (assurance) et prévenez le voisin du dessous ou le syndic.'**
  String get emLeak4;

  /// No description provided for @emGasTitle.
  ///
  /// In fr, this message translates to:
  /// **'Une odeur de gaz'**
  String get emGasTitle;

  /// No description provided for @emGas1.
  ///
  /// In fr, this message translates to:
  /// **'N\'actionnez aucun interrupteur, aucun appareil, aucune flamme. Ne fumez pas.'**
  String get emGas1;

  /// No description provided for @emGas2.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez grand les fenêtres.'**
  String get emGas2;

  /// No description provided for @emGas3.
  ///
  /// In fr, this message translates to:
  /// **'Fermez le robinet de gaz si vous pouvez le faire sans risque.'**
  String get emGas3;

  /// No description provided for @emGas4.
  ///
  /// In fr, this message translates to:
  /// **'Sortez, puis appelez depuis l\'extérieur.'**
  String get emGas4;

  /// No description provided for @emGasCall.
  ///
  /// In fr, this message translates to:
  /// **'Urgence Sécurité Gaz · 0 800 47 33 33'**
  String get emGasCall;

  /// No description provided for @emGasCallHint.
  ///
  /// In fr, this message translates to:
  /// **'Numéro gratuit, 24 h/24 (GRDF)'**
  String get emGasCallHint;

  /// No description provided for @emPowerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Plus de courant'**
  String get emPowerTitle;

  /// No description provided for @emPower1.
  ///
  /// In fr, this message translates to:
  /// **'Regardez si vos voisins ont du courant : sinon, c\'est une panne du réseau (Enedis, numéro sur votre facture).'**
  String get emPower1;

  /// No description provided for @emPower2.
  ///
  /// In fr, this message translates to:
  /// **'Au tableau électrique, repérez le disjoncteur abaissé.'**
  String get emPower2;

  /// No description provided for @emPower3.
  ///
  /// In fr, this message translates to:
  /// **'Débranchez les appareils de la pièce concernée, puis remontez le disjoncteur.'**
  String get emPower3;

  /// No description provided for @emPower4.
  ///
  /// In fr, this message translates to:
  /// **'S\'il saute aussitôt, laissez-le coupé et faites appel à un électricien. Jamais les mains mouillées.'**
  String get emPower4;

  /// No description provided for @emYourValve.
  ///
  /// In fr, this message translates to:
  /// **'Votre vanne d\'arrêt'**
  String get emYourValve;

  /// No description provided for @emYourPanel.
  ///
  /// In fr, this message translates to:
  /// **'Votre tableau électrique'**
  String get emYourPanel;

  /// No description provided for @emYourGas.
  ///
  /// In fr, this message translates to:
  /// **'Votre robinet de gaz'**
  String get emYourGas;

  /// No description provided for @emNumbers.
  ///
  /// In fr, this message translates to:
  /// **'Numéros d\'urgence'**
  String get emNumbers;

  /// No description provided for @emCall18.
  ///
  /// In fr, this message translates to:
  /// **'Pompiers · 18'**
  String get emCall18;

  /// No description provided for @emCall15.
  ///
  /// In fr, this message translates to:
  /// **'SAMU · 15'**
  String get emCall15;

  /// No description provided for @emCall112.
  ///
  /// In fr, this message translates to:
  /// **'Urgence européenne · 112'**
  String get emCall112;

  /// No description provided for @emDiagnose.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostiquer avec Nalvium'**
  String get emDiagnose;

  /// No description provided for @houseVitals.
  ///
  /// In fr, this message translates to:
  /// **'Points vitaux'**
  String get houseVitals;

  /// No description provided for @houseVitalsHint.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif : utile en cas d\'urgence.'**
  String get houseVitalsHint;

  /// No description provided for @houseMaintenance.
  ///
  /// In fr, this message translates to:
  /// **'Entretiens'**
  String get houseMaintenance;

  /// No description provided for @houseMaintenanceHint.
  ///
  /// In fr, this message translates to:
  /// **'Des rappels pour garder votre maison en forme. Ce ne sont pas des contrôles.'**
  String get houseMaintenanceHint;

  /// No description provided for @houseEquipment.
  ///
  /// In fr, this message translates to:
  /// **'Vos équipements'**
  String get houseEquipment;

  /// No description provided for @houseProfile.
  ///
  /// In fr, this message translates to:
  /// **'Votre logement'**
  String get houseProfile;

  /// No description provided for @houseProfileEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get houseProfileEdit;

  /// No description provided for @mtDone.
  ///
  /// In fr, this message translates to:
  /// **'C\'est fait'**
  String get mtDone;

  /// No description provided for @mtDoneOn.
  ///
  /// In fr, this message translates to:
  /// **'Fait le {date}'**
  String mtDoneOn(String date);

  /// No description provided for @mtMandatory.
  ///
  /// In fr, this message translates to:
  /// **'Obligatoire chaque année'**
  String get mtMandatory;

  /// No description provided for @mtNext.
  ///
  /// In fr, this message translates to:
  /// **'Prochain : {date}'**
  String mtNext(String date);

  /// No description provided for @mtBoiler.
  ///
  /// In fr, this message translates to:
  /// **'Entretien de la chaudière'**
  String get mtBoiler;

  /// No description provided for @mtBoilerBody.
  ///
  /// In fr, this message translates to:
  /// **'Chaque année, par un professionnel qualifié.'**
  String get mtBoilerBody;

  /// No description provided for @mtRadiators.
  ///
  /// In fr, this message translates to:
  /// **'Purge des radiateurs'**
  String get mtRadiators;

  /// No description provided for @mtRadiatorsBody.
  ///
  /// In fr, this message translates to:
  /// **'Avant l\'hiver, pour qu\'ils chauffent de façon homogène.'**
  String get mtRadiatorsBody;

  /// No description provided for @mtHeatPump.
  ///
  /// In fr, this message translates to:
  /// **'Entretien de la pompe à chaleur'**
  String get mtHeatPump;

  /// No description provided for @mtHeatPumpBody.
  ///
  /// In fr, this message translates to:
  /// **'Vérification recommandée par un professionnel.'**
  String get mtHeatPumpBody;

  /// No description provided for @mtWaterHeater.
  ///
  /// In fr, this message translates to:
  /// **'Groupe de sécurité du chauffe-eau'**
  String get mtWaterHeater;

  /// No description provided for @mtWaterHeaterBody.
  ///
  /// In fr, this message translates to:
  /// **'À manœuvrer régulièrement pour éviter qu\'il ne s\'entartre.'**
  String get mtWaterHeaterBody;

  /// No description provided for @mtVmc.
  ///
  /// In fr, this message translates to:
  /// **'Bouches de ventilation (VMC)'**
  String get mtVmc;

  /// No description provided for @mtVmcBody.
  ///
  /// In fr, this message translates to:
  /// **'À nettoyer pour garder un air sain.'**
  String get mtVmcBody;

  /// No description provided for @mtSmokeAlarm.
  ///
  /// In fr, this message translates to:
  /// **'Détecteur de fumée'**
  String get mtSmokeAlarm;

  /// No description provided for @mtSmokeAlarmBody.
  ///
  /// In fr, this message translates to:
  /// **'Testez-le en appuyant sur son bouton.'**
  String get mtSmokeAlarmBody;

  /// No description provided for @mtMarked.
  ///
  /// In fr, this message translates to:
  /// **'Entretien noté. Nalvium vous le rappellera.'**
  String get mtMarked;
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
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
