# Notification Telegram interne : procédure (NON exécutée)

État : **NOT_CONFIGURED**. Aucun bot n'a été créé, aucun message réel n'a été envoyé. Sans configuration, l'envoi d'une demande réussit normalement et la notification est simplement marquée « non configurée ».

1. Dans Telegram, parler à @BotFather → `/newbot`, récupérer le token. **Ne jamais le commiter ni le coller dans un chat/ticket.**
2. Créer un groupe privé (ou utiliser une conversation privée), y ajouter le bot, envoyer un message, puis lire le `chat_id` via `getUpdates`.
3. Sur le serveur uniquement (fichier d'environnement non versionné) : `NALVIUM_TELEGRAM_BOT_TOKEN`, `NALVIUM_TELEGRAM_CHAT_ID`.
4. Redémarrer le backend. Faire UNE demande de test avec des données fictives et vérifier le message reçu.
5. Contenu transmis : uniquement ce que l'utilisateur a consenti (problème, prénom, téléphone, ville/CP, créneau). **Aucune photo**.
6. Rotation : si le token fuit, `/revoke` chez BotFather puis remplacer la valeur.
7. Les journaux backend ne contiennent jamais l'URL Telegram (loggers `httpx`/`httpcore` silencieux).
