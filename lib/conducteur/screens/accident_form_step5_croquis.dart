import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';
import '../../models/accident_session_complete.dart';
import '../../services/accident_session_complete_service.dart';
import '../../services/photo_upload_service.dart';
import '../../widgets/simple_sketch_widget.dart';
import '../../widgets/join_sketch_session_widget.dart';
import '../../models/collaborative_sketch_model.dart';
import '../../services/collaborative_sketch_service.dart';
import 'accident_form_step6_signatures.dart';

/// 🎨 Étape 5 : Croquis interactif de l'accident (selon constat papier)
class AccidentFormStep5Croquis extends StatefulWidget {
  final AccidentSessionComplete session;

  const AccidentFormStep5Croquis({
    super.key,
    required this.session,
  });

  @override
  State<AccidentFormStep5Croquis> createState() => _AccidentFormStep5CroquisState();
}

class _AccidentFormStep5CroquisState extends State<AccidentFormStep5Croquis> {
  bool _isLoading = false;
  String _modeDessin = 'vehicule'; // 'vehicule', 'route', 'annotation', 'fleche'
  Color _couleurSelectionnee = Colors.blue;
  double _epaisseurTrait = 3.0;
  
  // Données du croquis
  List<ElementCroquis> _elementsCroquis = [];
  List<VehiculePosition> _vehiculesPositions = [];
  final TextEditingController _annotationController = TextEditingController();
  List<String> _photosCroquis = []; // URLs des photos du croquis

  // Session collaborative
  final CollaborativeSketchService _sketchService = CollaborativeSketchService();
  CollaborativeSketch? _collaborativeSketch;
  bool _isInCollaborativeMode = false;
  bool _showJoinInterface = false;
  
  // Outils de dessin
  final List<Map<String, dynamic>> _outilsDessin = [
    {
      'id': 'vehicule',
      'nom': 'Véhicules',
      'icone': Icons.directions_car,
      'couleur': Colors.blue,
      'description': 'Placer les véhicules',
    },
    {
      'id': 'route',
      'nom': 'Routes',
      'icone': Icons.timeline,
      'couleur': Colors.grey,
      'description': 'Dessiner les routes',
    },
    {
      'id': 'fleche',
      'nom': 'Trajectoires',
      'icone': Icons.arrow_forward,
      'couleur': Colors.red,
      'description': 'Sens de circulation',
    },
    {
      'id': 'annotation',
      'nom': 'Annotations',
      'icone': Icons.text_fields,
      'couleur': Colors.green,
      'description': 'Ajouter du texte',
    },
    {
      'id': 'obstacle',
      'nom': 'Obstacles',
      'icone': Icons.warning,
      'couleur': Colors.orange,
      'description': 'Murs, poteaux, etc.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initialiserCroquis();
  }

  @override
  void dispose() {
    _annotationController.dispose();
    super.dispose();
  }

  void _initialiserCroquis() {
    // Initialiser les positions des véhicules
    for (int i = 0; i < widget.session.conducteurs.length; i++) {
      final conducteur = widget.session.conducteurs[i];
      _vehiculesPositions.add(VehiculePosition(
        roleVehicule: conducteur.roleVehicule,
        position: Offset(100.0 + (i * 80.0), 200.0),
        angle: 0.0,
        couleur: _getCouleurVehicule(conducteur.roleVehicule),
      ));
    }

    // Charger le croquis existant si disponible
    if (widget.session.croquis.croquisData.isNotEmpty) {
      _chargerCroquisExistant();
    }

    // Initialiser la session collaborative
    _initializeCollaborativeSession();
  }

  /// Initialiser la session collaborative
  Future<void> _initializeCollaborativeSession() async {
    try {
      // Essayer de créer ou rejoindre une session de croquis
      final conducteur = widget.session.conducteurs.isNotEmpty
          ? widget.session.conducteurs.first
          : null;

      if (conducteur != null) {
        final sketchId = await _sketchService.createSketchForAccidentSession(
          sessionCode: widget.session.codeSession,
          creatorId: conducteur.userId,
          creatorName: '${conducteur.prenom} ${conducteur.nom}',
        );

        // Rejoindre la session
        await _sketchService.joinSketch(
          sketchId: sketchId,
          conducteurId: conducteur.userId,
          conducteurName: '${conducteur.prenom} ${conducteur.nom}',
        );

        setState(() {
          _isInCollaborativeMode = true;
        });
      }
    } catch (e) {
      print('Erreur initialisation session collaborative: $e');
      // En cas d'erreur, rester en mode local
    }
  }

  void _chargerCroquisExistant() {
    try {
      final data = jsonDecode(widget.session.croquis.croquisData);
      // TODO: Implémenter le chargement des données existantes
    } catch (e) {
      print('Erreur chargement croquis: $e');
    }
  }

  Color _getCouleurVehicule(String role) {
    final couleurs = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    final index = role.codeUnitAt(0) - 'A'.codeUnitAt(0);
    return couleurs[index % couleurs.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // 🎨 Fond gris clair pour éviter le noir
      appBar: AppBar(
        title: const Text(
          'Croquis de l\'accident',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _effacerTout,
            icon: const Icon(Icons.clear_all, color: Colors.white),
            tooltip: 'Effacer tout',
          ),
          IconButton(
            onPressed: _sauvegarder,
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de progression (compacte)
          _buildProgressBarCompact(),

          // Zone de dessin (AGRANDIE - prend la majorité de l'espace)
          Expanded(
            flex: 4, // 4/6 de l'espace pour le croquis
            child: _buildZoneDessin(),
          ),

          // Section photos du croquis (compacte)
          Expanded(
            flex: 1, // 1/6 de l'espace pour les photos
            child: _buildSectionPhotos(),
          ),

          // Bouton suivant (fixe en bas)
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
                'Étape 5 sur 6',
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
            value: 5 / 6,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBarCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Row(
        children: [
          const Text(
            'Étape 5/6 - Croquis',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LinearProgressIndicator(
              value: 5 / 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${widget.session.codeSession}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarreOutils() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Dessinez le schéma de l\'accident. Tous les conducteurs peuvent collaborer en temps réel.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Outils de dessin
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _outilsDessin.map((outil) {
                final isSelected = _modeDessin == outil['id'];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _changerModeDessin(outil['id']),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? outil['couleur'].withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? outil['couleur'] : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              outil['icone'],
                              color: isSelected ? outil['couleur'] : Colors.grey[600],
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              outil['nom'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? outil['couleur'] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Options de l'outil sélectionné
          _buildOptionsOutil(),
        ],
      ),
    );
  }

  Widget _buildOptionsOutil() {
    switch (_modeDessin) {
      case 'route':
      case 'fleche':
        return Row(
          children: [
            const Text('Épaisseur: ', style: TextStyle(fontSize: 12)),
            Expanded(
              child: Slider(
                value: _epaisseurTrait,
                min: 1.0,
                max: 8.0,
                divisions: 7,
                onChanged: (value) {
                  setState(() {
                    _epaisseurTrait = value;
                  });
                },
              ),
            ),
            Text('${_epaisseurTrait.toInt()}px', style: const TextStyle(fontSize: 12)),
          ],
        );
      case 'annotation':
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _annotationController,
                decoration: const InputDecoration(
                  hintText: 'Tapez votre annotation...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _ajouterAnnotation,
              child: const Text('Ajouter'),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildZoneDessin() {
    return _buildCroquisModerne();
  }

  /// 🎨 Nouveau croquis moderne (PLEIN ÉCRAN)
  Widget _buildCroquisModerne() {
    return Container(
      padding: const EdgeInsets.all(8), // Padding réduit
      child: Column(
        children: [
          // En-tête compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.draw, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Croquis de l\'accident',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isInCollaborativeMode)
                        Text(
                          'Session: ${widget.session.codeSession}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                ...(!_isInCollaborativeMode ? [
                  GestureDetector(
                    onTap: () => setState(() => _showJoinInterface = !_showJoinInterface),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group_add, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Rejoindre',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] : []),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_elementsCroquis.length} éléments',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Interface pour rejoindre une session
          if (_showJoinInterface && !_isInCollaborativeMode) ...[
            JoinSketchSessionWidget(
              conducteurId: widget.session.conducteurs.isNotEmpty
                  ? widget.session.conducteurs.first.userId
                  : '',
              conducteurName: widget.session.conducteurs.isNotEmpty
                  ? '${widget.session.conducteurs.first.prenom} ${widget.session.conducteurs.first.nom}'
                  : 'Conducteur',
              onSketchJoined: _onSketchJoined,
            ),
            const SizedBox(height: 8),
          ],

          // Widget de croquis collaboratif - PLEIN ÉCRAN
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SimpleSketchWidget(
                  width: double.infinity,
                  height: double.infinity,
                  onSketchChanged: _onSketchChanged,
                  initialElements: _convertToSketchElements(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendeVehicules() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Véhicules',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._vehiculesPositions.map((vehicule) {
            final conducteur = widget.session.conducteurs.firstWhere(
              (c) => c.roleVehicule == vehicule.roleVehicule,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: vehicule.couleur,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Center(
                      child: Text(
                        vehicule.roleVehicule,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${conducteur.prenom} ${conducteur.nom}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
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
                      'Finaliser',
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

  void _changerModeDessin(String mode) {
    setState(() {
      _modeDessin = mode;
      _couleurSelectionnee = _outilsDessin.firstWhere((o) => o['id'] == mode)['couleur'];
    });
  }

  /// Convertir les éléments existants vers le nouveau format
  List<SketchElement> _convertToSketchElements() {
    List<SketchElement> elements = [];

    // Convertir les véhicules
    for (final vehicule in _vehiculesPositions) {
      elements.add(SketchElement(
        type: SketchTool.vehicle,
        points: [vehicule.position],
        color: vehicule.couleur,
        strokeWidth: 3.0,
        text: vehicule.roleVehicule,
      ));
    }

    // Convertir les autres éléments
    for (final element in _elementsCroquis) {
      SketchTool tool;
      switch (element.type) {
        case 'route':
          tool = SketchTool.road;
          break;
        case 'fleche':
          tool = SketchTool.arrow;
          break;
        case 'annotation':
          tool = SketchTool.text;
          break;
        default:
          tool = SketchTool.pen;
      }

      elements.add(SketchElement(
        type: tool,
        points: element.points,
        color: element.couleur,
        strokeWidth: element.epaisseur,
        text: element.texte,
      ));
    }

    return elements;
  }

  /// Gérer les changements du nouveau croquis
  void _onSketchChanged(List<SketchElement> elements) {
    setState(() {
      // Convertir vers l'ancien format pour la compatibilité
      _elementsCroquis.clear();
      _vehiculesPositions.clear();

      for (final element in elements) {
        if (element.type == SketchTool.vehicle) {
          _vehiculesPositions.add(VehiculePosition(
            roleVehicule: element.text ?? 'A',
            position: element.points.first,
            angle: 0.0,
            couleur: element.color,
          ));
        } else {
          String type;
          switch (element.type) {
            case SketchTool.road:
              type = 'route';
              break;
            case SketchTool.arrow:
              type = 'fleche';
              break;
            case SketchTool.text:
              type = 'annotation';
              break;
            default:
              type = 'trait';
          }

          _elementsCroquis.add(ElementCroquis(
            type: type,
            points: element.points,
            couleur: element.color,
            epaisseur: element.strokeWidth,
            texte: element.text,
          ));
        }
      }
    });
  }

  /// Gérer les mises à jour du croquis collaboratif
  void _onCollaborativeSketchUpdated(CollaborativeSketch sketch) {
    setState(() {
      _collaborativeSketch = sketch;
      // TODO: Synchroniser avec les données locales si nécessaire
    });
  }

  /// Gérer la connexion à une session de croquis
  void _onSketchJoined(CollaborativeSketch sketch) {
    setState(() {
      _collaborativeSketch = sketch;
      _isInCollaborativeMode = true;
      _showJoinInterface = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connecté à la session ${sketch.sessionId}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final position = details.localPosition;
    
    if (_modeDessin == 'vehicule') {
      _deplacerVehicule(position);
    } else if (_modeDessin == 'route' || _modeDessin == 'fleche') {
      _commencerTrait(position);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final position = details.localPosition;
    
    if (_modeDessin == 'vehicule') {
      _deplacerVehicule(position);
    } else if (_modeDessin == 'route' || _modeDessin == 'fleche') {
      _continuerTrait(position);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_modeDessin == 'route' || _modeDessin == 'fleche') {
      _terminerTrait();
    }
  }

  void _onTapSimple() {
    // Pour l'instant, on ne fait rien car on n'a pas la position exacte
    // Cette méthode peut être étendue plus tard si nécessaire
  }

  void _onTap(TapUpDetails details) {
    final position = details.localPosition;

    if (_modeDessin == 'obstacle') {
      _ajouterObstacle(position);
    }
  }

  void _deplacerVehicule(Offset position) {
    // Trouver le véhicule le plus proche et le déplacer
    double distanceMin = double.infinity;
    int indexVehicule = -1;
    
    for (int i = 0; i < _vehiculesPositions.length; i++) {
      final distance = (position - _vehiculesPositions[i].position).distance;
      if (distance < distanceMin && distance < 50) {
        distanceMin = distance;
        indexVehicule = i;
      }
    }
    
    if (indexVehicule >= 0) {
      setState(() {
        _vehiculesPositions[indexVehicule] = _vehiculesPositions[indexVehicule].copyWith(
          position: position,
        );
      });
    }
  }

  void _commencerTrait(Offset position) {
    setState(() {
      _elementsCroquis.add(ElementCroquis(
        type: _modeDessin,
        points: [position],
        couleur: _couleurSelectionnee,
        epaisseur: _epaisseurTrait,
      ));
    });
  }

  void _continuerTrait(Offset position) {
    if (_elementsCroquis.isNotEmpty) {
      setState(() {
        final dernierElement = _elementsCroquis.last;
        dernierElement.points.add(position);
      });
    }
  }

  void _terminerTrait() {
    // Le trait est terminé, rien à faire de spécial
  }

  void _ajouterObstacle(Offset position) {
    setState(() {
      _elementsCroquis.add(ElementCroquis(
        type: 'obstacle',
        points: [position],
        couleur: Colors.orange,
        epaisseur: 20.0,
        texte: 'Obstacle',
      ));
    });
  }

  void _ajouterAnnotation() {
    if (_annotationController.text.trim().isNotEmpty) {
      // L'annotation sera ajoutée au prochain tap
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tapez sur le croquis pour placer l\'annotation'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _effacerTout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer le croquis'),
        content: const Text('Êtes-vous sûr de vouloir effacer tout le croquis ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _elementsCroquis.clear();
                // Remettre les véhicules à leur position initiale
                for (int i = 0; i < _vehiculesPositions.length; i++) {
                  _vehiculesPositions[i] = _vehiculesPositions[i].copyWith(
                    position: Offset(100.0 + (i * 80.0), 200.0),
                  );
                }
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }

  Future<void> _sauvegarder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Convertir le croquis en données JSON
      final croquisData = {
        'elements': _elementsCroquis.map((e) => e.toMap()).toList(),
        'vehicules': _vehiculesPositions.map((v) => v.toMap()).toList(),
      };

      final croquis = CroquisAccident(
        croquisData: jsonEncode(croquisData),
        annotations: _elementsCroquis
            .where((e) => e.type == 'annotation')
            .map((e) => e.texte ?? '')
            .toList(),
      );

      // Sauvegarder en Firestore
      await AccidentSessionCompleteService.mettreAJourCroquis(
        widget.session.id,
        croquis,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Croquis sauvegardé'),
            backgroundColor: Colors.green,
          ),
        );
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
      // Naviguer vers l'étape finale
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AccidentFormStep6Signatures(
            session: widget.session,
          ),
        ),
      );
    }
  }

  Widget _buildSectionPhotos() {
    return Container(
      padding: const EdgeInsets.all(12), // Padding réduit
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête compact
          Row(
            children: [
              Icon(Icons.photo_camera, color: Colors.blue[600], size: 18),
              const SizedBox(width: 6),
              const Text(
                'Photos du lieu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _photosCroquis.length >= 5 ? Colors.red[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_photosCroquis.length}/5',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _photosCroquis.length >= 5 ? Colors.red[600] : Colors.blue[600],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Photos en ligne horizontale (plus compact)
          if (_photosCroquis.isNotEmpty) ...[
            SizedBox(
              height: 60, // Hauteur réduite
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _photosCroquis.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    child: _buildPhotoCardCroquisCompact(_photosCroquis[index], index),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Boutons d'ajout compacts
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _photosCroquis.length < 5 ? () => _ajouterPhotoCroquis('camera') : null,
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Photo', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _photosCroquis.length < 5 ? () => _ajouterPhotoCroquis('gallery') : null,
                  icon: const Icon(Icons.photo_library, size: 16),
                  label: const Text('Galerie', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[600],
                    side: BorderSide(color: Colors.blue[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosGridCroquis() {
    if (_photosCroquis.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune photo du lieu',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ajoutez des photos pour documenter la scène',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _photosCroquis.length,
      itemBuilder: (context, index) {
        return _buildPhotoCardCroquis(_photosCroquis[index], index);
      },
    );
  }

  Widget _buildPhotoCardCroquis(String photoUrl, int index) {
    final bool isLocalImage = photoUrl.startsWith('file://') || photoUrl.startsWith('/');
    final String cleanPath = photoUrl.startsWith('file://') ? photoUrl.substring(7) : photoUrl;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: isLocalImage
                    ? FileImage(File(cleanPath))
                    : NetworkImage(photoUrl) as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Badge type d'image
          if (isLocalImage)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[600],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LOCAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Bouton supprimer
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _supprimerPhotoCroquis(index),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.red[600],
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
                  size: 16,
                ),
              ),
            ),
          ),

          // Overlay pour interaction
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _voirPhotoEnGrandCroquis(photoUrl),
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _ajouterPhotoCroquis(String source) async {
    try {
      // Afficher un dialog de chargement moderne
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Upload en cours...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  source == 'camera' ? 'Traitement de la photo' : 'Upload de l\'image',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      String? photoUrl;

      if (source == 'camera') {
        photoUrl = await PhotoUploadService.prendrePhoto(
          dossierDestination: 'sinistres/croquis',
          nomFichier: 'lieu_${DateTime.now().millisecondsSinceEpoch}',
        );
      } else {
        photoUrl = await PhotoUploadService.selectionnerPhoto(
          dossierDestination: 'sinistres/croquis',
          nomFichier: 'lieu_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Fermer l'indicateur de chargement
      if (mounted) Navigator.pop(context);

      if (photoUrl != null) {
        setState(() {
          _photosCroquis.add(photoUrl!);
        });

        if (mounted) {
          // Afficher un feedback de succès moderne
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Photo du lieu ajoutée avec succès',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Fermer l'indicateur de chargement en cas d'erreur
      if (mounted) Navigator.pop(context);

      if (mounted) {
        // Afficher un feedback d'erreur moderne
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Erreur lors de l\'ajout',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        e.toString().length > 50
                            ? '${e.toString().substring(0, 50)}...'
                            : e.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: () => _ajouterPhotoCroquis(source),
            ),
          ),
        );
      }
    }
  }

  void _supprimerPhotoCroquis(int index) {
    final photoUrl = _photosCroquis[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette photo du lieu ? Cette action est irréversible.'),
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
                  _photosCroquis.removeAt(index);
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

  void _voirPhotoEnGrandCroquis(String photoUrl) {
    final bool isLocalImage = photoUrl.startsWith('file://') || photoUrl.startsWith('/');
    final String cleanPath = photoUrl.startsWith('file://') ? photoUrl.substring(7) : photoUrl;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: isLocalImage
                      ? Image.file(
                          File(cleanPath),
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          photoUrl,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCardCroquisCompact(String photoUrl, int index) {
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

        // Badge type d'image (plus petit)
        if (isLocalImage)
          Positioned(
            top: 2,
            left: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.orange[600],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LOCAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Bouton supprimer (plus petit)
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _supprimerPhotoCroquis(index),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.red[600],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),

        // Overlay pour interaction
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _voirPhotoEnGrandCroquis(photoUrl),
              child: Container(),
            ),
          ),
        ),
      ],
    );
  }
}

/// 🎨 Élément du croquis
class ElementCroquis {
  final String type;
  final List<Offset> points;
  final Color couleur;
  final double epaisseur;
  final String? texte;

  ElementCroquis({
    required this.type,
    required this.points,
    required this.couleur,
    required this.epaisseur,
    this.texte,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'couleur': couleur.value,
      'epaisseur': epaisseur,
      'texte': texte,
    };
  }
}

/// 🚗 Position d'un véhicule
class VehiculePosition {
  final String roleVehicule;
  final Offset position;
  final double angle;
  final Color couleur;

  VehiculePosition({
    required this.roleVehicule,
    required this.position,
    required this.angle,
    required this.couleur,
  });

  VehiculePosition copyWith({
    String? roleVehicule,
    Offset? position,
    double? angle,
    Color? couleur,
  }) {
    return VehiculePosition(
      roleVehicule: roleVehicule ?? this.roleVehicule,
      position: position ?? this.position,
      angle: angle ?? this.angle,
      couleur: couleur ?? this.couleur,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roleVehicule': roleVehicule,
      'position': {'x': position.dx, 'y': position.dy},
      'angle': angle,
      'couleur': couleur.value,
    };
  }
}

/// 🎨 Painter pour la grille de fond
class GrillePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    const espacement = 20.0;

    // Lignes verticales
    for (double x = 0; x < size.width; x += espacement) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Lignes horizontales
    for (double y = 0; y < size.height; y += espacement) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 🎨 Painter pour le croquis
class CroquisPainter extends CustomPainter {
  final List<ElementCroquis> elementsCroquis;
  final List<VehiculePosition> vehiculesPositions;

  CroquisPainter({
    required this.elementsCroquis,
    required this.vehiculesPositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner les éléments du croquis
    for (final element in elementsCroquis) {
      _dessinerElement(canvas, element);
    }

    // Dessiner les véhicules
    for (final vehicule in vehiculesPositions) {
      _dessinerVehicule(canvas, vehicule);
    }
  }

  void _dessinerElement(Canvas canvas, ElementCroquis element) {
    final paint = Paint()
      ..color = element.couleur
      ..strokeWidth = element.epaisseur
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (element.points.length > 1) {
      final path = Path();
      path.moveTo(element.points.first.dx, element.points.first.dy);
      
      for (int i = 1; i < element.points.length; i++) {
        path.lineTo(element.points[i].dx, element.points[i].dy);
      }
      
      canvas.drawPath(path, paint);
      
      // Dessiner une flèche à la fin si c'est une trajectoire
      if (element.type == 'fleche' && element.points.length >= 2) {
        _dessinerFleche(canvas, element.points[element.points.length - 2], element.points.last, paint);
      }
    } else if (element.points.length == 1) {
      // Dessiner un obstacle ou annotation
      if (element.type == 'obstacle') {
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(element.points.first, element.epaisseur / 2, paint);
      }
    }
  }

  void _dessinerFleche(Canvas canvas, Offset start, Offset end, Paint paint) {
    final direction = (end - start).direction;
    final longueurFleche = 15.0;
    final angleFleche = 0.5;
    
    final pointe1 = end + Offset(
      longueurFleche * math.cos(direction + math.pi - angleFleche),
      longueurFleche * math.sin(direction + math.pi - angleFleche),
    );
    
    final pointe2 = end + Offset(
      longueurFleche * math.cos(direction + math.pi + angleFleche),
      longueurFleche * math.sin(direction + math.pi + angleFleche),
    );
    
    canvas.drawLine(end, pointe1, paint);
    canvas.drawLine(end, pointe2, paint);
  }

  void _dessinerVehicule(Canvas canvas, VehiculePosition vehicule) {
    final paint = Paint()
      ..color = vehicule.couleur
      ..style = PaintingStyle.fill;

    final paintBordure = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Dessiner le rectangle du véhicule
    const largeur = 40.0;
    const hauteur = 20.0;
    
    final rect = Rect.fromCenter(
      center: vehicule.position,
      width: largeur,
      height: hauteur,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paint,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paintBordure,
    );

    // Dessiner la lettre du véhicule
    final textPainter = TextPainter(
      text: TextSpan(
        text: vehicule.roleVehicule,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      vehicule.position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
