import 'package:flutter/material.dart';
import 'ai_accident_analysis_widget.dart';
import '../models/accident_analysis_model.dart';
import 'dart:math' as math;

/// 🎯 Widget de démonstration pour l'intégration IA
/// Montre comment intégrer l'analyse IA dans le formulaire de constat
class AIIntegrationDemo extends StatefulWidget {
  final String sessionId;
  final bool isCollaborative;

  const AIIntegrationDemo({
    Key? key,
    required this.sessionId,
    this.isCollaborative = false,
  }) : super(key: key);

  @override
  State<AIIntegrationDemo> createState() => _AIIntegrationDemoState();
}

class _AIIntegrationDemoState extends State<AIIntegrationDemo>
    with TickerProviderStateMixin {
  AccidentAnalysis? _analysis;
  bool _showAnalysis = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 Analyse IA d\'Accident'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête explicatif
            _buildHeader(),
            const SizedBox(height: 24),

            // Widget d'analyse IA
            AIAccidentAnalysisWidget(
              sessionId: widget.sessionId,
              isCollaborative: widget.isCollaborative,
              onAnalysisComplete: (analysis) {
                setState(() {
                  _analysis = analysis;
                  _showAnalysis = true;
                });
              },
            ),

            // Résultats de l'analyse
            if (_showAnalysis && _analysis != null) ...[
              const SizedBox(height: 24),
              _buildAnalysisResults(),
            ],

            // Guide d'utilisation
            const SizedBox(height: 24),
            _buildUsageGuide(),
          ],
        ),
      ),
    );
  }

  /// 📋 En-tête explicatif
  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Analyse IA Gratuite',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Cette fonctionnalité utilise uniquement des technologies gratuites :',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            _buildFeatureList(),
          ],
        ),
      ),
    );
  }

  /// ✅ Liste des fonctionnalités gratuites
  Widget _buildFeatureList() {
    final features = [
      '📸 Analyse d\'images avec algorithmes simples',
      '🎤 Reconnaissance vocale native',
      '🧠 Traitement de texte basique',
      '📊 Génération de rapports automatiques',
      '💾 Sauvegarde dans Firebase',
    ];

    return Column(
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(feature, style: const TextStyle(fontSize: 14))),
          ],
        ),
      )).toList(),
    );
  }

  /// 📊 Résultats de l'analyse
  Widget _buildAnalysisResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Résultats de l\'analyse',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Chip(
                  label: Text('${(_analysis!.reconstruction.confidence * 100).toInt()}% confiance'),
                  backgroundColor: Colors.green.shade100,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Véhicules détectés
            _buildVehicleResults(),
            const SizedBox(height: 12),

            // Dégâts détectés
            _buildDamageResults(),
            const SizedBox(height: 12),

            // Impact analysé
            _buildImpactResults(),
            const SizedBox(height: 12),

            // Description traitée
            if (_analysis!.description.originalText.isNotEmpty)
              _buildDescriptionResults(),

            const SizedBox(height: 20),

            // 🎬 BOUTONS D'ACTION VIDÉO
            _buildVideoActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🚗 Véhicules détectés (${_analysis!.imageAnalysis.vehicleCount})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...(_analysis!.imageAnalysis.vehicles.map((vehicle) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Text('• ${vehicle.type} ${vehicle.color} (${vehicle.position})'),
        ))),
      ],
    );
  }

  Widget _buildDamageResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💥 Dégâts identifiés (${_analysis!.imageAnalysis.damages.length})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...(_analysis!.imageAnalysis.damages.map((damage) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Text('• ${damage.location}: ${damage.severity}'),
        ))),
      ],
    );
  }

  Widget _buildImpactResults() {
    final impact = _analysis!.imageAnalysis.impact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💥 Analyse de l\'impact',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Direction: ${impact.direction}'),
              Text('• Angle: ${impact.angle}'),
              Text('• Vitesse estimée: ${impact.speed}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📝 Description analysée',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _analysis!.description.originalText,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        if (_analysis!.description.keyWords.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _analysis!.description.keyWords.map((keyword) => Chip(
              label: Text(keyword),
              backgroundColor: Colors.blue.shade100,
            )).toList(),
          ),
        ],
      ],
    );
  }

  /// 🎬 Boutons d'action pour la vidéo de reconstitution
  Widget _buildVideoActionButtons() {
    return Column(
      children: [
        // Séparateur
        Divider(color: Colors.grey.shade300, thickness: 1),
        const SizedBox(height: 16),

        // Titre de section
        Row(
          children: [
            const Icon(Icons.video_library, color: Colors.purple, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Reconstitution vidéo IA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Boutons d'action
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showReconstructionVideo(),
                icon: const Icon(Icons.play_circle_filled),
                label: const Text('Voir la reconstitution'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showVideoDetails(),
                icon: const Icon(Icons.info_outline),
                label: const Text('Détails'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                  side: const BorderSide(color: Colors.purple),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Bouton de téléchargement
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _downloadReconstructionVideo(),
            icon: const Icon(Icons.download),
            label: const Text('Télécharger la vidéo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// 📖 Guide d'utilisation
  Widget _buildUsageGuide() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, color: Colors.purple, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Guide d\'utilisation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGuideSteps(),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideSteps() {
    final steps = [
      '1. Prenez des photos claires de l\'accident',
      '2. Ajoutez une description vocale ou écrite',
      '3. Lancez l\'analyse IA gratuite',
      '4. Consultez les résultats générés',
      '5. Utilisez les données dans votre constat',
    ];

    return Column(
      children: steps.map((step) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  step[0],
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(step.substring(3))),
          ],
        ),
      )).toList(),
    );
  }

  /// 🎬 Afficher la reconstitution vidéo
  void _showReconstructionVideo() {
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
                  const Icon(Icons.play_circle, color: Colors.purple, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Reconstitution IA - Accident',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),

              // Lecteur vidéo simulé avec animation
              Expanded(
                child: _buildVideoPlayer(),
              ),

              const SizedBox(height: 16),

              // Contrôles vidéo
              _buildVideoControls(),

              const SizedBox(height: 16),

              // Informations de l'analyse
              _buildVideoInfo(),
            ],
          ),
        ),
      ),
    );
  }

  /// 📊 Afficher les détails de la vidéo
  void _showVideoDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('Détails de l\'analyse'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailSection('🚗 Véhicules', [
                  'Nombre détecté: ${_analysis!.imageAnalysis.vehicleCount}',
                  'Confiance: ${(_analysis!.imageAnalysis.confidence * 100).toInt()}%',
                ]),
                const SizedBox(height: 16),
                _buildDetailSection('💥 Impact', [
                  'Direction: ${_analysis!.imageAnalysis.impact.direction}',
                  'Angle: ${_analysis!.imageAnalysis.impact.angle}',
                  'Vitesse: ${_analysis!.imageAnalysis.impact.speed}',
                ]),
                const SizedBox(height: 16),
                _buildDetailSection('🎬 Reconstitution', [
                  'Confiance: ${(_analysis!.reconstruction.confidence * 100).toInt()}%',
                  'Durée estimée: 30 secondes',
                  'Format: MP4 HD',
                ]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...details.map((detail) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Text('• $detail'),
        )),
      ],
    );
  }

  /// 🎬 Construire le lecteur vidéo avec animation
  Widget _buildVideoPlayer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Fond de la vidéo avec route visible
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.green[100], // Fond vert pour simuler l'herbe
              child: CustomPaint(
                size: Size.infinite,
                painter: RoadPainter(),
              ),
            ),

            // Animation de véhicules
            _buildVehicleAnimation(),

            // Overlay avec informations
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
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
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.purple,
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
  Widget _buildVehicleAnimation() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: VehicleAnimationPainter(
            progress: _animationController.value,
            vehicleCount: _analysis?.imageAnalysis.vehicleCount ?? 2,
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
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
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
                color: Colors.purple,
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
                color: Colors.purple,
                iconSize: 32,
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  _animationController.forward();
                },
                icon: const Icon(Icons.fast_forward),
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Informations de la vidéo
  Widget _buildVideoInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Détails de la reconstitution',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _analysis?.reconstruction.prompt ?? 'Aucune information disponible',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip('Véhicules', '${_analysis?.imageAnalysis.vehicleCount ?? 0}'),
              const SizedBox(width: 8),
              _buildInfoChip('Confiance', '${((_analysis?.reconstruction.confidence ?? 0) * 100).toInt()}%'),
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
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// 📥 Télécharger la vidéo de reconstitution
  void _downloadReconstructionVideo() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.download, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('🎥 Génération de la vidéo en cours...'),
            ),
          ],
        ),
        backgroundColor: Colors.purple,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () => _showReconstructionVideo(),
        ),
      ),
    );

    // Simulation du téléchargement
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Vidéo générée ! Cliquez sur "Voir" pour la visionner'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }
}

/// 🛣️ Painter pour dessiner la route
class RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Route principale horizontale
    final roadPaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.2),
      roadPaint,
    );

    // Route secondaire verticale
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.4, 0, size.width * 0.2, size.height),
      roadPaint,
    );

    // Lignes blanches horizontales
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;

    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(
        Offset(x, size.height * 0.5),
        Offset(x + 25, size.height * 0.5),
        linePaint,
      );
    }

    // Lignes blanches verticales
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(
        Offset(size.width * 0.5, y),
        Offset(size.width * 0.5, y + 25),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

    // Véhicule 1 (Berline Noir - venant de la gauche)
    final vehicle1X = (size.width * 0.7 * progress) - 40;
    final vehicle1Y = size.height * 0.42;

    // Ombre du véhicule 1
    paint.color = Colors.black.withValues(alpha: 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(vehicle1X + 2, vehicle1Y + 2, 70, 35),
        const Radius.circular(8),
      ),
      paint,
    );

    // Corps du véhicule 1
    paint.color = Colors.black;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(vehicle1X, vehicle1Y, 70, 35),
        const Radius.circular(8),
      ),
      paint,
    );

    // Fenêtres véhicule 1
    paint.color = Colors.blue[200]!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(vehicle1X + 5, vehicle1Y + 5, 60, 25),
        const Radius.circular(4),
      ),
      paint,
    );

    // Véhicule 2 (Citadine Bleu - venant du haut)
    final vehicle2X = size.width * 0.47;
    final vehicle2Y = (size.height * 0.7 * progress) - 40;

    // Ombre du véhicule 2
    paint.color = Colors.black.withValues(alpha: 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(vehicle2X + 2, vehicle2Y + 2, 35, 70),
        const Radius.circular(8),
      ),
      paint,
    );

    // Corps du véhicule 2
    paint.color = Colors.blue[700]!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(vehicle2X, vehicle2Y, 35, 70),
        const Radius.circular(8),
      ),
      paint,
    );

    // Fenêtres véhicule 2
    paint.color = Colors.blue[200]!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(vehicle2X + 5, vehicle2Y + 5, 25, 60),
        const Radius.circular(4),
      ),
      paint,
    );

    // Point d'impact avec explosion (apparaît vers la fin)
    if (progress > 0.6) {
      final impactProgress = (progress - 0.6) / 0.4;

      // Explosion principale
      final impactPaint = Paint()
        ..color = Colors.orange.withValues(alpha: impactProgress * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.5),
        30 * impactProgress,
        impactPaint,
      );

      // Étincelles
      final sparkPaint = Paint()
        ..color = Colors.yellow.withValues(alpha: impactProgress * 0.9)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < 8; i++) {
        final angle = (i * 45) * (3.14159 / 180);
        final sparkX = size.width * 0.5 + (40 * impactProgress * math.cos(angle));
        final sparkY = size.height * 0.5 + (40 * impactProgress * math.sin(angle));

        canvas.drawCircle(
          Offset(sparkX, sparkY),
          5 * impactProgress,
          sparkPaint,
        );
      }
    }

    // Trajectoires des véhicules (lignes pointillées)
    final trajectoryPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Trajectoire véhicule 1
    if (progress > 0.2) {
      canvas.drawLine(
        const Offset(0, 0),
        Offset(vehicle1X + 35, vehicle1Y + 17.5),
        trajectoryPaint,
      );
    }

    // Trajectoire véhicule 2
    if (progress > 0.2) {
      trajectoryPaint.color = Colors.blue.withValues(alpha: 0.5);
      canvas.drawLine(
        Offset(vehicle2X + 17.5, 0),
        Offset(vehicle2X + 17.5, vehicle2Y + 35),
        trajectoryPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
