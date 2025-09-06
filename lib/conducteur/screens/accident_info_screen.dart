import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/vehicule_model.dart';
import '../../models/accident_session.dart';
import 'accident_invitations_screen.dart';

/// 📋 Écran 2 - Informations communes de l'accident (cases 1-5, 13, 14)
class AccidentInfoScreen extends StatefulWidget {
  final VehiculeModel vehiculeSelectionne;

  const AccidentInfoScreen({
    Key? key,
    required this.vehiculeSelectionne,
  }) : super(key: key);

  @override
  State<AccidentInfoScreen> createState() => _AccidentInfoScreenState();
}

class _AccidentInfoScreenState extends State<AccidentInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lieuController = TextEditingController();
  final _observationsController = TextEditingController();
  
  // Cases 1-2: Date, heure, lieu
  DateTime _dateAccident = DateTime.now();
  TimeOfDay _heureAccident = TimeOfDay.now();
  String? _lieuGps;
  bool _isLoadingLocation = false;
  
  // Case 3: Blessés
  bool? _blesses;
  
  // Case 4: Dégâts matériels autres
  bool? _degatsAutres;
  
  // Case 5: Témoins
  List<Temoin> _temoins = [];
  
  // Photos
  List<String> _photosIds = [];
  
  @override
  void dispose() {
    _lieuController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  /// 📍 Obtenir la localisation actuelle
  Future<void> _obtenirLocalisation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée définitivement');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final adresse = [
          placemark.street,
          placemark.locality,
          placemark.postalCode,
          placemark.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _lieuController.text = adresse;
          _lieuGps = '${position.latitude},${position.longitude}';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de localisation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  /// 📅 Sélectionner la date
  Future<void> _selectionnerDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateAccident,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );

    if (date != null) {
      setState(() {
        _dateAccident = date;
      });
    }
  }

  /// 🕐 Sélectionner l'heure
  Future<void> _selectionnerHeure() async {
    final heure = await showTimePicker(
      context: context,
      initialTime: _heureAccident,
    );

    if (heure != null) {
      setState(() {
        _heureAccident = heure;
      });
    }
  }

  /// 👥 Ajouter un témoin
  void _ajouterTemoin() {
    showDialog(
      context: context,
      builder: (context) => _TemoinDialog(
        onTemoinAjoute: (temoin) {
          setState(() {
            _temoins.add(temoin);
          });
        },
      ),
    );
  }

  /// ➡️ Continuer vers les invitations
  void _continuer() {
    if (!_formKey.currentState!.validate()) return;

    if (_blesses == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez indiquer s\'il y a des blessés'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_degatsAutres == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez indiquer s\'il y a des dégâts matériels autres'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Afficher bannière sécurité si blessés
    if (_blesses == true) {
      _showSecuriteDialog();
      return;
    }

    _naviguerVersInvitations();
  }

  /// ⚠️ Dialog sécurité pour blessés
  void _showSecuriteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.medical_services, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Sécurité / Urgence'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '⚠️ BLESSÉS SIGNALÉS ⚠️',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'En cas de blessés, même légers :\n\n'
              '• Appelez immédiatement les secours (190)\n'
              '• Ne déplacez pas les blessés\n'
              '• Sécurisez la zone\n'
              '• Attendez les forces de l\'ordre\n\n'
              'Vous pouvez continuer la déclaration après avoir pris ces mesures.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Lancer l'appel d'urgence
            },
            icon: const Icon(Icons.phone, color: Colors.red),
            label: const Text('Appeler 190'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _naviguerVersInvitations();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  /// ➡️ Naviguer vers l'écran d'invitations
  void _naviguerVersInvitations() async {
    // Récupérer les informations d'assurance du véhicule depuis Firestore
    Map<String, dynamic> assuranceInfo = {};
    try {
      // Chercher dans demandes_contrats pour récupérer les infos d'assurance
      final contratsSnapshot = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('conducteurId', isEqualTo: widget.vehiculeSelectionne.conducteurId)
          .where('statut', whereIn: ['contrat_actif', 'contrat_valide'])
          .where('numeroImmatriculation', isEqualTo: widget.vehiculeSelectionne.numeroImmatriculation)
          .limit(1)
          .get();

      if (contratsSnapshot.docs.isNotEmpty) {
        final contratData = contratsSnapshot.docs.first.data();
        assuranceInfo = {
          'compagnieAssurance': contratData['compagnieNom'] ?? contratData['compagnieAssurance'] ?? 'Assurance Elite Tunisie',
          'agenceAssurance': contratData['agenceNom'] ?? contratData['agenceAssurance'] ?? 'Agence Centrale Tunis',
          'numeroPolice': contratData['numeroContrat'] ?? contratData['numeroPolice'] ?? 'N/A',
          'agentNom': contratData['agentNom'] ?? 'Agent inconnu',
          'agentTelephone': contratData['agentTelephone'] ?? '',
          // Informations supplémentaires du contrat
          'numeroDemande': contratData['numeroDemande'] ?? '',
          'typeContrat': contratData['typeContrat'] ?? '',
          'prime': contratData['prime'] ?? 0,
          'franchise': contratData['franchise'] ?? 0,
          'statutContrat': contratData['statut'] ?? '',
        };
        print('✅ Informations complètes du contrat récupérées:');
        print('   - Contrat: ${assuranceInfo['numeroPolice']}');
        print('   - Compagnie: ${assuranceInfo['compagnieAssurance']}');
        print('   - Agence: ${assuranceInfo['agenceAssurance']}');
        print('   - Type: ${assuranceInfo['typeContrat']}');
        print('   - Statut: ${assuranceInfo['statutContrat']}');
      } else {
        // Valeurs par défaut si aucun contrat trouvé
        assuranceInfo = {
          'compagnieAssurance': widget.vehiculeSelectionne.compagnieAssurance ?? 'Compagnie inconnue',
          'agenceAssurance': widget.vehiculeSelectionne.agenceNom ?? 'Agence inconnue',
          'numeroPolice': widget.vehiculeSelectionne.numeroPolice ?? 'N/A',
          'agentNom': 'Agent inconnu',
          'agentTelephone': '',
        };
        print('⚠️ Aucun contrat trouvé, utilisation des données du véhicule');
      }
    } catch (e) {
      print('❌ Erreur récupération infos assurance: $e');
      // Valeurs par défaut en cas d'erreur
      assuranceInfo = {
        'compagnieAssurance': 'Compagnie inconnue',
        'agenceAssurance': 'Agence inconnue',
        'numeroPolice': 'N/A',
        'agentNom': 'Agent inconnu',
        'agentTelephone': '',
      };
    }

    // Créer l'identité du véhicule créateur avec les infos d'assurance
    final identiteVehiculeCreateur = IdentiteVehicule(
      marque: widget.vehiculeSelectionne.marque,
      type: widget.vehiculeSelectionne.modele,
      numeroImmatriculation: widget.vehiculeSelectionne.numeroImmatriculation,
      senssuivi: '', // Sera rempli plus tard
      venantDe: '', // Sera rempli plus tard
      allantA: '', // Sera rempli plus tard
    );

    // Créer la session d'accident
    final session = AccidentSession(
      id: '', // Sera généré par Firestore
      codePublic: _genererCodePublic(),
      createurUserId: widget.vehiculeSelectionne.conducteurId,
      createurVehiculeId: widget.vehiculeSelectionne.id,
      statut: AccidentSession.STATUT_BROUILLON,
      dateOuverture: DateTime.now(),
      dateAccident: _dateAccident,
      heureAccident: _heureAccident,
      localisation: {
        'adresse': _lieuController.text.trim(),
        'lat': _lieuGps?.split(',')[0],
        'lng': _lieuGps?.split(',')[1],
        'ville': '',
        'codePostal': '',
        // Ajouter les informations d'assurance dans la localisation pour accès facile
        'assuranceInfo': assuranceInfo,
      },
      blesses: _blesses ?? false,
      degatsAutres: _degatsAutres ?? false,
      degatsApparents: {}, // Sera rempli par rôle
      circonstances: {}, // Sera rempli par rôle
      temoins: _temoins,
      identitesVehicules: {'A': identiteVehiculeCreateur}, // Véhicule créateur = rôle A
      pointsChocInitial: {},
      croquisFileId: null,
      croquisData: null,
      observations: _observationsController.text.trim(),
      photos: [], // TODO: Convertir _photosIds en PhotoMetadata
      nombreParticipants: 2,
      rolesDisponibles: ['A', 'B'],
      deadlineDeclaration: _dateAccident.add(const Duration(days: 5)),
      declarationUnilaterale: false,
      dateCreation: DateTime.now(),
      dateModification: DateTime.now(),
      observationsVehicules: {}, // Sera rempli par rôle
      signatures: {}, // Sera rempli lors de la signature
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccidentInvitationsScreen(
          session: session,
          vehiculeCreateur: widget.vehiculeSelectionne,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Informations de l\'Accident',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Véhicule sélectionné
              _buildVehiculeInfo(),
              
              const SizedBox(height: 24),
              
              // Cases 1-2: Date, heure, lieu
              _buildDateHeureLieu(),
              
              const SizedBox(height: 24),
              
              // Cases 3-4: Blessés et dégâts
              _buildBlessesEtDegats(),
              
              const SizedBox(height: 24),
              
              // Case 5: Témoins
              _buildTemoins(),
              
              const SizedBox(height: 24),
              
              // Case 14: Observations
              _buildObservations(),
              
              const SizedBox(height: 24),
              
              // Photos
              _buildPhotos(),
              
              const SizedBox(height: 32),
              
              // Bouton continuer
              SizedBox(
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
                    'Continuer vers les invitations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehiculeInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Véhicule sélectionné:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${widget.vehiculeSelectionne.marque} ${widget.vehiculeSelectionne.modele}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.vehiculeSelectionne.numeroImmatriculation,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeureLieu() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Cases 1-2: Date, heure et lieu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Date et heure
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectionnerDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date de l\'accident',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${_dateAccident.day.toString().padLeft(2, '0')}/${_dateAccident.month.toString().padLeft(2, '0')}/${_dateAccident.year}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectionnerHeure,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Heure',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        '${_heureAccident.hour.toString().padLeft(2, '0')}:${_heureAccident.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Lieu
            TextFormField(
              controller: _lieuController,
              decoration: const InputDecoration(
                labelText: 'Lieu de l\'accident *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                hintText: 'Adresse complète',
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le lieu est obligatoire';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoadingLocation ? null : _obtenirLocalisation,
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_isLoadingLocation 
                    ? 'Localisation...' 
                    : 'Utiliser ma position'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlessesEtDegats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.health_and_safety,
                  color: Colors.red[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Cases 3-4: Blessés et dégâts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Case 3: Blessés
            const Text(
              'Y a-t-il des blessés (même légers) ?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Oui'),
                    value: true,
                    groupValue: _blesses,
                    onChanged: (value) {
                      setState(() {
                        _blesses = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Non'),
                    value: false,
                    groupValue: _blesses,
                    onChanged: (value) {
                      setState(() {
                        _blesses = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Case 4: Dégâts matériels autres
            const Text(
              'Y a-t-il des dégâts matériels autres qu\'aux véhicules A et B ?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Oui'),
                    value: true,
                    groupValue: _degatsAutres,
                    onChanged: (value) {
                      setState(() {
                        _degatsAutres = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Non'),
                    value: false,
                    groupValue: _degatsAutres,
                    onChanged: (value) {
                      setState(() {
                        _degatsAutres = value;
                      });
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

  Widget _buildTemoins() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Colors.orange[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Case 5: Témoins',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _ajouterTemoin,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            
            if (_temoins.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Aucun témoin ajouté',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              ..._temoins.asMap().entries.map((entry) {
                final index = entry.key;
                final temoin = entry.value;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange[100],
                    child: Text('${index + 1}'),
                  ),
                  title: Text('${temoin.prenom} ${temoin.nom}'),
                  subtitle: Text(temoin.telephone),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _temoins.removeAt(index);
                      });
                    },
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildObservations() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.comment,
                  color: Colors.purple[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Case 14: Observations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _observationsController,
              decoration: const InputDecoration(
                labelText: 'Observations sur l\'accident',
                border: OutlineInputBorder(),
                hintText: 'Décrivez les circonstances de l\'accident...',
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotos() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.camera_alt,
                  color: Colors.green[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Photos de l\'accident',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implémenter la prise de photo
                  },
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Minimum 4 photos recommandées: vue générale, dégâts, plaques d\'immatriculation',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            
            if (_photosIds.isEmpty) ...[
              const SizedBox(height: 16),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Text(
                    'Aucune photo ajoutée',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 🎲 Générer un code public unique
  String _genererCodePublic() {
    final now = DateTime.now();
    final year = now.year;
    final timestamp = now.millisecondsSinceEpoch.toString().substring(8);
    return 'ACC-$year-$timestamp';
  }
}

/// Dialog pour ajouter un témoin
class _TemoinDialog extends StatefulWidget {
  final Function(Temoin) onTemoinAjoute;

  const _TemoinDialog({required this.onTemoinAjoute});

  @override
  State<_TemoinDialog> createState() => _TemoinDialogState();
}

class _TemoinDialogState extends State<_TemoinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  void _ajouter() {
    if (_formKey.currentState!.validate()) {
      final temoin = Temoin(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        adresse: _adresseController.text.trim(),
        telephone: _telephoneController.text.trim(),
      );
      
      widget.onTemoinAjoute(temoin);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un témoin'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _prenomController,
              decoration: const InputDecoration(
                labelText: 'Prénom *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le prénom est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'L\'adresse est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telephoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le téléphone est obligatoire';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _ajouter,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
