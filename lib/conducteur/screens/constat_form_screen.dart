import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../common/widgets/custom_app_bar.dart';
import '../../common/widgets/gradient_background.dart';
import '../../services/modern_sinistre_service.dart';

/// 📋 Écran principal du formulaire de constat
class ConstatFormScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final Map<String, dynamic> vehiculeSelectionne;
  final bool isInscrit;
  final Map<String, dynamic>? conducteurData;

  const ConstatFormScreen({
    Key? key,
    required this.sessionData,
    required this.vehiculeSelectionne,
    required this.isInscrit,
    this.conducteurData,
  }) : super(key: key);

  @override
  State<ConstatFormScreen> createState() => _ConstatFormScreenState();
}

class _ConstatFormScreenState extends State<ConstatFormScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  // Données du formulaire
  final Map<String, dynamic> _formData = {};
  
  // Statuts de completion des onglets
  final Map<int, bool> _tabCompleted = {
    0: false, // Informations générales
    1: false, // Circonstances
    2: false, // Croquis
    3: false, // Consultation autres
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeFormData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeFormData() {
    _formData.addAll({
      'sessionData': widget.sessionData,
      'vehiculeSelectionne': widget.vehiculeSelectionne,
      'isInscrit': widget.isInscrit,
      'conducteurData': widget.conducteurData,
      'dateAccident': widget.sessionData['dateAccident'],
      'heureAccident': widget.sessionData['heureAccident'],
      'lieuAccident': widget.sessionData['localisation']?['adresse'] ?? '',
      'lieuGps': widget.sessionData['localisation']?['coordinates'] ?? '',
    });
  }

  void _updateTabCompletion(int tabIndex, bool completed) {
    setState(() {
      _tabCompleted[tabIndex] = completed;
    });
  }

  bool get _canSubmit {
    return _tabCompleted.values.every((completed) => completed);
  }

  Future<void> _soumettreConstat() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez compléter tous les onglets avant de soumettre'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Préparer les données pour la création du sinistre
      final conducteurs = [
        {
          'id': widget.isInscrit
              ? FirebaseAuth.instance.currentUser?.uid
              : 'invite_${DateTime.now().millisecondsSinceEpoch}',
          'isInscrit': widget.isInscrit,
          'aRejoint': true,
          'formulaireComplete': true,
          'vehicule': widget.vehiculeSelectionne,
          'conducteurData': widget.conducteurData,
          'agenceId': widget.isInscrit
              ? (widget.conducteurData?['agenceId'] ?? '')
              : (widget.vehiculeSelectionne['agenceId'] ?? ''),
          'compagnieId': widget.isInscrit
              ? (widget.conducteurData?['compagnieId'] ?? '')
              : (widget.vehiculeSelectionne['compagnieId'] ?? ''),
        },
      ];

      // Créer le sinistre
      final sinistreId = await ModernSinistreService.creerSinistre(
        sessionId: widget.sessionData['id'] ?? '',
        codeSession: widget.sessionData['codePublic'] ?? '',
        accidentData: _formData,
        conducteurs: conducteurs,
        croquisData: _formData['croquisData'] ?? {},
        photos: List<String>.from(_formData['photos'] ?? []),
      );

      // Afficher le succès
      _showSuccessDialog(sinistreId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String sinistreId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Constat Envoyé'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Votre constat a été envoyé avec succès à votre agence d\'assurance.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Numéro de sinistre:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(sinistreId),
                  const SizedBox(height: 8),
                  const Text('Statut:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text('En attente de traitement par l\'agence'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Retour au tableau de bord'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Constat d\'Accident',
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  if (_canSubmit)
                    IconButton(
                      onPressed: _isLoading ? null : _soumettreConstat,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                ],
              ),
              _buildSessionInfo(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoGeneralesTab(),
                    _buildCirconstancesTab(),
                    _buildCroquisTab(),
                    _buildConsultationTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Session: ${widget.sessionData['codePublic'] ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isInscrit ? Colors.green[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.isInscrit ? 'Conducteur inscrit' : 'Conducteur invité',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.isInscrit ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Véhicule: ${widget.vehiculeSelectionne['marque']} ${widget.vehiculeSelectionne['modele']} (${widget.vehiculeSelectionne['immatriculation']})',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue[600],
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue[600],
        indicatorWeight: 3,
        tabs: [
          _buildTab(0, 'Infos', Icons.info_outline),
          _buildTab(1, 'Circonstances', Icons.description_outlined),
          _buildTab(2, 'Croquis', Icons.draw_outlined),
          _buildTab(3, 'Consultation', Icons.visibility_outlined),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isCompleted = _tabCompleted[index] ?? false;
    return Tab(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Icon(icon),
              if (isCompleted)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGeneralesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            'Informations de l\'accident',
            [
              _buildInfoRow('Date', _formData['dateAccident']?.toString() ?? 'Non spécifiée'),
              _buildInfoRow('Heure', _formData['heureAccident'] ?? 'Non spécifiée'),
              _buildInfoRow('Lieu', _formData['lieuAccident'] ?? 'Non spécifié'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Votre véhicule',
            [
              _buildInfoRow('Marque', widget.vehiculeSelectionne['marque'] ?? ''),
              _buildInfoRow('Modèle', widget.vehiculeSelectionne['modele'] ?? ''),
              _buildInfoRow('Immatriculation', widget.vehiculeSelectionne['immatriculation'] ?? ''),
              _buildInfoRow('Année', widget.vehiculeSelectionne['annee']?.toString() ?? ''),
            ],
          ),
          const SizedBox(height: 16),
          if (!widget.isInscrit && widget.conducteurData != null)
            _buildInfoCard(
              'Vos informations',
              [
                _buildInfoRow('Nom', '${widget.conducteurData!['prenom']} ${widget.conducteurData!['nom']}'),
                _buildInfoRow('Email', widget.conducteurData!['email'] ?? ''),
                _buildInfoRow('Téléphone', widget.conducteurData!['telephone'] ?? ''),
                _buildInfoRow('CIN', widget.conducteurData!['cin'] ?? ''),
              ],
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _updateTabCompletion(0, true),
            child: const Text('Valider les informations'),
          ),
        ],
      ),
    );
  }

  Widget _buildCirconstancesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Circonstances de l\'accident',
            [
              const Text(
                'Décrivez les circonstances de l\'accident en cochant les cases appropriées:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCirconstancesCheckboxes(),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Description libre',
            [
              TextFormField(
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Décrivez l\'accident avec vos propres mots...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _formData['description'] = value,
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _updateTabCompletion(1, true),
            child: const Text('Valider les circonstances'),
          ),
        ],
      ),
    );
  }

  Widget _buildCroquisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            'Croquis de l\'accident',
            [
              const Text(
                'Le croquis sera partagé avec tous les participants de la session.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.draw, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Zone de dessin du croquis'),
                  Text('(À implémenter)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implémenter l'accord du croquis
                  },
                  icon: const Icon(Icons.check, color: Colors.green),
                  label: const Text('Approuver'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implémenter le désaccord du croquis
                  },
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Contester'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _updateTabCompletion(2, true),
            child: const Text('Valider le croquis'),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            'Consultation des autres conducteurs',
            [
              const Text(
                'Vous pouvez consulter les informations des autres participants sans les modifier.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAutresConducteursListe(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _updateTabCompletion(3, true),
            child: const Text('Terminer la consultation'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
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
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCirconstancesCheckboxes() {
    final circonstances = [
      'Stationnait',
      'Quittait un stationnement',
      'Prenait un stationnement',
      'Sortait d\'un parking',
      'Entrait dans un parking',
      'Circulait',
      'Changeait de file',
      'Doublait',
      'Virait à droite',
      'Virait à gauche',
      'Reculait',
      'Empiétait sur une file réservée à la circulation en sens inverse',
      'Venait de droite dans un carrefour',
      'N\'avait pas observé un signal de priorité ou un feu rouge',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: circonstances.map((circonstance) {
          return CheckboxListTile(
            title: Text(circonstance),
            value: _formData['circonstances_$circonstance'] ?? false,
            onChanged: (value) {
              setState(() {
                _formData['circonstances_$circonstance'] = value ?? false;
              });
            },
            dense: true,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAutresConducteursListe() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Aucun autre conducteur n\'a encore rejoint cette session.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Les informations des autres participants apparaîtront ici une fois qu\'ils auront rejoint la session.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
