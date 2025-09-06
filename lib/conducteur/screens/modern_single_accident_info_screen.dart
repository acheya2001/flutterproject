import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../services/accident_session_complete_service.dart';
import '../../services/conducteur_data_service.dart';
import '../../models/accident_session_complete.dart';
import 'accident_form_step2_vehicules.dart';
import 'accident_form_step4_circonstances.dart';

/// 🚗 Écran moderne pour accidents à véhicule unique (sortie de route, objet fixe, piéton)
class ModernSingleAccidentInfoScreen extends StatefulWidget {
  final String typeAccident;

  const ModernSingleAccidentInfoScreen({
    super.key,
    required this.typeAccident,
  });

  @override
  State<ModernSingleAccidentInfoScreen> createState() => _ModernSingleAccidentInfoScreenState();
}

class _ModernSingleAccidentInfoScreenState extends State<ModernSingleAccidentInfoScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Contrôleurs pour les champs
  final _dateController = TextEditingController();
  final _heureController = TextEditingController();
  final _lieuController = TextEditingController();
  final _detailsBlessesController = TextEditingController();

  // Contrôleurs pour les informations auto-remplies
  final _immatriculationController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _compagnieController = TextEditingController();
  final _agenceController = TextEditingController();
  final _numeroContratController = TextEditingController();

  // Contrôleurs pour le conducteur
  final _nomConducteurController = TextEditingController();
  final _prenomConducteurController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();

  // Variables d'état
  DateTime _dateAccident = DateTime.now();
  TimeOfDay _heureAccident = TimeOfDay.now();
  bool _blesses = false;
  String _lieuGps = '';
  List<Temoin> _temoins = [];

  // Données du conducteur (remplissage automatique)
  Map<String, dynamic>? _donneesConducteur;
  bool _donneesChargees = false;

  // Gestion conducteur/propriétaire
  bool _proprietaireConduit = true; // Le propriétaire conduit-il ?
  bool _conducteurAPermis = true; // Le conducteur a-t-il un permis ?
  String? _photoPermisRectoUrl;
  String? _photoPermisVersoUrl;
  File? _photoPermisRecto;
  File? _photoPermisVerso;
  final ImagePicker _picker = ImagePicker();

  // Variables pour la sélection de véhicule
  String? _vehiculeSelectionneId;
  Map<String, dynamic>? _vehiculeSelectionne;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _initialiserFormulaire();
    _chargerDonneesConducteur();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dateController.dispose();
    _heureController.dispose();
    _lieuController.dispose();
    _detailsBlessesController.dispose();
    _immatriculationController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _compagnieController.dispose();
    _agenceController.dispose();
    _numeroContratController.dispose();
    _nomConducteurController.dispose();
    _prenomConducteurController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  /// 📝 Remplir automatiquement tous les champs depuis les données
  void _remplirChampsAutomatiquement(Map<String, dynamic> donnees) {
    // Informations véhicule
    final vehicule = donnees['vehicule'] ?? {};
    _immatriculationController.text = vehicule['numeroImmatriculation'] ?? '';
    _marqueController.text = vehicule['marque'] ?? '';
    _modeleController.text = vehicule['modele'] ?? '';

    // Informations assurance
    final assurance = donnees['assurance'] ?? {};
    _compagnieController.text = assurance['compagnieNom'] ?? '';
    _agenceController.text = assurance['agenceNom'] ?? '';
    _numeroContratController.text = assurance['numeroPolice'] ?? '';

    // Informations conducteur (propriétaire par défaut)
    final conducteur = donnees['conducteur'] ?? {};
    _nomConducteurController.text = conducteur['nom'] ?? '';
    _prenomConducteurController.text = conducteur['prenom'] ?? '';
    _telephoneController.text = conducteur['telephone'] ?? '';
    _adresseController.text = conducteur['adresse'] ?? '';

    print('✅ Champs remplis automatiquement:');
    print('   - Véhicule: ${_marqueController.text} ${_modeleController.text}');
    print('   - Immatriculation: ${_immatriculationController.text}');
    print('   - Compagnie: ${_compagnieController.text}');
    print('   - Conducteur: ${_nomConducteurController.text} ${_prenomConducteurController.text}');
  }

  void _initialiserFormulaire() {
    _dateController.text = '${_dateAccident.day}/${_dateAccident.month}/${_dateAccident.year}';
    _heureController.text = '${_heureAccident.hour}:${_heureAccident.minute.toString().padLeft(2, '0')}';
  }

  /// 📊 Charger toutes les données du conducteur automatiquement
  Future<void> _chargerDonneesConducteur() async {
    try {
      print('🔄 Chargement données conducteur...');

      final donnees = await ConducteurDataService.recupererDonneesConducteur();

      if (donnees != null) {
        setState(() {
          _donneesConducteur = donnees;
          _donneesChargees = true;

          // Remplir automatiquement tous les champs
          _remplirChampsAutomatiquement(donnees);
        });

        print('✅ Données conducteur chargées:');
        print('   - Nom: ${donnees['conducteur']?['nom']} ${donnees['conducteur']?['prenom']}');
        print('   - Véhicule: ${donnees['vehicule']?['marque']} ${donnees['vehicule']?['modele']}');
        print('   - Compagnie: ${donnees['assurance']?['compagnieNom']}');
        print('   - Agence: ${donnees['assurance']?['agenceNom']}');
        print('   - Contrat actif: ${donnees['contrat']?['estActif']}');

        // Afficher un message de confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Informations chargées automatiquement depuis votre contrat',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('❌ Aucune donnée trouvée pour le conducteur');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Aucun contrat trouvé. Veuillez remplir manuellement.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur chargement données: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getCouleurTypeAccident().withOpacity(0.8),
              _getCouleurTypeAccident(),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header moderne
              _buildHeader(),
              
              // Contenu principal
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildFormulaire(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCouleurTypeAccident() {
    switch (widget.typeAccident) {
      case 'Sortie de route':
        return Colors.orange;
      case 'Collision avec objet fixe':
        return Colors.red;
      case 'Accident avec piéton ou cycliste':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _getIconeTypeAccident() {
    switch (widget.typeAccident) {
      case 'Sortie de route':
        return '🛣️';
      case 'Collision avec objet fixe':
        return '🛑';
      case 'Accident avec piéton ou cycliste':
        return '🚴‍♂️';
      default:
        return '🚗';
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Bouton retour et titre
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Déclaration d\'accident',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Bouton de test pour recharger les données
                        IconButton(
                          onPressed: _chargerDonneesConducteur,
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Recharger les données',
                        ),
                      ],
                    ),
                    Text(
                      widget.typeAccident,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Icône du type
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    _getIconeTypeAccident(),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Message informatif
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getMessageInfo(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMessageInfo() {
    switch (widget.typeAccident) {
      case 'Sortie de route':
        return 'Déclaration simplifiée pour sortie de route - Aucun autre conducteur à inviter';
      case 'Collision avec objet fixe':
        return 'Collision avec un objet fixe - Processus de déclaration individuel';
      case 'Accident avec piéton ou cycliste':
        return 'Accident impliquant un piéton ou cycliste - Informations détaillées requises';
      default:
        return 'Déclaration d\'accident individuelle';
    }
  }

  Widget _buildFormulaire() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Titre principal
            _buildTitleSection(),

            const SizedBox(height: 32),

            // Section sélection de véhicule
            _buildSelectionVehiculeSection(),
            const SizedBox(height: 20),

            // Informations auto-remplies
            if (_donneesChargees) ...[
              _buildInformationsAutoSection(),
              const SizedBox(height: 24),
            ],

            // Gestion conducteur/propriétaire
            _buildConducteurProprietaireSection(),

            const SizedBox(height: 24),

            // 1. Date et heure
            _buildDateHeureSection(),
            
            const SizedBox(height: 24),
            
            // 2. Lieu
            _buildLieuSection(),
            
            const SizedBox(height: 24),
            
            // 3. Blessés
            _buildBlessesSection(),
            
            const SizedBox(height: 24),
            
            // 4. Témoins
            _buildTemoinsSection(),
            
            const SizedBox(height: 40),
            
            // Bouton continuer
            _buildBoutonContinuer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de l\'accident',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _getCouleurTypeAccident(),
          ),
        ),
        
        const SizedBox(height: 8),
        
        const Text(
          'Renseignez les informations essentielles de votre accident',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDateHeureSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCouleurTypeAccident().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getCouleurTypeAccident(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Date et heure de l\'accident',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Date *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: _selectionnerDate,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Date requise';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _heureController,
                    decoration: InputDecoration(
                      labelText: 'Heure *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: _selectionnerHeure,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Heure requise';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLieuSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCouleurTypeAccident().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getCouleurTypeAccident(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Lieu de l\'accident',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _lieuController,
              decoration: InputDecoration(
                labelText: 'Adresse ou description du lieu *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.location_on),
                hintText: 'Ex: Avenue Habib Bourguiba, Tunis',
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Lieu requis';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _obtenirPositionGPS,
                icon: Icon(_lieuGps.isEmpty ? Icons.my_location : Icons.location_on),
                label: Text(
                  _lieuGps.isEmpty
                    ? '📍 Obtenir position GPS'
                    : '✅ Position GPS obtenue',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lieuGps.isEmpty ? Colors.blue[600] : Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // Afficher les coordonnées si disponibles
            if (_lieuGps.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Coordonnées: $_lieuGps',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[800],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBlessesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCouleurTypeAccident().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getCouleurTypeAccident(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Blessés (même légers)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _blesses ? _getCouleurTypeAccident().withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _blesses ? _getCouleurTypeAccident() : Colors.grey[300]!,
                      ),
                    ),
                    child: RadioListTile<bool>(
                      title: const Text('Oui'),
                      value: true,
                      groupValue: _blesses,
                      onChanged: (value) {
                        setState(() {
                          _blesses = value!;
                        });
                      },
                      activeColor: _getCouleurTypeAccident(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: !_blesses ? Colors.green.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !_blesses ? Colors.green : Colors.grey[300]!,
                      ),
                    ),
                    child: RadioListTile<bool>(
                      title: const Text('Non'),
                      value: false,
                      groupValue: _blesses,
                      onChanged: (value) {
                        setState(() {
                          _blesses = value!;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            
            if (_blesses) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _detailsBlessesController,
                decoration: InputDecoration(
                  labelText: 'Détails des blessures',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Décrivez les blessures...',
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemoinsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCouleurTypeAccident().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '4',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getCouleurTypeAccident(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Témoins',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _ajouterTemoin,
                  icon: Icon(
                    Icons.add_circle,
                    color: _getCouleurTypeAccident(),
                    size: 28,
                  ),
                  tooltip: 'Ajouter un témoin',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_temoins.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aucun témoin ajouté. Vous pouvez ajouter des témoins si nécessaire.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ..._temoins.asMap().entries.map((entry) {
                final index = entry.key;
                final temoin = entry.value;
                return _buildTemoinCard(temoin, index);
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemoinCard(Temoin temoin, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCouleurTypeAccident().withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getCouleurTypeAccident().withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getCouleurTypeAccident().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getCouleurTypeAccident(),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  temoin.nom,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (temoin.telephone.isNotEmpty)
                  Text(
                    temoin.telephone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          
          IconButton(
            onPressed: () => _supprimerTemoin(index),
            icon: const Icon(Icons.delete, color: Colors.red),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBoutonContinuer() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _continuer,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getCouleurTypeAccident(),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 8,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continuer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ],
              ),
      ),
    );
  }

  void _selectionnerDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateAccident,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _dateAccident = date;
        _dateController.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  void _selectionnerHeure() async {
    final heure = await showTimePicker(
      context: context,
      initialTime: _heureAccident,
    );
    
    if (heure != null) {
      setState(() {
        _heureAccident = heure;
        _heureController.text = '${heure.hour}:${heure.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _obtenirPositionGPS() async {
    try {
      // Afficher un indicateur de chargement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Obtention de la position GPS...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée définitivement. Veuillez l\'activer dans les paramètres.');
      }

      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Service de localisation désactivé. Veuillez l\'activer.');
      }

      // Obtenir la position avec une meilleure précision
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        _lieuGps = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Position GPS obtenue avec succès\nPrécision: ±${position.accuracy.toStringAsFixed(1)}m'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur GPS: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _obtenirPositionGPS,
            ),
          ),
        );
      }
    }
  }

  /// 📸 Prendre une photo du permis (recto ou verso)
  Future<void> _prendrePhotoPermis(bool isRecto) async {
    try {
      // Afficher un dialog de choix entre caméra et galerie
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('📸 Photo ${isRecto ? 'Recto' : 'Verso'} du permis'),
            content: const Text('Choisissez la source de l\'image :'),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Caméra'),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      );

      if (source == null) return;

      // Prendre la photo
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (isRecto) {
            _photoPermisRecto = File(image.path);
            _photoPermisRectoUrl = image.path;
          } else {
            _photoPermisVerso = File(image.path);
            _photoPermisVersoUrl = image.path;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('✅ Photo ${isRecto ? 'recto' : 'verso'} du permis prise avec succès'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('❌ Erreur lors de la prise de photo: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 🚗 Sélectionner un contrat et remplir automatiquement les informations
  void _selectionnerVehicule(Map<String, dynamic> contrat) {
    setState(() {
      _vehiculeSelectionneId = contrat['id'];
      _vehiculeSelectionne = contrat;
    });

    // Remplir automatiquement tous les champs depuis le contrat
    _remplirChampsDepuisContrat(contrat);

    final vehiculeInfo = contrat['vehiculeInfo'] as Map<String, dynamic>? ?? {};

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✅ Contrat sélectionné: ${vehiculeInfo['marque']} ${vehiculeInfo['modele']} (${contrat['numeroContrat']})',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 📋 Remplir les champs depuis un contrat sélectionné
  void _remplirChampsDepuisContrat(Map<String, dynamic> contrat) {
    final vehiculeInfo = contrat['vehiculeInfo'] as Map<String, dynamic>? ?? {};

    print('🔍 Données du contrat à remplir:');
    print('   - Contrat complet: $contrat');
    print('   - VehiculeInfo: $vehiculeInfo');

    // Informations véhicule depuis le contrat
    final immatriculation = vehiculeInfo['numeroImmatriculation'] ??
                           contrat['numeroImmatriculation'] ??
                           contrat['immatriculation'] ?? '';
    final marque = vehiculeInfo['marque'] ?? contrat['marque'] ?? '';
    final modele = vehiculeInfo['modele'] ?? contrat['modele'] ?? '';

    _immatriculationController.text = immatriculation;
    _marqueController.text = marque;
    _modeleController.text = modele;

    print('🔧 Remplissage immatriculation:');
    print('   - vehiculeInfo[numeroImmatriculation]: ${vehiculeInfo['numeroImmatriculation']}');
    print('   - contrat[numeroImmatriculation]: ${contrat['numeroImmatriculation']}');
    print('   - contrat[immatriculation]: ${contrat['immatriculation']}');
    print('   - Résultat final: $immatriculation');

    // Informations assurance depuis le contrat - utiliser les vraies données
    final compagnie = contrat['compagnieNom'] ??
                     contrat['compagnieAssurance'] ??
                     'Assurance Elite Tunisie';
    final agence = contrat['agenceNom'] ??
                  contrat['agenceAssurance'] ??
                  'Agence Centrale Tunis';
    final numeroContrat = contrat['numeroContrat'] ??
                         contrat['numeroPolice'] ?? '';

    _compagnieController.text = compagnie;
    _agenceController.text = agence;
    _numeroContratController.text = numeroContrat;

    // Informations conducteur (propriétaire) depuis le contrat
    final nom = contrat['proprietaireNom'] ??
               contrat['nomConducteur'] ??
               contrat['nom'] ?? '';
    final prenom = contrat['proprietairePrenom'] ??
                  contrat['prenomConducteur'] ??
                  contrat['prenom'] ?? '';
    final telephone = contrat['proprietaireTelephone'] ??
                     contrat['telephoneConducteur'] ??
                     contrat['telephone'] ?? '';
    final adresse = contrat['proprietaireAdresse'] ??
                   contrat['adresseConducteur'] ??
                   contrat['adresse'] ?? '';

    _nomConducteurController.text = nom;
    _prenomConducteurController.text = prenom;
    _telephoneController.text = telephone;
    _adresseController.text = adresse;

    print('✅ Champs remplis depuis contrat sélectionné:');
    print('   - Véhicule: $marque $modele');
    print('   - Immatriculation: $immatriculation');
    print('   - Contrat: $numeroContrat');
    print('   - Compagnie: $compagnie');
    print('   - Agence: $agence');
    print('   - Propriétaire: $nom $prenom');
    print('   - Téléphone: $telephone');
    print('   - Adresse: $adresse');
  }

  /// 📋 Récupérer les contrats actifs du conducteur depuis les demandes de contrats
  Future<List<Map<String, dynamic>>> _recupererContratsActifs() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Utilisateur non connecté');
        return [];
      }

      print('🔍 Récupération des contrats actifs pour: ${user.uid}');

      // D'abord, essayons la collection 'contrats'
      print('🔍 Recherche dans la collection "contrats"...');
      final contratsSnapshot = await FirebaseFirestore.instance
          .collection('contrats')
          .where('conducteurId', isEqualTo: user.uid)
          .get();

      print('📊 ${contratsSnapshot.docs.length} documents trouvés dans "contrats"');

      // Si aucun contrat trouvé, essayons 'demandes_contrats'
      if (contratsSnapshot.docs.isEmpty) {
        print('🔍 Recherche dans la collection "demandes_contrats"...');
        final demandesSnapshot = await FirebaseFirestore.instance
            .collection('demandes_contrats')
            .where('conducteurId', isEqualTo: user.uid)
            .where('statut', whereIn: ['contrat_actif', 'contrat_valide', 'affectee'])
            .get();

        print('📊 ${demandesSnapshot.docs.length} demandes trouvées dans "demandes_contrats"');

        List<Map<String, dynamic>> contratsActifs = [];

        for (final doc in demandesSnapshot.docs) {
          final data = doc.data();

          print('📋 Traitement demande: ${doc.id}');
          print('   - Toutes les clés: ${data.keys.toList()}');
          print('   - Marque: ${data['marque']}');
          print('   - Modèle: ${data['modele']}');
          print('   - Immatriculation: ${data['immatriculation']}');
          print('   - Statut: ${data['statut']}');
          print('   - Nom: ${data['nom']}');
          print('   - Prénom: ${data['prenom']}');
          print('   - Téléphone: ${data['telephone']}');
          print('   - Adresse: ${data['adresse']}');
          print('   - Compagnie: ${data['compagnieNom']}');
          print('   - Agence: ${data['agenceNom']}');

          // Créer un objet contrat avec toutes les informations nécessaires
          final contrat = {
            'id': doc.id,
            'numeroContrat': data['numeroContrat'] ?? '',
            'numeroDemande': data['numeroDemande'] ?? '',
            'statut': data['statut'] ?? '',
            'dateDebut': data['dateDebut'],
            'dateFin': data['dateFin'],

            // Informations véhicule
            'vehiculeInfo': {
              'marque': data['marque'] ?? '',
              'modele': data['modele'] ?? '',
              'numeroImmatriculation': data['immatriculation'] ?? '',
              'typeCarburant': data['typeCarburant'] ?? '',
              'puissance': data['puissance'] ?? '',
              'anneeConstruction': data['anneeConstruction'] ?? '',
            },

            // Aussi stocker directement au niveau racine pour compatibilité
            'marque': data['marque'] ?? '',
            'modele': data['modele'] ?? '',
            'numeroImmatriculation': data['immatriculation'] ?? '',
            'immatriculation': data['immatriculation'] ?? '',

            // Informations assurance
            'compagnieNom': data['compagnieNom'] ?? 'Assurance Elite Tunisie',
            'agenceNom': data['agenceNom'] ?? 'Agence Centrale Tunis',
            'compagnieAssurance': data['compagnieNom'] ?? 'Assurance Elite Tunisie',
            'agenceAssurance': data['agenceNom'] ?? 'Agence Centrale Tunis',
            'typeContrat': data['typeContrat'] ?? '',
            'prime': data['prime'] ?? 0,
            'franchise': data['franchise'] ?? 0,

            // Informations conducteur/propriétaire (utiliser les vrais noms de champs)
            'proprietaireNom': data['nom'] ?? '',
            'proprietairePrenom': data['prenom'] ?? '',
            'proprietaireTelephone': data['telephone'] ?? '',
            'proprietaireAdresse': data['adresse'] ?? '',
            'proprietaireEmail': data['email'] ?? '',

            // Aussi stocker avec d'autres noms pour compatibilité
            'nomConducteur': data['nom'] ?? '',
            'prenomConducteur': data['prenom'] ?? '',
            'telephoneConducteur': data['telephone'] ?? '',
            'adresseConducteur': data['adresse'] ?? '',
            'nom': data['nom'] ?? '',
            'prenom': data['prenom'] ?? '',
            'telephone': data['telephone'] ?? '',
            'adresse': data['adresse'] ?? '',
          };

          contratsActifs.add(contrat);

          final vehiculeInfo = contrat['vehiculeInfo'] as Map<String, dynamic>;
          print('✅ Contrat actif créé: ${vehiculeInfo['marque']} ${vehiculeInfo['modele']} (${contrat['numeroContrat']})');
          print('   - Immatriculation dans vehiculeInfo: ${vehiculeInfo['numeroImmatriculation']}');
          print('   - Immatriculation racine: ${contrat['numeroImmatriculation']}');
        }

        print('📋 ${contratsActifs.length} contrats actifs récupérés depuis "demandes_contrats"');
        return contratsActifs;
      }

      // Traitement des contrats depuis la collection 'contrats'
      List<Map<String, dynamic>> contratsActifs = [];

      for (final doc in contratsSnapshot.docs) {
        final data = doc.data();

        print('📋 Traitement contrat: ${doc.id}');
        print('   - Data keys: ${data.keys.toList()}');

        // Vérifier si le contrat est actif (date de fin dans le futur)
        final dateFin = (data['dateFin'] as Timestamp?)?.toDate();
        final isActive = dateFin?.isAfter(DateTime.now()) ?? false;

        if (!isActive) {
          print('⏭️ Contrat expiré ignoré: ${doc.id}');
          continue;
        }

        // Créer un objet contrat avec toutes les informations nécessaires
        final contrat = {
          'id': doc.id,
          'numeroContrat': data['numeroContrat'] ?? data['numeroPolice'] ?? '',
          'numeroDemande': data['numeroDemande'] ?? '',
          'statut': 'contrat_actif',
          'dateDebut': data['dateDebut'],
          'dateFin': data['dateFin'],

          // Informations véhicule depuis vehiculeInfo
          'vehiculeInfo': data['vehiculeInfo'] ?? {
            'marque': data['marque'] ?? '',
            'modele': data['modele'] ?? '',
            'numeroImmatriculation': data['numeroImmatriculation'] ?? '',
            'typeCarburant': data['typeCarburant'] ?? '',
            'puissance': data['puissance'] ?? '',
            'anneeConstruction': data['anneeConstruction'] ?? '',
          },

          // Informations assurance
          'compagnieNom': data['compagnieAssurance'] ?? data['compagnieNom'] ?? 'Assurance Elite Tunisie',
          'agenceNom': data['agenceAssurance'] ?? data['agenceNom'] ?? 'Agence Centrale Tunis',
          'typeContrat': data['typeContrat'] ?? data['typeAssurance'] ?? '',
          'prime': data['montantPrime'] ?? data['prime'] ?? 0,
          'franchise': data['franchise'] ?? 0,

          // Informations conducteur/propriétaire
          'proprietaireNom': data['proprietaireNom'] ?? data['nomConducteur'] ?? '',
          'proprietairePrenom': data['proprietairePrenom'] ?? data['prenomConducteur'] ?? '',
          'proprietaireTelephone': data['proprietaireTelephone'] ?? data['telephoneConducteur'] ?? '',
          'proprietaireAdresse': data['proprietaireAdresse'] ?? data['adresseConducteur'] ?? '',
          'proprietaireEmail': data['proprietaireEmail'] ?? data['emailConducteur'] ?? '',
        };

        contratsActifs.add(contrat);

        final vehiculeInfo = contrat['vehiculeInfo'] as Map<String, dynamic>;
        print('✅ Contrat actif trouvé: ${vehiculeInfo['marque']} ${vehiculeInfo['modele']} (${contrat['numeroContrat']})');
      }

      print('📋 ${contratsActifs.length} contrats actifs récupérés depuis "contrats"');
      return contratsActifs;

    } catch (e) {
      print('❌ Erreur lors de la récupération des contrats: $e');
      return [];
    }
  }

  void _ajouterTemoin() {
    showDialog(
      context: context,
      builder: (context) => _buildDialogueTemoin(),
    );
  }

  Widget _buildDialogueTemoin() {
    final nomController = TextEditingController();
    final adresseController = TextEditingController();
    final telephoneController = TextEditingController();

    return AlertDialog(
      title: const Text('Ajouter un témoin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nomController,
            decoration: const InputDecoration(
              labelText: 'Nom complet *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: adresseController,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: telephoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
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
            if (nomController.text.trim().isNotEmpty) {
              setState(() {
                _temoins.add(Temoin(
                  nom: nomController.text.trim(),
                  adresse: adresseController.text.trim(),
                  telephone: telephoneController.text.trim(),
                ));
              });
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _getCouleurTypeAccident(),
          ),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }

  void _supprimerTemoin(int index) {
    setState(() {
      _temoins.removeAt(index);
    });
  }

  void _continuer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer les vraies infos utilisateur depuis le contrat sélectionné
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Utiliser les informations du contrat sélectionné
      final contratSelectionne = _vehiculeSelectionne;
      if (contratSelectionne == null) {
        throw Exception('Aucun véhicule sélectionné');
      }

      print('🚗 Création session avec contrat: ${contratSelectionne['numeroContrat']}');

      final session = await AccidentSessionCompleteService.creerNouvelleSession(
        typeAccident: widget.typeAccident,
        nombreVehicules: 1, // Accident à véhicule unique
        nomCreateur: contratSelectionne['nom'] ?? 'Nom Utilisateur',
        prenomCreateur: contratSelectionne['prenom'] ?? 'Prénom Utilisateur',
        emailCreateur: contratSelectionne['email'] ?? user.email ?? 'email@example.com',
        telephoneCreateur: contratSelectionne['telephone'] ?? '+216 XX XXX XXX',
      );

      // Mettre à jour les informations générales
      final infosGenerales = InfosGeneralesAccident(
        dateAccident: _dateAccident,
        heureAccident: _heureController.text,
        lieuAccident: _lieuController.text.trim(),
        lieuGps: _lieuGps,
        blesses: _blesses,
        detailsBlesses: _detailsBlessesController.text.trim(),
        degatsMaterielsAutres: false, // Pas applicable pour accident unique
        detailsDegatsAutres: '',
        temoins: _temoins,
      );

      await AccidentSessionCompleteService.mettreAJourInfosGenerales(
        session.id,
        infosGenerales,
      );

      // 🎯 NOUVEAU: Créer automatiquement le véhicule du conducteur avec les infos du contrat
      final vehiculeConducteur = VehiculeAccident(
        roleVehicule: 'A', // Le conducteur est toujours véhicule A
        conducteurId: user.uid,

        // Informations véhicule depuis le contrat
        marque: contratSelectionne['marque'] ?? '',
        modele: contratSelectionne['modele'] ?? '',
        immatriculation: contratSelectionne['immatriculation'] ?? '',
        sensCirculation: '', // À remplir plus tard
        pointChocInitial: '', // À remplir plus tard
        degatsApparents: [], // À remplir plus tard

        // Informations assurance depuis le contrat
        societeAssurance: contratSelectionne['compagnieNom'] ?? '',
        numeroContrat: contratSelectionne['numeroContrat'] ?? '',
        agence: contratSelectionne['agenceNom'] ?? '',
        validiteAssuranceDebut: DateTime.now().subtract(const Duration(days: 30)), // Approximation
        validiteAssuranceFin: DateTime.now().add(const Duration(days: 335)), // Approximation

        // Informations conducteur depuis le contrat
        nomConducteur: contratSelectionne['nom'] ?? '',
        prenomConducteur: contratSelectionne['prenom'] ?? '',
        adresseConducteur: contratSelectionne['adresse'] ?? '',
        numeroPermis: '', // À remplir si nécessaire
        dateDelivrancePermis: DateTime.now().subtract(const Duration(days: 365)), // Approximation
        categoriePermis: 'B', // Valeur par défaut

        // Assuré (même personne que le conducteur)
        assureDifferent: false,
        nomAssure: contratSelectionne['nom'] ?? '',
        prenomAssure: contratSelectionne['prenom'] ?? '',
        adresseAssure: contratSelectionne['adresse'] ?? '',
      );

      // Sauvegarder le véhicule du conducteur
      await AccidentSessionCompleteService.mettreAJourVehicule(
        session.id,
        vehiculeConducteur,
      );

      print('✅ Véhicule conducteur créé automatiquement avec les données du contrat');

      if (mounted) {
        // 🎯 NOUVEAU: Passer directement aux circonstances (étape 4)
        // puisque nous avons déjà les informations véhicule et assurance
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AccidentFormStep4Circonstances(
              session: session,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
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

  /// 🚗 Section de sélection de véhicule depuis les contrats
  Widget _buildSelectionVehiculeSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _recupererContratsActifs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Chargement de vos véhicules...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur lors du chargement des véhicules: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              ],
            ),
          );
        }

        final contrats = snapshot.data ?? [];

        if (contrats.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[600]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Aucun contrat actif trouvé. Veuillez d\'abord souscrire à une assurance.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Sélectionnez votre contrat d\'assurance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Choisissez le contrat d\'assurance du véhicule impliqué dans l\'accident pour remplir automatiquement toutes les informations :',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ...contrats.map((contrat) => _buildContratCard(contrat)).toList(),
            ],
          ),
        );
      },
    );
  }

  /// 📄 Carte de contrat sélectionnable
  Widget _buildContratCard(Map<String, dynamic> contrat) {
    final bool isSelected = _vehiculeSelectionneId == contrat['id'];
    final vehiculeInfo = contrat['vehiculeInfo'] as Map<String, dynamic>? ?? {};
    final statut = contrat['statut'] ?? '';
    final isActif = statut == 'contrat_actif';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green[100] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.green[400]! : (isActif ? Colors.blue[300]! : Colors.orange[300]!),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectionnerVehicule(contrat),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.green[600]
                        : (isActif ? Colors.blue[600] : Colors.orange[600]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : (isActif ? Icons.verified : Icons.pending),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehiculeInfo['marque']} ${vehiculeInfo['modele']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.green[800] : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '🚗 ${vehiculeInfo['numeroImmatriculation']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.green[700] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📋 Contrat: ${contrat['numeroContrat']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.green[600] : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActif ? Colors.green[100] : Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isActif ? '✅ ACTIF' : '⏳ EN COURS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isActif ? Colors.green[700] : Colors.orange[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '🏢 ${contrat['compagnieNom']}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📋 Section des informations auto-remplies
  Widget _buildInformationsAutoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Informations chargées automatiquement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Véhicule
          _buildInfoAutoRow('🚗 Véhicule', '${_marqueController.text} ${_modeleController.text}'),
          _buildInfoAutoRow('🔢 Immatriculation', _immatriculationController.text),
          _buildInfoAutoRow('📋 N° Contrat', _numeroContratController.text),

          const SizedBox(height: 12),

          // Assurance
          _buildInfoAutoRow('🏢 Compagnie', _compagnieController.text),
          _buildInfoAutoRow('🏪 Agence', _agenceController.text),

          const SizedBox(height: 12),

          // Propriétaire
          _buildInfoAutoRow('👤 Propriétaire', '${_nomConducteurController.text} ${_prenomConducteurController.text}'),
          _buildInfoAutoRow('📞 Téléphone', _telephoneController.text),
        ],
      ),
    );
  }

  /// 📝 Ligne d'information auto-remplie
  Widget _buildInfoAutoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.green[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Non renseigné',
              style: TextStyle(
                fontSize: 13,
                color: value.isNotEmpty ? Colors.black87 : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 Section gestion conducteur/propriétaire
  Widget _buildConducteurProprietaireSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👤 Qui conduisait le véhicule ?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          // Question propriétaire conduit
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[300]!, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _proprietaireConduit,
                      onChanged: (value) {
                        setState(() {
                          _proprietaireConduit = value!;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Le propriétaire du véhicule conduisait',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: _proprietaireConduit,
                      onChanged: (value) {
                        setState(() {
                          _proprietaireConduit = value!;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Une autre personne conduisait',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Si ce n'est pas le propriétaire qui conduit
          if (!_proprietaireConduit) ...[
            const Text(
              'Informations du conducteur',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Champs conducteur
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nomConducteurController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du conducteur',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _prenomConducteurController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _telephoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone du conducteur',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),

            const SizedBox(height: 16),
          ],

          // Question permis - seulement si ce n'est pas le propriétaire qui conduit
          if (!_proprietaireConduit) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[300]!, width: 2),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🪪 Le conducteur a-t-il un permis de conduire ?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _conducteurAPermis,
                      onChanged: (value) {
                        setState(() {
                          _conducteurAPermis = value!;
                        });
                      },
                    ),
                    const Text(
                      'Oui, permis valide',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Radio<bool>(
                      value: false,
                      groupValue: _conducteurAPermis,
                      onChanged: (value) {
                        setState(() {
                          _conducteurAPermis = value!;
                        });
                      },
                    ),
                    const Text(
                      'Non, pas de permis',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                if (_conducteurAPermis) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '📸 Photos du permis (optionnel)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _buildPhotoPermisButton('Recto', _photoPermisRectoUrl, true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPhotoPermisButton('Verso', _photoPermisVersoUrl, false),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Conduite sans permis - Infraction grave',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          ], // Fin du bloc conditionnel pour la question du permis
        ],
      ),
    );
  }

  /// 📸 Bouton pour photo permis
  Widget _buildPhotoPermisButton(String label, String? photoUrl, bool isRecto) {
    final bool hasPhoto = photoUrl != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasPhoto ? Colors.green : Colors.grey[400]!,
          width: hasPhoto ? 2 : 1,
        ),
        color: hasPhoto ? Colors.green[50] : Colors.grey[50],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _prendrePhotoPermis(isRecto),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasPhoto ? Icons.check_circle : Icons.camera_alt,
                  color: hasPhoto ? Colors.green[600] : Colors.grey[600],
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  hasPhoto ? '$label ✓' : label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasPhoto ? Colors.green[700] : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (hasPhoto) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Modifier',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
