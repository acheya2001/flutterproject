import 'package:flutter/material.dart';
import '../../models/accident_session.dart';
import '../../models/vehicule_model.dart';
import '../widgets/assistance_urgence_widget.dart';
import '../widgets/croquis_interactif_widget.dart';

/// 🎯 Mode guidé simplifié pour remplissage de constat
class ConstatModeGuide extends StatefulWidget {
  final AccidentSession session;
  final String role;
  final VehiculeModel? monVehicule;
  final bool estInvite;

  const ConstatModeGuide({
    super.key,
    required this.session,
    required this.role,
    this.monVehicule,
    this.estInvite = false,
  });

  @override
  State<ConstatModeGuide> createState() => _ConstatModeGuideState();
}

class _ConstatModeGuideState extends State<ConstatModeGuide> {
  final PageController _pageController = PageController();
  int _etapeActuelle = 0;
  final int _nombreEtapes = 6;

  // Données du formulaire
  final Map<String, dynamic> _donneesConstat = {};
  bool _blesses = false;
  bool _degatsAutres = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Constat Véhicule ${widget.role}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _afficherAide,
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildIndicateurProgression(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _etapeActuelle = index;
                });
              },
              children: [
                _buildEtape1Urgence(),
                _buildEtape2Informations(),
                _buildEtape3Vehicule(),
                _buildEtape4Circonstances(),
                _buildEtape5Croquis(),
                _buildEtape6Signature(),
              ],
            ),
          ),
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildIndicateurProgression() {
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    widget.role,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                      _getTitreEtape(_etapeActuelle),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Étape ${_etapeActuelle + 1} sur $_nombreEtapes',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${((_etapeActuelle + 1) / _nombreEtapes * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_etapeActuelle + 1) / _nombreEtapes,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        ],
      ),
    );
  }

  String _getTitreEtape(int etape) {
    switch (etape) {
      case 0: return 'Urgence et Sécurité';
      case 1: return 'Informations Générales';
      case 2: return 'Votre Véhicule';
      case 3: return 'Circonstances';
      case 4: return 'Croquis de l\'Accident';
      case 5: return 'Signature';
      default: return 'Étape ${etape + 1}';
    }
  }

  Widget _buildEtape1Urgence() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitreEtape(
            'Urgence et Sécurité',
            'Vérifiez d\'abord s\'il y a des blessés ou des dangers immédiats',
            Icons.warning,
            Colors.red,
          ),
          
          const SizedBox(height: 24),
          
          // Widget d'assistance d'urgence
          AssistanceUrgenceWidget(
            onBlessesChanged: (blesses) {
              setState(() {
                _blesses = blesses;
                _donneesConstat['blesses'] = blesses;
              });
            },
            blessesInitial: _blesses,
          ),
          
          const SizedBox(height: 24),
          
          // Dégâts matériels autres
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.home_repair_service, color: Colors.orange[600]),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Y a-t-il des dégâts matériels autres que les véhicules ?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Exemple: barrières, panneaux, façades, mobilier urbain...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOptionButton(
                          label: 'NON',
                          isSelected: !_degatsAutres,
                          color: Colors.green,
                          onTap: () {
                            setState(() {
                              _degatsAutres = false;
                              _donneesConstat['degatsAutres'] = false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildOptionButton(
                          label: 'OUI',
                          isSelected: _degatsAutres,
                          color: Colors.orange,
                          onTap: () {
                            setState(() {
                              _degatsAutres = true;
                              _donneesConstat['degatsAutres'] = true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Conseils de sécurité
          Container(
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
                    Icon(Icons.security, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'Conseils de Sécurité',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '✓ Allumez vos feux de détresse\n'
                  '✓ Placez un triangle de signalisation\n'
                  '✓ Portez un gilet réfléchissant\n'
                  '✓ Évacuez les véhicules si possible\n'
                  '✓ Restez vigilant à la circulation',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtape2Informations() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitreEtape(
            'Informations Générales',
            'Détails sur le lieu et l\'heure de l\'accident',
            Icons.info,
            Colors.blue,
          ),
          
          const SizedBox(height: 24),
          
          // Date et heure (pré-remplies)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date et Heure',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.session.dateAccident?.day}/${widget.session.dateAccident?.month}/${widget.session.dateAccident?.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        widget.session.heureAccident?.format(context) ?? 'Non spécifiée',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lieu (avec géolocalisation)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lieu de l\'Accident',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Adresse ou description du lieu',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      _donneesConstat['lieu'] = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _obtenirPositionGPS,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Utiliser ma position'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Témoins
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Témoins',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Y a-t-il des témoins de l\'accident ?',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Nom et téléphone des témoins (optionnel)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      _donneesConstat['temoins'] = value;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtape3Vehicule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitreEtape(
            'Votre Véhicule',
            'Informations sur votre véhicule et votre assurance',
            Icons.directions_car,
            Colors.green,
          ),
          
          const SizedBox(height: 24),
          
          if (widget.monVehicule != null) ...[
            // Véhicule pré-enregistré
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.green[300]!, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        const Text(
                          'Véhicule Enregistré',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${widget.monVehicule!.marque} ${widget.monVehicule!.modele}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Immatriculation: ${widget.monVehicule!.numeroImmatriculation}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (widget.monVehicule!.compagnieAssurance != null)
                      Text(
                        'Assurance: ${widget.monVehicule!.compagnieAssurance}',
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Saisie manuelle pour invités
            const Text(
              'Veuillez saisir les informations de votre véhicule:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // TODO: Formulaire de saisie véhicule
          ],
          
          const SizedBox(height: 24),
          
          // Point de choc et dégâts
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dégâts Visibles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Décrivez les dégâts apparents',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.build),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      _donneesConstat['degats'] = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _prendrePhotoDegats,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Prendre une photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtape4Circonstances() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitreEtape(
            'Circonstances',
            'Cochez les cases qui correspondent à votre situation',
            Icons.checklist,
            Colors.orange,
          ),
          
          const SizedBox(height: 24),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: const Text(
              'Cochez TOUTES les cases qui correspondent à ce que vous faisiez au moment de l\'accident. '
              'Soyez précis et honnête.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Liste des circonstances (simplifiée pour le mode guidé)
          ..._buildCirconstancesSimplifiees(),
        ],
      ),
    );
  }

  List<Widget> _buildCirconstancesSimplifiees() {
    final circonstancesSimplifiees = [
      {'id': '1', 'libelle': 'stationnait'},
      {'id': '2', 'libelle': 'quittait un stationnement'},
      {'id': '7', 'libelle': 'roulait normalement'},
      {'id': '9', 'libelle': 'changeait de file'},
      {'id': '10', 'libelle': 'doublait'},
      {'id': '11', 'libelle': 'virait à droite'},
      {'id': '12', 'libelle': 'virait à gauche'},
      {'id': '13', 'libelle': 'reculait'},
    ];

    return circonstancesSimplifiees.map((circ) {
      final id = circ['id']!;
      final libelle = circ['libelle']!;
      final isSelected = _donneesConstat['circonstances_$id'] == true;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Card(
          elevation: isSelected ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? Colors.orange[600]! : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: CheckboxListTile(
            title: Text('$id. $libelle'),
            value: isSelected,
            onChanged: (value) {
              setState(() {
                _donneesConstat['circonstances_$id'] = value;
              });
            },
            activeColor: Colors.orange[600],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildEtape5Croquis() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitreEtape(
            'Croquis de l\'Accident',
            'Dessinez la situation de l\'accident',
            Icons.draw,
            Colors.purple,
          ),
          
          const SizedBox(height: 24),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: const Text(
              'Dessinez un croquis simple montrant:\n'
              '• La position des véhicules\n'
              '• Le sens de circulation\n'
              '• Les éléments importants (feux, panneaux...)',
              style: TextStyle(fontSize: 14),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Widget de croquis
          SizedBox(
            height: 300,
            child: CroquisInteractifWidget(
              onCroquisComplete: (bytes) {
                _donneesConstat['croquis'] = bytes;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtape6Signature() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitreEtape(
            'Signature',
            'Validez votre partie du constat',
            Icons.edit,
            Colors.green,
          ),
          
          const SizedBox(height: 24),
          
          // Résumé
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Résumé de votre déclaration',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Véhicule: ${widget.role}'),
                  Text('Blessés: ${_blesses ? "Oui" : "Non"}'),
                  Text('Dégâts autres: ${_degatsAutres ? "Oui" : "Non"}'),
                  // TODO: Ajouter autres éléments du résumé
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Checkbox responsabilité
          Card(
            child: CheckboxListTile(
              title: const Text('J\'accepte la responsabilité selon ma déclaration'),
              subtitle: const Text('Cochez si vous reconnaissez votre responsabilité'),
              value: _donneesConstat['accepte_responsabilite'] == true,
              onChanged: (value) {
                setState(() {
                  _donneesConstat['accepte_responsabilite'] = value;
                });
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Zone de signature
          // TODO: Intégrer le widget de signature électronique
        ],
      ),
    );
  }

  Widget _buildTitreEtape(String titre, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
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
                    fontSize: 18,
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
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
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
      child: Row(
        children: [
          if (_etapeActuelle > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _etapePrecedente,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
              ),
            ),
          
          if (_etapeActuelle > 0) const SizedBox(width: 16),
          
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _etapeActuelle < _nombreEtapes - 1 ? _etapeSuivante : _finaliser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: Icon(_etapeActuelle < _nombreEtapes - 1 ? Icons.arrow_forward : Icons.check),
              label: Text(
                _etapeActuelle < _nombreEtapes - 1 ? 'Suivant' : 'Finaliser',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _etapePrecedente() {
    if (_etapeActuelle > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _etapeSuivante() {
    if (_etapeActuelle < _nombreEtapes - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finaliser() {
    // TODO: Implémenter la finalisation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Constat Complété'),
        content: const Text('Votre partie du constat a été enregistrée avec succès.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  void _afficherAide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide'),
        content: Text('Aide pour l\'étape: ${_getTitreEtape(_etapeActuelle)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _obtenirPositionGPS() {
    // TODO: Implémenter géolocalisation
  }

  void _prendrePhotoDegats() {
    // TODO: Implémenter prise de photo
  }
}
