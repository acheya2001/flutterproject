# 📧 Service d'Envoi de PDF aux Agents

## 🎯 Vue d'ensemble

Le `ConstatAgentNotificationService` permet d'envoyer automatiquement le PDF du constat aux agents d'assurance responsables de chaque conducteur impliqué dans l'accident.

## 🔧 Fonctionnalités

### ✅ **Identification automatique des agents**
- Recherche l'agent responsable de chaque participant
- Utilise les demandes de contrats et les véhicules affectés
- Support de plusieurs sources de données

### ✅ **Génération de PDF personnalisés**
- PDF adapté pour chaque agent
- Contient les informations spécifiques au client de l'agent
- Format professionnel avec toutes les données du constat

### ✅ **Envoi par email automatique**
- Email personnalisé pour chaque agent
- Lien de téléchargement sécurisé du PDF
- Template HTML professionnel

### ✅ **Traçabilité complète**
- Logs détaillés de tous les envois
- Gestion des erreurs par agent
- Statistiques de réussite/échec

## 📋 Utilisation

### 1. Utilisation basique

```dart
import '../services/constat_agent_notification_service.dart';

// Envoyer le PDF aux agents
final resultat = await ConstatAgentNotificationService.envoyerConstatAuxAgents(
  sessionId: 'votre_session_id',
);

if (resultat['success']) {
  print('✅ PDF envoyé à ${resultat['envoisReussis']} agent(s)');
} else {
  print('❌ Erreur: ${resultat['error']}');
}
```

### 2. Intégration dans un widget

```dart
// Dans votre widget
ElevatedButton(
  onPressed: () async {
    final resultat = await ConstatAgentNotificationService.envoyerConstatAuxAgents(
      sessionId: widget.sessionId,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          resultat['success'] 
            ? '✅ PDF envoyé à ${resultat['envoisReussis']} agent(s)'
            : '❌ Erreur: ${resultat['error']}'
        ),
        backgroundColor: resultat['success'] ? Colors.green : Colors.red,
      ),
    );
  },
  child: const Text('Envoyer aux Agents'),
)
```

### 3. Avec gestion d'erreurs complète

```dart
try {
  // Afficher un indicateur de chargement
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Envoi en cours...'),
        ],
      ),
    ),
  );

  final resultat = await ConstatAgentNotificationService.envoyerConstatAuxAgents(
    sessionId: sessionId,
  );

  Navigator.of(context).pop(); // Fermer le loading

  if (resultat['success']) {
    _afficherResultatSucces(resultat);
  } else {
    _afficherErreur(resultat['error']);
  }

} catch (e) {
  Navigator.of(context).pop();
  _afficherErreur(e.toString());
}
```

## 📊 Structure de la réponse

```dart
{
  'success': true,
  'envoisReussis': 2,
  'envoisEchoues': 0,
  'totalAgents': 2,
  'details': {
    'agent1@email.com': {
      'success': true,
      'pdfUrl': 'https://...',
      'agentEmail': 'agent1@email.com'
    },
    'agent2@email.com': {
      'success': true,
      'pdfUrl': 'https://...',
      'agentEmail': 'agent2@email.com'
    }
  }
}
```

## 🔍 Comment ça marche

### 1. **Identification des agents**
```
Session → Participants → Conducteurs → Demandes de contrats → Agents
```

Le service recherche pour chaque participant :
- Les demandes de contrats avec statut `affectee`, `contrat_actif`, ou `contrat_valide`
- Les véhicules avec un `agentAffecteId`

### 2. **Génération du PDF**
- Utilise le `ModernPDFAgentService` existant
- Génère un PDF personnalisé pour chaque agent
- Sauvegarde dans Firebase Storage

### 3. **Envoi de l'email**
- Utilise la fonction Cloud `sendConstatPdfToAgent`
- Email HTML professionnel avec informations du client
- Lien de téléchargement sécurisé du PDF

## 📧 Template d'email

L'email envoyé aux agents contient :

- **En-tête** : Identification claire du type de notification
- **Client concerné** : Nom du participant qui est client de l'agent
- **Détails du constat** : Code, lieu, véhicules impliqués
- **Informations PDF** : Description du contenu du document
- **Bouton de téléchargement** : Lien direct vers le PDF
- **Instructions** : Actions à prendre par l'agent

## 🔧 Configuration requise

### Firebase Functions
La fonction Cloud `sendConstatPdfToAgent` doit être déployée :

```javascript
exports.sendConstatPdfToAgent = functions.https.onCall(async (data, context) => {
  // Implémentation dans functions/src/emailNotifications.js
});
```

### Collections Firestore
Le service utilise ces collections :
- `sessions_collaboratives` : Sessions de constat
- `demandes_contrats` : Demandes avec agents affectés
- `vehicules` : Véhicules avec agents affectés
- `agents_assurance` : Données des agents
- `constat_envois_logs` : Logs des envois

## 🐛 Débogage

### Logs disponibles
```dart
print('📧 [CONSTAT-AGENTS] Début envoi PDF pour session: $sessionId');
print('👥 [CONSTAT-AGENTS] ${agentsInfo.length} agents identifiés');
print('✅ [CONSTAT-AGENTS] PDF envoyé à ${agentInfo['agentEmail']}');
print('❌ [CONSTAT-AGENTS] Erreur envoi à ${agentInfo['agentEmail']}: $e');
```

### Problèmes courants

1. **Aucun agent trouvé**
   - Vérifier que les participants ont des demandes de contrats
   - Vérifier que les demandes ont un `agentId` valide

2. **Erreur génération PDF**
   - Vérifier que la session est finalisée
   - Vérifier les permissions Firebase Storage

3. **Erreur envoi email**
   - Vérifier la configuration SMTP dans Firebase Functions
   - Vérifier que les adresses email sont valides

## 📱 Interface utilisateur

Le bouton d'envoi est intégré dans l'onglet "PDF Agent" de `SessionDetailsScreen` :

- **Condition d'activation** : Session finalisée (`statut == 'finalise'`)
- **Feedback visuel** : Indicateur de chargement pendant l'envoi
- **Résultat** : Dialog avec statistiques détaillées
- **Gestion d'erreurs** : Messages d'erreur explicites

## 🔒 Sécurité

- **Authentification** : Seuls les utilisateurs connectés peuvent envoyer
- **Autorisation** : Vérification des permissions sur la session
- **Données sensibles** : PDF stocké de manière sécurisée dans Firebase Storage
- **Logs** : Traçabilité complète des envois pour audit

## 🚀 Améliorations futures

- [ ] Support de templates d'email personnalisables
- [ ] Envoi groupé avec optimisation des performances
- [ ] Notifications push aux agents
- [ ] Interface d'administration pour suivre les envois
- [ ] Intégration avec systèmes CRM des compagnies d'assurance
