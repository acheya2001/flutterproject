import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/services/universal_auth_service.dart';
import '../../../core/models/admin_hierarchy_model.dart';

/// 🏢 Interface d'administration hiérarchique pour gérer les demandes
class HierarchicalAdminDemandesScreen extends StatefulWidget {
  final AdminHierarchyModel admin;

  const HierarchicalAdminDemandesScreen({
    Key? key,
    required this.admin,
  }) : super(key: key);

  @override
  State<HierarchicalAdminDemandesScreen> createState() => _HierarchicalAdminDemandesScreenState();
}

class _HierarchicalAdminDemandesScreenState extends State<HierarchicalAdminDemandesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filtreStatut = 'en_attente';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Demandes d\'Inscription'),
            Text(
              widget.admin.typeAdminNom,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filtreStatut = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'en_attente', child: Text('En attente')),
              const PopupMenuItem(value: 'en_cours_traitement', child: Text('En cours')),
              const PopupMenuItem(value: 'approuvee', child: Text('Approuvées')),
              const PopupMenuItem(value: 'refusee', child: Text('Refusées')),
              const PopupMenuItem(value: 'toutes', child: Text('Toutes')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Informations de l'admin
          _buildAdminInfoCard(),
          
          // Liste des demandes
          Expanded(
            child: _buildDemandesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[600],
            child: Text(
              '${widget.admin.prenom[0]}${widget.admin.nom[0]}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.admin.prenom} ${widget.admin.nom}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.admin.typeAdminNom,
                  style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
                ),
                Text(
                  widget.admin.descriptionRole,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Actif',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getDemandesStream(),
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

        final demandes = snapshot.data?.docs ?? [];
        final demandesFiltrees = demandes.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final demande = DemandeInscriptionModel.fromMap(data, doc.id);
          
          // Filtrer selon les permissions de l'admin
          if (!widget.admin.peutApprouverDemande(data)) {
            return false;
          }
          
          // Filtrer selon le statut sélectionné
          if (_filtreStatut != 'toutes' && demande.statut != _filtreStatut) {
            return false;
          }
          
          return true;
        }).toList();

        if (demandesFiltrees.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune demande',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                Text(
                  _getMessageAucuneDemande(),
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: demandesFiltrees.length,
          itemBuilder: (context, index) {
            final doc = demandesFiltrees[index];
            final data = doc.data() as Map<String, dynamic>;
            final demande = DemandeInscriptionModel.fromMap(data, doc.id);
            
            return _buildDemandeCard(demande);
          },
        );
      },
    );
  }

  Widget _buildDemandeCard(DemandeInscriptionModel demande) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: demande.couleurStatut.withOpacity(0.2),
                  child: Icon(
                    demande.iconeStatut,
                    color: demande.couleurStatut,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${demande.prenom} ${demande.nom}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        demande.email,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: demande.couleurStatut,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatStatut(demande.statut),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Informations professionnelles
            _buildInfoRow('Compagnie', demande.compagnie),
            _buildInfoRow('Agence', demande.agence),
            _buildInfoRow('Gouvernorat', demande.gouvernorat),
            _buildInfoRow('Poste', demande.poste),
            _buildInfoRow('Numéro Agent', demande.numeroAgent),
            _buildInfoRow('Téléphone', demande.telephone),
            _buildInfoRow('Date demande', _formatDate(demande.dateCreation)),
            
            if (demande.adminTraitantId != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Traité par', 'Admin ${demande.adminTraitantId}'),
            ],
            
            if (demande.motifRefus != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Motif de refus:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    Text(demande.motifRefus!),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Boutons d'action
            if (demande.peutEtreTraitee) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approuverDemande(demande),
                      icon: const Icon(Icons.check),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _refuserDemande(demande),
                      icon: const Icon(Icons.close),
                      label: const Text('Refuser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getDemandesStream() {
    Query query = _firestore.collection('demandes_inscription');
    
    // Filtrer selon le type d'admin
    switch (widget.admin.typeAdmin) {
      case TypeAdmin.superAdmin:
        // Super admin voit tout
        break;
      case TypeAdmin.adminCompagnie:
        query = query.where('compagnie', isEqualTo: widget.admin.compagnieId);
        break;
      case TypeAdmin.adminAgence:
        query = query
            .where('compagnie', isEqualTo: widget.admin.compagnieId)
            .where('agence', isEqualTo: widget.admin.agenceId);
        break;
      case TypeAdmin.adminRegional:
        query = query.where('gouvernorat', whereIn: widget.admin.gouvernoratsGeres);
        break;
    }
    
    return query.snapshots();
  }

  Future<void> _approuverDemande(DemandeInscriptionModel demande) async {
    try {
      // Marquer comme en cours de traitement
      await _firestore.collection('demandes_inscription').doc(demande.id).update({
        'statut': 'en_cours_traitement',
        'adminTraitantId': widget.admin.id,
        'dateTraitement': FieldValue.serverTimestamp(),
      });

      // Créer le compte Firebase Auth et Firestore
      final result = await UniversalAuthService.signUp(
        email: demande.email,
        password: demande.motDePasseTemporaire,
        nom: demande.nom,
        prenom: demande.prenom,
        userType: 'assureur',
        additionalData: {
          'telephone': demande.telephone,
          'compagnie': demande.compagnie,
          'agence': demande.agence,
          'gouvernorat': demande.gouvernorat,
          'poste': demande.poste,
          'numeroAgent': demande.numeroAgent,
        },
      );

      if (result['success'] == true) {
        // Marquer la demande comme approuvée
        await _firestore.collection('demandes_inscription').doc(demande.id).update({
          'statut': 'approuvee',
          'dateApprobation': FieldValue.serverTimestamp(),
        });

        // Mettre à jour les statistiques de l'admin
        await _mettreAJourStatistiquesAdmin('approuvee');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Demande approuvée: ${demande.prenom} ${demande.nom}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      // Remettre le statut en attente en cas d'erreur
      await _firestore.collection('demandes_inscription').doc(demande.id).update({
        'statut': 'en_attente',
        'adminTraitantId': null,
        'dateTraitement': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refuserDemande(DemandeInscriptionModel demande) async {
    final motifController = TextEditingController();
    
    final motif = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Êtes-vous sûr de vouloir refuser la demande de ${demande.prenom} ${demande.nom} ?'),
            const SizedBox(height: 16),
            TextField(
              controller: motifController,
              decoration: const InputDecoration(
                labelText: 'Motif du refus (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, motifController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (motif != null) {
      try {
        await _firestore.collection('demandes_inscription').doc(demande.id).update({
          'statut': 'refusee',
          'adminTraitantId': widget.admin.id,
          'dateTraitement': FieldValue.serverTimestamp(),
          'motifRefus': motif.isNotEmpty ? motif : 'Aucun motif spécifié',
        });

        await _mettreAJourStatistiquesAdmin('refusee');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Demande refusée'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _mettreAJourStatistiquesAdmin(String action) async {
    try {
      await _firestore.collection('admins_hierarchy').doc(widget.admin.id).update({
        'statistiques.demandesTraitees': FieldValue.increment(1),
        'statistiques.demandes${action == 'approuvee' ? 'Approuvees' : 'Refusees'}': FieldValue.increment(1),
        'derniereConnexion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erreur mise à jour statistiques: $e');
    }
  }

  String _formatStatut(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'en_cours_traitement':
        return 'En cours';
      case 'approuvee':
        return 'Approuvée';
      case 'refusee':
        return 'Refusée';
      default:
        return statut;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getMessageAucuneDemande() {
    switch (_filtreStatut) {
      case 'en_attente':
        return 'Aucune demande en attente dans votre périmètre';
      case 'approuvee':
        return 'Aucune demande approuvée';
      case 'refusee':
        return 'Aucune demande refusée';
      default:
        return 'Aucune demande trouvée';
    }
  }
}
