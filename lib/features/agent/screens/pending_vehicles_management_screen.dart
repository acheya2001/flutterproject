import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../conducteur/models/vehicule_model.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../services/agent_contract_service.dart';

/// 🚗 Écran de gestion des véhicules en attente pour les agents et admins agence
class PendingVehiclesManagementScreen extends StatefulWidget {
  const PendingVehiclesManagementScreen({super.key});

  @override
  State<PendingVehiclesManagementScreen> createState() => _PendingVehiclesManagementScreenState();
}

class _PendingVehiclesManagementScreenState extends State<PendingVehiclesManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> _pendingVehicles = [];
  bool _isLoading = true;
  String? _userRole;
  String? _agenceId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _userRole = userData['role'];
        _agenceId = userData['agenceId'];
        
        await _loadPendingVehicles();
      }
    } catch (e) {
      print('❌ Erreur chargement info utilisateur: $e');
    }
  }

  Future<void> _loadPendingVehicles() async {
    try {
      setState(() => _isLoading = true);

      Query query = _firestore.collection('vehicules')
          .where('etatCompte', isEqualTo: 'En attente');

      // Filtrer par agence pour les agents ET les admins d'agence
      if ((_userRole == 'agent' || _userRole == 'admin_agence') && _agenceId != null) {
        query = query.where('agenceAssuranceId', isEqualTo: _agenceId);
        print('🔍 Filtrage par agence: $_agenceId pour rôle: $_userRole');
      } else {
        print('⚠️ Pas de filtrage par agence - Rôle: $_userRole, AgenceId: $_agenceId');
      }

      final snapshot = await query.get();
      print('📊 ${snapshot.docs.length} véhicules trouvés en attente');

      final vehicles = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final vehicleData = doc.data() as Map<String, dynamic>;
        vehicleData['id'] = doc.id;

        print('🚗 Véhicule trouvé: ${vehicleData['marque']} ${vehicleData['modele']} - Agence: ${vehicleData['agenceAssuranceId']}');

        // Récupérer les infos du conducteur depuis la collection 'users' (plus cohérent)
        final conducteurId = vehicleData['conducteurId'];
        if (conducteurId != null) {
          // Essayer d'abord dans 'users'
          final userDoc = await _firestore
              .collection('users')
              .doc(conducteurId)
              .get();

          if (userDoc.exists) {
            vehicleData['conducteurInfo'] = userDoc.data();
          } else {
            // Fallback vers 'conducteurs'
            final conducteurDoc = await _firestore
                .collection('conducteurs')
                .doc(conducteurId)
                .get();

            if (conducteurDoc.exists) {
              vehicleData['conducteurInfo'] = conducteurDoc.data();
            }
          }
        }

        vehicles.add(vehicleData);
      }

      setState(() {
        _pendingVehicles = vehicles;
        _isLoading = false;
      });

      print('✅ ${vehicles.length} véhicules chargés avec succès');
    } catch (e) {
      print('❌ Erreur chargement véhicules en attente: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Véhicules en Attente',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_pendingVehicles.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadPendingVehicles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingVehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _pendingVehicles[index];
          return _buildVehicleCard(vehicle);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun véhicule en attente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les nouveaux véhicules ajoutés par les conducteurs apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final conducteurInfo = vehicle['conducteurInfo'] as Map<String, dynamic>?;
    final createdAt = (vehicle['createdAt'] as Timestamp?)?.toDate();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showVehicleDetails(vehicle),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${vehicle['marque']} ${vehicle['modele']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'EN ATTENTE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Informations véhicule
              _buildInfoRow('Immatriculation', vehicle['numeroImmatriculation'] ?? 'N/A'),
              _buildInfoRow('Année', vehicle['annee']?.toString() ?? 'N/A'),
              _buildInfoRow('Couleur', vehicle['couleur'] ?? 'N/A'),
              _buildInfoRow('Type', vehicle['typeVehicule'] ?? 'N/A'),
              
              if (conducteurInfo != null) ...[
                const Divider(height: 24),
                Text(
                  'Informations Conducteur',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Nom', '${conducteurInfo['nom'] ?? ''} ${conducteurInfo['prenom'] ?? ''}'),
                _buildInfoRow('Téléphone', conducteurInfo['telephone'] ?? 'N/A'),
                _buildInfoRow('Email', conducteurInfo['email'] ?? 'N/A'),
              ],
              
              const SizedBox(height: 16),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _validateVehicle(vehicle['id']),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Valider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectVehicle(vehicle['id']),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rejeter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              if (createdAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Ajouté le ${_formatDate(createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showVehicleDetails(Map<String, dynamic> vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailsScreen(vehicle: vehicle),
      ),
    );
  }

  /// ⚠️ Afficher dialog de confirmation
  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required IconData icon,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: confirmColor, size: 28),
            SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    ) ?? false;
  }

  /// 📝 Afficher dialog pour saisir la raison du rejet
  Future<String?> _showRejectReasonDialog() async {
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit_note, color: Colors.orange.shade600, size: 28),
            SizedBox(width: 12),
            Text('Raison du rejet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Veuillez indiquer la raison du rejet de ce véhicule :',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ex: Documents manquants, informations incorrectes...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isNotEmpty) {
                Navigator.pop(context, reason);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Veuillez saisir une raison'),
                    backgroundColor: Colors.orange.shade600,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _validateVehicle(String vehicleId) async {
    try {
      // Afficher dialog de confirmation
      final confirmed = await _showConfirmationDialog(
        title: 'Valider le véhicule',
        message: 'Êtes-vous sûr de vouloir valider ce véhicule ? Vous pourrez ensuite créer un contrat d\'assurance.',
        confirmText: 'Valider',
        confirmColor: Colors.green,
        icon: Icons.check_circle,
      );

      if (!confirmed) return;

      // Mettre à jour le statut
      await _firestore.collection('vehicules').doc(vehicleId).update({
        'etatCompte': 'Validé par Agent',
        'validatedAt': FieldValue.serverTimestamp(),
        'validatedBy': _auth.currentUser?.uid,
        'validatedByEmail': _auth.currentUser?.email,
        'validatedByRole': 'agent',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Véhicule validé avec succès'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      print('✅ [AGENT] Véhicule $vehicleId validé par ${_auth.currentUser?.email}');
      _loadPendingVehicles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la validation: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('❌ [AGENT] Erreur validation: $e');
    }
  }

  Future<void> _rejectVehicle(String vehicleId) async {
    try {
      // Demander la raison du rejet
      final reason = await _showRejectReasonDialog();
      if (reason == null || reason.trim().isEmpty) return;

      // Afficher dialog de confirmation
      final confirmed = await _showConfirmationDialog(
        title: 'Rejeter le véhicule',
        message: 'Êtes-vous sûr de vouloir rejeter ce véhicule ?\n\nRaison: $reason',
        confirmText: 'Rejeter',
        confirmColor: Colors.red,
        icon: Icons.cancel,
      );

      if (!confirmed) return;

      await _firestore.collection('vehicules').doc(vehicleId).update({
        'etatCompte': 'Rejeté par Agent',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _auth.currentUser?.uid,
        'rejectedByEmail': _auth.currentUser?.email,
        'rejectedByRole': 'agent',
        'rejectionReason': reason.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.cancel, color: Colors.white),
              SizedBox(width: 8),
              Text('Véhicule rejeté'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );

      print('❌ [AGENT] Véhicule $vehicleId rejeté par ${_auth.currentUser?.email} - Raison: $reason');
      _loadPendingVehicles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du rejet: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('❌ [AGENT] Erreur rejet: $e');
    }
  }
}

/// Écran de détails complets du véhicule
class VehicleDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const VehicleDetailsScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final conducteurInfo = widget.vehicle['conducteurInfo'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicle['marque']} ${widget.vehicle['modele']}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'validate') {
                _validateVehicle();
              } else if (value == 'reject') {
                _showRejectDialog();
              } else if (value == 'contract') {
                _createContract();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'validate',
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Valider'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reject',
                child: Row(
                  children: [
                    Icon(Icons.close, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Rejeter'),
                  ],
                ),
              ),
              if (widget.vehicle['etatCompte'] == 'Validé par Agent')
                const PopupMenuItem(
                  value: 'contract',
                  child: Row(
                    children: [
                      Icon(Icons.description, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Créer Contrat'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut du véhicule
            _buildStatusCard(),
            const SizedBox(height: 16),

            // Informations véhicule
            _buildSectionCard(
              'Informations Véhicule',
              Icons.directions_car,
              _buildVehicleInfo(),
            ),
            const SizedBox(height: 16),

            // Informations propriétaire
            _buildSectionCard(
              'Informations Propriétaire',
              Icons.person,
              _buildOwnerInfo(),
            ),
            const SizedBox(height: 16),

            // Informations conducteur
            if (conducteurInfo != null)
              _buildSectionCard(
                'Informations Conducteur',
                Icons.account_circle,
                _buildConducteurInfo(conducteurInfo),
              ),
            const SizedBox(height: 16),

            // Informations assurance
            if (widget.vehicle['estAssure'] == true)
              _buildSectionCard(
                'Informations Assurance',
                Icons.security,
                _buildInsuranceInfo(),
              ),
            const SizedBox(height: 16),

            // Documents
            _buildSectionCard(
              'Documents',
              Icons.folder,
              _buildDocumentsInfo(),
            ),
            const SizedBox(height: 16),

            // Actions
            _buildActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = widget.vehicle['etatCompte'] ?? 'En attente';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Validé par Agent':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Rejeté par Agent':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'Contrat Proposé':
        statusColor = Colors.blue;
        statusIcon = Icons.description;
        break;
      case 'Contrat Actif':
        statusColor = Colors.purple;
        statusIcon = Icons.verified;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Text(
            'Statut: $status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfo() {
    return Column(
      children: [
        _buildDetailRow('Marque', widget.vehicle['marque']),
        _buildDetailRow('Modèle', widget.vehicle['modele']),
        _buildDetailRow('Immatriculation', widget.vehicle['numeroImmatriculation']),
        _buildDetailRow('Année', widget.vehicle['annee']?.toString()),
        _buildDetailRow('Couleur', widget.vehicle['couleur']),
        _buildDetailRow('Type', widget.vehicle['typeVehicule']),
        _buildDetailRow('Carburant', widget.vehicle['carburant']),
        _buildDetailRow('Usage', widget.vehicle['usage']),
        _buildDetailRow('Nombre de places', widget.vehicle['nombrePlaces']?.toString()),
        _buildDetailRow('N° de série', widget.vehicle['numeroSerie']),
        _buildDetailRow('Puissance fiscale', widget.vehicle['puissanceFiscale']),
        _buildDetailRow('Cylindrée', widget.vehicle['cylindree']),
        _buildDetailRow('Poids', widget.vehicle['poids']?.toString()),
        _buildDetailRow('Genre', widget.vehicle['genre']),
        _buildDetailRow('N° carte grise', widget.vehicle['numeroCarteGrise']),
        _buildDetailRow('Date 1ère immatriculation', _formatDate(widget.vehicle['datePremiereImmatriculation'])),
        _buildDetailRow('Date mise en circulation', _formatDate(widget.vehicle['dateMiseEnCirculation'])),
      ],
    );
  }

  Widget _buildOwnerInfo() {
    return Column(
      children: [
        _buildDetailRow('Nom', widget.vehicle['nomProprietaire']),
        _buildDetailRow('Prénom', widget.vehicle['prenomProprietaire']),
        _buildDetailRow('Adresse', widget.vehicle['adresseProprietaire']),
        _buildDetailRow('N° permis', widget.vehicle['numeroPermis']),
        _buildDetailRow('Catégorie permis', widget.vehicle['categoriePermis']),
        _buildDetailRow('Date obtention permis', _formatDate(widget.vehicle['dateObtentionPermis'])),
        _buildDetailRow('Date expiration permis', _formatDate(widget.vehicle['dateExpirationPermis'])),
      ],
    );
  }

  Widget _buildConducteurInfo(Map<String, dynamic> conducteurInfo) {
    return Column(
      children: [
        _buildDetailRow('Nom complet', '${conducteurInfo['nom'] ?? ''} ${conducteurInfo['prenom'] ?? ''}'),
        _buildDetailRow('Email', conducteurInfo['email']),
        _buildDetailRow('Téléphone', conducteurInfo['telephone']),
        _buildDetailRow('Adresse', conducteurInfo['adresse']),
        _buildDetailRow('CIN', conducteurInfo['cin']),
        _buildDetailRow('Date de naissance', _formatDate(conducteurInfo['dateNaissance'])),
      ],
    );
  }

  Widget _buildInsuranceInfo() {
    return Column(
      children: [
        _buildDetailRow('Assuré', widget.vehicle['estAssure'] == true ? 'Oui' : 'Non'),
        if (widget.vehicle['estAssure'] == true) ...[
          _buildDetailRow('Compagnie', widget.vehicle['compagnieAssuranceNom']),
          _buildDetailRow('Agence', widget.vehicle['agenceAssuranceNom']),
          _buildDetailRow('N° contrat', widget.vehicle['numeroContratAssurance']),
          _buildDetailRow('Date début', _formatDate(widget.vehicle['dateDebutAssurance'])),
          _buildDetailRow('Date fin', _formatDate(widget.vehicle['dateFinAssurance'])),
          _buildDetailRow('Dernière assurance', _formatDate(widget.vehicle['dateDerniereAssurance'])),
        ],
      ],
    );
  }

  Widget _buildDocumentsInfo() {
    return Column(
      children: [
        if (widget.vehicle['imageCarteGriseUrl'] != null)
          _buildDocumentRow('Carte grise', widget.vehicle['imageCarteGriseUrl']),
        if (widget.vehicle['imagePermisUrl'] != null)
          _buildDocumentRow('Permis de conduire', widget.vehicle['imagePermisUrl']),
        if (widget.vehicle['imageCarteGriseUrl'] == null && widget.vehicle['imagePermisUrl'] == null)
          const Text(
            'Aucun document uploadé',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.vehicle['etatCompte'] == 'En attente'
                        ? _validateVehicle
                        : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.vehicle['etatCompte'] == 'En attente'
                        ? () => _showRejectDialog()
                        : null,
                    icon: const Icon(Icons.close),
                    label: const Text('Rejeter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.vehicle['etatCompte'] == 'Validé par Agent') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createContract,
                  icon: const Icon(Icons.description),
                  label: const Text('Créer un Contrat d\'Assurance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Non spécifié',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _viewDocument(url),
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('Voir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  String? _formatDate(dynamic date) {
    if (date == null) return null;

    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is DateTime) {
        dateTime = date;
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        return null;
      }

      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return null;
    }
  }

  void _viewDocument(String url) {
    // TODO: Implémenter la visualisation de document
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture du document: $url'),
        action: SnackBarAction(
          label: 'Copier',
          onPressed: () {
            // TODO: Copier l'URL dans le presse-papier
          },
        ),
      ),
    );
  }

  Future<void> _validateVehicle() async {
    try {
      await _firestore.collection('vehicules').doc(widget.vehicle['id']).update({
        'etatCompte': 'Validé par Agent',
        'validatedAt': FieldValue.serverTimestamp(),
        'validatedBy': _auth.currentUser?.uid,
        'validatedByEmail': _auth.currentUser?.email,
        'validatedByRole': 'agent',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Véhicule validé avec succès'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retourner avec succès
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la validation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter le véhicule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison du rejet:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Motif du rejet...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectVehicle(reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectVehicle(String reason) async {
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez indiquer un motif de rejet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _firestore.collection('vehicules').doc(widget.vehicle['id']).update({
        'etatCompte': 'Rejeté par Agent',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _auth.currentUser?.uid,
        'rejectedByEmail': _auth.currentUser?.email,
        'rejectedByRole': 'agent',
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cancel, color: Colors.white),
                SizedBox(width: 8),
                Text('Véhicule rejeté'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, true); // Retourner avec succès
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du rejet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createContract() {
    // TODO: Naviguer vers l'écran de création de contrat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractCreationScreen(vehicle: widget.vehicle),
      ),
    );
  }
}

/// 📋 **TYPES DE CONTRATS D'ASSURANCE**
enum ContractType {
  responsabiliteCivile('Responsabilité Civile', 'RC obligatoire uniquement'),
  tiersPlusVol('Tiers + Vol', 'RC + Vol + Incendie + Bris de glace'),
  tousRisques('Tous Risques', 'Couverture complète tous dommages'),
  temporaire('Temporaire', 'Assurance courte durée'),
  flotte('Flotte', 'Multi-véhicules entreprise');

  const ContractType(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// 📄 Écran de création de contrat d'assurance
class ContractCreationScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const ContractCreationScreen({super.key, required this.vehicle});

  @override
  State<ContractCreationScreen> createState() => _ContractCreationScreenState();
}

class _ContractCreationScreenState extends State<ContractCreationScreen> {
  ContractType _selectedContractType = ContractType.responsabiliteCivile;
  final _contractNumberController = TextEditingController();
  final _primeController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un Contrat'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations véhicule (résumé)
            _buildVehicleSummary(),
            const SizedBox(height: 24),

            // Type de contrat
            _buildContractTypeSelection(),
            const SizedBox(height: 24),

            // Détails du contrat
            _buildContractDetails(),
            const SizedBox(height: 24),

            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Véhicule à assurer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('${widget.vehicle['marque']} ${widget.vehicle['modele']}'),
            Text('Immatriculation: ${widget.vehicle['numeroImmatriculation']}'),
            Text('Propriétaire: ${widget.vehicle['nomProprietaire']} ${widget.vehicle['prenomProprietaire']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildContractTypeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type de Contrat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...ContractType.values.map((type) => RadioListTile<ContractType>(
              title: Text(type.displayName),
              subtitle: Text(type.description),
              value: type,
              groupValue: _selectedContractType,
              onChanged: (value) {
                setState(() {
                  _selectedContractType = value!;
                  _calculatePrime(); // Recalculer la prime
                });
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildContractDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails du Contrat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _contractNumberController,
              decoration: const InputDecoration(
                labelText: 'Numéro de contrat',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _primeController,
              decoration: const InputDecoration(
                labelText: 'Prime annuelle (TND)',
                border: OutlineInputBorder(),
                suffixText: 'TND',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date de début',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_formatDateForDisplay(_startDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date de fin',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_formatDateForDisplay(_endDate)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createContract,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Créer le Contrat', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  void _calculatePrime() {
    // Utiliser le service de calcul de prime
    final vehicleYear = widget.vehicle['annee'] as int? ?? DateTime.now().year;
    final puissanceFiscale = widget.vehicle['puissanceFiscale'] as int?;
    final usage = widget.vehicle['usage'] as String?;

    final calculatedPrime = AgentContractService.calculatePrime(
      contractType: _selectedContractType.name,
      vehicleYear: vehicleYear,
      puissanceFiscale: puissanceFiscale,
      usage: usage,
    );

    _primeController.text = calculatedPrime.toStringAsFixed(0);
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1095)), // 3 ans
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _endDate = picked.add(const Duration(days: 365)); // 1 an par défaut
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDateForDisplay(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _createContract() async {
    if (_contractNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un numéro de contrat'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final prime = double.tryParse(_primeController.text);
    if (prime == null || prime <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir une prime valide'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Utiliser le service de création de contrat
      final contractId = await AgentContractService.createContract(
        vehicleData: widget.vehicle,
        contractType: _selectedContractType.name,
        primeAnnuelle: prime,
        dateDebut: _startDate,
        dateFin: _endDate,
        numeroContrat: _contractNumberController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Contrat créé et proposé au conducteur\nN° $contractId'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context); // Retour à l'écran précédent
        Navigator.pop(context, true); // Retour à la liste avec refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création du contrat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Générer un numéro de contrat automatique
    _contractNumberController.text = 'CTR-${DateTime.now().millisecondsSinceEpoch}';
    _calculatePrime();
  }

  @override
  void dispose() {
    _contractNumberController.dispose();
    _primeController.dispose();
    super.dispose();
  }
}
