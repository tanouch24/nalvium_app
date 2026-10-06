# Rétention et nettoyage (V1)

Valeurs par défaut dans `backend/app/config.py`, ajustables par variables `NALVIUM_RETENTION_*`. **À revoir après relecture juridique.**

| Donnée | Conservation | Pourquoi |
|---|---|---|
| Diagnostics, médias de diagnostic, Maison, équipements, notices | Tant que l'utilisateur ne supprime pas ses données | Historique utile à l'utilisateur |
| Demande d'intervention **brouillon** jamais envoyée | 14 jours (`RETENTION_DRAFT_REQUEST_DAYS`) | Laisser le temps de revenir |
| Demande d'intervention envoyée | Tant que l'utilisateur ne supprime pas ses données | Preuve du consentement et suivi |
| Photo temporaire non rattachée | 48 h (`RETENTION_TEMP_PHOTO_HOURS`) | Abandon probable |
| Copie publique d'un brouillon Communauté jamais publié | 24 h (`RETENTION_COMMUNITY_DRAFT_HOURS`) | Un brouillon se fait en minutes |
| Fichier du stockage sans référence en base | 48 h (`RETENTION_ORPHAN_FILE_HOURS`) | Reste d'un échec ; délai de sécurité |
| Publications / commentaires Communauté | Tant que l'utilisateur ne supprime pas ses données | Supprimés, jamais anonymisés |

## Job de nettoyage
`python -m app.maintenance.cleanup` (depuis `backend/`). Idempotent, borné (`CLEANUP_BATCH_LIMIT` éléments par catégorie et par exécution), ne touche jamais aux diagnostics, aux médias référencés ni aux demandes envoyées. Journaux : compteurs uniquement, aucune donnée personnelle.
**Non planifié automatiquement** : à brancher sur un cron / planificateur du serveur de production (ex. 1 fois par jour). ACTION MANUELLE.

## Suppression par l'utilisateur
`DELETE /v1/me` (Réglages › Mes données › Supprimer mes données) supprime tout ce qui est rattaché à l'identité anonyme, fichiers compris. Limite : un message Telegram déjà envoyé à l'exploitant ne peut pas être rappelé.

## Export
`GET /v1/me/export` (JSON, `export_version` 1) existe côté backend. Pas d'écran dans l'app en V1 : demande par e-mail à contact@nalvium.com (traitement manuel).
