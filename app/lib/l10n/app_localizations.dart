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

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoon;

  /// No description provided for @houseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ma maison'**
  String get houseTitle;

  /// No description provided for @houseEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre maison est vide pour l\'instant'**
  String get houseEmptyTitle;

  /// No description provided for @houseEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Vos équipements et vos interventions apparaîtront ici.'**
  String get houseEmptyBody;

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

  /// No description provided for @repairEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Si un problème demande un professionnel, vous pourrez le demander ici.'**
  String get repairEmptyBody;

  /// No description provided for @communityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Communauté'**
  String get communityTitle;

  /// No description provided for @communityEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'La communauté arrive bientôt'**
  String get communityEmptyTitle;

  /// No description provided for @communityEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez y voir des problèmes réellement résolus par d\'autres personnes.'**
  String get communityEmptyBody;

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

  /// No description provided for @previewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre photo'**
  String get previewTitle;

  /// No description provided for @previewQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Est-ce que le problème est bien visible ?'**
  String get previewQuestion;

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

  /// No description provided for @analyzingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Je regarde ce qui pourrait provoquer ça.'**
  String get analyzingSubtitle;

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

  /// No description provided for @youWillNeed.
  ///
  /// In fr, this message translates to:
  /// **'Vous aurez besoin de : {items}'**
  String youWillNeed(String items);

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

  /// No description provided for @safetyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Arrêtez-vous ici'**
  String get safetyTitle;

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

  /// No description provided for @stateAwaiting.
  ///
  /// In fr, this message translates to:
  /// **'L\'analyse est à relancer'**
  String get stateAwaiting;

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

  /// No description provided for @statusReferred.
  ///
  /// In fr, this message translates to:
  /// **'Professionnel conseillé'**
  String get statusReferred;

  /// No description provided for @statusActive.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get statusActive;

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
