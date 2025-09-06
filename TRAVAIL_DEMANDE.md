🎯 Scénario d’utilisation pour le conducteur
1. Inscription / Connexion

Nouveau conducteur :

Il télécharge l’application.

Il choisit "Créer un compte".

Il saisit ses infos personnelles (CIN, permis, adresse, téléphone, email).

Il choisit sa compagnie + agence (ou il scanne un QR code donné par l’agent).

Son compte reste en "pending" jusqu’à validation par l’agent (qui rattache le contrat).

Conducteur existant (ancien assuré) :

L’agent crée son compte dans le back-office et lui envoie des identifiants (SMS/email).

Quand il se connecte, il voit directement son contrat et ses véhicules.

👉 Résultat : les deux types de conducteurs (nouveaux & anciens) accèdent à la même dashboard conducteur.

2. Dashboard conducteur

Le tableau de bord contient :

📄 Demande de contrat d’assurance (uniquement pour les nouveaux ou si l’ancien veut ajouter un nouveau véhicule).

🚘 Mes véhicules : liste des véhicules déjà assurés (importés via contrat validé par agent).

🔔 Mes sinistres : suivi des déclarations en cours.

👤 Mon profil : données personnelles modifiables (tel, adresse, etc.).

3. Déclaration d’un sinistre collaboratif

Conducteur A crée un nouveau constat → saisit la date, lieu, photos, etc.

L’application génère un code unique ou QR code.

Conducteur B (impliqué) :

S’il est déjà inscrit → il scanne / saisit le code et rejoint le constat collaboratif.

S’il n’est pas inscrit → il reçoit une invitation SMS/email avec lien → il s’inscrit rapidement (light signup) et rejoint directement le constat.

👉 Cela évite de bloquer le processus même si un conducteur n’a jamais utilisé l’application.

4. Validation du constat

Les deux conducteurs remplissent ensemble les champs obligatoires (photos, croquis, responsabilités).

Chacun signe digitalement (signature mobile).

Le constat est automatiquement envoyé à la compagnie d’assurance respective.

Les deux conducteurs reçoivent une copie (PDF ou consultable dans l’app).

5. Rôle des agents / compagnies

Agent d’assurance :

Crée les contrats dans le back-office.

Valide les demandes de contrats des nouveaux conducteurs.

Rattache les véhicules aux conducteurs.

Conducteur :

N’a pas besoin de recréer un contrat, il consulte seulement.

Peut faire une demande de contrat pour un nouveau véhicule (soumise à validation de l’agent).

✅ Remarques & améliorations

Ergonomie simple : pour adoption en Tunisie, il faut un processus fluide → exemple : inscription rapide possible via CIN + matricule voiture (l’agent complète après).

Multi-compagnies & agences : très bien que tu as déjà pensé au rôle super-admin, admin compagnie, admin agence, agent → ça garantit la scalabilité.

Notifications push/SMS :

Quand un constat est en cours.

Quand un contrat est validé.

Signature électronique légale : en Tunisie, vérifie si la loi autorise signature digitale ou il faut e-signature certifiée (via TunTrust par exemple).

Mode hors-ligne : beaucoup de zones sans connexion → permettre de remplir le constat offline et synchroniser quand internet revient.

Ajout futur :

📷 Scan automatique de la carte grise et permis (OCR).

📍 Géolocalisation automatique du lieu d’accident.

📑 Historique des constats (utile pour assurance).

🤝 Assistance routière (option payante : appeler dépanneuse directement via app).

👉 En résumé :

Nouveau conducteur → inscription + demande de contrat (agent valide).

Ancien conducteur → compte créé par agent, reçoit identifiants, retrouve ses véhicules et contrats.

Tous → même dashboard conducteur.

Constat collaboratif → invitation + inscription rapide si nécessaire.

==>1. Demande de contrat (côté conducteur)

Le conducteur (nouveau ou ancien) remplit une demande de contrat via son dashboard.

La demande contient :

Infos personnelles.

Infos sur véhicule.

Sélection compagnie et agence.

Une fois envoyée → elle arrive chez l’admin d’agence.

2. Rôle de l’admin d’agence

L’admin d’agence reçoit toutes les demandes de contrats en attente.

Il approuve ou rejette la demande.

Si approuvée → il doit affecter la demande à un agent.

👉 Équilibrage automatique :

Le système calcule le nombre de contrats déjà traités par chaque agent de l’agence.

L’admin peut choisir l’affectation manuelle ou laisser le système attribuer automatiquement à l’agent le moins chargé.

3. Rôle de l’agent

L’agent reçoit uniquement les contrats qui lui ont été affectés.

Il traite la demande (vérification documents, validation finale, création contrat).

Une fois validé → le véhicule et le contrat apparaissent dans le dashboard conducteur.

4. Tableau de suivi des performances

Pour suivre l’équilibre du travail :

Admin agence a un dashboard avec :

Nombre de demandes en attente.

Nombre de contrats créés par chaque agent.

Répartition (%) des contrats entre les agents.

Possibilité d’imposer une règle d’équilibrage automatique (par exemple : max 25% des contrats par agent).

📌 Exemple du parcours complet

Conducteur A fait une demande pour assurer une Peugeot 208.

La demande arrive → Admin Agence Tunis Centre.

Admin valide et affecte automatiquement → Agent X (car il a traité moins de contrats que Agent Y).

Agent X finalise le contrat.

Conducteur A voit son véhicule et son contrat dans son dashboard.

✅ Avantages de ce workflow

⚖️ Équilibrage automatique des tâches entre agents.

🔒 Contrôle par l’admin d’agence (meilleur management).

📊 Suivi de performance et charge de travail.

🚀 Plus transparent pour la compagnie.
===>
le choix de l’agent soit intelligent et non juste manuel.
On peut introduire une IA simple (ou un algorithme intelligent) qui aide l’admin à suggérer automatiquement l’agent idéal pour traiter une demande.

🤖 IA pour l’affectation des contrats aux agents
1. Critères possibles pour l’affectation

⚖️ Charge de travail actuelle (nombre de contrats en cours).

⏳ Délai moyen de traitement (vitesse de chaque agent).

⭐ Taux de satisfaction / erreurs (qualité du travail).

📍 Zone géographique / spécialité (si l’agence a des agents spécialisés par type de contrat ou véhicule).

🔄 Équilibrage global (éviter que certains agents soient surchargés).

2. Algorithmes utilisables

Règle simple (heuristique) :
→ Toujours choisir l’agent avec le moins de contrats actifs.

Système de scoring :

Chaque agent a un score calculé :

Score = α*(Charge de travail) + β*(Délai traitement) + γ*(Taux satisfaction)


L’IA attribue la demande à l’agent avec le meilleur score (plus équilibré).

Machine Learning (si tu as beaucoup de données) :

Tu peux entraîner un modèle sur les historique d’affectations pour prédire l’agent le plus adapté (supervised learning).

Exemple : Random Forest ou XGBoost pour prédire la probabilité de succès d’un agent sur un contrat donné.

3. Expérience utilisateur

Admin d’agence :

Reçoit la demande → voit la suggestion IA : "Attribuer à Agent X (charge actuelle 3 contrats, délai moyen 1,2 jours)".

Peut accepter ou modifier l’affectation.

👉 L’IA ne remplace pas l’admin, elle assiste.

4. Dashboard d’équilibrage avec IA

Vue pour admin :

Histogramme des contrats par agent.

Temps moyen de traitement par agent.

Recommandations IA pour la prochaine affectation.

💡 Exemple concret :

Agent A : 12 contrats actifs, délai moyen 3 jours.

Agent B : 5 contrats actifs, délai moyen 2 jours.

Agent C : 8 contrats actifs, délai moyen 1 jour mais taux d’erreur élevé.

👉 L’IA peut recommander Agent B pour un nouvel entrant, car il est équilibré et efficace.