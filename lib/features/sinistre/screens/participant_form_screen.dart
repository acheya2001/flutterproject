import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/widgets/custom_app_bar.dart';
import '../../../common/widgets/gradient_background.dart';
import '../../../models/accident_session.dart';
import '../../../models/participant.dart';
import '../services/accident_session_service.dart';
import '../../../conducteur/widgets/vehicule_point_choc_widget.dart';
import '../../../conducteur/widgets/photo_manager_widget.dart';

/// Écran de formulaire pour un participant (cases 6-12 du constat)
class ParticipantFormScreen extends StatefulWidget {
  final AccidentSession session;
  final String roleAssigne;
  final bool isFromInvitation;
  final Map<String, dynamic>? vehiculeData; // Pour le créateur

  const ParticipantFormScreen({
    Key? key,
    required this.session,
    required this.roleAssigne,
    required this.isFromInvitation,
    this.vehiculeData,
  }) : super(key: key);

  @override
  State<ParticipantFormScreen> createState() => _ParticipantFormScreenState();
}

class _ParticipantFormScreenState extends State<ParticipantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Contrôleurs de formulaire
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telController = TextEditingController();
  final _emailController = TextEditingController();
  final _cinController = TextEditingController();
  final _permisNumController = TextEditingController();
  final _permisCatController = TextEditingController();
  final _policeNumController = TextEditingController();
  final _assureNomController = TextEditingController();
  final _assureAdresseController = TextEditingController();
  final _vehMarqueController = TextEditingController();
  final _vehTypeController = TextEditingController();
  final _immatriculationController = TextEditingController();
  final _sensSuiviController = TextEditingController();
  final _venantDeController = TextEditingController();
  final _allantAController = TextEditingController();
  final _degatsTextController = TextEditingController();

  // Données du formulaire
  DateTime? _permisDate;
  DateTime? _attestationDu;
  DateTime? _attestationAu;
  String? _assureurId;
  String? _agenceId;
  List<bool> _circonstances = List.filled(17, false);
  List<String> _piecesJointes = [];
  List<String> _degatsPhotos = [];
  Map<String, dynamic>? _chocInitial;
  List<String> _pointsChocSelectionnes = [];
  bool _conducteurDifferentAssure = false;

  // Services
  final AccidentSessionService _sessionService = AccidentSessionService();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && !widget.isFromInvitation) {
      // Pré-remplir automatiquement toutes les données du conducteur connecté
      _loadConducteurData(user.uid);
    }
  }

  /// Charge et pré-remplit toutes les données du conducteur connecté
  Future<void> _loadConducteurData(String userId) async {
    try {
      setState(() => _isLoading = true);

      // 1. Récupérer les données du conducteur
      final conducteurData = await _getConducteurData(userId);

      // 2. Récupérer les données du véhicule sélectionné
      final vehiculeData = widget.vehiculeData;

      // 3. Récupérer les données d'assurance complètes
      final assuranceData = await _getAssuranceData(vehiculeData);

      if (conducteurData != null) {
        // Pré-remplir les informations personnelles
        _nomController.text = conducteurData['nom'] ?? '';
        _prenomController.text = conducteurData['prenom'] ?? '';
        _adresseController.text = conducteurData['adresse'] ?? '';
        _telController.text = conducteurData['telephone'] ?? '';
        _emailController.text = conducteurData['email'] ?? '';
        _cinController.text = conducteurData['cin'] ?? '';
        _permisNumController.text = conducteurData['numeroPermis'] ?? '';
        _permisCatController.text = conducteurData['categoriePermis'] ?? 'B';
      }

      if (vehiculeData != null) {
        // Pré-remplir les informations du véhicule
        _vehMarqueController.text = vehiculeData['marque'] ?? vehiculeData['marqueVehicule'] ?? '';
        _vehTypeController.text = vehiculeData['modele'] ?? vehiculeData['modeleVehicule'] ?? '';
        _immatriculationController.text = vehiculeData['immatriculation'] ?? vehiculeData['numeroImmatriculation'] ?? '';

        // Informations d'assurance
        _policeNumController.text = vehiculeData['numeroContrat'] ?? '';

        // Utiliser les données d'assurance enrichies si disponibles
        if (assuranceData != null) {
          _assureNomController.text = assuranceData['compagnieNom'] ?? '';
          _assureAdresseController.text = assuranceData['agenceAdresse'] ?? '';
        } else {
          // Fallback sur les données du véhicule
          _assureNomController.text = vehiculeData['compagnieAssurance'] ?? vehiculeData['companyName'] ?? '';
          _assureAdresseController.text = vehiculeData['agenceAssurance'] ?? vehiculeData['agencyName'] ?? '';
        }
      }

      setState(() => _isLoading = false);

      // Afficher un message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Vos informations ont été pré-remplies automatiquement'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des données conducteur: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Récupère les données du conducteur depuis Firestore
  Future<Map<String, dynamic>?> _getConducteurData(String userId) async {
    try {
      // Essayer d'abord dans la collection 'conducteurs'
      var doc = await FirebaseFirestore.instance.collection('conducteurs').doc(userId).get();
      if (doc.exists) return doc.data();

      // Sinon essayer dans 'users'
      doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) return doc.data();

      return null;
    } catch (e) {
      print('❌ Erreur récupération conducteur: $e');
      return null;
    }
  }

  /// Récupère les données d'assurance enrichies (compagnie et agence)
  Future<Map<String, dynamic>?> _getAssuranceData(Map<String, dynamic>? vehiculeData) async {
    if (vehiculeData == null) return null;

    try {
      final Map<String, dynamic> assuranceData = {};

      // 1. Récupérer les informations de la compagnie
      final compagnieId = vehiculeData['compagnieId'] ?? vehiculeData['assureur_id'];
      if (compagnieId != null) {
        final compagnieDoc = await FirebaseFirestore.instance
            .collection('compagnies_assurance')
            .doc(compagnieId)
            .get();

        if (compagnieDoc.exists) {
          final compagnieInfo = compagnieDoc.data()!;
          assuranceData['compagnieNom'] = compagnieInfo['nom'] ?? '';
          assuranceData['compagnieAdresse'] = compagnieInfo['adresse'] ?? '';
        }
      }

      // 2. Récupérer les informations de l'agence
      final agenceId = vehiculeData['agenceId'];
      if (agenceId != null) {
        final agenceDoc = await FirebaseFirestore.instance
            .collection('agences_assurance')
            .doc(agenceId)
            .get();

        if (agenceDoc.exists) {
          final agenceInfo = agenceDoc.data()!;
          assuranceData['agenceNom'] = agenceInfo['nom'] ?? '';
          assuranceData['agenceAdresse'] = agenceInfo['adresse'] ?? '';
        }
      }

      return assuranceData.isNotEmpty ? assuranceData : null;
    } catch (e) {
      print('❌ Erreur récupération données assurance: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _adresseController.dispose();
    _telController.dispose();
    _emailController.dispose();
    _cinController.dispose();
    _permisNumController.dispose();
    _permisCatController.dispose();
    _policeNumController.dispose();
    _assureNomController.dispose();
    _assureAdresseController.dispose();
    _vehMarqueController.dispose();
    _vehTypeController.dispose();
    _immatriculationController.dispose();
    _sensSuiviController.dispose();
    _venantDeController.dispose();
    _allantAController.dispose();
    _degatsTextController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Véhicule ${widget.roleAssigne} - Mon Formulaire',
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildIdentiteConducteurPage(),
                    _buildAssurancePage(),
                    _buildVehiculePage(),
                    _buildCirconstancesPage(),
                    _buildDegatsPage(),
                    _buildPiecesJointesPage(),
                  ],
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(6, (index) {
          final isActive = index <= _currentPage;
          final isCompleted = index < _currentPage;
          
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : isActive
                        ? Colors.blue
                        : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildIdentiteConducteurPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.person,
            title: 'Identité du Conducteur',
            subtitle: 'Case 6 - Vos informations personnelles',
          ),
          const SizedBox(height: 32),
          _buildFormCard([
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => value?.trim().isEmpty == true ? 'Nom requis' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _prenomController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value?.trim().isEmpty == true ? 'Prénom requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse complète *',
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
              validator: (value) => value?.trim().isEmpty == true ? 'Adresse requise' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _telController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone *',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value?.trim().isEmpty == true ? 'Téléphone requis' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.trim().isEmpty == true) return 'Email requis';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cinController,
              decoration: const InputDecoration(
                labelText: 'CIN *',
                prefixIcon: Icon(Icons.credit_card),
              ),
              validator: (value) => value?.trim().isEmpty == true ? 'CIN requis' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _permisNumController,
                    decoration: const InputDecoration(
                      labelText: 'N° Permis *',
                      prefixIcon: Icon(Icons.drive_eta),
                    ),
                    validator: (value) => value?.trim().isEmpty == true ? 'N° permis requis' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _permisCatController,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDateField(
              label: 'Date de délivrance du permis',
              value: _permisDate,
              onChanged: (date) => setState(() => _permisDate = date),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildAssurancePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.security,
            title: 'Assurance',
            subtitle: 'Case 7 - Informations d\'assurance',
          ),
          const SizedBox(height: 32),
          _buildFormCard([
            // TODO: Dropdown pour sélectionner l'assureur
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Compagnie d\'assurance *',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) => value?.trim().isEmpty == true ? 'Compagnie requise' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Agence',
                prefixIcon: Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _policeNumController,
              decoration: const InputDecoration(
                labelText: 'N° Police/Contrat *',
                prefixIcon: Icon(Icons.policy),
              ),
              validator: (value) => value?.trim().isEmpty == true ? 'N° police requis' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Attestation valable du',
                    value: _attestationDu,
                    onChanged: (date) => setState(() => _attestationDu = date),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    label: 'Au',
                    value: _attestationAu,
                    onChanged: (date) => setState(() => _attestationAu = date),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 24),
          _buildAssureSection(),
        ],
      ),
    );
  }

  Widget _buildAssureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _conducteurDifferentAssure,
              onChanged: (value) => setState(() => _conducteurDifferentAssure = value ?? false),
            ),
            Expanded(
              child: Text(
                'L\'assuré est différent du conducteur (Case 8)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (_conducteurDifferentAssure) ...[
          const SizedBox(height: 16),
          _buildFormCard([
            TextFormField(
              controller: _assureNomController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'assuré',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _assureAdresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse de l\'assuré',
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
          ]),
        ],
      ],
    );
  }

  Widget _buildVehiculePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.directions_car,
            title: 'Véhicule',
            subtitle: 'Case 8 - Informations du véhicule',
          ),
          const SizedBox(height: 32),
          _buildFormCard([
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vehMarqueController,
                    decoration: const InputDecoration(
                      labelText: 'Marque *',
                      prefixIcon: Icon(Icons.branding_watermark),
                    ),
                    validator: (value) => value?.trim().isEmpty == true ? 'Marque requise' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _vehTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Type/Modèle *',
                      prefixIcon: Icon(Icons.model_training),
                    ),
                    validator: (value) => value?.trim().isEmpty == true ? 'Type requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _immatriculationController,
              decoration: const InputDecoration(
                labelText: 'Immatriculation *',
                prefixIcon: Icon(Icons.confirmation_number),
              ),
              validator: (value) => value?.trim().isEmpty == true ? 'Immatriculation requise' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sensSuiviController,
              decoration: const InputDecoration(
                labelText: 'Sens suivi',
                prefixIcon: Icon(Icons.arrow_forward),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _venantDeController,
                    decoration: const InputDecoration(
                      labelText: 'Venant de',
                      prefixIcon: Icon(Icons.place),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _allantAController,
                    decoration: const InputDecoration(
                      labelText: 'Allant à',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildCirconstancesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.list_alt,
            title: 'Circonstances',
            subtitle: 'Case 12 - Cochez les cases correspondantes',
          ),
          const SizedBox(height: 32),
          _buildFormCard([
            Text(
              'Cochez les circonstances qui correspondent à votre situation au moment de l\'accident:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ...Participant.circonstancesLabels.asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              
              return CheckboxListTile(
                title: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                value: _circonstances[index],
                onChanged: (value) {
                  setState(() => _circonstances[index] = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              );
            }).toList(),
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
                  Text(
                    'Cases cochées: ${_circonstances.where((c) => c).length}/17',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildDegatsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.build,
            title: 'Dégâts et Point de Choc',
            subtitle: 'Cases 10-11 - Décrivez les dégâts',
          ),
          const SizedBox(height: 32),
          _buildFormCard([
            TextFormField(
              controller: _degatsTextController,
              decoration: const InputDecoration(
                labelText: 'Description des dégâts apparents',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) => value?.trim().isEmpty == true ? 'Description requise' : null,
            ),

            const SizedBox(height: 24),

            // Section photos des dégâts
            _buildPhotosDegatSection(),

            const SizedBox(height: 24),

            // Widget interactif pour le point de choc initial
            _buildPointChocWidget(),
          ]),
        ],
      ),
    );
  }

  Widget _buildPiecesJointesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.attach_file,
            title: 'Pièces Jointes',
            subtitle: 'Documents obligatoires et photos',
          ),
          const SizedBox(height: 32),
          _buildFormCard([
            Text(
              'Documents obligatoires:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDocumentItem('Carte grise', Icons.credit_card, true),
            _buildDocumentItem('Attestation d\'assurance', Icons.security, true),
            _buildDocumentItem('Permis de conduire', Icons.drive_eta, true),
            const SizedBox(height: 24),
            Text(
              'Photos des dégâts:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Grille de photos
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 32, color: Colors.grey[600]),
                    const SizedBox(height: 8),
                    Text(
                      'Ajouter des photos',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildPageHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.blue[600]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        children: children,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: IconButton(
          icon: const Icon(Icons.edit_calendar),
          onPressed: () => _selectDate(onChanged),
        ),
      ),
      readOnly: true,
      controller: TextEditingController(
        text: value != null ? '${value.day}/${value.month}/${value.year}' : '',
      ),
    );
  }

  Widget _buildDocumentItem(String title, IconData icon, bool required) {
    final isUploaded = _piecesJointes.any((doc) => doc.contains(title.toLowerCase()));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUploaded ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUploaded ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isUploaded ? Colors.green : Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title + (required ? ' *' : ''),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isUploaded ? Colors.green[800] : Colors.grey[800],
              ),
            ),
          ),
          if (isUploaded)
            Icon(Icons.check_circle, color: Colors.green, size: 20)
          else
            IconButton(
              onPressed: () => _uploadDocument(title),
              icon: const Icon(Icons.upload_file),
              tooltip: 'Télécharger',
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Précédent'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage < 5 ? _nextPage : _saveParticipant,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(_currentPage < 5 ? 'Suivant' : 'Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_validateCurrentPage()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0: // Identité
        return _nomController.text.trim().isNotEmpty &&
               _prenomController.text.trim().isNotEmpty &&
               _adresseController.text.trim().isNotEmpty &&
               _telController.text.trim().isNotEmpty &&
               _emailController.text.trim().isNotEmpty &&
               _cinController.text.trim().isNotEmpty &&
               _permisNumController.text.trim().isNotEmpty;
      case 1: // Assurance
        return _policeNumController.text.trim().isNotEmpty;
      case 2: // Véhicule
        return _vehMarqueController.text.trim().isNotEmpty &&
               _vehTypeController.text.trim().isNotEmpty &&
               _immatriculationController.text.trim().isNotEmpty;
      case 3: // Circonstances
        return true; // Pas de validation spécifique
      case 4: // Dégâts
        return _degatsTextController.text.trim().isNotEmpty;
      case 5: // Pièces jointes
        return _piecesJointes.length >= 3; // 3 documents minimum
      default:
        return true;
    }
  }

  Future<void> _selectDate(Function(DateTime?) onChanged) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    onChanged(date);
  }

  Widget _buildPhotosDegatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre avec numérotation correcte
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[300]!, width: 2),
          ),
          child: Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.green[600], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Case 11: Photos des Dégâts Apparents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Widget de gestion des photos
        PhotoManagerWidget(
          onPhotosChanged: (photos) {
            if (mounted) setState(() {
              _degatsPhotos = photos;
            });
          },
          photosInitiales: _degatsPhotos,
        ),
      ],
    );
  }

  Widget _buildPointChocWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre avec numérotation correcte
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[300]!, width: 2),
          ),
          child: Row(
            children: [
              Icon(Icons.directions_car, color: Colors.orange[600], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Case 10: Point de Choc Initial',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Widget interactif du véhicule
        VehiculePointChocWidget(
          onPointsChocChanged: (points) {
            if (mounted) setState(() {
              _pointsChocSelectionnes = points;
            });
          },
          pointsChocInitiaux: _pointsChocSelectionnes,
        ),
      ],
    );
  }

  void _showChocDialog() {
    // Cette méthode n'est plus utilisée mais on la garde pour compatibilité
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Point de choc initial'),
        content: const Text('Utilisez le widget interactif ci-dessus'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _uploadDocument(String documentType) {
    // TODO: Implémenter l'upload de documents
    setState(() {
      _piecesJointes.add('${documentType.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}');
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$documentType téléchargé (simulation)')),
    );
  }

  Future<void> _saveParticipant() async {
    if (!_validateCurrentPage()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      final participant = Participant(
        id: '',
        sessionId: widget.session.id,
        role: widget.roleAssigne,
        isRegistered: user != null && !widget.isFromInvitation,
        userId: user?.uid,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        adresse: _adresseController.text.trim(),
        tel: _telController.text.trim(),
        email: _emailController.text.trim(),
        cin: _cinController.text.trim(),
        permisNum: _permisNumController.text.trim(),
        permisCat: _permisCatController.text.trim(),
        permisDate: _permisDate,
        assureurId: _assureurId,
        agenceId: _agenceId,
        policeNum: _policeNumController.text.trim(),
        attestationDu: _attestationDu,
        attestationAu: _attestationAu,
        assureNom: _conducteurDifferentAssure ? _assureNomController.text.trim() : null,
        assureAdresse: _conducteurDifferentAssure ? _assureAdresseController.text.trim() : null,
        vehMarque: _vehMarqueController.text.trim(),
        vehType: _vehTypeController.text.trim(),
        immatriculation: _immatriculationController.text.trim(),
        sensSuivi: _sensSuiviController.text.trim(),
        venantDe: _venantDeController.text.trim(),
        allantA: _allantAController.text.trim(),
        degatsText: _degatsTextController.text.trim(),
        degatsPhotos: _degatsPhotos,
        chocInitial: _chocInitial,
        circonstances: _circonstances,
        nbCirconstances: _circonstances.where((c) => c).length,
        piecesJointes: _piecesJointes,
        statutPartie: Participant.STATUT_EN_SAISIE,
      );

      await _sessionService.addParticipant(participant);

      setState(() => _isLoading = false);

      // Naviguer vers l'écran de signature ou de résumé
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Vos informations ont été enregistrées'),
          backgroundColor: Colors.green,
        ),
      );

      // TODO: Naviguer vers l'écran de signature
      Navigator.pop(context);

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}

