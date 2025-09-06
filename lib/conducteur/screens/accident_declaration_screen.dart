import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/vehicule_model.dart';
import '../../services/vehicule_service.dart';
import 'accident_creation_wizard.dart';
import 'carambolage_wizard.dart';
import 'modern_accident_type_screen.dart';
import 'guest_join_session_screen.dart';
import '../../features/auth/presentation/screens/guest_access_screen.dart';
import '../widgets/assistance_urgence_widget.dart';
import '../../features/sinistre/screens/accident_type_selection_screen.dart';

/// 🚗 Écran de choix du type de déclaration d'accident (Nouvelle Version Complète)
class AccidentDeclarationScreen extends StatefulWidget {
  const AccidentDeclarationScreen({Key? key}) : super(key: key);

  @override
  State<AccidentDeclarationScreen> createState() => _AccidentDeclarationScreenState();
}

class _AccidentDeclarationScreenState extends State<AccidentDeclarationScreen> {
  List<VehiculeModel> _mesVehicules = [];
  bool _isLoadingVehicules = true;
  bool _blesses = false;
  String? _typeAccidentSelectionne;
  int? _nombreVehiculesSelectionne;

  @override
  void initState() {
    super.initState();
    _chargerMesVehicules();
  }

  Future<void> _chargerMesVehicules() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Charger les véhicules assurés du conducteur depuis Firestore
        final vehicules = await VehiculeService.obtenirVehiculesUtilisateur(user.uid);

        // Filtrer uniquement les véhicules avec contrat actif (assurés)
        _mesVehicules = vehicules.where((v) => v.contratActif).toList();

        print('🚗 ${_mesVehicules.length} véhicules assurés chargés pour déclaration');
        for (var vehicule in _mesVehicules) {
          print('  ✅ ${vehicule.marque} ${vehicule.modele} (${vehicule.numeroImmatriculation})');
        }
      }
    } catch (e) {
      print('Erreur chargement véhicules: $e');
    } finally {
      setState(() {
        _isLoadingVehicules = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingVehicules) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nouvelle Déclaration'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Nouvelle Déclaration d\'Accident',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête avec vérification d'urgence
            _buildHeaderUrgence(),

            const SizedBox(height: 24),

            // Interface moderne de sélection d'accident
            _buildInterfaceModerne(),

            const SizedBox(height: 24),

            // Affichage conditionnel selon le type d'accident
            if (_typeAccidentSelectionne != null) ...[
              _buildTypeAccidentSelectionne(),
              const SizedBox(height: 16),
            ],

            // Mes véhicules (affiché seulement si un type d'accident est sélectionné)
            if (_typeAccidentSelectionne != null) ...[
              if (_isLoadingVehicules)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_mesVehicules.isNotEmpty)
                _buildMesVehicules()
              else
                _buildAucunVehiculeAssure(),
            ],

            const SizedBox(height: 24),

          // Option pour rejoindre une session
          _buildRejoindreSession(),

          const SizedBox(height: 24),

            // Informations importantes
            _buildInformationsImportantes(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderUrgence() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[400]!, Colors.orange[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vérification d\'Urgence',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Vérifiez d\'abord s\'il y a des blessés',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Widget d'assistance d'urgence intégré
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AssistanceUrgenceWidget(
              onBlessesChanged: (blesses) {
                setState(() {
                  _blesses = blesses;
                });
              },
              blessesInitial: _blesses,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterfaceModerne() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Déclarer votre accident',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Interface moderne et intuitive pour déclarer votre sinistre',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 24),

          // Carte principale moderne
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[400]!,
                  Colors.purple[600]!,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _ouvrirInterfaceModerne,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Icône principale
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Center(
                          child: Text(
                            '🚗💥',
                            style: TextStyle(fontSize: 40),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Commencer la déclaration',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Interface moderne avec sélection intelligente du type d\'accident',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      // Bouton d'action
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Commencer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Fonctionnalités
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  '⚡',
                  'Rapide',
                  'Interface optimisée',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeatureCard(
                  '🎯',
                  'Précis',
                  'Sélection intelligente',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeatureCard(
                  '🔒',
                  'Sécurisé',
                  'Données protégées',
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String emoji, String titre, String description, Color couleur) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: couleur.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            titre,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: couleur,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTypesAccidents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type d\'Accident',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Accident simple (2 véhicules)
        _buildTypeAccidentCard(
          titre: 'Accident Simple',
          description: '2 véhicules impliqués',
          icon: Icons.directions_car,
          couleur: Colors.blue,
          onTap: _creerAccidentSimple,
          recommande: true,
        ),

        const SizedBox(height: 12),

        // Accident multiple (3-5 véhicules)
        _buildTypeAccidentCard(
          titre: 'Accident Multiple',
          description: '3 à 5 véhicules impliqués',
          icon: Icons.traffic,
          couleur: Colors.orange,
          onTap: _creerAccidentMultiple,
        ),

        const SizedBox(height: 12),

        // Carambolage complexe (+5 véhicules)
        _buildTypeAccidentCard(
          titre: 'Carambolage Complexe',
          description: '6+ véhicules impliqués',
          icon: Icons.warning,
          couleur: Colors.red,
          onTap: _creerCarambolage,
          urgent: true,
        ),
      ],
    );
  }

  Widget _buildTypeAccidentCard({
    required String titre,
    required String description,
    required IconData icon,
    required Color couleur,
    required VoidCallback onTap,
    bool recommande = false,
    bool urgent = false,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: urgent ? Colors.red[300]! :
                 recommande ? Colors.blue[300]! :
                 Colors.grey[300]!,
          width: urgent || recommande ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  icon,
                  color: couleur,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            titre,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (recommande) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'REC',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                        if (urgent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'URG',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: couleur,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTypeAccidentSelectionne() {
    String titre = '';
    String description = '';
    IconData icon = Icons.directions_car;
    Color couleur = Colors.blue;

    switch (_typeAccidentSelectionne) {
      case 'simple':
        titre = 'Accident Simple Sélectionné';
        description = '2 véhicules impliqués - Sélectionnez votre véhicule ci-dessous';
        icon = Icons.directions_car;
        couleur = Colors.blue;
        break;
      case 'multiple':
        titre = 'Accident Multiple Sélectionné';
        description = '3 à 5 véhicules impliqués';
        icon = Icons.traffic;
        couleur = Colors.orange;
        break;
      case 'carambolage':
        titre = 'Carambolage Complexe Sélectionné';
        description = '6+ véhicules impliqués';
        icon = Icons.warning;
        couleur = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: couleur,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _typeAccidentSelectionne = null;
                _nombreVehiculesSelectionne = null;
              });
            },
            icon: const Icon(Icons.close),
            tooltip: 'Changer le type d\'accident',
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
          'Mes Véhicules',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        ..._mesVehicules.map((vehicule) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          color: Colors.blue[600],
                          size: 24,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: vehicule.contratActif ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          vehicule.contratActif ? 'ASSURÉ' : 'NON ASSURÉ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: vehicule.contratActif ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: vehicule.contratActif
                          ? () => _selectionnerVehicule(vehicule, nombreVehicules: _nombreVehiculesSelectionne)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vehicule.contratActif ? Colors.blue[600] : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(vehicule.contratActif ? Icons.check_circle : Icons.block),
                      label: Text(
                        vehicule.contratActif
                            ? 'Sélectionner ce véhicule'
                            : 'Véhicule non assuré',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }

  void _selectionnerVehicule(VehiculeModel vehicule, {int? nombreVehicules}) {
    // Naviguer vers l'assistant de création d'accident avec le véhicule sélectionné
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccidentCreationWizard(
          vehiculeSelectionne: vehicule,
          estProprietaire: true, // Par défaut, on assume que c'est le propriétaire
          nombreVehiculesInitial: nombreVehicules,
        ),
      ),
    );
  }

  Widget _buildAucunVehiculeAssure() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun véhicule assuré disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pour déclarer un sinistre, vous devez avoir au moins un véhicule avec un contrat d\'assurance actif.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Comment procéder ?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Souscrivez d\'abord une assurance pour votre véhicule\n'
                  '2. Attendez l\'activation de votre contrat\n'
                  '3. Revenez ensuite déclarer votre sinistre',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/conducteur-dashboard');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.home),
                  label: const Text('Accueil'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformationsImportantes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.amber[600]),
              const SizedBox(width: 8),
              const Text(
                'Informations Importantes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• Assurez-vous que la zone est sécurisée\n'
            '• Prenez des photos si possible\n'
            '• Notez les témoins présents\n'
            '• Gardez votre calme et soyez précis\n'
            '• Vous pourrez inviter les autres conducteurs après création',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Actions pour les différents types d'accidents
  void _creerAccidentSimple() {
    setState(() {
      _typeAccidentSelectionne = 'simple';
      _nombreVehiculesSelectionne = 2;
    });

    if (_blesses) {
      _afficherDialogueUrgence(() {
        // Pour accident simple, pas besoin de l'assistant - directement sélection véhicule
        _afficherSelectionVehicule();
      });
    } else {
      _afficherSelectionVehicule();
    }
  }

  void _creerAccidentMultiple() {
    setState(() {
      _typeAccidentSelectionne = 'multiple';
      _nombreVehiculesSelectionne = null; // Sera choisi dans l'assistant
    });

    if (_blesses) {
      _afficherDialogueUrgence(() {
        _naviguerVersAssistant(null);
      });
    } else {
      _naviguerVersAssistant(null);
    }
  }

  void _creerCarambolage() {
    setState(() {
      _typeAccidentSelectionne = 'carambolage';
      _nombreVehiculesSelectionne = null; // Sera choisi dans l'assistant
    });

    if (_blesses) {
      _afficherDialogueUrgence(() {
        _naviguerVersCarambolage();
      });
    } else {
      _naviguerVersCarambolage();
    }
  }

  void _ouvrirInterfaceModerne() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AccidentTypeSelectionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _afficherSelectionVehicule() {
    // Faire défiler vers la section des véhicules pour accident simple
    setState(() {
      // Forcer le rebuild pour mettre à jour l'affichage
    });

    // Optionnel : scroll automatique vers la section véhicules
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        // Scroll vers le bas pour voir les véhicules
        // Vous pouvez ajouter un ScrollController si nécessaire
      }
    });
  }

  void _naviguerVersAssistant(int? nombreVehicules) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccidentCreationWizard(
          nombreVehiculesInitial: nombreVehicules,
        ),
      ),
    );
  }

  void _naviguerVersCarambolage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CarambolageWizard(),
      ),
    );
  }

  Widget _buildRejoindreSession() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green[400]!.withOpacity(0.1),
            Colors.teal[400]!.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green[300]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.group_add,
                  color: Colors.green[600],
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rejoindre une session',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Rejoignez un constat déjà créé par un autre conducteur',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _rejoindreAvecQR,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scanner QR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green[600],
                    side: BorderSide(color: Colors.green[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _rejoindreAvecCode,
                  icon: const Icon(Icons.pin),
                  label: const Text('Entrer code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green[600],
                    side: BorderSide(color: Colors.green[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _rejoindreAvecQR() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );
  }

  void _rejoindreAvecCode() {
    showDialog(
      context: context,
      builder: (context) => _buildDialogueCodeSession(),
    );
  }

  Widget _buildDialogueCodeSession() {
    final codeController = TextEditingController();

    return AlertDialog(
      title: const Text('Rejoindre une session'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Entrez le code de session à 6 chiffres fourni par l\'autre conducteur :',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: codeController,
            decoration: const InputDecoration(
              hintText: 'Exemple: 123456',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers),
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            maxLength: 6,
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
            if (codeController.text.length == 6) {
              Navigator.pop(context);
              _rejoindreSessionAvecCode(codeController.text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
          ),
          child: const Text('Rejoindre'),
        ),
      ],
    );
  }

  void _rejoindreSessionAvecCode(String code) {
    // TODO: Récupérer les infos utilisateur connecté
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuestJoinSessionScreen(
          sessionCode: code,
        ),
      ),
    );
  }

  void _ajouterVehicule() {
    // TODO: Naviguer vers l'écran d'ajout de véhicule
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité d\'ajout de véhicule à implémenter'),
      ),
    );
  }

  void _afficherDialogueUrgence(VoidCallback onContinue) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('URGENCE DÉTECTÉE'),
          ],
        ),
        content: const Text(
          'Des blessés ont été signalés. Assurez-vous d\'avoir appelé les secours avant de continuer avec le constat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onContinue();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }
}
