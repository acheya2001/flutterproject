import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/accident_session_complete.dart';
import '../../models/vehicule_model.dart';
import '../../services/accident_session_complete_service.dart';
import '../../services/photo_upload_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/vehicule_service.dart';
import 'accident_form_step3_assurance.dart';

/// 🚗 Étape 2 : Informations des véhicules (selon constat papier)
class AccidentFormStep2Vehicules extends StatefulWidget {
  final AccidentSessionComplete session;
  final Map<String, dynamic>? vehiculeSelectionne;

  const AccidentFormStep2Vehicules({
    super.key,
    required this.session,
    this.vehiculeSelectionne,
  });

  @override
  State<AccidentFormStep2Vehicules> createState() => _AccidentFormStep2VehiculesState();
}

class _AccidentFormStep2VehiculesState extends State<AccidentFormStep2Vehicules>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _monRoleVehicule;

  // Données des véhicules
  Map<String, VehiculeFormData> _vehiculesData = {};

  // Véhicules de l'utilisateur
  List<VehiculeModel> _mesVehicules = [];
  bool _isLoadingVehicules = true;

  @override
  void initState() {
    super.initState();
    _initialiserVehicules();
    _chargerMesVehicules();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initialiserVehicules() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Trouver le rôle de l'utilisateur actuel
      final conducteur = widget.session.conducteurs.firstWhere(
        (c) => c.userId == user.uid,
        orElse: () => widget.session.conducteurs.first,
      );
      _monRoleVehicule = conducteur.roleVehicule;
    }

    // Initialiser les données pour chaque véhicule
    for (final conducteur in widget.session.conducteurs) {
      _vehiculesData[conducteur.roleVehicule] = VehiculeFormData();
    }

    // Pré-remplir avec les données existantes
    for (final vehicule in widget.session.vehicules) {
      if (_vehiculesData.containsKey(vehicule.roleVehicule)) {
        _vehiculesData[vehicule.roleVehicule]!.remplirDepuisVehicule(vehicule);
      }
    }

    _tabController = TabController(
      length: widget.session.conducteurs.length,
      vsync: this,
    );

    // Aller directement à l'onglet de l'utilisateur
    if (_monRoleVehicule != null) {
      final index = widget.session.conducteurs.indexWhere(
        (c) => c.roleVehicule == _monRoleVehicule,
      );
      if (index >= 0) {
        _tabController.index = index;
      }
    }
  }

  /// 🚗 Charger les véhicules de l'utilisateur
  Future<void> _chargerMesVehicules() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final vehicules = await VehiculeService.obtenirVehiculesUtilisateur(user.uid);
        setState(() {
          _mesVehicules = vehicules.where((v) => v.contratActif).toList();
          _isLoadingVehicules = false;
        });
        print('🚗 ${_mesVehicules.length} véhicules chargés pour sélection');
      }
    } catch (e) {
      print('❌ Erreur chargement véhicules: $e');
      setState(() {
        _isLoadingVehicules = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Informations véhicules',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: widget.session.conducteurs.map((conducteur) {
            final estMonVehicule = conducteur.roleVehicule == _monRoleVehicule;
            return Tab(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: estMonVehicule ? Colors.white.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Véhicule ${conducteur.roleVehicule}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (estMonVehicule) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, color: Colors.white, size: 16),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
          indicatorColor: Colors.white,
        ),
        actions: [
          IconButton(
            onPressed: _sauvegarder,
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de progression
          _buildProgressBar(),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: widget.session.conducteurs.map((conducteur) {
                return _buildVehiculeForm(conducteur);
              }).toList(),
            ),
          ),
          
          // Bouton suivant
          _buildBoutonSuivant(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Étape 2 sur 6',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Session: ${widget.session.codeSession}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 2 / 6,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiculeForm(ConducteurSession conducteur) {
    final vehiculeData = _vehiculesData[conducteur.roleVehicule]!;
    final estMonVehicule = conducteur.roleVehicule == _monRoleVehicule;
    final peutModifier = estMonVehicule;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du véhicule
          _buildVehiculeHeader(conducteur, estMonVehicule),

          const SizedBox(height: 24),

          // Informations du véhicule pré-sélectionné (si disponible)
          if (estMonVehicule && widget.vehiculeSelectionne != null) ...[
            _buildVehiculePreselectionne(),
            const SizedBox(height: 24),
          ] else ...[
            // Bouton de sélection de véhicule (seulement pour mon véhicule)
            if (estMonVehicule) ...[
              _buildBoutonSelectionVehicule(vehiculeData),
              const SizedBox(height: 16),
            ],

            // Informations du véhicule (seulement si pas pré-sélectionné)
            _buildInfosVehicule(vehiculeData, peutModifier),
            const SizedBox(height: 24),
          ],

          // Sens de circulation (seulement si nécessaire)
          if (estMonVehicule && widget.vehiculeSelectionne == null) ...[
            const SizedBox(height: 24),
            _buildSensCirculation(vehiculeData, peutModifier),
          ] else if (!estMonVehicule) ...[
            const SizedBox(height: 24),
            _buildSensCirculation(vehiculeData, peutModifier),
          ],
          
          const SizedBox(height: 24),
          
          // Point de choc initial
          _buildPointChoc(vehiculeData, peutModifier),
          
          const SizedBox(height: 24),
          
          // Dégâts apparents
          _buildDegatsApparents(vehiculeData, peutModifier),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildVehiculeHeader(ConducteurSession conducteur, bool estMonVehicule) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: estMonVehicule 
              ? [Colors.green[400]!, Colors.green[600]!]
              : [Colors.grey[400]!, Colors.grey[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                conducteur.roleVehicule,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Véhicule ${conducteur.roleVehicule}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${conducteur.prenom} ${conducteur.nom}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                if (estMonVehicule)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'MON VÉHICULE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          if (!estMonVehicule)
            const Icon(
              Icons.lock,
              color: Colors.white,
              size: 24,
            ),
        ],
      ),
    );
  }

  /// 🚗 Bouton pour sélectionner un véhicule existant
  Widget _buildBoutonSelectionVehicule(VehiculeFormData vehiculeData) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _afficherSelectionVehicule(vehiculeData),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sélectionner un véhicule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Choisir parmi vos véhicules assurés',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📋 Afficher la sélection de véhicule
  Future<void> _afficherSelectionVehicule(VehiculeFormData vehiculeData) async {
    if (_isLoadingVehicules) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chargement des véhicules en cours...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_mesVehicules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun véhicule trouvé. Veuillez d\'abord ajouter un véhicule.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final vehiculeSelectionne = await showModalBottomSheet<VehiculeModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Sélectionner votre véhicule',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Liste des véhicules
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _mesVehicules.length,
                itemBuilder: (context, index) {
                  final vehicule = _mesVehicules[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        '${vehicule.marque} ${vehicule.modele}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Immatriculation: ${vehicule.numeroImmatriculation}'),
                          Text('Police: ${vehicule.numeroPolice ?? "Non renseigné"}'),
                          if (vehicule.compagnieAssurance?.isNotEmpty == true)
                            Text('Assurance: ${vehicule.compagnieAssurance}'),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => Navigator.pop(context, vehicule),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (vehiculeSelectionne != null) {
      _remplirDonneesVehicule(vehiculeData, vehiculeSelectionne);
    }
  }

  /// 📝 Remplir les données du véhicule sélectionné
  void _remplirDonneesVehicule(VehiculeFormData vehiculeData, VehiculeModel vehicule) {
    setState(() {
      vehiculeData.marqueController.text = vehicule.marque;
      vehiculeData.modeleController.text = vehicule.modele;
      vehiculeData.immatriculationController.text = vehicule.numeroImmatriculation;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Véhicule "${vehicule.marque} ${vehicule.modele}" sélectionné'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildInfosVehicule(VehiculeFormData vehiculeData, bool peutModifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations du véhicule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Marque et modèle
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: vehiculeData.marqueController,
                    decoration: const InputDecoration(
                      labelText: 'Marque *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    enabled: peutModifier,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: vehiculeData.modeleController,
                    decoration: const InputDecoration(
                      labelText: 'Modèle *',
                      border: OutlineInputBorder(),
                    ),
                    enabled: peutModifier,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Immatriculation
            TextFormField(
              controller: vehiculeData.immatriculationController,
              decoration: const InputDecoration(
                labelText: 'Numéro d\'immatriculation *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
                hintText: 'Ex: 123 TUN 456',
              ),
              enabled: peutModifier,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensCirculation(VehiculeFormData vehiculeData, bool peutModifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sens de circulation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Indiquez la direction que suivait le véhicule',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: vehiculeData.sensCirculationController,
              decoration: const InputDecoration(
                labelText: 'Venant de... allant vers...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.navigation),
                hintText: 'Ex: Venant de Tunis, allant vers Sousse',
              ),
              maxLines: 2,
              enabled: peutModifier,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointChoc(VehiculeFormData vehiculeData, bool peutModifier) {
    final pointsChoc = [
      'Avant',
      'Arrière',
      'Côté droit',
      'Côté gauche',
      'Angle avant droit',
      'Angle avant gauche',
      'Angle arrière droit',
      'Angle arrière gauche',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Point de choc initial',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Schéma du véhicule (simplifié)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.directions_car,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vehiculeData.pointChocInitial.isEmpty 
                          ? 'Sélectionnez le point de choc'
                          : 'Choc: ${vehiculeData.pointChocInitial}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Sélection du point de choc
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pointsChoc.map((point) {
                final isSelected = vehiculeData.pointChocInitial == point;
                return FilterChip(
                  label: Text(point),
                  selected: isSelected,
                  onSelected: peutModifier ? (selected) {
                    setState(() {
                      vehiculeData.pointChocInitial = selected ? point : '';
                    });
                  } : null,
                  selectedColor: Colors.red[100],
                  checkmarkColor: Colors.red[700],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDegatsApparents(VehiculeFormData vehiculeData, bool peutModifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dégâts apparents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: vehiculeData.degatsController,
              decoration: const InputDecoration(
                labelText: 'Description des dégâts',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.build),
                hintText: 'Décrivez les dégâts visibles...',
              ),
              maxLines: 4,
              enabled: peutModifier,
            ),
            
            const SizedBox(height: 16),
            
            // Section photos des dégâts
            if (peutModifier) ...[
              const Text(
                'Photos des dégâts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Grille de photos
              _buildPhotosGrid(vehiculeData),

              const SizedBox(height: 12),

              // Boutons d'ajout de photos
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _ajouterPhoto(vehiculeData, 'camera'),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Prendre photo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[600],
                        side: BorderSide(color: Colors.blue[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _ajouterPhoto(vehiculeData, 'galerie'),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galerie'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green[600],
                        side: BorderSide(color: Colors.green[300]!),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Conseils pour les photos
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue[600], size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Conseils pour les photos',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• Photographiez chaque dégât sous plusieurs angles\n'
                      '• Prenez des vues d\'ensemble et des détails\n'
                      '• Assurez-vous que l\'éclairage est suffisant\n'
                      '• Incluez des éléments de référence (taille)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[800], // Couleur plus foncée pour une meilleure lisibilité
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (vehiculeData.photosDegats.isNotEmpty) ...[
              const Text(
                'Photos des dégâts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildPhotosGrid(vehiculeData),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBoutonSuivant() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _continuer,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Suivant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _sauvegarder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sauvegarder seulement le véhicule de l'utilisateur actuel
      if (_monRoleVehicule != null) {
        final vehiculeData = _vehiculesData[_monRoleVehicule]!;
        final vehicule = vehiculeData.versVehiculeAccident(_monRoleVehicule!);
        
        await AccidentSessionCompleteService.mettreAJourVehicule(
          widget.session.id,
          vehicule,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Véhicule sauvegardé'),
              backgroundColor: Colors.green,
            ),
          );
        }
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _continuer() async {
    // Sauvegarder d'abord
    await _sauvegarder();

    if (mounted) {
      // Naviguer vers l'étape suivante
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AccidentFormStep3Assurance(
            session: widget.session,
            vehiculeSelectionne: widget.vehiculeSelectionne,
          ),
        ),
      );
    }
  }

  Widget _buildVehiculePreselectionne() {
    if (widget.vehiculeSelectionne == null) return const SizedBox.shrink();

    final vehicule = widget.vehiculeSelectionne!['vehicule'] as VehiculeModel;
    final estProprietaire = widget.vehiculeSelectionne!['estProprietaire'] as bool;
    final conducteur = widget.vehiculeSelectionne!['conducteur'] as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.blue[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Véhicule pré-sélectionné',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Auto-rempli',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Informations du véhicule en grille
          Row(
            children: [
              Expanded(
                child: _buildInfoCard('Véhicule', '${vehicule.marque} ${vehicule.modele}', Icons.directions_car),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard('Immatriculation', vehicule.numeroImmatriculation, Icons.confirmation_number),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildInfoCard('Assurance', vehicule.compagnieAssurance ?? 'N/A', Icons.security),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard('N° Police', vehicule.numeroPolice ?? 'N/A', Icons.policy),
              ),
            ],
          ),

          if (vehicule.agenceNom != null) ...[
            const SizedBox(height: 12),
            _buildInfoCard('Agence', vehicule.agenceNom!, Icons.business),
          ],

          const SizedBox(height: 16),

          // Informations du conducteur
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conducteur',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 8),
                if (estProprietaire) ...[
                  const Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Propriétaire du véhicule', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ] else ...[
                  Text('${conducteur['nom']} ${conducteur['prenom']}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        conducteur['aPermis'] ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: conducteur['aPermis'] ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Permis: ${conducteur['aPermis'] ? 'Oui' : 'Non'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: conducteur['aPermis'] ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Note informative
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[700], size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ces informations ont été automatiquement remplies depuis votre sélection de véhicule.',
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

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.blue[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid(VehiculeFormData vehiculeData) {
    if (vehiculeData.photosDegats.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_camera, color: Colors.grey, size: 32),
              SizedBox(height: 8),
              Text(
                'Aucune photo ajoutée',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: vehiculeData.photosDegats.length + 1, // +1 pour le bouton d'ajout
      itemBuilder: (context, index) {
        if (index == vehiculeData.photosDegats.length) {
          // Bouton d'ajout
          return GestureDetector(
            onTap: () => _ajouterPhoto(vehiculeData, 'camera'),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[300]!, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: Colors.blue[600], size: 24),
                  const SizedBox(height: 4),
                  Text(
                    'Ajouter',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Photo existante
        final photoUrl = vehiculeData.photosDegats[index];
        final bool isLocalImage = photoUrl.startsWith('file://') || photoUrl.startsWith('/');
        final String cleanPath = photoUrl.startsWith('file://') ? photoUrl.substring(7) : photoUrl;

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: isLocalImage
                      ? FileImage(File(cleanPath))
                      : NetworkImage(photoUrl) as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Bouton de suppression
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _supprimerPhoto(vehiculeData, index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _ajouterPhoto(VehiculeFormData vehiculeData, String source) async {
    try {
      // 🚀 Affichage immédiat avec indicateur élégant
      _showProgressDialog('Préparation de l\'image...');

      String? photoUrl;

      File? imageFile;
      if (source == 'camera') {
        imageFile = await _prendrePhotoOptimisee();
      } else {
        imageFile = await _selectionnerPhotoOptimisee();
      }

      if (imageFile != null) {
        photoUrl = await CloudinaryService.uploadImage(
          imageFile,
          'sinistres/degats',
        );
      }

      // Fermer l'indicateur
      if (mounted) Navigator.pop(context);

      if (photoUrl != null) {
        setState(() {
          vehiculeData.photosDegats.add(photoUrl!);
        });

        _showSuccessMessage('✅ Photo ajoutée instantanément !');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorMessage('Erreur lors de l\'ajout: $e');
    }
  }

  /// 📸 Prise de photo optimisée
  Future<File?> _prendrePhotoOptimisee() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75, // Optimisé pour la performance
      maxWidth: 1920,
      maxHeight: 1080,
    );
    return image != null ? File(image.path) : null;
  }

  /// 🖼️ Sélection de photo optimisée
  Future<File?> _selectionnerPhotoOptimisee() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    return image != null ? File(image.path) : null;
  }

  /// 🔄 Dialog de progression élégant
  void _showProgressDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Message de succès
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ❌ Message d'erreur
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 🖼️ Widget élégant pour afficher une photo
  Widget _buildPhotoCard(String photoUrl, VoidCallback onDelete) {
    final bool isLocalImage = photoUrl.startsWith('file://') || photoUrl.startsWith('/');
    final String cleanPath = photoUrl.startsWith('file://') ? photoUrl.substring(7) : photoUrl;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image avec gestion d'erreur élégante
            Container(
              width: double.infinity,
              height: double.infinity,
              child: isLocalImage
                  ? Image.file(
                      File(cleanPath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
                    )
                  : Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildLoadingPlaceholder();
                      },
                      errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
                    ),
            ),

            // Overlay avec bouton de suppression
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔄 Placeholder de chargement
  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ),
    );
  }

  /// ❌ Placeholder d'erreur
  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _supprimerPhoto(VehiculeFormData vehiculeData, int index) {
    final photoUrl = vehiculeData.photosDegats[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette photo ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Afficher un indicateur de chargement
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                // Supprimer de Firebase Storage si ce n'est pas une URL de placeholder
                if (!photoUrl.contains('placeholder')) {
                  await PhotoUploadService.supprimerPhoto(photoUrl);
                }

                // Supprimer de la liste locale
                setState(() {
                  vehiculeData.photosDegats.removeAt(index);
                });

                if (mounted) {
                  Navigator.pop(context); // Fermer l'indicateur de chargement
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Photo supprimée avec succès'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Fermer l'indicateur de chargement
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la suppression: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

/// 📝 Classe pour gérer les données du formulaire véhicule
class VehiculeFormData {
  final TextEditingController marqueController = TextEditingController();
  final TextEditingController modeleController = TextEditingController();
  final TextEditingController immatriculationController = TextEditingController();
  final TextEditingController sensCirculationController = TextEditingController();
  final TextEditingController degatsController = TextEditingController();

  String pointChocInitial = '';
  List<String> photosDegats = []; // URLs des photos des dégâts
  List<String> photosCroquis = []; // URLs des photos du croquis

  void remplirDepuisVehicule(VehiculeAccident vehicule) {
    marqueController.text = vehicule.marque;
    modeleController.text = vehicule.modele;
    immatriculationController.text = vehicule.immatriculation;
    sensCirculationController.text = vehicule.sensCirculation;
    degatsController.text = vehicule.degatsApparents.join(', ');
    pointChocInitial = vehicule.pointChocInitial;
  }

  VehiculeAccident versVehiculeAccident(String roleVehicule) {
    final user = FirebaseAuth.instance.currentUser;
    
    return VehiculeAccident(
      roleVehicule: roleVehicule,
      conducteurId: user?.uid ?? '',
      marque: marqueController.text.trim(),
      modele: modeleController.text.trim(),
      immatriculation: immatriculationController.text.trim(),
      sensCirculation: sensCirculationController.text.trim(),
      pointChocInitial: pointChocInitial,
      degatsApparents: degatsController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      
      // Valeurs par défaut (seront remplies dans l'étape assurance)
      societeAssurance: '',
      numeroContrat: '',
      agence: '',
      validiteAssuranceDebut: DateTime.now(),
      validiteAssuranceFin: DateTime.now(),
      nomConducteur: '',
      prenomConducteur: '',
      adresseConducteur: '',
      numeroPermis: '',
      dateDelivrancePermis: DateTime.now(),
      categoriePermis: '',
      assureDifferent: false,
      nomAssure: '',
      prenomAssure: '',
      adresseAssure: '',
    );
  }

  void dispose() {
    marqueController.dispose();
    modeleController.dispose();
    immatriculationController.dispose();
    sensCirculationController.dispose();
    degatsController.dispose();
  }
}
