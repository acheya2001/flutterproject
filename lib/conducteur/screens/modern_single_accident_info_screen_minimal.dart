import 'package:flutter/material.dart';
import '../../models/collaborative_session_model.dart';
import '../../services/conducteur_data_service.dart';

/// Version ultra-simplifiée pour identifier le problème
class ModernSingleAccidentInfoScreenMinimal extends StatefulWidget {
  final String typeAccident;
  final CollaborativeSession? session;
  final bool isCollaborative;
  final String? roleVehicule;

  ModernSingleAccidentInfoScreenMinimal({
    super.key,
    required this.typeAccident,
    this.session,
    this.isCollaborative = false,
    this.roleVehicule,
  }) {
    print('🔥 CONSTRUCTEUR ModernSingleAccidentInfoScreenMinimal');
    print('🔥 typeAccident: $typeAccident');
    print('🔥 isCollaborative: $isCollaborative');
  }

  @override
  State<ModernSingleAccidentInfoScreenMinimal> createState() {
    print('🔥 createState() appelé');
    return _ModernSingleAccidentInfoScreenMinimalState();
  }
}

class _ModernSingleAccidentInfoScreenMinimalState extends State<ModernSingleAccidentInfoScreenMinimal> {

  // Variables d'état de base
  bool _isInitialized = false;
  bool _donneesChargees = false;
  bool _chargementEnCours = false;
  Map<String, dynamic>? _donneesConducteur;

  @override
  void initState() {
    print('🔥 initState() DÉBUT');
    super.initState();

    // Test 1: Ajouter l'initialisation de base
    _isInitialized = true;
    print('🔥 _isInitialized = true');

    print('🔥 initState() TERMINÉ');
  }

  /// Test de la méthode de chargement des données
  Future<void> _chargerDonneesConducteur() async {
    print('🔥 _chargerDonneesConducteur() DÉBUT');
    try {
      final donnees = await ConducteurDataService.recupererDonneesConducteur();
      print('🔥 Données récupérées: ${donnees != null ? "OUI" : "NON"}');

      if (mounted) {
        setState(() {
          _donneesConducteur = donnees;
          _donneesChargees = true;
          _chargementEnCours = false;
        });
        print('🔥 setState() appelé avec succès');
      }
    } catch (e) {
      print('🔥 ERREUR dans _chargerDonneesConducteur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔥 build() DÉBUT');

    // Test 2: Ajouter la logique de chargement des données
    if (!_donneesChargees && _isInitialized && !_chargementEnCours) {
      print('🔥 Conditions remplies pour charger les données');
      _chargementEnCours = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('🔥 Dans addPostFrameCallback pour chargement données');
        _chargerDonneesConducteur();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Formulaire Minimal - ${widget.typeAccident}'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FORMULAIRE MINIMAL FONCTIONNE !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text('Type: ${widget.typeAccident}'),
            Text('Collaboratif: ${widget.isCollaborative}'),
            Text('Session ID: ${widget.session?.id ?? "Aucune"}'),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                print('🔥 Bouton retour pressé');
                Navigator.pop(context);
              },
              child: Text('RETOUR'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print('🔥 Test SnackBar dans formulaire minimal');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Test SnackBar depuis formulaire minimal'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('TEST SNACKBAR'),
            ),
          ],
        ),
      ),
    );
  }
}
