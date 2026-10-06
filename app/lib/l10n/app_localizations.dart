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

  /// No description provided for @cmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Communauté'**
  String get cmTitle;

  /// No description provided for @cmIntro.
  ///
  /// In fr, this message translates to:
  /// **'Les solutions partagées par la communauté Nalvium.'**
  String get cmIntro;

  /// No description provided for @cmShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager une solution'**
  String get cmShare;

  /// No description provided for @cmSaved.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrés'**
  String get cmSaved;

  /// No description provided for @cmEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les premières solutions arriveront bientôt.'**
  String get cmEmptyTitle;

  /// No description provided for @cmEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez réglé un problème chez vous ? Votre expérience peut aider quelqu\'un d\'autre.'**
  String get cmEmptyBody;

  /// No description provided for @cmSavedEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez encore enregistré aucune solution.'**
  String get cmSavedEmpty;

  /// No description provided for @cmLoadFail.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la Communauté'**
  String get cmLoadFail;

  /// No description provided for @cmLoadMore.
  ///
  /// In fr, this message translates to:
  /// **'Voir plus'**
  String get cmLoadMore;

  /// No description provided for @cmEnd.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez tout vu.'**
  String get cmEnd;

  /// No description provided for @cmHelpful.
  ///
  /// In fr, this message translates to:
  /// **'Utile'**
  String get cmHelpful;

  /// No description provided for @cmComment.
  ///
  /// In fr, this message translates to:
  /// **'Commenter'**
  String get cmComment;

  /// No description provided for @cmSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get cmSave;

  /// No description provided for @cmUnsave.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des enregistrés'**
  String get cmUnsave;

  /// No description provided for @cmMember.
  ///
  /// In fr, this message translates to:
  /// **'Membre Nalvium'**
  String get cmMember;

  /// No description provided for @cmNotOfficial.
  ///
  /// In fr, this message translates to:
  /// **'Solution partagée par un membre de la communauté.'**
  String get cmNotOfficial;

  /// No description provided for @cmMaterials.
  ///
  /// In fr, this message translates to:
  /// **'Matériel'**
  String get cmMaterials;

  /// No description provided for @cmComments.
  ///
  /// In fr, this message translates to:
  /// **'Commentaires'**
  String get cmComments;

  /// No description provided for @cmNoComments.
  ///
  /// In fr, this message translates to:
  /// **'Aucun commentaire pour le moment.'**
  String get cmNoComments;

  /// No description provided for @cmCommentHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un commentaire'**
  String get cmCommentHint;

  /// No description provided for @cmCommentSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get cmCommentSend;

  /// No description provided for @cmCommentDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon commentaire'**
  String get cmCommentDelete;

  /// No description provided for @cmCommentFail.
  ///
  /// In fr, this message translates to:
  /// **'Le commentaire n\'a pas pu être envoyé. Réessayez.'**
  String get cmCommentFail;

  /// No description provided for @cmCommentTooLong.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire trop long (500 caractères maximum).'**
  String get cmCommentTooLong;

  /// No description provided for @cmCommentUnsafe.
  ///
  /// In fr, this message translates to:
  /// **'Ce commentaire ne peut pas être publié : il touche à un sujet dangereux.'**
  String get cmCommentUnsafe;

  /// No description provided for @cmActionFail.
  ///
  /// In fr, this message translates to:
  /// **'L\'action n\'a pas pu être enregistrée. Réessayez.'**
  String get cmActionFail;

  /// No description provided for @cmReport.
  ///
  /// In fr, this message translates to:
  /// **'Signaler'**
  String get cmReport;

  /// No description provided for @cmReportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi signalez-vous ceci ?'**
  String get cmReportTitle;

  /// No description provided for @cmReasonDangerous.
  ///
  /// In fr, this message translates to:
  /// **'Contenu dangereux'**
  String get cmReasonDangerous;

  /// No description provided for @cmReasonSpam.
  ///
  /// In fr, this message translates to:
  /// **'Spam / publicité'**
  String get cmReasonSpam;

  /// No description provided for @cmReasonInappropriate.
  ///
  /// In fr, this message translates to:
  /// **'Contenu inapproprié'**
  String get cmReasonInappropriate;

  /// No description provided for @cmReasonPersonal.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get cmReasonPersonal;

  /// No description provided for @cmReasonOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get cmReasonOther;

  /// No description provided for @cmReported.
  ///
  /// In fr, this message translates to:
  /// **'Merci. Votre signalement a été enregistré.'**
  String get cmReported;

  /// No description provided for @cmReportedAlready.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà signalé ceci. Merci.'**
  String get cmReportedAlready;

  /// No description provided for @cmEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get cmEdit;

  /// No description provided for @cmDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get cmDelete;

  /// No description provided for @cmDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette publication ?'**
  String get cmDeleteTitle;

  /// No description provided for @cmDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Elle disparaîtra de la Communauté. Cette action est définitive.'**
  String get cmDeleteBody;

  /// No description provided for @cmDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la publication'**
  String get cmDeleteConfirm;

  /// No description provided for @cmDeleteFail.
  ///
  /// In fr, this message translates to:
  /// **'La publication n\'a pas pu être supprimée. Réessayez.'**
  String get cmDeleteFail;

  /// No description provided for @cmGone.
  ///
  /// In fr, this message translates to:
  /// **'Cette publication n\'existe plus.'**
  String get cmGone;

  /// No description provided for @cmBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get cmBack;

  /// No description provided for @cmNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partager une solution'**
  String get cmNewTitle;

  /// No description provided for @cmEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier ma publication'**
  String get cmEditTitle;

  /// No description provided for @cmFieldTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get cmFieldTitle;

  /// No description provided for @cmFieldTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Mon lave-vaisselle ne vidangeait plus'**
  String get cmFieldTitleHint;

  /// No description provided for @cmFieldSolution.
  ///
  /// In fr, this message translates to:
  /// **'Solution'**
  String get cmFieldSolution;

  /// No description provided for @cmFieldSolutionHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. J\'ai nettoyé le filtre et retiré un morceau de verre qui bloquait la pompe.'**
  String get cmFieldSolutionHint;

  /// No description provided for @cmFieldCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get cmFieldCategory;

  /// No description provided for @cmFieldMaterials.
  ///
  /// In fr, this message translates to:
  /// **'Matériel utilisé (facultatif)'**
  String get cmFieldMaterials;

  /// No description provided for @cmFieldMaterialsHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Tournevis cruciforme, chiffon'**
  String get cmFieldMaterialsHint;

  /// No description provided for @cmCatPlumbing.
  ///
  /// In fr, this message translates to:
  /// **'Plomberie'**
  String get cmCatPlumbing;

  /// No description provided for @cmCatAppliance.
  ///
  /// In fr, this message translates to:
  /// **'Électroménager'**
  String get cmCatAppliance;

  /// No description provided for @cmCatHandyman.
  ///
  /// In fr, this message translates to:
  /// **'Bricolage'**
  String get cmCatHandyman;

  /// No description provided for @cmCatOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get cmCatOther;

  /// No description provided for @cmPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get cmPhoto;

  /// No description provided for @cmPhotoRecommended.
  ///
  /// In fr, this message translates to:
  /// **'Recommandée mais facultative.'**
  String get cmPhotoRecommended;

  /// No description provided for @cmPhotoTake.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get cmPhotoTake;

  /// No description provided for @cmPhotoFromDiagnostic.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser une photo de mon diagnostic'**
  String get cmPhotoFromDiagnostic;

  /// No description provided for @cmPhotoPublicNotice.
  ///
  /// In fr, this message translates to:
  /// **'Cette photo sera visible publiquement dans la Communauté Nalvium.'**
  String get cmPhotoPublicNotice;

  /// No description provided for @cmPhotoRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la photo'**
  String get cmPhotoRemove;

  /// No description provided for @cmPhotoConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rendre cette photo publique ?'**
  String get cmPhotoConfirmTitle;

  /// No description provided for @cmPhotoConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Une copie nettoyée de cette photo (sans localisation) sera visible publiquement dans la Communauté Nalvium. L\'original reste privé.'**
  String get cmPhotoConfirmBody;

  /// No description provided for @cmPhotoConfirmYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui, utiliser cette photo'**
  String get cmPhotoConfirmYes;

  /// No description provided for @cmPhotoFail.
  ///
  /// In fr, this message translates to:
  /// **'La photo n\'a pas pu être préparée. Réessayez.'**
  String get cmPhotoFail;

  /// No description provided for @cmReview.
  ///
  /// In fr, this message translates to:
  /// **'Relisez avant de publier : n\'ajoutez aucune information personnelle (nom, adresse, téléphone).'**
  String get cmReview;

  /// No description provided for @cmPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get cmPreview;

  /// No description provided for @cmPreviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Voici votre publication'**
  String get cmPreviewTitle;

  /// No description provided for @cmConsent.
  ///
  /// In fr, this message translates to:
  /// **'Je comprends que cette publication sera visible publiquement dans la Communauté Nalvium.'**
  String get cmConsent;

  /// No description provided for @cmPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get cmPublish;

  /// No description provided for @cmContinue.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'aperçu'**
  String get cmContinue;

  /// No description provided for @cmBackEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get cmBackEdit;

  /// No description provided for @cmErrTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez un titre (3 caractères minimum).'**
  String get cmErrTitle;

  /// No description provided for @cmErrSolution.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez la solution (10 caractères minimum).'**
  String get cmErrSolution;

  /// No description provided for @cmErrConsent.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez accepter pour publier.'**
  String get cmErrConsent;

  /// No description provided for @cmErrUnsafe.
  ///
  /// In fr, this message translates to:
  /// **'Cette solution touche à un sujet dangereux (gaz, électricité, produits chimiques…). Elle ne peut pas être publiée.'**
  String get cmErrUnsafe;

  /// No description provided for @cmErrPublish.
  ///
  /// In fr, this message translates to:
  /// **'La publication n\'a pas pu être envoyée. Votre texte est conservé : réessayez.'**
  String get cmErrPublish;

  /// No description provided for @cmPublished.
  ///
  /// In fr, this message translates to:
  /// **'Votre solution est publiée.'**
  String get cmPublished;

  /// No description provided for @cmShareSolution.
  ///
  /// In fr, this message translates to:
  /// **'Partager cette solution'**
  String get cmShareSolution;

  /// No description provided for @cmHelpfulCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} Utile'**
  String cmHelpfulCount(int count);

  /// No description provided for @cmCommentCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} commentaire(s)'**
  String cmCommentCount(int count);
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
