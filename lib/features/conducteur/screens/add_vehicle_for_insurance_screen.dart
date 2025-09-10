import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/complete_insurance_workflow_service.dart';
import '../../../features/conducteur/services/insurance_data_service.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/services/logging_service.dart';

/// 🚗 Écran amélioré pour demande d'assurance (workflow complet tunisien)
/// Suit le processus : Demande → Agent crée contrat → Paiement hors app → Documents
class AddVehicleForInsuranceScreen extends StatefulWidget {
  const AddVehicleForInsuranceScreen({Key? key}) : super(key: key);

  @override
  State<AddVehicleForInsuranceScreen> createState() => _AddVehicleForInsuranceScreenState();
}

class _AddVehicleForInsuranceScreenState extends State<AddVehicleForInsuranceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isFormValid = false;

  // Contrôleurs pour les champs
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _immatriculationController = TextEditingController();
  final _couleurController = TextEditingController();
  final _anneeController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  final _puissanceFiscaleController = TextEditingController();
  final _cylindreeController = TextEditingController();
  final _poidsController = TextEditingController();
  final _numeroCarteGriseController = TextEditingController();
  final _permisController = TextEditingController();
  final _adresseController = TextEditingController();

  // Sélections
  String? _selectedCompagnie;
  String? _selectedAgence;
  String _selectedTypeVehicule = 'VP';
  String _selectedCarburant = 'Essence';
  String _selectedUsage = 'Personnel';
  int _selectedNombrePlaces = 5;
  DateTime? _selectedDateImmatriculation;
  DateTime? _selectedDatePermis;

  // Données des compagnies et agences
  List<Map<String, dynamic>> _compagnies = [];
  List<Map<String, dynamic>> _agences = [];

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadCompagnies();
    _setupFormValidation();
    });
  }

  void _setupFormValidation() {
    // Ajouter des listeners pour valider le formulaire en temps réel
    _marqueController.addListener(_validateForm);
    _modeleController.addListener(_validateForm);
    _immatriculationController.addListener(_validateForm);
    _anneeController.addListener(_validateForm);
    _permisController.addListener(_validateForm);
    _adresseController.addListener(_validateForm);
  }

  void _validateForm() {
    final isValid = _marqueController.text.trim().isNotEmpty &&
        _modeleController.text.trim().isNotEmpty &&
        _immatriculationController.text.trim().isNotEmpty &&
        _anneeController.text.trim().isNotEmpty &&
        _permisController.text.trim().isNotEmpty &&
        _adresseController.text.trim().isNotEmpty &&
        _selectedCompagnie != null &&
        _selectedAgence != null;

    if (isValid != _isFormValid) {
      if (mounted) setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    // Supprimer les listeners avant de disposer
    _marqueController.removeListener(_validateForm);
    _modeleController.removeListener(_validateForm);
    _immatriculationController.removeListener(_validateForm);
    _anneeController.removeListener(_validateForm);
    _permisController.removeListener(_validateForm);
    _adresseController.removeListener(_validateForm);

    _marqueController.dispose();
    _modeleController.dispose();
    _immatriculationController.dispose();
    _couleurController.dispose();
    _anneeController.dispose();
    _numeroSerieController.dispose();
    _puissanceFiscaleController.dispose();
    _cylindreeController.dispose();
    _poidsController.dispose();
    _numeroCarteGriseController.dispose();
    _permisController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _loadCompagnies() async {
    try {
      final compagnies = await InsuranceDataService.getCompagnies();
      if (mounted) setState(() {
        _compagnies = compagnies;
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des compagnies: $e');
    }
  }

  Future<void> _loadAgences(String compagnieId) async {
    try {
      final agences = await InsuranceDataService.getAgencesByCompagnie(compagnieId);
      if (mounted) setState(() {
        _agences = agences;
        _selectedAgence = null; // Reset selection
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des agences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demande d\'Assurance'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 20),
                _buildCompagnieSection(),
                const SizedBox(height: 20),
                _buildVehicleInfoSection(),
                const SizedBox(height: 20),
                _buildTechnicalInfoSection(),
                const SizedBox(height: 20),
                _buildOwnerInfoSection(),
                const SizedBox(height: 30),
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.timeline, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Processus d\'assurance tunisien',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProcessStep('1', 'Vous soumettez votre demande', true, Icons.send),
            _buildProcessStep('2', 'L\'agent crée votre contrat', false, Icons.assignment),
            _buildProcessStep('3', 'Vous payez (agence/D17/virement)', false, Icons.payment),
            _buildProcessStep('4', 'Documents numériques générés', false, Icons.description),
            _buildProcessStep('5', 'Carte verte avec QR Code', false, Icons.qr_code),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pas de paiement dans l\'app - Processus sécurisé tunisien',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessStep(String number, String text, bool isActive, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.blue.shade600 : Colors.grey.shade300,
              boxShadow: isActive ? [
                BoxShadow(
                  color: Colors.blue.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            icon,
            color: isActive ? Colors.blue.shade600 : Colors.grey.shade400,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isActive ? Colors.blue.shade700 : Colors.grey.shade600,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompagnieSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏢 Compagnie d\'Assurance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCompagnie,
              decoration: const InputDecoration(
                labelText: 'Choisir une compagnie *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              items: _compagnies.map((compagnie) {
                return DropdownMenuItem<String>(
                  value: compagnie['id'],
                  child: Text(compagnie['nom'] ?? 'Compagnie'),
                );
              }).toList(),
              onChanged: (value) {
                if (mounted) setState(() {
                  _selectedCompagnie = value;
                  _selectedAgence = null;
                });
                if (value != null) {
                  _loadAgences(value);
                }
                _validateForm();
              },
              validator: (value) => value == null ? 'Veuillez choisir une compagnie' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedAgence,
              decoration: const InputDecoration(
                labelText: 'Choisir une agence *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              items: _agences.map((agence) {
                return DropdownMenuItem<String>(
                  value: agence['id'],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(agence['nom'] ?? 'Agence'),
                      Text(
                        agence['adresse'] ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (mounted) setState(() {
                  _selectedAgence = value;
                });
                _validateForm();
              },
              validator: (value) => value == null ? 'Veuillez choisir une agence' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚗 Informations du Véhicule',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _marqueController,
                    decoration: const InputDecoration(
                      labelText: 'Marque *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _modeleController,
                    decoration: const InputDecoration(
                      labelText: 'Modèle *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _immatriculationController,
                    decoration: const InputDecoration(
                      labelText: 'Immatriculation *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.confirmation_number),
                      hintText: 'Ex: 123 TUN 456',
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _anneeController,
                    decoration: const InputDecoration(
                      labelText: 'Année *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Champ requis';
                      final year = int.tryParse(value!);
                      if (year == null || year < 1990 || year > DateTime.now().year + 1) {
                        return 'Année invalide';
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

  Widget _buildTechnicalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚙️ Informations Techniques',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Type de véhicule et carburant
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTypeVehicule,
                    decoration: const InputDecoration(
                      labelText: 'Type de véhicule',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'VP', child: Text('Voiture Particulière')),
                      DropdownMenuItem(value: 'VU', child: Text('Véhicule Utilitaire')),
                      DropdownMenuItem(value: 'MOTO', child: Text('Motocyclette')),
                      DropdownMenuItem(value: 'TAXI', child: Text('Taxi')),
                    ],
                    onChanged: (value) => setState(() => _selectedTypeVehicule = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCarburant,
                    decoration: const InputDecoration(
                      labelText: 'Carburant',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Essence', child: Text('Essence')),
                      DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
                      DropdownMenuItem(value: 'Hybride', child: Text('Hybride')),
                      DropdownMenuItem(value: 'Électrique', child: Text('Électrique')),
                    ],
                    onChanged: (value) => setState(() => _selectedCarburant = value!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '👤 Informations Conducteur',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _permisController,
              decoration: const InputDecoration(
                labelText: 'Numéro de permis *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse complète *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 2,
              validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      children: [
        // Indicateur de validation du formulaire
        if (!_isFormValid && !_isLoading)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Veuillez remplir tous les champs obligatoires (*) pour continuer',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: (_isLoading || !_isFormValid) ? null : _submitVehicle,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_isLoading || !_isFormValid) ? Colors.grey : Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _isFormValid ? 'Soumettre ma demande' : 'Formulaire incomplet',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompagnie == null || _selectedAgence == null) {
      _showErrorSnackBar('Veuillez sélectionner une compagnie et une agence');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw const AuthException('Utilisateur non connecté');

      // Récupérer les infos du conducteur
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Préparer les données du véhicule (format amélioré)
      final vehicleData = {
        'marque': _marqueController.text.trim(),
        'modele': _modeleController.text.trim(),
        'immatriculation': _immatriculationController.text.trim().toUpperCase(),
        'couleur': _couleurController.text.trim().isEmpty ? 'Non spécifiée' : _couleurController.text.trim(),
        'annee': int.parse(_anneeController.text.trim()),
        'typeVehicule': _selectedTypeVehicule,
        'carburant': _selectedCarburant,
        'usage': _selectedUsage,
        'nombrePlaces': _selectedNombrePlaces,
        'numeroSerie': _numeroSerieController.text.trim(),
        'puissanceFiscale': _puissanceFiscaleController.text.trim(),
        'cylindree': _cylindreeController.text.trim(),
        'poids': double.tryParse(_poidsController.text.trim()) ?? 0.0,
        'numeroCarteGrise': _numeroCarteGriseController.text.trim(),
        'submittedAt': DateTime.now().toIso8601String(),
      };

      // Préparer les données du conducteur (format amélioré)
      final conducteurData = {
        'nom': userData['nom'] ?? '',
        'prenom': userData['prenom'] ?? '',
        'telephone': userData['telephone'] ?? '',
        'email': userData['email'] ?? user.email ?? '',
        'adresse': _adresseController.text.trim(),
        'permisNumber': _permisController.text.trim(),
        'cin': userData['cin'] ?? '',
        'dateNaissance': userData['dateNaissance'],
        'submittedAt': DateTime.now().toIso8601String(),
      };

      LoggingService.info('INSURANCE_REQUEST', '🚀 Soumission demande assurance via nouveau workflow');

      // Utiliser le nouveau service de workflow complet
      final result = await CompleteInsuranceWorkflowService.submitInsuranceRequest(
        conducteurData: conducteurData,
        vehicleData: vehicleData,
        compagnieId: _selectedCompagnie!,
        agenceId: _selectedAgence!,
      );

      // Succès - Afficher le résultat avec plus de détails
      if (mounted) {
        _showSuccessDialog(result);
      }

    } on AuthException catch (e) {
      _showErrorSnackBar('Erreur d\'authentification: ${e.message}');
    } on BusinessException catch (e) {
      _showErrorSnackBar('Erreur métier: ${e.message}');
    } catch (e) {
      LoggingService.error('INSURANCE_REQUEST', '❌ Erreur soumission demande', e);
      _showErrorSnackBar('Erreur inattendue: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🎉 Afficher le dialog de succès avec détails du processus
  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Demande soumise!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result['message'] ?? 'Demande soumise avec succès',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Prochaines étapes:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('📋 ${result['nextStep'] ?? 'L\'agent va traiter votre dossier'}'),
                  const SizedBox(height: 4),
                  const Text('💰 Vous recevrez les détails de paiement'),
                  const SizedBox(height: 4),
                  const Text('📱 Paiement via agence, D17 ou virement'),
                  const SizedBox(height: 4),
                  const Text('📄 Documents numériques automatiques'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ID de demande: ${result['requestId']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer dialog
              Navigator.of(context).pop(); // Retourner à l'écran précédent
            },
            child: const Text('Parfait!'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer dialog
              Navigator.of(context).pop(); // Retourner à l'écran précédent
              // TODO: Naviguer vers l'écran de suivi des demandes
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Suivre ma demande'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

