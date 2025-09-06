import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/sinistre_tracking_service.dart';
import 'accident_invitation_screen.dart';
import '../../features/sinistre/screens/accident_type_selection_screen.dart';

/// 🚗 Écran de sélection de véhicule pour déclarer un sinistre
class AccidentVehicleSelectionScreen extends StatefulWidget {
  const AccidentVehicleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<AccidentVehicleSelectionScreen> createState() => _AccidentVehicleSelectionScreenState();
}

class _AccidentVehicleSelectionScreenState extends State<AccidentVehicleSelectionScreen> {
  List<Map<String, dynamic>> _vehicules = [];
  Map<String, dynamic>? _selectedVehicle;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicules();
  }

  /// 🔄 Charger les véhicules de l'utilisateur
  Future<void> _loadVehicules() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Charger depuis demandes_contrats (contrats actifs)
      final snapshot = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('conducteurId', isEqualTo: user.uid)
          .where('statut', isEqualTo: 'contrat_actif')
          .get();

      final vehicules = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        vehicules.add({
          'id': doc.id,
          'marque': data['marque'] ?? '',
          'modele': data['modele'] ?? '',
          'immatriculation': data['immatriculation'] ?? '',
          'couleur': data['couleur'] ?? '',
          'numeroPolice': data['numeroPolice'] ?? '',
          'compagnieAssurance': data['compagnieAssurance'] ?? '',
          'agenceAssurance': data['agenceAssurance'] ?? '',
        });
      }

      setState(() {
        _vehicules = vehicules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur lors du chargement des véhicules: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Sélectionner votre véhicule'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicules.isEmpty
              ? _buildNoVehiclesState()
              : _buildVehiclesList(),
      bottomNavigationBar: _selectedVehicle != null
          ? _buildContinueButton()
          : null,
    );
  }

  /// 📋 Liste des véhicules
  Widget _buildVehiclesList() {
    return Column(
      children: [
        // En-tête
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[600],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.directions_car,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Choisissez le véhicule impliqué',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sélectionnez votre véhicule pour continuer',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),

        // Liste des véhicules
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _vehicules.length,
            itemBuilder: (context, index) {
              final vehicule = _vehicules[index];
              final isSelected = _selectedVehicle?['id'] == vehicule['id'];
              
              return _buildVehicleCard(vehicule, isSelected);
            },
          ),
        ),
      ],
    );
  }

  /// 🚗 Carte de véhicule
  Widget _buildVehicleCard(Map<String, dynamic> vehicule, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedVehicle = vehicule),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icône véhicule
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: isSelected ? Colors.blue[600] : Colors.grey[600],
                    size: 30,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Infos véhicule
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicule['marque']} ${vehicule['modele']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue[800] : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicule['immatriculation'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicule['couleur'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Indicateur de sélection
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ❌ État aucun véhicule
  Widget _buildNoVehiclesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun véhicule assuré',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous devez d\'abord souscrire une assurance pour déclarer un sinistre',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ▶️ Bouton continuer
  Widget _buildContinueButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _continueToInvitation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Continuer → Inviter les autres conducteurs',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// ▶️ Continuer vers l'invitation
  Future<void> _continueToInvitation() async {
    if (_selectedVehicle == null) return;

    try {
      // Créer un sinistre avec le véhicule sélectionné
      final user = FirebaseAuth.instance.currentUser!;
      final sinistreId = await SinistreTrackingService.createSinistreWithTracking(
        conducteurId: user.uid,
        type: 'accident_route',
        description: 'Accident impliquant ${_selectedVehicle!['marque']} ${_selectedVehicle!['modele']}',
        metadata: {
          'vehicule_selectionne': _selectedVehicle,
          'workflow_step': 'vehicle_selected',
        },
      );

      if (sinistreId != null) {
        // Naviguer vers la sélection du type d'accident
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccidentTypeSelectionScreen(
              sinistreId: sinistreId,
              vehiculeSelectionne: _selectedVehicle!,
            ),
          ),
        );
      } else {
        _showError('Erreur lors de la création du sinistre');
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  /// ❌ Afficher erreur
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
