# Publication Google Play : ce qui est prêt, ce qui manque

Aucune release n'a été créée, la Play Console n'a pas été touchée.

## Identité de l'app
- Package : `com.nalvium.nalvium` · version `1.0.0+1` (pubspec.yaml) · minSdk 24 · targetSdk 36 (valeurs Flutter) — à revérifier contre l'exigence de niveau d'API cible Google Play au moment de la soumission.
- AdMob release : App `ca-app-pub-9787163762873138~8283818658` ; Banner `…/7749641197`, Interstitiel `…/8092246961`, App Open `…/1479657021`. Debug = IDs de test Google (jamais d'ID de production en debug).

## Signature — BLOQUANT (ACTION MANUELLE)
Aucune clé de production n'existe. Sans `android/key.properties`, le build release est signé avec la clé **debug** (refusée par le Play Store).
1. `keytool -genkey -v -keystore ~/nalvium-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload` (garder le fichier et les mots de passe hors du dépôt, sauvegardés).
2. Créer `app/android/key.properties` (ignoré par git) : `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.
3. `flutter build appbundle --release --dart-define=NALVIUM_API_URL=https://<URL de production>` (HTTPS obligatoire, sinon le build refuse de démarrer).
4. Activer Play App Signing dans la Play Console.

## Backend de production — BLOQUANT
URL HTTPS définitive, base PostgreSQL, `NALVIUM_ENV=production`, clé OpenAI serveur, sauvegardes, tâche planifiée de nettoyage (docs/RETENTION.md), Telegram optionnel (docs/TELEGRAM_SETUP.md).

## Permissions déclarées (APK release)
`INTERNET`, `AD_ID` (AdMob), `CAMERA` + `RECORD_AUDIO` (demandées seulement au moment de filmer), `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `FOREGROUND_SERVICE` (bibliothèques Google/caméra), `READ/WRITE_EXTERNAL_STORAGE` (héritées d'une dépendance, WRITE limité à SDK ≤ 28) — à examiner pour la déclaration Play.

## Formulaires Play Console (à remplir à la main)
- **Sécurité des données** : données collectées = description/photos/vidéos de diagnostic, ville/CP/nom/téléphone (demande d'intervention, facultatif), identifiant d'installation anonyme, publications Communauté, identifiant publicitaire (AdMob). Partage : fournisseur d'IA (OpenAI), Google (publicité). Chiffrement en transit : oui (HTTPS). Suppression : oui, dans l'app (Réglages › Mes données) + e-mail.
- **Politique de confidentialité** : URL publique requise → **BLOQUANT** : les textes sont dans l'app (provisoires, non relus par un juriste) ; il faut les publier sur une page web.
- **Publicité** : l'app contient des annonces. Classification de contenu, public cible (pas un public enfant), déclaration de l'ID publicitaire : oui.
- **Contact** : contact@nalvium.com (aucun téléphone).
- Visuels du store (icône 512, bannière 1024×500, captures) : à produire.
