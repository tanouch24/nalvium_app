# Checklist V1 — Nalvium (état au 2026-10-06, non commité)

Légende : **DONE** vérifié · **MANUAL** action humaine requise · **BLOCKED** bloquant avant Play Store · **N/A**

## CODE
- DONE `flutter analyze` sans alerte ; tests Flutter et backend verts (voir rapport final pour les nombres) ; `ruff` propre.
- DONE builds debug et release.
- MANUAL dépendance `cupertino_icons` non importée (héritée du modèle Flutter) : suppression possible, non faite par prudence.

## SECURITY
- DONE clé OpenAI uniquement backend ; aucun secret dans l'APK release (scan `libapp.so` + dex : pas de clé, pas de Telegram, pas d'URL locale).
- DONE en-têtes `nosniff`, `no-referrer` ; pas de CORS ; docs OpenAPI coupées en production ; erreurs génériques (`internal_error`), jamais de trace.
- DONE limitation de débit (en mémoire, par identité anonyme).
- MANUAL limitation de débit non partagée entre processus : suffisant pour un seul worker ; à renforcer (proxy / Redis) si plusieurs.
- MANUAL HTTPS et pare-feu du serveur de production.

## PRIVACY
- DONE suppression complète (`DELETE /v1/me`) testée en A/B, fichiers inclus, nouvelle identité ensuite ; validée sur Samsung avec données de test.
- DONE export JSON backend (`GET /v1/me/export`). Pas d'écran d'export dans l'app (V1 : demande par e-mail).
- DONE journaux sans donnée personnelle (backend ; Flutter : seulement des codes, `debugPrint` ne contient ni texte ni identifiant).

## LEGAL
- DONE écrans : confidentialité, conditions, mentions légales, à propos/limites, informations IA — centralisés et versionnés (`legal_texts.dart`).
- BLOCKED textes **provisoires, non relus par un juriste** ; champs `[À COMPLÉTER AVANT PUBLICATION]` (éditeur, hébergeur, juridiction).
- BLOCKED URL publique de la politique de confidentialité (exigée par Google Play).

## ADS
- DONE IDs test en debug, IDs Nalvium en release (vérifié dans l'APK). UMP : option « Choix publicitaires » dans Réglages (visible seulement si requise).
- DONE aucune publicité sur capture/analyse/sécurité/suppression.
- MANUAL affichage réel d'annonces et du formulaire UMP NON validés (le Samsung de test bloque le réseau publicitaire ; zone UE à tester).
- MANUAL app-ads.txt / compte AdMob : à vérifier côté AdMob.

## AI
- DONE appels serveur, sortie structurée, `store=False`, Safety avant/après l'IA. Information utilisateur dans l'app.

## MEDIA
- DONE EXIF/GPS supprimés, copies publiques dérivées, médias privés par défaut, nettoyage des orphelins.

## DATABASE
- DONE migrations 0001→0008 sur base vierge (+ aller/retour 0008→0007→0008) et base existante à jour.
- MANUAL sauvegarde/restauration PostgreSQL de production à mettre en place et tester.

## CLEANUP
- DONE job `python -m app.maintenance.cleanup` testé. MANUAL planification en production (docs/RETENTION.md).

## COMMUNITY
- DONE publication, commentaires, Utile, enregistrés, signalements ; supprimés avec les données.
- MANUAL modération : aucun outil d'administration (suppression à la main en base).

## SERVICE REQUESTS
- DONE zone pilote Lyon + 50 km, consentement explicite, médias choisis seulement.

## TELEGRAM
- DONE abstraction + idempotence. État : NOT_CONFIGURED. MANUAL procédure : docs/TELEGRAM_SETUP.md (aucun bot créé, aucun message réel).

## ANALYTICS
- DONE abstraction sans SDK, sink NoOp par défaut, liste blanche de propriétés (aucune donnée personnelle), testée.

## ANDROID
- DONE package `com.nalvium.nalvium`, version 1.0.0+1, minSdk 24, targetSdk 36, permissions justifiées (docs/PLAY_STORE_RELEASE.md).
- BLOCKED aucune clé de signature de production : le release local est signé en debug (la configuration `key.properties` est prête, aucune clé créée).
- MANUAL `READ_EXTERNAL_STORAGE` vient d'une dépendance : à examiner pour la déclaration Play.

## PLAY STORE
- BLOCKED fiche, visuels, sécurité des données, classification, politique en ligne (docs/PLAY_STORE_RELEASE.md).
- MANUAL URL backend de production et build `appbundle`.

## REAL DEVICE (Samsung, données de test)
- DONE Réglages, Mes données, Confidentialité, Choix publicitaires, À propos, Contact, suppression (case obligatoire, suppression de 22 fichiers de test, retour accueil vide). Captures : `validation/phase7/` (non versionné).
- NOT DONE réseau publicitaire, UMP réel, parcours diagnostic IA complet dans cette phase.

## BACKUP / ROLLBACK
- MANUAL sauvegarde base + `var/media` avant déploiement ; `alembic downgrade` testé 0008→0007.
