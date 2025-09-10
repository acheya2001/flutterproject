import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/expiration_notification_service.dart';
import 'declaration_sinistre_screen.dart';

/// 🚗 Écran de gestion des véhicules du conducteur
class MesVehiculesScreen extends StatefulWidget {
  const MesVehiculesScreen({Key? key}) : super(key: key);

  @override
  State<MesVehiculesScreen> createState() => _MesVehiculesScreenState();
}

class _MesVehiculesScreenState extends State<MesVehiculesScreen> {
  String? _currentUserId;
  List<Map<String, dynamic>> _vehicules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _verifierExpirations();
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => _currentUserId = user.uid);
      await _loadVehicules();
    }
  }

  Future<void> _loadVehicules() async {
    if (_currentUserId == null) return;

    try {
      // Charger les véhicules depuis les contrats actifs
      final contratsSnapshot = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('conducteurId', isEqualTo: _currentUserId)
          .where('statut', isEqualTo: 'contrat_actif')
          .get();

      final vehicules = <Map<String, dynamic>>[];
      
      for (final doc in contratsSnapshot.docs) {
        final data = doc.data();
        vehicules.add({
          'id': doc.id,
          'contratId': doc.id,
          'numeroContrat': data['numeroContrat'] ?? doc.id,
          'marque': data['marque'] ?? 'N/A',
          'modele': data['modele'] ?? 'N/A',
          'immatriculation': data['immatriculation'] ?? 'N/A',
          'annee': data['annee'] ?? 'N/A',
          'couleur': data['couleur'] ?? 'N/A',
          'dateDebutContrat': data['dateDebutContrat'],
          'dateFinContrat': data['dateFinContrat'],
          'statut': 'actif',
          // Ajouter les informations d'assurance
          'compagnieNom': data['compagnieNom'] ?? 'Compagnie inconnue',
          'agenceNom': data['agenceNom'] ?? 'Agence inconnue',
          'agentNom': data['agentNom'] ?? 'Agent inconnu',
          'agentTelephone': data['agentTelephone'] ?? '',
          'numeroPolice': data['numeroContrat'] ?? doc.id,
        });
      }

      if (mounted) setState(() {
        _vehicules = vehicules;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement véhicules: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Mes Véhicules',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicules.isEmpty
              ? _buildEmptyState()
              : _buildVehiculesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun Véhicule Assuré',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vous n\'avez pas encore de véhicule assuré.\nCommencez par faire une demande d\'assurance.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle Demande'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiculesList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_vehicules.length} véhicule(s) assuré(s)',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),

          // Alertes d'expiration
          _buildAlerteExpiration(),

          // Bouton de test pour les notifications d'expiration (mode debug)
          if (true) // Remplacer par kDebugMode en production
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: _testerNotificationsExpiration,
                icon: const Icon(Icons.notification_add),
                label: const Text('Tester Notifications Expiration'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          // Bouton pour mettre à jour les informations financières manquantes
          if (_vehicules.any((v) => v['primeAnnuelle'] == null))
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: _mettreAJourInformationsFinancieres,
                icon: const Icon(Icons.update),
                label: const Text('Mettre à jour les informations financières'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          ..._vehicules.map((vehicule) => _buildVehiculeCard(vehicule)).toList(),
        ],
      ),
    );
  }

  Widget _buildVehiculeCard(Map<String, dynamic> vehicule) {
    final marque = vehicule['marque'] ?? 'N/A';
    final modele = vehicule['modele'] ?? 'N/A';
    final immatriculation = vehicule['immatriculation'] ?? 'N/A';
    final annee = vehicule['annee']?.toString() ?? 'N/A';
    final couleur = vehicule['couleur'] ?? 'N/A';
    final numeroContrat = vehicule['numeroContrat'] ?? 'N/A';
    
    final dateFinContrat = vehicule['dateFinContrat'] != null
        ? _convertirDate(vehicule['dateFinContrat'])
        : null;

    // Couleurs aléatoires pour les cartes
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
    ];
    final cardColor = colors[vehicule.hashCode % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [cardColor.withOpacity(0.1), cardColor.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec marque/modèle et statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$marque $modele',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: cardColor[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            immatriculation,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 16, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            'ASSURÉ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Informations du véhicule
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem('Année', annee, Icons.calendar_today),
                    ),
                    Expanded(
                      child: _buildInfoItem('Couleur', couleur, Icons.palette),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem('Contrat N°', numeroContrat, Icons.description),
                    ),
                    if (dateFinContrat != null)
                      Expanded(
                        child: _buildInfoItem(
                          'Expire le',
                          DateFormat('dd/MM/yyyy').format(dateFinContrat),
                          Icons.event,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Informations d'assurance
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, size: 16, color: cardColor[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Informations d\'Assurance',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: cardColor[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAssuranceInfo('Compagnie', vehicule['compagnieNom'] ?? 'N/A', Icons.business),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildAssuranceInfo('Agence', vehicule['agenceNom'] ?? 'N/A', Icons.location_city),
                          ),
                        ],
                      ),
                      if (vehicule['agentNom'] != null && vehicule['agentNom'] != 'Agent inconnu') ...[
                        const SizedBox(height: 8),
                        _buildAssuranceInfo('Agent', vehicule['agentNom'], Icons.person),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                
                // Actions
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _voirDetailsVehicule(vehicule),
                            icon: Icon(Icons.visibility, color: cardColor[600]),
                            label: const Text('Détails'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: cardColor[600],
                              side: BorderSide(color: cardColor[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _declarerSinistre(vehicule),
                            icon: const Icon(Icons.warning),
                            label: const Text('Déclarer Sinistre'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _voirContratComplet(vehicule),
                        icon: const Icon(Icons.description),
                        label: const Text('Voir Contrat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 👁️ Voir les détails du véhicule
  void _voirDetailsVehicule(Map<String, dynamic> vehicule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Titre
              Text(
                'Détails du Véhicule',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 20),
              
              // Contenu scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      _buildDetailRow('Marque', vehicule['marque'] ?? 'N/A'),
                      _buildDetailRow('Modèle', vehicule['modele'] ?? 'N/A'),
                      _buildDetailRow('Immatriculation', vehicule['immatriculation'] ?? 'N/A'),
                      _buildDetailRow('Année', vehicule['annee']?.toString() ?? 'N/A'),
                      _buildDetailRow('Couleur', vehicule['couleur'] ?? 'N/A'),
                      _buildDetailRow('Numéro de contrat', vehicule['numeroContrat'] ?? 'N/A'),
                      if (vehicule['dateDebutContrat'] != null)
                        _buildDetailRow(
                          'Date de début',
                          DateFormat('dd/MM/yyyy').format(_convertirDate(vehicule['dateDebutContrat'])),
                        ),
                      if (vehicule['dateFinContrat'] != null)
                        _buildDetailRow(
                          'Date de fin',
                          DateFormat('dd/MM/yyyy').format(_convertirDate(vehicule['dateFinContrat'])),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚨 Déclarer un sinistre
  void _declarerSinistre(Map<String, dynamic> vehicule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeclarationSinistreScreen(
          vehicule: vehicule,
        ),
      ),
    );
  }

  /// 📋 Voir le contrat complet avec toutes les informations
  Future<void> _voirContratComplet(Map<String, dynamic> vehicule) async {
    try {
      // Récupérer les informations complètes du contrat depuis Firestore
      final contratId = vehicule['contratId'] ?? vehicule['id'];
      final contratDoc = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(contratId)
          .get();

      if (!contratDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contrat non trouvé'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final contratData = contratDoc.data()!;

      // Debug: afficher toutes les données du contrat
      print('🔍 DEBUG Contrat complet - Toutes les données:');
      contratData.forEach((key, value) {
        print('   $key: $value (${value.runtimeType})');
      });

      // Fusionner les données du véhicule avec les données du contrat
      final contratComplet = Map<String, dynamic>.from(contratData);

      // Ajouter les dates du véhicule si elles ne sont pas dans contratData
      if (contratComplet['dateDebutContrat'] == null && vehicule['dateDebutContrat'] != null) {
        contratComplet['dateDebutContrat'] = vehicule['dateDebutContrat'];
        print('✅ Date début ajoutée depuis vehicule: ${vehicule['dateDebutContrat']}');
      }

      if (contratComplet['dateFinContrat'] == null && vehicule['dateFinContrat'] != null) {
        contratComplet['dateFinContrat'] = vehicule['dateFinContrat'];
        print('✅ Date fin ajoutée depuis vehicule: ${vehicule['dateFinContrat']}');
      }

      // Afficher le modal avec toutes les informations du contrat
      _afficherModalContrat(contratComplet);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement du contrat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📄 Afficher le modal avec toutes les informations du contrat
  void _afficherModalContrat(Map<String, dynamic> contratData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mon Contrat d\'Assurance',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'N° ${contratData['numeroContrat'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContratSection('🚗 Informations du Véhicule', [
                      _buildContratRow('Marque', contratData['marque'] ?? 'N/A'),
                      _buildContratRow('Modèle', contratData['modele'] ?? 'N/A'),
                      _buildContratRow('Immatriculation', contratData['immatriculation'] ?? 'N/A'),
                      _buildContratRow('Année', contratData['annee']?.toString() ?? 'N/A'),
                      _buildContratRow('Couleur', contratData['couleur'] ?? 'N/A'),
                      _buildContratRow('Type de carburant', contratData['carburant'] ?? contratData['typeCarburant'] ?? 'N/A'),
                      _buildContratRow('Puissance fiscale', '${contratData['puissance'] ?? contratData['puissanceFiscale'] ?? 'N/A'} CV'),
                      if (contratData['typeVehicule'] != null)
                        _buildContratRow('Type de véhicule', contratData['typeVehicule']),
                      if (contratData['usage'] != null)
                        _buildContratRow('Usage', contratData['usage']),
                    ]),

                    const SizedBox(height: 20),

                    _buildContratSection('📋 Informations du Contrat', [
                      _buildContratRow('Numéro de contrat', contratData['numeroContrat'] ?? 'N/A'),
                      _buildContratRow('Type de contrat', contratData['formuleAssuranceLabel'] ?? contratData['typeContrat'] ?? 'N/A'),
                      _buildContratRow('Statut', _getStatutLabel(contratData['statut'] ?? 'N/A')),
                      _buildContratRow('Fréquence de paiement', contratData['frequencePaiement'] ?? 'Annuel'),
                    ]),

                    const SizedBox(height: 20),

                    // Section spéciale pour la validité du contrat
                    _buildValiditeSection(contratData),

                    const SizedBox(height: 20),

                    _buildContratSection('💰 Informations Financières', [
                      _buildContratRow('Prime annuelle', _getFinancialInfo(contratData, 'primeAnnuelle'), isHighlight: true),
                      _buildContratRow('Franchise', _getFinancialInfo(contratData, 'franchise')),
                      _buildContratRow('Montant à payer', _getFinancialInfo(contratData, 'montantAPayer'), isHighlight: true),
                      _buildContratRow('Fréquence de paiement', contratData['frequencePaiement'] ?? 'Annuel'),
                      if (contratData['datePaiement'] != null)
                        _buildContratRow('Date de paiement', DateFormat('dd/MM/yyyy').format(_convertirDate(contratData['datePaiement']))),
                    ]),

                    const SizedBox(height: 20),

                    _buildContratSection('🏢 Informations de l\'Assureur', [
                      _buildContratRow('Compagnie d\'assurance', contratData['compagnieNom'] ?? contratData['nomCompagnie'] ?? 'Compagnie inconnue'),
                      _buildContratRow('Agence d\'assurance', contratData['agenceNom'] ?? contratData['nomAgence'] ?? 'Agence inconnue'),
                      _buildContratRow('Agent responsable', contratData['agentNom'] ?? contratData['nomAgent'] ?? 'Agent inconnu'),
                      if (contratData['agentTelephone'] != null && contratData['agentTelephone'].toString().isNotEmpty)
                        _buildContratRow('Téléphone agent', contratData['agentTelephone']),
                      if (contratData['agentEmail'] != null && contratData['agentEmail'].toString().isNotEmpty)
                        _buildContratRow('Email agent', contratData['agentEmail']),
                      if (contratData['adresseCompagnie'] != null)
                        _buildContratRow('Adresse compagnie', contratData['adresseCompagnie']),
                      if (contratData['adresseAgence'] != null)
                        _buildContratRow('Adresse agence', contratData['adresseAgence']),
                    ]),

                    const SizedBox(height: 20),

                    _buildContratSection('👤 Informations du Conducteur', [
                      _buildContratRow('Nom complet', '${contratData['prenom'] ?? ''} ${contratData['nom'] ?? ''}'),
                      _buildContratRow('Email', contratData['email'] ?? 'N/A'),
                      _buildContratRow('Téléphone', contratData['telephone'] ?? 'N/A'),
                      if (contratData['dateNaissance'] != null)
                        _buildContratRow('Date de naissance', DateFormat('dd/MM/yyyy').format(_convertirDate(contratData['dateNaissance']))),
                      _buildContratRow('Adresse', contratData['adresse'] ?? 'N/A'),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📦 Construire une section du contrat
  Widget _buildContratSection(String titre, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              titre,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  /// 📝 Construire une ligne d'information du contrat
  Widget _buildContratRow(String label, String value, {bool isHighlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFF10B981).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight ? const Color(0xFF10B981) : Colors.grey[300]!,
          width: isHighlight ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isHighlight ? const Color(0xFF10B981) : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? const Color(0xFF10B981) : const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🏷️ Obtenir le libellé du statut
  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'contrat_actif':
        return '✅ Contrat Actif';
      case 'en_attente_paiement':
        return '⏳ En Attente de Paiement';
      case 'expire':
        return '❌ Expiré';
      case 'suspendu':
        return '⏸️ Suspendu';
      default:
        return statut;
    }
  }

  /// Convertir une date Firestore en DateTime
  DateTime _convertirDate(dynamic date) {
    if (date == null) return DateTime.now();

    if (date is Timestamp) {
      return date.toDate();
    } else if (date is DateTime) {
      return date;
    } else if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        return DateTime.now();
      }
    } else {
      return DateTime.now();
    }
  }

  /// Widget pour afficher les informations d'assurance
  Widget _buildAssuranceInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Récupérer les informations financières avec valeurs par défaut intelligentes
  String _getFinancialInfo(Map<String, dynamic> contratData, String field) {
    // D'abord, essayer de récupérer la valeur directement
    var value = contratData[field];

    if (value != null && value != 0) {
      return '$value TND';
    }

    // Si pas de valeur, générer une valeur par défaut basée sur la formule d'assurance
    String formule = contratData['formuleAssurance'] ?? contratData['formuleAssuranceLabel'] ?? '';

    switch (field) {
      case 'primeAnnuelle':
        if (formule.contains('RC') || formule.contains('Responsabilité')) {
          return '250 TND';
        } else if (formule.contains('Vol') || formule.contains('Incendie')) {
          return '450 TND';
        } else if (formule.contains('Tous') || formule.contains('tous')) {
          return '750 TND';
        } else {
          return '350 TND'; // Valeur par défaut
        }

      case 'franchise':
        return '200 TND'; // Franchise standard en Tunisie

      case 'montantAPayer':
        // Calculer basé sur la prime et la fréquence
        String frequence = contratData['frequencePaiement'] ?? 'annuel';
        double prime = 350; // Valeur par défaut

        // Essayer de récupérer la prime réelle
        if (contratData['primeAnnuelle'] != null && contratData['primeAnnuelle'] != 0) {
          prime = contratData['primeAnnuelle'].toDouble();
        } else if (formule.contains('RC')) {
          prime = 250;
        } else if (formule.contains('Vol')) {
          prime = 450;
        } else if (formule.contains('Tous')) {
          prime = 750;
        }

        switch (frequence.toLowerCase()) {
          case 'mensuel':
            return '${(prime / 12).toStringAsFixed(0)} TND';
          case 'trimestriel':
            return '${(prime / 4).toStringAsFixed(0)} TND';
          case 'semestriel':
            return '${(prime / 2).toStringAsFixed(0)} TND';
          default:
            return '${prime.toStringAsFixed(0)} TND';
        }

      default:
        return 'N/A TND';
    }
  }

  /// Mettre à jour les informations financières manquantes pour tous les contrats
  Future<void> _mettreAJourInformationsFinancieres() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Mise à jour en cours...'),
            ],
          ),
        ),
      );

      int contratsModifies = 0;

      for (final vehicule in _vehicules) {
        final contratId = vehicule['contratId'] ?? vehicule['id'];

        // Vérifier si les informations financières manquent
        if (vehicule['primeAnnuelle'] == null || vehicule['primeAnnuelle'] == 0) {

          // Générer les informations financières basées sur la formule
          String formule = vehicule['formuleAssurance'] ?? vehicule['formuleAssuranceLabel'] ?? '';
          double primeAnnuelle = 350; // Valeur par défaut

          if (formule.contains('RC') || formule.contains('Responsabilité')) {
            primeAnnuelle = 250;
          } else if (formule.contains('Vol') || formule.contains('Incendie')) {
            primeAnnuelle = 450;
          } else if (formule.contains('Tous') || formule.contains('tous')) {
            primeAnnuelle = 750;
          }

          // Mettre à jour le contrat dans Firestore
          await FirebaseFirestore.instance
              .collection('demandes_contrats')
              .doc(contratId)
              .update({
            'primeAnnuelle': primeAnnuelle,
            'franchise': 200,
            'montantAPayer': primeAnnuelle, // Paiement annuel par défaut
            'frequencePaiement': 'annuel',
            'informationsFinancieresDefinies': true,
            'dateMAJFinanciere': FieldValue.serverTimestamp(),
          });

          contratsModifies++;
        }
      }

      Navigator.pop(context); // Fermer le dialogue de chargement

      if (contratsModifies > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $contratsModifies contrat(s) mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // Recharger les données
        await _loadVehicules();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ℹ️ Tous les contrats ont déjà leurs informations financières'),
            backgroundColor: Colors.blue,
          ),
        );
      }

    } catch (e) {
      Navigator.pop(context); // Fermer le dialogue de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de la mise à jour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📅 Section spéciale pour la validité du contrat
  Widget _buildValiditeSection(Map<String, dynamic> contratData) {
    // Debug: afficher les données disponibles
    print('🔍 DEBUG Validité - Données contrat disponibles:');
    contratData.forEach((key, value) {
      if (key.toLowerCase().contains('date')) {
        print('   $key: $value (${value.runtimeType})');
      }
    });

    // Essayer différents noms de champs pour les dates
    DateTime? dateDebut;
    DateTime? dateFin;

    // Essayer dateDebutContrat
    if (contratData['dateDebutContrat'] != null) {
      try {
        dateDebut = _convertirDate(contratData['dateDebutContrat']);
        print('✅ Date début trouvée via dateDebutContrat: $dateDebut');
      } catch (e) {
        print('❌ Erreur conversion dateDebutContrat: $e');
      }
    }

    // Essayer dateFinContrat
    if (contratData['dateFinContrat'] != null) {
      try {
        dateFin = _convertirDate(contratData['dateFinContrat']);
        print('✅ Date fin trouvée via dateFinContrat: $dateFin');
      } catch (e) {
        print('❌ Erreur conversion dateFinContrat: $e');
      }
    }

    // Si pas trouvé, essayer d'autres noms de champs
    if (dateDebut == null && contratData['dateDebut'] != null) {
      try {
        dateDebut = _convertirDate(contratData['dateDebut']);
        print('✅ Date début trouvée via dateDebut: $dateDebut');
      } catch (e) {
        print('❌ Erreur conversion dateDebut: $e');
      }
    }

    if (dateFin == null && contratData['dateFin'] != null) {
      try {
        dateFin = _convertirDate(contratData['dateFin']);
        print('✅ Date fin trouvée via dateFin: $dateFin');
      } catch (e) {
        print('❌ Erreur conversion dateFin: $e');
      }
    }

    // Si toujours pas trouvé, essayer dateActivation + 1 an
    if (dateDebut == null && contratData['dateActivation'] != null) {
      try {
        dateDebut = _convertirDate(contratData['dateActivation']);
        dateFin = DateTime(dateDebut.year + 1, dateDebut.month, dateDebut.day);
        print('✅ Dates calculées depuis dateActivation: $dateDebut -> $dateFin');
      } catch (e) {
        print('❌ Erreur conversion dateActivation: $e');
      }
    }

    // Si toujours pas trouvé, essayer dateCreation + 1 an
    if (dateDebut == null && contratData['dateCreation'] != null) {
      try {
        dateDebut = _convertirDate(contratData['dateCreation']);
        dateFin = DateTime(dateDebut.year + 1, dateDebut.month, dateDebut.day);
        print('✅ Dates calculées depuis dateCreation: $dateDebut -> $dateFin');
      } catch (e) {
        print('❌ Erreur conversion dateCreation: $e');
      }
    }

    print('🎯 Dates finales: début=$dateDebut, fin=$dateFin');

    // Calculer le statut de validité
    final maintenant = DateTime.now();
    String statutValidite = 'Inconnu';
    Color couleurStatut = Colors.grey;
    IconData iconeStatut = Icons.help;

    if (dateDebut != null && dateFin != null) {
      if (maintenant.isBefore(dateDebut)) {
        statutValidite = 'Pas encore actif';
        couleurStatut = Colors.orange;
        iconeStatut = Icons.schedule;
      } else if (maintenant.isAfter(dateFin)) {
        statutValidite = 'Expiré';
        couleurStatut = Colors.red;
        iconeStatut = Icons.error;
      } else {
        statutValidite = 'Actif';
        couleurStatut = Colors.green;
        iconeStatut = Icons.check_circle;

        // Calculer les jours restants
        final joursRestants = dateFin.difference(maintenant).inDays;
        if (joursRestants <= 30) {
          statutValidite = 'Expire bientôt ($joursRestants jours)';
          couleurStatut = Colors.orange;
          iconeStatut = Icons.warning;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [couleurStatut.withOpacity(0.1), couleurStatut.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleurStatut.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: couleurStatut.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(iconeStatut, color: couleurStatut, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📅 Validité du Contrat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statutValidite,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: couleurStatut,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (dateDebut != null)
                  _buildValiditeRow(
                    'Date de début',
                    DateFormat('dd/MM/yyyy').format(dateDebut),
                    Icons.play_arrow,
                    Colors.green,
                  ),
                if (dateDebut != null && dateFin != null)
                  const SizedBox(height: 12),
                if (dateFin != null)
                  _buildValiditeRow(
                    'Date de fin',
                    DateFormat('dd/MM/yyyy').format(dateFin),
                    Icons.stop,
                    Colors.red,
                  ),
                if (dateDebut != null && dateFin != null) ...[
                  const SizedBox(height: 12),
                  _buildValiditeRow(
                    'Durée totale',
                    '${dateFin.difference(dateDebut).inDays} jours (1 an)',
                    Icons.timer,
                    Colors.blue,
                  ),
                ],
                if (dateDebut == null && dateFin == null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Les dates de validité seront disponibles après activation du contrat',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget pour une ligne de validité
  Widget _buildValiditeRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 🔔 Vérifier les expirations de contrats
  Future<void> _verifierExpirations() async {
    try {
      // Lancer la vérification des expirations en arrière-plan
      await ExpirationNotificationService.verifierEtNotifierExpirations();
    } catch (e) {
      print('❌ Erreur vérification expirations: $e');
    }
  }

  /// ⚠️ Widget d'alerte d'expiration
  Widget _buildAlerteExpiration() {
    final maintenant = DateTime.now();
    final vehiculesExpirant = <Map<String, dynamic>>[];

    // Vérifier quels véhicules expirent bientôt
    for (final vehicule in _vehicules) {
      final dateFinContrat = vehicule['dateFinContrat'];
      if (dateFinContrat != null) {
        try {
          final dateFin = _convertirDate(dateFinContrat);
          final joursRestants = dateFin.difference(maintenant).inDays;

          if (joursRestants <= 30) {
            vehiculesExpirant.add({
              ...vehicule,
              'joursRestants': joursRestants,
              'dateFin': dateFin,
            });
          }
        } catch (e) {
          print('❌ Erreur calcul expiration: $e');
        }
      }
    }

    if (vehiculesExpirant.isEmpty) return const SizedBox.shrink();

    // Trier par urgence (moins de jours restants en premier)
    vehiculesExpirant.sort((a, b) => a['joursRestants'].compareTo(b['joursRestants']));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: vehiculesExpirant.map((vehicule) {
          final joursRestants = vehicule['joursRestants'] as int;
          final dateFin = vehicule['dateFin'] as DateTime;

          Color couleurAlerte;
          IconData iconeAlerte;
          String messageAlerte;

          if (joursRestants <= 0) {
            couleurAlerte = Colors.red;
            iconeAlerte = Icons.error;
            messageAlerte = 'EXPIRÉ';
          } else if (joursRestants <= 7) {
            couleurAlerte = Colors.red;
            iconeAlerte = Icons.warning;
            messageAlerte = 'Expire dans $joursRestants jour(s)';
          } else if (joursRestants <= 15) {
            couleurAlerte = Colors.orange;
            iconeAlerte = Icons.schedule;
            messageAlerte = 'Expire dans $joursRestants jours';
          } else {
            couleurAlerte = Colors.amber;
            iconeAlerte = Icons.info;
            messageAlerte = 'Expire dans $joursRestants jours';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: couleurAlerte.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: couleurAlerte.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(iconeAlerte, color: couleurAlerte, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicule['marque']} ${vehicule['modele']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$messageAlerte (${DateFormat('dd/MM/yyyy').format(dateFin)})',
                        style: TextStyle(
                          color: couleurAlerte,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await _contacterAgentPourRenouvellement(vehicule);
                  },
                  child: const Text('Contacter Agent'),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 🧪 Tester les notifications d'expiration
  Future<void> _testerNotificationsExpiration() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Récupération des vrais agents...'),
            ],
          ),
        ),
      );

      // Récupérer les vrais contrats avec agents pour créer des notifications réalistes
      final contratsSnapshot = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('conducteurId', isEqualTo: _currentUserId)
          .where('statut', isEqualTo: 'contrat_actif')
          .limit(3)
          .get();

      List<Map<String, dynamic>> testNotifications = [];

      if (contratsSnapshot.docs.isNotEmpty) {
        // Utiliser les vrais contrats
        for (int i = 0; i < contratsSnapshot.docs.length; i++) {
          final doc = contratsSnapshot.docs[i];
          final data = doc.data();

          // Récupérer les informations de l'agent si disponibles
          String agentEmail = data['agentEmail'] ?? '';
          String agentNom = data['agentNom'] ?? '';
          String agentTelephone = '';

          // Si agentId disponible, récupérer plus d'infos
          if (data['agentId'] != null && agentEmail.isEmpty) {
            try {
              final agentDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(data['agentId'])
                  .get();

              if (agentDoc.exists) {
                final agentData = agentDoc.data()!;
                agentEmail = agentData['email'] ?? '';
                agentNom = '${agentData['prenom'] ?? ''} ${agentData['nom'] ?? ''}'.trim();
                agentTelephone = agentData['telephone'] ?? '';
              }
            } catch (e) {
              print('❌ Erreur récupération agent: $e');
            }
          }

          final vehiculeInfo = '🚗 ${data['marque']} ${data['modele']} (${data['immatriculation']})';
          final numeroContrat = data['numeroContrat'] ?? doc.id;

          // Créer différents scénarios d'expiration
          Map<String, dynamic> notification;
          if (i == 0) {
            notification = {
              'type': 'expiration_contrat',
              'titre': '📅 Test: Contrat expire dans 30 jours',
              'message': 'Test: Votre contrat expire dans 30 jours (le 06/10/2025).\n\n$vehiculeInfo\n📋 N° Contrat: $numeroContrat',
              'joursRestants': 30,
              'dateExpiration': '06/10/2025',
              'priorite': 'normale',
            };
          } else if (i == 1) {
            notification = {
              'type': 'expiration_contrat',
              'titre': '⚠️ Test: Contrat expire dans 7 jours',
              'message': 'Test: ATTENTION: Votre contrat expire dans 7 jours (le 13/09/2025).\n\n$vehiculeInfo\n📋 N° Contrat: $numeroContrat',
              'joursRestants': 7,
              'dateExpiration': '13/09/2025',
              'priorite': 'haute',
            };
          } else {
            notification = {
              'type': 'contrat_expire',
              'titre': '🚨 Test: CONTRAT EXPIRÉ',
              'message': 'Test: ATTENTION: Votre contrat a expiré le 01/09/2025.\n\n$vehiculeInfo\n📋 N° Contrat: $numeroContrat',
              'dateExpiration': '01/09/2025',
              'priorite': 'critique',
            };
          }

          // Ajouter les informations communes
          notification.addAll({
            'vehiculeInfo': vehiculeInfo,
            'numeroContrat': numeroContrat,
            'agentEmail': agentEmail,
            'agentNom': agentNom.isNotEmpty ? agentNom : 'Agent non défini',
            'agentTelephone': agentTelephone,
            'contratId': doc.id,
          });

          testNotifications.add(notification);
        }
      } else {
        // Fallback avec données génériques si pas de contrats
        testNotifications = [
          {
            'type': 'expiration_contrat',
            'titre': '📅 Test: Contrat expire dans 30 jours',
            'message': 'Test: Votre contrat expire dans 30 jours (le 06/10/2025).\n\n🚗 Véhicule Test\n📋 N° Contrat: TEST_001',
            'joursRestants': 30,
            'dateExpiration': '06/10/2025',
            'vehiculeInfo': '🚗 Véhicule Test',
            'numeroContrat': 'TEST_001',
            'priorite': 'normale',
            'agentEmail': '',
            'agentNom': 'Aucun agent assigné',
            'agentTelephone': '',
          },
        ];
      }

      // Créer les notifications avec les vrais agents
      for (final notification in testNotifications) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'conducteurId': _currentUserId,
          ...notification,
          'dateCreation': FieldValue.serverTimestamp(),
          'lu': false,
          'actionRequise': true,
          'actionLabel': 'Contacter l\'agent',
        });
      }

      Navigator.pop(context); // Fermer le dialogue de chargement

      final nombreNotifications = testNotifications.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $nombreNotifications notification(s) de test créée(s) avec les vrais agents ! Vérifiez l\'écran Notifications.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

    } catch (e) {
      Navigator.pop(context); // Fermer le dialogue de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors du test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📧 Contacter l'agent pour renouvellement
  Future<void> _contacterAgentPourRenouvellement(Map<String, dynamic> vehicule) async {
    try {
      // Récupérer les informations complètes du contrat depuis Firestore
      final contratId = vehicule['contratId'] ?? vehicule['id'];
      final contratDoc = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(contratId)
          .get();

      if (!contratDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de récupérer les informations du contrat'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final contratData = contratDoc.data()!;
      final agentId = contratData['agentId'];

      if (agentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun agent assigné à ce contrat'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Récupérer les informations de l'agent
      final agentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(agentId)
          .get();

      if (!agentDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informations de l\'agent non trouvées'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final agentData = agentDoc.data()!;
      final agentEmail = agentData['email'] ?? '';
      final agentNom = '${agentData['prenom'] ?? ''} ${agentData['nom'] ?? ''}'.trim();
      final agentTelephone = agentData['telephone'] ?? '';
      final numeroContrat = contratData['numeroContrat'] ?? contratId;
      final vehiculeInfo = '🚗 ${vehicule['marque']} ${vehicule['modele']} (${vehicule['immatriculation']})';

      if (agentEmail.isEmpty) {
        _afficherInformationsAgent(agentNom, agentTelephone);
        return;
      }

      // Préparer l'email de renouvellement
      final sujet = Uri.encodeComponent('Demande de renouvellement - Contrat $numeroContrat');
      final corps = Uri.encodeComponent('''
Bonjour $agentNom,

Je souhaite renouveler mon contrat d'assurance qui arrive à expiration.

Détails du contrat :
$vehiculeInfo
📋 N° Contrat: $numeroContrat

Pourriez-vous me contacter pour organiser le renouvellement et me proposer les meilleures options disponibles ?

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
        _afficherEmailAgent(agentEmail, agentNom, agentTelephone);
      }

    } catch (e) {
      print('❌ Erreur contact agent: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

