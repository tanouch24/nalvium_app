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
  /// **'Maison'**
  String get navHouse;

  /// No description provided for @navRepair.
  ///
  /// In fr, this message translates to:
  /// **'Dépannage'**
  String get navRepair;

  /// No description provided for @navCommunity.
  ///
  /// In fr, this message translates to:
  /// **'Communauté'**
  String get navCommunity;

  /// No description provided for @navCamera.
  ///
  /// In fr, this message translates to:
  /// **'Caméra'**
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

  /// No description provided for @communityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Communauté'**
  String get communityTitle;

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
  /// **'Votre maison prendra forme ici'**
  String get houseEmptyTitle;

  /// No description provided for @houseEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Les équipements que vous ajoutez apparaîtront ici.'**
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
