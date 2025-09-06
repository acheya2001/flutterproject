import 'package:flutter/material.dart';
import '../services/collaborative_sketch_service.dart';
import '../models/collaborative_sketch_model.dart';

/// 🎨 Widget pour rejoindre une session de croquis
class JoinSketchSessionWidget extends StatefulWidget {
  final String conducteurId;
  final String conducteurName;
  final Function(CollaborativeSketch) onSketchJoined;

  const JoinSketchSessionWidget({
    super.key,
    required this.conducteurId,
    required this.conducteurName,
    required this.onSketchJoined,
  });

  @override
  State<JoinSketchSessionWidget> createState() => _JoinSketchSessionWidgetState();
}

class _JoinSketchSessionWidgetState extends State<JoinSketchSessionWidget> {
  final TextEditingController _sessionCodeController = TextEditingController();
  final CollaborativeSketchService _sketchService = CollaborativeSketchService();
  
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _sessionCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinSession() async {
    final sessionCode = _sessionCodeController.text.trim();
    
    if (sessionCode.isEmpty) {
      setState(() {
        _error = 'Veuillez entrer un code de session';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Chercher le croquis par code de session
      final sketch = await _sketchService.getSketchBySession(sessionCode);
      
      if (sketch == null) {
        setState(() {
          _error = 'Aucune session trouvée avec ce code';
          _isLoading = false;
        });
        return;
      }

      if (sketch.isLocked) {
        setState(() {
          _error = 'Cette session est verrouillée';
          _isLoading = false;
        });
        return;
      }

      // Rejoindre la session
      await _sketchService.joinSketch(
        sketchId: sketch.id,
        conducteurId: widget.conducteurId,
        conducteurName: widget.conducteurName,
      );

      // Notifier le parent
      widget.onSketchJoined(sketch);
      
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la connexion: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Rejoindre une session de croquis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Entrez le code de session partagé par l\'autre conducteur',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Champ de saisie du code
            TextField(
              controller: _sessionCodeController,
              decoration: InputDecoration(
                labelText: 'Code de session',
                hintText: 'Ex: ABC123',
                prefixIcon: const Icon(Icons.vpn_key),
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _joinSession(),
            ),
            
            const SizedBox(height: 24),
            
            // Bouton de connexion
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _joinSession,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(_isLoading ? 'Connexion...' : 'Rejoindre la session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Informations supplémentaires
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Comment ça marche ?',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. L\'autre conducteur crée une session de croquis\n'
                    '2. Il vous partage le code de session\n'
                    '3. Vous entrez ce code pour rejoindre le croquis\n'
                    '4. Vous collaborez en temps réel sur le même croquis',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🎨 Widget pour afficher le code de session à partager
class ShareSessionCodeWidget extends StatelessWidget {
  final String sessionCode;
  final String sketchMode;

  const ShareSessionCodeWidget({
    super.key,
    required this.sessionCode,
    required this.sketchMode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.share,
              size: 48,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Session créée !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mode: $sketchMode',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Code de session
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'Code de session à partager :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    sessionCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bouton de partage
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implémenter le partage (SMS, WhatsApp, etc.)
              },
              icon: const Icon(Icons.share),
              label: const Text('Partager le code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.orange[600], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Instructions',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Partagez ce code avec l\'autre conducteur pour qu\'il puisse rejoindre votre session de croquis. Une fois connecté, vous pourrez collaborer en temps réel.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
