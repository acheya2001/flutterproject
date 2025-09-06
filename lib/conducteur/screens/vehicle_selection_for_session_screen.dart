import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/vehicule_model.dart';
import '../../services/vehicule_service.dart';
import '../../models/accident_session_complete.dart';
import 'accident_form_step1_infos_generales.dart';

/// 🚗 Écran de sélection de véhicule pour conducteurs inscrits dans une session
class VehicleSelectionForSessionScreen extends StatefulWidget {
  final AccidentSessionComplete session;

  const VehicleSelectionForSessionScreen({
    super.key,
    required this.session,
  });

  @override
  State<VehicleSelectionForSessionScreen> createState() => _VehicleSelectionForSessionScreenState();
}

class _VehicleSelectionForSessionScreenState extends State<VehicleSelectionForSessionScreen> {
  bool _isLoading = true;
  List<VehiculeModel> _vehicules = [];
  VehiculeModel? _vehiculeSelectionne;
  bool _estProprietaire = true;
  bool _autrePersonneAPermis = true;
  
  // Contrôleurs pour les infos du conducteur (si différent du propriétaire)
  final _nomConducteurController = TextEditingController();
  final _prenomConducteurController = TextEditingController();
  final _adresseConducteurController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerVehicules();
  }

  @override
  void dispose() {
    _nomConducteurController.dispose();
    _prenomConducteurController.dispose();
    _adresseConducteurController.dispose();
    super.dispose();
  }

  Future<void> _chargerVehicules() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Charger les véhicules depuis vehicules_assures avec statut actif
        final snapshot = await FirebaseFirestore.instance
            .collection('vehicules_assures')
            .where('conducteurId', isEqualTo: user.uid)
            .where('statut', isEqualTo: 'actif')
            .get();

        print('🚗 ${snapshot.docs.length} véhicules trouvés dans vehicules_assures');

        List<VehiculeModel> vehiculesCharges = [];

        for (final doc in snapshot.docs) {
          final data = doc.data();

          // Vérifier si le contrat est actif (date de fin > maintenant)
          final dateFinContrat = (data['dateFinContrat'] as Timestamp?)?.toDate();
          final contratActif = dateFinContrat != null && dateFinContrat.isAfter(DateTime.now());

          if (contratActif) {
            vehiculesCharges.add(VehiculeModel(
              id: doc.id,
              conducteurId: user.uid,
              marque: data['marque'] ?? 'N/A',
              modele: data['modele'] ?? 'N/A',
              numeroImmatriculation: data['immatriculation'] ?? 'N/A',
              compagnieAssurance: data['compagnieNom'] ?? 'N/A',
              numeroPolice: data['numeroContrat'] ?? 'N/A',
              contratActif: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              // Données supplémentaires pour le constat
              compagnieId: data['compagnieId'],
              agenceId: data['agenceId'],
              agenceNom: data['agenceNom'],
              dateDebutContrat: (data['dateDebutContrat'] as Timestamp?)?.toDate(),
              dateFinContrat: dateFinContrat,
            ));
          }
        }

        // Si aucun véhicule dans vehicules_assures, essayer depuis demandes_contrats
        if (vehiculesCharges.isEmpty) {
          final contratsSnapshot = await FirebaseFirestore.instance
              .collection('demandes_contrats')
              .where('conducteurId', isEqualTo: user.uid)
              .where('statut', isEqualTo: 'contrat_actif')
              .get();

          print('📄 ${contratsSnapshot.docs.length} contrats actifs trouvés');

          for (final doc in contratsSnapshot.docs) {
            final data = doc.data();
            vehiculesCharges.add(VehiculeModel(
              id: doc.id,
              conducteurId: user.uid,
              marque: data['marque'] ?? 'N/A',
              modele: data['modele'] ?? 'N/A',
              numeroImmatriculation: data['immatriculation'] ?? 'N/A',
              compagnieAssurance: data['compagnieNom'] ?? 'N/A',
              numeroPolice: data['numeroContrat'] ?? 'N/A',
              contratActif: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              // Données supplémentaires
              compagnieId: data['compagnieId'],
              agenceId: data['agenceId'],
              agenceNom: data['agenceNom'],
            ));
          }
        }

        setState(() {
          _vehicules = vehiculesCharges;
          _isLoading = false;
        });

        print('✅ ${_vehicules.length} véhicules assurés chargés');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des véhicules: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sélection du véhicule',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicules.isEmpty
              ? _buildAucunVehicule()
              : _buildSelectionVehicule(),
    );
  }

  Widget _buildAucunVehicule() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 12),
            
            const Text(
              'Vous n\'avez aucun véhicule avec une assurance active. Veuillez ajouter un véhicule ou vérifier vos contrats d\'assurance.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Naviguer vers l'ajout de véhicule
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité d\'ajout de véhicule à implémenter'),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un véhicule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionVehicule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions
          _buildInstructions(),
          
          const SizedBox(height: 24),
          
          // Liste des véhicules
          _buildListeVehicules(),
          
          if (_vehiculeSelectionne != null) ...[
            const SizedBox(height: 24),
            
            // Question propriétaire
            _buildQuestionProprietaire(),
            
            if (!_estProprietaire) ...[
              const SizedBox(height: 24),
              
              // Informations du conducteur
              _buildInfosConducteur(),
            ],
            
            const SizedBox(height: 32),
            
            // Bouton continuer
            _buildBoutonContinuer(),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Sélection du véhicule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            'Sélectionnez le véhicule impliqué dans l\'accident parmi vos véhicules assurés avec un contrat actif.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeVehicules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vos véhicules assurés',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        ..._vehicules.map((vehicule) => _buildCarteVehicule(vehicule)).toList(),
      ],
    );
  }

  Widget _buildCarteVehicule(VehiculeModel vehicule) {
    final isSelected = _vehiculeSelectionne?.id == vehicule.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _vehiculeSelectionne = vehicule;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icône véhicule
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: isSelected ? Colors.blue[600] : Colors.grey[600],
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Informations véhicule
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicule.marque} ${vehicule.modele}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue[700] : Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        vehicule.numeroImmatriculation,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Assuré',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            vehicule.compagnieAssurance ?? 'Assurance',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Indicateur de sélection
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

  Widget _buildQuestionProprietaire() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Qui conduisait le véhicule ?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _estProprietaire ? Colors.blue[50] : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _estProprietaire ? Colors.blue[300]! : Colors.grey[300]!,
                      ),
                    ),
                    child: RadioListTile<bool>(
                      title: const Text('Moi (propriétaire)'),
                      value: true,
                      groupValue: _estProprietaire,
                      onChanged: (value) {
                        setState(() {
                          _estProprietaire = value!;
                        });
                      },
                      activeColor: Colors.blue[600],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: !_estProprietaire ? Colors.orange[50] : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !_estProprietaire ? Colors.orange[300]! : Colors.grey[300]!,
                      ),
                    ),
                    child: RadioListTile<bool>(
                      title: const Text('Autre personne'),
                      value: false,
                      groupValue: _estProprietaire,
                      onChanged: (value) {
                        setState(() {
                          _estProprietaire = value!;
                        });
                      },
                      activeColor: Colors.orange[600],
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

  Widget _buildInfosConducteur() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations du conducteur',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Nom et prénom
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nomConducteurController,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _prenomConducteurController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Adresse
            TextFormField(
              controller: _adresseConducteurController,
              decoration: const InputDecoration(
                labelText: 'Adresse *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Question permis
            const Text(
              'Le conducteur a-t-il un permis de conduire valide ?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _autrePersonneAPermis ? Colors.green[50] : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _autrePersonneAPermis ? Colors.green[300]! : Colors.grey[300]!,
                      ),
                    ),
                    child: RadioListTile<bool>(
                      title: const Text('Oui, j\'ai un permis'),
                      value: true,
                      groupValue: _autrePersonneAPermis,
                      onChanged: (value) {
                        setState(() {
                          _autrePersonneAPermis = value!;
                        });
                      },
                      activeColor: Colors.green[600],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: !_autrePersonneAPermis ? Colors.red[50] : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !_autrePersonneAPermis ? Colors.red[300]! : Colors.grey[300]!,
                      ),
                    ),
                    child: RadioListTile<bool>(
                      title: const Text('Non, pas de permis'),
                      value: false,
                      groupValue: _autrePersonneAPermis,
                      onChanged: (value) {
                        setState(() {
                          _autrePersonneAPermis = value!;
                        });
                      },
                      activeColor: Colors.red[600],
                    ),
                  ),
                ),
              ],
            ),

            // Champs supplémentaires si la personne a un permis
            if (_autrePersonneAPermis) ...[
              const SizedBox(height: 16),

              const Text(
                'Informations du permis de conduire',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Numéro de permis *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                  hintText: 'Ex: 123456789',
                ),
                validator: _autrePersonneAPermis
                    ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Numéro de permis requis';
                        }
                        return null;
                      }
                    : null,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Date de délivrance',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        hintText: 'JJ/MM/AAAA',
                      ),
                      readOnly: true,
                      onTap: () {
                        // TODO: Sélecteur de date
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Catégorie',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                        hintText: 'Ex: B',
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (!_autrePersonneAPermis) ...[
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
                        'Attention : Conduire sans permis est une infraction grave qui peut affecter la couverture d\'assurance.',
                        style: TextStyle(
                          fontSize: 12,
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
    );
  }

  Widget _buildBoutonContinuer() {
    final peutContinuer = _vehiculeSelectionne != null &&
                         (_estProprietaire ||
                          (_nomConducteurController.text.trim().isNotEmpty &&
                           _prenomConducteurController.text.trim().isNotEmpty &&
                           _adresseConducteurController.text.trim().isNotEmpty));

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: peutContinuer ? _continuer : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: peutContinuer ? Colors.blue[600] : Colors.grey[300],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continuer',
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
    );
  }

  void _continuer() {
    if (_vehiculeSelectionne == null) return;

    // Créer les données du véhicule sélectionné avec informations du conducteur
    final vehiculeData = {
      'vehicule': _vehiculeSelectionne!,
      'estProprietaire': _estProprietaire,
      'conducteur': {
        'nom': _estProprietaire ? 'Propriétaire' : _nomConducteurController.text.trim(),
        'prenom': _estProprietaire ? 'Propriétaire' : _prenomConducteurController.text.trim(),
        'adresse': _estProprietaire ? 'Adresse propriétaire' : _adresseConducteurController.text.trim(),
        'aPermis': _estProprietaire ? true : _autrePersonneAPermis,
      },
    };

    // Naviguer vers l'étape suivante avec les données du véhicule
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AccidentFormStep1InfosGenerales(
          session: widget.session,
          vehiculeSelectionne: vehiculeData,
        ),
      ),
    );
  }
}
