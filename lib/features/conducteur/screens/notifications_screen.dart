import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'completer_documents_screen.dart';
import 'choix_frequence_paiement_screen.dart';
import 'contrat_actif_screen.dart';
import '../../../services/test_notifications_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (mounted) setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('🔔 Notifications'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all),
            tooltip: 'Marquer tout comme lu',
          ),
          IconButton(
            onPressed: _clearAllNotifications,
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Supprimer toutes les notifications',
          ),
        ],
      ),
      body: _currentUserId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('conducteurId', isEqualTo: _currentUserId)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final notifications = snapshot.data?.docs ?? [];

                // Trier les notifications par date de création (plus récentes en premier)
                notifications.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aDate = aData['dateCreation'] as Timestamp?;
                  final bDate = bData['dateCreation'] as Timestamp?;

                  if (aDate == null && bDate == null) return 0;
                  if (aDate == null) return 1;
                  if (bDate == null) return -1;

                  return bDate.compareTo(aDate); // Plus récentes en premier
                });

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune notification',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final data = notification.data() as Map<String, dynamic>;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: _buildNotificationCard(notification.id, data),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildNotificationCard(String notificationId, Map<String, dynamic> data) {
    final isRead = data['lu'] ?? false;
    final type = data['type'] ?? '';
    final titre = data['titre'] ?? 'Notification';
    final message = data['message'] ?? '';
    final dateCreation = data['dateCreation'] as Timestamp?;
    final demandeId = data['demandeId'];
    final documentsManquants = data['documentsManquants'] as List<dynamic>?;

    Color cardColor;
    IconData icon;
    Color iconColor;

    switch (type) {
      case 'documents_manquants':
        cardColor = Colors.orange[50]!;
        icon = Icons.warning;
        iconColor = Colors.orange[700]!;
        break;
      case 'contrat_valide':
        cardColor = Colors.green[50]!;
        icon = Icons.check_circle;
        iconColor = Colors.green[700]!;
        break;
      case 'paiement_requis':
        cardColor = Colors.blue[50]!;
        icon = Icons.payment;
        iconColor = Colors.blue[700]!;
        break;
      case 'expiration_proche':
        cardColor = Colors.red[50]!;
        icon = Icons.schedule;
        iconColor = Colors.red[700]!;
        break;
      case 'expiration_contrat':
        final joursRestants = data['joursRestants'] ?? 0;
        if (joursRestants <= 7) {
          cardColor = Colors.red[50]!;
          icon = Icons.warning;
          iconColor = Colors.red[700]!;
        } else if (joursRestants <= 15) {
          cardColor = Colors.orange[50]!;
          icon = Icons.schedule;
          iconColor = Colors.orange[700]!;
        } else {
          cardColor = Colors.amber[50]!;
          icon = Icons.info;
          iconColor = Colors.amber[700]!;
        }
        break;
      case 'contrat_expire':
        cardColor = Colors.red[100]!;
        icon = Icons.error;
        iconColor = Colors.red[800]!;
        break;
      case 'contrat_active':
        cardColor = Colors.green[50]!;
        icon = Icons.check_circle;
        iconColor = Colors.green[700]!;
        break;
      default:
        cardColor = Colors.grey[50]!;
        icon = Icons.info;
        iconColor = Colors.grey[700]!;
    }

    return InkWell(
      onTap: () => _handleNotificationTap(notificationId, data),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? Colors.grey[300]! : iconColor.withOpacity(0.3),
            width: isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isRead ? Colors.grey[700] : Colors.black87,
                        ),
                      ),
                      if (dateCreation != null)
                        Text(
                          _formatDate(dateCreation),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isRead ? Colors.grey[600] : Colors.black87,
              ),
            ),
            
            if (type == 'documents_manquants' && demandeId != null && documentsManquants != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToCompleteDocuments(demandeId, documentsManquants),
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Compléter Documents'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  Future<void> _handleNotificationTap(String notificationId, Map<String, dynamic> data) async {
    // Marquer comme lu
    if (!(data['lu'] ?? false)) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'lu': true});
    }

    // Actions spécifiques selon le type
    final type = data['type'] ?? '';
    switch (type) {
      case 'documents_manquants':
        final demandeId = data['demandeId'];
        final documentsManquants = data['documentsManquants'] as List<dynamic>?;
        if (demandeId != null && documentsManquants != null) {
          _navigateToCompleteDocuments(demandeId, documentsManquants);
        }
        break;
      case 'contrat_valide':
        // Naviguer vers les contrats
        break;
      case 'paiement_requis':
        // Naviguer vers le choix de fréquence de paiement
        final demandeId = data['demandeId'];
        if (demandeId != null) {
          _navigateToChoixFrequence(demandeId);
        }
        break;

      case 'contrat_active':
        // Naviguer vers l'écran de contrat actif
        final demandeId = data['demandeId'];
        if (demandeId != null) {
          _navigateToContratActif(demandeId);
        }
        break;

      case 'expiration_contrat':
      case 'contrat_expire':
        // Afficher dialogue d'information sur l'expiration
        _afficherDialogueExpiration(data);
        break;
    }
  }

  void _navigateToCompleteDocuments(String demandeId, List<dynamic> documentsManquants) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompleterDocumentsScreen(
          demandeId: demandeId,
          documentsManquants: documentsManquants.cast<String>(),
        ),
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('conducteurId', isEqualTo: _currentUserId)
          .where('lu', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'lu': true});
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Toutes les notifications marquées comme lues'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🧹 Supprimer toutes les notifications
  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🧹 Supprimer toutes les notifications'),
          content: const Text('Voulez-vous supprimer toutes vos notifications ? Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await TestNotificationsService.clearTestNotifications();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Toutes les notifications supprimées !'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 💰 Naviguer vers le choix de fréquence de paiement
  Future<void> _navigateToChoixFrequence(String demandeId) async {
    try {
      // Récupérer les données de la demande
      final demandeDoc = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeId)
          .get();

      if (!demandeDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Demande non trouvée'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final demandeData = demandeDoc.data()!;

      // Vérifier que la demande est bien en attente de paiement
      if (demandeData['statut'] != 'en_attente_paiement') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cette demande n\'est plus en attente de paiement (statut: ${demandeData['statut']})'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Naviguer vers l'écran de choix de fréquence
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChoixFrequencePaiementScreen(
            demandeId: demandeId,
            conducteurId: _currentUserId!,
            numeroContrat: demandeData['numeroContrat'] ?? demandeId,
            demandeData: demandeData,
          ),
        ),
      );

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Fréquence de paiement configurée !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur navigation choix fréquence: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📄 Naviguer vers l'écran de contrat actif
  Future<void> _navigateToContratActif(String demandeId) async {
    try {
      // Naviguer vers l'écran de contrat actif
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContratActifScreen(demandeId: demandeId),
        ),
      );

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📄 Contrat consulté avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur navigation contrat actif: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📅 Afficher dialogue d'information sur l'expiration
  void _afficherDialogueExpiration(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final joursRestants = data['joursRestants'] ?? 0;
    final dateExpiration = data['dateExpiration'] ?? '';
    final vehiculeInfo = data['vehiculeInfo'] ?? '';
    final numeroContrat = data['numeroContrat'] ?? '';

    // Informations de l'agent
    final agentEmail = data['agentEmail'] ?? '';
    final agentNom = data['agentNom'] ?? 'Votre agent';
    final agentTelephone = data['agentTelephone'] ?? '';

    String titre;
    String message;
    Color couleur;
    IconData icone;

    if (type == 'contrat_expire') {
      titre = '🚨 CONTRAT EXPIRÉ';
      message = 'Votre contrat d\'assurance a expiré le $dateExpiration.\n\n⚠️ ATTENTION: Votre véhicule n\'est plus couvert par l\'assurance. Il est illégal de circuler sans assurance valide.\n\n$vehiculeInfo\n📋 N° Contrat: $numeroContrat\n\n👨‍💼 Contactez immédiatement votre agent pour renouveler votre contrat.';
      couleur = Colors.red;
      icone = Icons.error;
    } else {
      titre = '⚠️ CONTRAT EXPIRE BIENTÔT';
      message = 'Votre contrat d\'assurance expire dans $joursRestants jour(s) (le $dateExpiration).\n\n📋 Pour éviter toute interruption de couverture, renouvelez votre contrat avant cette date.\n\n$vehiculeInfo\n📋 N° Contrat: $numeroContrat\n\n👨‍💼 Contactez votre agent pour organiser le renouvellement.';
      couleur = joursRestants <= 7 ? Colors.red : Colors.orange;
      icone = joursRestants <= 7 ? Icons.warning : Icons.schedule;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icone, color: couleur, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titre,
                style: TextStyle(
                  color: couleur,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _contacterAgent(agentEmail, agentNom, agentTelephone, numeroContrat, vehiculeInfo);
            },
            icon: const Icon(Icons.email),
            label: Text(agentEmail.isNotEmpty ? 'Contacter $agentNom' : 'Contacter Agent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: couleur,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 📧 Contacter l'agent par email
  Future<void> _contacterAgent(
    String agentEmail,
    String agentNom,
    String agentTelephone,
    String numeroContrat,
    String vehiculeInfo
  ) async {
    try {
      if (agentEmail.isEmpty) {
        // Si pas d'email, afficher les informations disponibles
        _afficherInformationsAgent(agentNom, agentTelephone);
        return;
      }

      // Préparer le sujet et le corps de l'email
      final sujet = Uri.encodeComponent('Renouvellement contrat $numeroContrat');
      final corps = Uri.encodeComponent('''
Bonjour $agentNom,

J'ai reçu une notification concernant l'expiration prochaine de mon contrat d'assurance.

Détails du contrat :
$vehiculeInfo
📋 N° Contrat: $numeroContrat

Pourriez-vous me contacter pour organiser le renouvellement de mon contrat ?

Merci pour votre assistance.

Cordialement
''');

      // Créer l'URL mailto
      final emailUrl = 'mailto:$agentEmail?subject=$sujet&body=$corps';
      final uri = Uri.parse(emailUrl);

      // Tenter d'ouvrir l'application email
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📧 Email ouvert pour contacter $agentNom'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Si impossible d'ouvrir l'email, copier l'adresse dans le presse-papiers
        _afficherEmailAgent(agentEmail, agentNom, agentTelephone);
      }

    } catch (e) {
      print('❌ Erreur ouverture email: $e');
      _afficherEmailAgent(agentEmail, agentNom, agentTelephone);
    }
  }

  /// 📋 Afficher les informations de l'agent
  void _afficherInformationsAgent(String agentNom, String agentTelephone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('Informations Agent'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (agentNom.isNotEmpty) ...[
              const Text('👤 Nom:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(agentNom),
              const SizedBox(height: 12),
            ],
            if (agentTelephone.isNotEmpty) ...[
              const Text('📞 Téléphone:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(agentTelephone),
              const SizedBox(height: 12),
            ],
            const Text(
              'Contactez votre agent pour organiser le renouvellement de votre contrat.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (agentTelephone.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final telUrl = 'tel:$agentTelephone';
                final uri = Uri.parse(telUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              icon: const Icon(Icons.phone),
              label: const Text('Appeler'),
            ),
        ],
      ),
    );
  }

  /// 📧 Afficher l'email de l'agent avec option de copie
  void _afficherEmailAgent(String agentEmail, String agentNom, String agentTelephone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.email, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('Contact Agent'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (agentNom.isNotEmpty) ...[
              const Text('👤 Agent:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(agentNom),
              const SizedBox(height: 12),
            ],
            const Text('📧 Email:', style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(
              agentEmail,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
            if (agentTelephone.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('📞 Téléphone:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(agentTelephone),
            ],
            const SizedBox(height: 16),
            const Text(
              'Impossible d\'ouvrir automatiquement l\'application email. Vous pouvez copier l\'adresse ci-dessus.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (agentTelephone.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final telUrl = 'tel:$agentTelephone';
                final uri = Uri.parse(telUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              icon: const Icon(Icons.phone),
              label: const Text('Appeler'),
            ),
        ],
      ),
    );
  }
}

