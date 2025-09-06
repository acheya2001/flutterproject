import 'package:flutter/material.dart';
import 'dart:async';
import '../models/collaborative_sketch_model.dart';
import '../services/collaborative_sketch_service.dart';
import 'modern_sketch_widget.dart';

/// 🎨 Widget de croquis collaboratif en temps réel
class CollaborativeSketchWidget extends StatefulWidget {
  final String sessionId;
  final String conducteurId;
  final String conducteurName;
  final Function(CollaborativeSketch) onSketchUpdated;

  const CollaborativeSketchWidget({
    super.key,
    required this.sessionId,
    required this.conducteurId,
    required this.conducteurName,
    required this.onSketchUpdated,
  });

  @override
  State<CollaborativeSketchWidget> createState() => _CollaborativeSketchWidgetState();
}

class _CollaborativeSketchWidgetState extends State<CollaborativeSketchWidget> {
  final CollaborativeSketchService _sketchService = CollaborativeSketchService();
  
  CollaborativeSketch? _currentSketch;
  List<ConducteurParticipation> _participants = [];
  bool _isLoading = true;
  bool _hasJoined = false;
  String? _error;
  
  StreamSubscription<CollaborativeSketch?>? _sketchSubscription;
  StreamSubscription<List<ConducteurParticipation>>? _participantsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeSketch();
  }

  @override
  void dispose() {
    _sketchSubscription?.cancel();
    _participantsSubscription?.cancel();
    if (_hasJoined && _currentSketch != null) {
      _sketchService.leaveSketch(
        sketchId: _currentSketch!.id,
        conducteurId: widget.conducteurId,
      );
    }
    super.dispose();
  }

  Future<void> _initializeSketch() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Chercher un croquis existant pour cette session
      final existingSketch = await _sketchService.getSketchBySession(widget.sessionId);
      
      if (existingSketch != null) {
        // Rejoindre le croquis existant
        await _sketchService.joinSketch(
          sketchId: existingSketch.id,
          conducteurId: widget.conducteurId,
          conducteurName: widget.conducteurName,
        );
        _hasJoined = true;
        _setupStreams(existingSketch.id);
      } else {
        // Aucun croquis existant, afficher les options de création
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createSketch(SketchMode mode) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final sketchId = await _sketchService.createCollaborativeSketch(
        sessionId: widget.sessionId,
        creatorId: widget.conducteurId,
        creatorName: widget.conducteurName,
        mode: mode,
      );

      _hasJoined = true;
      _setupStreams(sketchId);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setupStreams(String sketchId) {
    // Stream du croquis
    _sketchSubscription = _sketchService.watchSketch(sketchId).listen(
      (sketch) {
        if (sketch != null) {
          setState(() {
            _currentSketch = sketch;
            _isLoading = false;
          });
          widget.onSketchUpdated(sketch);
        }
      },
      onError: (error) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      },
    );

    // Stream des participants
    _participantsSubscription = _sketchService.watchParticipants(sketchId).listen(
      (participants) {
        setState(() {
          _participants = participants;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement du croquis...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erreur: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeSketch,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_currentSketch == null) {
      return _buildSketchCreationOptions();
    }

    return _buildCollaborativeSketch();
  }

  Widget _buildSketchCreationOptions() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.draw, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Créer le croquis de l\'accident',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choisissez le mode de collaboration :',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Mode exclusif
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lock, color: Colors.orange),
                  title: const Text('Mode Exclusif'),
                  subtitle: const Text('Seul vous pouvez modifier le croquis\n(Plus simple et sûr)'),
                  trailing: ElevatedButton(
                    onPressed: () => _createSketch(SketchMode.exclusive),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Créer'),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Mode collaboratif
              Card(
                child: ListTile(
                  leading: const Icon(Icons.group, color: Colors.green),
                  title: const Text('Mode Collaboratif'),
                  subtitle: const Text('Tous les conducteurs peuvent modifier\n(Chacun a sa couleur)'),
                  trailing: ElevatedButton(
                    onPressed: () => _createSketch(SketchMode.collaborative),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Créer'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollaborativeSketch() {
    final sketch = _currentSketch!;
    final canEdit = _canCurrentUserEdit();
    
    return Column(
      children: [
        // En-tête avec participants
        _buildParticipantsHeader(),
        
        // Zone de croquis
        Expanded(
          child: Stack(
            children: [
              // Widget de croquis
              ModernSketchWidget(
                width: double.infinity,
                height: double.infinity,
                onSketchChanged: canEdit ? _onSketchChanged : null,
                initialElements: _convertToSketchElements(sketch.elements),
                isReadOnly: !canEdit,
              ),
              
              // Overlay de verrouillage
              if (sketch.isLocked)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 48, color: Colors.orange),
                            SizedBox(height: 8),
                            Text(
                              'Croquis verrouillé',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text('Plus de modifications possibles'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Actions
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildParticipantsHeader() {
    final sketch = _currentSketch!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(
            sketch.mode == SketchMode.exclusive ? Icons.lock : Icons.group,
            color: sketch.mode == SketchMode.exclusive ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            sketch.mode == SketchMode.exclusive ? 'Mode Exclusif' : 'Mode Collaboratif',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _participants.map((participant) {
                  final color = Color(int.parse(participant.assignedColor.substring(1), radix: 16) + 0xFF000000);
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: participant.isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          participant.conducteurName,
                          style: TextStyle(
                            fontSize: 12,
                            color: color.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final sketch = _currentSketch!;
    final isCreator = sketch.creatorId == widget.conducteurId;
    final canEdit = _canCurrentUserEdit();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (canEdit && !sketch.isLocked)
            ElevatedButton.icon(
              onPressed: () => _clearSketch(),
              icon: const Icon(Icons.clear),
              label: const Text('Effacer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
            ),
          
          if (isCreator && !sketch.isLocked)
            ElevatedButton.icon(
              onPressed: () => _lockSketch(),
              icon: const Icon(Icons.lock),
              label: const Text('Verrouiller'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
            ),
          
          ElevatedButton.icon(
            onPressed: () => _showSignatureDialog(),
            icon: Icon(sketch.signatures.containsKey(widget.conducteurId) 
                ? Icons.check_circle 
                : Icons.edit),
            label: Text(sketch.signatures.containsKey(widget.conducteurId) 
                ? 'Signé' 
                : 'Signer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: sketch.signatures.containsKey(widget.conducteurId)
                  ? Colors.green[600]
                  : Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  bool _canCurrentUserEdit() {
    final sketch = _currentSketch!;
    if (sketch.isLocked) return false;
    
    return sketch.mode == SketchMode.collaborative || 
           sketch.creatorId == widget.conducteurId;
  }

  List<SketchElement> _convertToSketchElements(List<SketchElementData> elements) {
    // Conversion des éléments collaboratifs vers les éléments du widget de croquis
    // TODO: Implémenter la conversion
    return [];
  }

  void _onSketchChanged(List<SketchElement> elements) {
    // TODO: Convertir et envoyer les changements au service
  }

  void _clearSketch() {
    // TODO: Implémenter l'effacement
  }

  void _lockSketch() {
    // TODO: Implémenter le verrouillage
  }

  void _showSignatureDialog() {
    // TODO: Implémenter la signature
  }
}
