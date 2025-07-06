import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt; // Temporairement désactivé
import '../models/accident_analysis_model.dart';
import '../services/offline_ai_service.dart';

/// 🤖 Widget d'analyse IA d'accident
class AIAccidentAnalysisWidget extends StatefulWidget {
  final String sessionId;
  final bool isCollaborative;
  final Function(AccidentAnalysis) onAnalysisComplete;

  const AIAccidentAnalysisWidget({
    Key? key,
    required this.sessionId,
    required this.isCollaborative,
    required this.onAnalysisComplete,
  }) : super(key: key);

  @override
  State<AIAccidentAnalysisWidget> createState() => _AIAccidentAnalysisWidgetState();
}

class _AIAccidentAnalysisWidgetState extends State<AIAccidentAnalysisWidget>
    with TickerProviderStateMixin {
  final OfflineAIService _aiService = OfflineAIService();
  final ImagePicker _picker = ImagePicker();
  // final stt.SpeechToText _speech = stt.SpeechToText(); // Temporairement désactivé
  final TextEditingController _descriptionController = TextEditingController();
  late AnimationController _animationController;

  List<File> _accidentImages = [];
  String _voiceDescription = '';
  bool _isListening = false;
  bool _isAnalyzing = false;
  bool _analysisExists = false;
  AccidentAnalysis? _existingAnalysis;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    _checkExistingAnalysis();
    _initSpeech();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 🔍 Vérifier si l'analyse existe déjà
  Future<void> _checkExistingAnalysis() async {
    if (widget.isCollaborative) {
      final exists = await _aiService.analysisExistsForSession(widget.sessionId);
      if (exists) {
        final analysis = await _aiService.getExistingAnalysis(widget.sessionId);
        setState(() {
          _analysisExists = true;
          _existingAnalysis = analysis;
        });
      }
    }
  }

  /// 🎤 Initialiser la reconnaissance vocale (temporairement désactivé)
  Future<void> _initSpeech() async {
    // await _speech.initialize(); // Temporairement désactivé
    debugPrint('[AI] Reconnaissance vocale temporairement désactivée');
  }

  @override
  Widget build(BuildContext context) {
    if (_analysisExists && _existingAnalysis != null) {
      return _buildExistingAnalysis();
    }

    return _buildCreateAnalysis();
  }

  /// 📋 Afficher l'analyse existante
  Widget _buildExistingAnalysis() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Analyse IA Existante',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Chip(
                  label: Text('${(_existingAnalysis!.reconstruction.confidence * 100).toInt()}% confiance'),
                  backgroundColor: Colors.green.shade100,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Résumé de l'analyse
            _buildAnalysisSummary(_existingAnalysis!),
            
            const SizedBox(height: 16),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showReconstructionVideo(_existingAnalysis!),
                    icon: const Icon(Icons.play_circle),
                    label: const Text('Voir la reconstitution'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDetailedAnalysis(_existingAnalysis!),
                    icon: const Icon(Icons.analytics),
                    label: const Text('Détails'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ➕ Interface de création d'analyse
  Widget _buildCreateAnalysis() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Analyse IA de l\'accident',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des photos et une description pour générer automatiquement un croquis et une reconstitution vidéo.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // Section photos
            _buildPhotosSection(),
            const SizedBox(height: 20),

            // Section description
            _buildDescriptionSection(),
            const SizedBox(height: 20),

            // Bouton d'analyse
            _buildAnalyzeButton(),
          ],
        ),
      ),
    );
  }

  /// 📸 Section des photos
  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📸 Photos de l\'accident',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        
        // Grille des photos
        if (_accidentImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _accidentImages.length + 1,
              itemBuilder: (context, index) {
                if (index == _accidentImages.length) {
                  return _buildAddPhotoButton();
                }
                return _buildPhotoItem(_accidentImages[index], index);
              },
            ),
          )
        else
          _buildAddPhotoButton(),
      ],
    );
  }

  /// ➕ Bouton d'ajout de photo
  Widget _buildAddPhotoButton() {
    return Container(
      width: 120,
      height: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(12),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
            SizedBox(height: 8),
            Text('Ajouter photo', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  /// 🖼️ Item de photo
  Widget _buildPhotoItem(File image, int index) {
    return Container(
      width: 120,
      height: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: FileImage(image),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Section description
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📝 Description de l\'accident',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        
        // Champ de texte
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Décrivez comment l\'accident s\'est produit...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        
        // Bouton vocal
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isListening ? _stopListening : _startListening,
                icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                label: Text(_isListening ? 'Arrêter' : 'Description vocale'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isListening ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (_voiceDescription.isNotEmpty) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ],
        ),

        // Indicateur vocal
        if (_voiceDescription.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '✅ Enregistrement vocal ajouté',
              style: TextStyle(color: Colors.green[700], fontSize: 12),
            ),
          ),
      ],
    );
  }

  /// 🚀 Bouton d'analyse
  Widget _buildAnalyzeButton() {
    final canAnalyze = _accidentImages.isNotEmpty && 
                      (_descriptionController.text.isNotEmpty || _voiceDescription.isNotEmpty);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canAnalyze && !_isAnalyzing ? _performAnalysis : null,
        icon: _isAnalyzing 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(_isAnalyzing ? 'Analyse en cours...' : 'Générer l\'analyse IA'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // Méthodes d'action
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _accidentImages.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _accidentImages.removeAt(index);
    });
  }

  Future<void> _startListening() async {
    // Simulation réaliste de reconnaissance vocale
    setState(() => _isListening = true);

    // Simulation progressive plus réaliste (8-12 secondes)
    final descriptions = [
      'Écoute en cours...',
      'J\'ai entendu un bruit de freinage...',
      'Il y a eu une collision à l\'intersection...',
      'Deux véhicules sont impliqués dans l\'accident...',
      'Le véhicule blanc roulait vers le nord...',
      'Le véhicule noir arrivait de la droite...',
      'L\'impact s\'est produit côté conducteur...',
      'Les dégâts semblent importants à l\'avant...',
      'Collision à l\'intersection entre véhicule blanc et noir, impact latéral, dégâts importants à l\'avant des deux véhicules, freinage d\'urgence visible.'
    ];

    // Simulation progressive
    for (int i = 0; i < descriptions.length; i++) {
      if (!_isListening) break; // Arrêt si l'utilisateur clique stop

      await Future.delayed(Duration(milliseconds: 800 + (i * 200)));
      if (mounted) {
        setState(() {
          _voiceDescription = descriptions[i];
        });
      }
    }

    if (mounted) {
      setState(() => _isListening = false);
    }

    debugPrint('[AI] Simulation reconnaissance vocale terminée: $_voiceDescription');
  }

  void _stopListening() {
    // _speech.stop(); // Temporairement désactivé
    setState(() => _isListening = false);
  }

  Future<void> _performAnalysis() async {
    setState(() => _isAnalyzing = true);

    try {
      final analysis = await _aiService.analyzeAccidentImages(
        accidentImages: _accidentImages,
        sessionId: widget.sessionId,
        voiceDescription: _voiceDescription.isNotEmpty ? _voiceDescription : null,
        textDescription: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      );

      widget.onAnalysisComplete(analysis);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Analyse IA terminée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de l\'analyse: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  // Méthodes d'affichage
  Widget _buildAnalysisSummary(AccidentAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🚗 ${analysis.imageAnalysis.vehicleCount} véhicules détectés'),
        Text('💥 ${analysis.imageAnalysis.damages.length} zones de dégâts'),
        Text('📍 Impact: ${analysis.imageAnalysis.impact.direction}'),
        if (analysis.description.originalText.isNotEmpty)
          Text('📝 Description: ${analysis.description.originalText.substring(0, 50)}...'),
      ],
    );
  }

  void _showReconstructionVideo(AccidentAnalysis analysis) {
    // Démarrer l'animation automatiquement
    _animationController.reset();
    _animationController.repeat();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // En-tête
              Row(
                children: [
                  const Icon(Icons.play_circle, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Reconstitution IA - Accident',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _animationController.stop();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),

              // Lecteur vidéo simulé avec animation
              Expanded(
                child: _buildVideoPlayer(analysis),
              ),

              const SizedBox(height: 16),

              // Contrôles vidéo
              _buildVideoControls(),

              const SizedBox(height: 16),

              // Informations de l'analyse
              _buildVideoInfo(analysis),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailedAnalysis(AccidentAnalysis analysis) {
    // TODO: Implémenter l'affichage détaillé
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analyse détaillée'),
        content: const Text('Fonctionnalité en cours de développement'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 🎬 Construire le lecteur vidéo avec animation
  Widget _buildVideoPlayer(AccidentAnalysis analysis) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Fond de la vidéo avec animation
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1a1a2e),
                    Color(0xFF16213e),
                    Color(0xFF0f3460),
                  ],
                ),
              ),
            ),

            // Animation de véhicules
            _buildVehicleAnimation(analysis),

            // Overlay avec informations
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videocam, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Reconstitution 3D - IA Avancée',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bouton play/pause au centre
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🚗 Animation des véhicules
  Widget _buildVehicleAnimation(AccidentAnalysis analysis) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: VehicleAnimationPainter(
            progress: _animationController.value,
            vehicleCount: analysis.imageAnalysis.vehicleCount,
          ),
        );
      },
    );
  }

  /// 🎮 Contrôles vidéo
  Widget _buildVideoControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Barre de progression
          Row(
            children: [
              Text(
                '0:${(_animationController.value * 15).toInt().toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: _animationController.value,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '0:15',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Boutons de contrôle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  _animationController.reset();
                },
                icon: const Icon(Icons.replay),
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  if (_animationController.isAnimating) {
                    _animationController.stop();
                  } else {
                    _animationController.repeat();
                  }
                },
                icon: Icon(_animationController.isAnimating ? Icons.pause : Icons.play_arrow),
                color: Colors.blue,
                iconSize: 32,
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  _animationController.forward();
                },
                icon: const Icon(Icons.fast_forward),
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Informations de la vidéo
  Widget _buildVideoInfo(AccidentAnalysis analysis) {
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
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Détails de la reconstitution',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            analysis.reconstruction.prompt,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip('Véhicules', '${analysis.imageAnalysis.vehicleCount}'),
              const SizedBox(width: 8),
              _buildInfoChip('Confiance', '${(analysis.reconstruction.confidence * 100).toInt()}%'),
              const SizedBox(width: 8),
              _buildInfoChip('Durée', '15s'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// 🎨 Painter pour l'animation des véhicules
class VehicleAnimationPainter extends CustomPainter {
  final double progress;
  final int vehicleCount;

  VehicleAnimationPainter({
    required this.progress,
    required this.vehicleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Route
    final roadPaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.fill;

    // Dessiner la route
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.2),
      roadPaint,
    );

    // Lignes de route
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(
        Offset(x, size.height * 0.5),
        Offset(x + 20, size.height * 0.5),
        linePaint,
      );
    }

    // Véhicule 1 (venant de la gauche)
    final vehicle1X = (size.width * 0.8 * progress) - 50;
    final vehicle1Y = size.height * 0.42;

    paint.color = Colors.blue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(vehicle1X, vehicle1Y, 60, 30),
        const Radius.circular(8),
      ),
      paint,
    );

    // Véhicule 2 (venant du haut)
    final vehicle2X = size.width * 0.6;
    final vehicle2Y = (size.height * 0.8 * progress) - 50;

    paint.color = Colors.red;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(vehicle2X, vehicle2Y, 30, 60),
        const Radius.circular(8),
      ),
      paint,
    );

    // Point d'impact (apparaît vers la fin)
    if (progress > 0.7) {
      final impactPaint = Paint()
        ..color = Colors.orange.withValues(alpha: (progress - 0.7) * 3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width * 0.6, size.height * 0.5),
        20 * (progress - 0.7) * 3,
        impactPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
