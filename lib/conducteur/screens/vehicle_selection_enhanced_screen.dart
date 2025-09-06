import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/vehicule_model.dart';
import '../../services/vehicule_service.dart';
import 'accident_creation_wizard.dart';

/// 🚗 Écran de sélection de véhicule amélioré avec gestion propriétaire/conducteur
class VehicleSelectionEnhancedScreen extends StatefulWidget {
  final String? sessionId;
  final String? roleVehicule;
  final bool isGuest;
  final String? accidentType;
  final int? vehicleCount;

  const VehicleSelectionEnhancedScreen({
    super.key,
    this.sessionId,
    this.roleVehicule,
    this.isGuest = false,
    this.accidentType,
    this.vehicleCount,
  });

  @override
  State<VehicleSelectionEnhancedScreen> createState() => _VehicleSelectionEnhancedScreenState();
}

class _VehicleSelectionEnhancedScreenState extends State<VehicleSelectionEnhancedScreen> {
  List<VehiculeModel> _mesVehicules = [];
  bool _isLoadingVehicules = true;
  VehiculeModel? _vehiculeSelectionne;
  
  // Gestion propriétaire vs conducteur
  bool _estProprietaire = true;
  final _nomConducteurController = TextEditingController();
  final _numeroPermisController = TextEditingController();
  final _dateNaissanceController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerMesVehicules();
  }

  @override
  void dispose() {
    _nomConducteurController.dispose();
    _numeroPermisController.dispose();
    _dateNaissanceController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _chargerMesVehicules() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final vehicules = await VehiculeService.obtenirVehiculesUtilisateur(user.uid);
        setState(() {
          _mesVehicules = vehicules;
          _isLoadingVehicules = false;
        });
      }
    } catch (e) {
      print('Erreur chargement véhicules: $e');
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
          'Sélection du Véhicule',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
      ),
      body: _isLoadingVehicules
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  _buildHeader(),
                  
                  const SizedBox(height: 24),
                  
                  // Mes véhicules
                  if (_mesVehicules.isNotEmpty) ...[
                    _buildMesVehicules(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Ajouter nouveau véhicule
                  _buildAjouterVehicule(),
                  
                  const SizedBox(height: 24),
                  
                  // Gestion propriétaire/conducteur
                  if (_vehiculeSelectionne != null) ...[
                    _buildProprietaireConducteur(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Bouton continuer
                  if (_vehiculeSelectionne != null)
                    _buildBoutonContinuer(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_car,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            widget.isGuest 
                ? 'Véhicule Impliqué'
                : 'Sélectionnez Votre Véhicule',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isGuest
                ? 'Renseignez les informations du véhicule impliqué dans l\'accident'
                : 'Choisissez le véhicule impliqué dans l\'accident',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMesVehicules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes Véhicules Enregistrés',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        ..._mesVehicules.map((vehicule) => _buildVehiculeCard(vehicule)),
      ],
    );
  }

  Widget _buildVehiculeCard(VehiculeModel vehicule) {
    final isSelected = _vehiculeSelectionne?.id == vehicule.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _vehiculeSelectionne = vehicule;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: isSelected ? Colors.blue[600] : Colors.grey[600],
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicule.marque} ${vehicule.modele}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        vehicule.numeroImmatriculation,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      if (vehicule.compagnieAssurance != null)
                        Text(
                          'Assurance: ${vehicule.compagnieAssurance}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Colors.blue[600],
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAjouterVehicule() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: _ajouterNouveauVehicule,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.green[600],
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ajouter un nouveau véhicule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Véhicule non enregistré dans l\'app',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProprietaireConducteur() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Qui Conduisait le Véhicule ?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Radio buttons
            RadioListTile<bool>(
              title: const Text('Moi (Propriétaire)'),
              subtitle: const Text('Je conduisais mon véhicule'),
              value: true,
              groupValue: _estProprietaire,
              onChanged: (value) {
                setState(() {
                  _estProprietaire = value!;
                });
              },
            ),
            
            RadioListTile<bool>(
              title: const Text('Une autre personne'),
              subtitle: const Text('Quelqu\'un d\'autre conduisait'),
              value: false,
              groupValue: _estProprietaire,
              onChanged: (value) {
                setState(() {
                  _estProprietaire = value!;
                });
              },
            ),
            
            // Formulaire conducteur si pas propriétaire
            if (!_estProprietaire) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              const Text(
                'Informations du Conducteur',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nomConducteurController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet du conducteur *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _numeroPermisController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de permis de conduire *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _dateNaissanceController,
                decoration: const InputDecoration(
                  labelText: 'Date de naissance',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _selectionnerDateNaissance,
                readOnly: true,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBoutonContinuer() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _continuer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Continuer',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _ajouterNouveauVehicule() {
    // TODO: Naviguer vers formulaire d'ajout de véhicule
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité d\'ajout de véhicule à implémenter'),
      ),
    );
  }

  void _selectionnerDateNaissance() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 80)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    
    if (date != null) {
      _dateNaissanceController.text = '${date.day}/${date.month}/${date.year}';
    }
  }

  void _continuer() {
    if (_vehiculeSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un véhicule'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validation si conducteur différent
    if (!_estProprietaire) {
      if (_nomConducteurController.text.trim().isEmpty ||
          _numeroPermisController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez remplir les informations obligatoires du conducteur'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Navigation selon le contexte
    if (widget.sessionId != null) {
      // Rejoindre une session existante
      // TODO: Naviguer vers l'écran de constat avec le rôle assigné
    } else {
      // Créer nouvelle session
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AccidentCreationWizard(
            vehiculeSelectionne: _vehiculeSelectionne!,
            estProprietaire: _estProprietaire,
            infoConducteur: !_estProprietaire ? {
              'nom': _nomConducteurController.text.trim(),
              'numeroPermis': _numeroPermisController.text.trim(),
              'dateNaissance': _dateNaissanceController.text.trim(),
              'telephone': _telephoneController.text.trim(),
            } : null,
          ),
        ),
      );
    }
  }
}
