import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

/// 🎬 Page principale de reconstitution vidéo d'accident
class AccidentVideoReconstructionPage extends StatefulWidget {
  const AccidentVideoReconstructionPage({super.key});

  @override
  State<AccidentVideoReconstructionPage> createState() => _AccidentVideoReconstructionPageState();
}

class _AccidentVideoReconstructionPageState extends State<AccidentVideoReconstructionPage>
    with TickerProviderStateMixin {
  
  late AnimationController _videoController;
  late AnimationController _impactController;
  late Animation<double> _impactAnimation;
  
  bool _isPlaying = false;
  bool _showImpactEffect = false;
  Timer? _impactTimer;

  @override
  void initState() {
    super.initState();
    
    // Contrôleur principal pour l'animation des véhicules
    _videoController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    // Contrôleur pour l'effet d'impact
    _impactController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _impactAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _impactController,
      curve: Curves.elasticOut,
    ));
    
    // Écouter les changements d'animation
    _videoController.addListener(() {
      // Déclencher l'impact à 70% de l'animation
      if (_videoController.value >= 0.7 && !_showImpactEffect) {
        _triggerImpactEffect();
      }
    });
    
    // Démarrer automatiquement
    _startAnimation();
  }

  void _triggerImpactEffect() {
    setState(() {
      _showImpactEffect = true;
    });
    _impactController.forward();
    
    // Vibration simulée
    _impactTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (timer.tick >= 5) {
        timer.cancel();
      }
    });
  }

  void _startAnimation() {
    setState(() {
      _isPlaying = true;
      _showImpactEffect = false;
    });
    _videoController.reset();
    _impactController.reset();
    _videoController.forward();
  }

  void _pauseAnimation() {
    setState(() {
      _isPlaying = false;
    });
    _videoController.stop();
  }

  void _resetAnimation() {
    setState(() {
      _isPlaying = false;
      _showImpactEffect = false;
    });
    _videoController.reset();
    _impactController.reset();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _impactController.dispose();
    _impactTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('🎬 Reconstitution Vidéo Accident'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec informations
            _buildHeader(),
            const SizedBox(height: 20),
            
            // Zone vidéo principale
            _buildVideoPlayer(),
            const SizedBox(height: 20),
            
            // Contrôles vidéo
            _buildVideoControls(),
            const SizedBox(height: 20),
            
            // Informations détaillées
            _buildAccidentDetails(),
            const SizedBox(height: 20),
            
            // Actions
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// 📋 En-tête avec informations de session
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[50]!, Colors.purple[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reconstitution IA Avancée',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    Text(
                      'Analyse automatique de l\'accident',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'GRATUIT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '🎯 Cette reconstitution utilise l\'IA pour analyser les photos et créer une simulation 3D de l\'accident.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// 🎬 Lecteur vidéo principal
  Widget _buildVideoPlayer() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Fond avec route
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.green[200],
              child: CustomPaint(
                size: Size.infinite,
                painter: RoadPainter(),
              ),
            ),
            
            // Animation des véhicules
            AnimatedBuilder(
              animation: _videoController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: VehicleAnimationPainter(
                    progress: _videoController.value,
                    showImpact: _showImpactEffect,
                    impactProgress: _impactAnimation.value,
                  ),
                );
              },
            ),
            
            // Overlay d'informations
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
                      'Reconstitution 3D en temps réel',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isPlaying ? Colors.red : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _isPlaying ? 'LIVE' : 'PAUSE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bouton play/pause central
            if (!_isPlaying)
              Center(
                child: GestureDetector(
                  onTap: _startAnimation,
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
                          offset: const Offset(0, 4),
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
              ),
          ],
        ),
      ),
    );
  }

  /// 🎮 Contrôles vidéo
  Widget _buildVideoControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de progression
          Row(
            children: [
              Text(
                '${(_videoController.value * 8).toInt()}:${((_videoController.value * 8 % 1) * 60).toInt().toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedBuilder(
                  animation: _videoController,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _videoController.value,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                      minHeight: 6,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '0:08',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Boutons de contrôle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: Icons.replay,
                onPressed: _resetAnimation,
                color: Colors.grey[600]!,
              ),
              const SizedBox(width: 20),
              _buildControlButton(
                icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                onPressed: _isPlaying ? _pauseAnimation : _startAnimation,
                color: Colors.purple,
                size: 40,
                isMain: true,
              ),
              const SizedBox(width: 20),
              _buildControlButton(
                icon: Icons.download,
                onPressed: _downloadVideo,
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    double size = 24,
    bool isMain = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isMain ? 60 : 45,
        height: isMain ? 60 : 45,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size,
        ),
      ),
    );
  }

  /// 📊 Détails de l'accident
  Widget _buildAccidentDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text(
                'Analyse de l\'accident',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildDetailSection(
            '🚗 VÉHICULES IMPLIQUÉS',
            [
              'Berline Noir - Position: Nord',
              'Citadine Bleu - Position: Sud',
            ],
          ),

          const SizedBox(height: 12),

          _buildDetailSection(
            '💥 ANALYSE DE L\'IMPACT',
            [
              'Direction: Latéral',
              'Angle: 90°',
              'Vitesse estimée: Modérée',
            ],
          ),

          const SizedBox(height: 12),

          _buildDetailSection(
            '🔧 DÉGÂTS IDENTIFIÉS',
            [
              'Côté droit (Grave)',
              'Côté gauche (Modéré)',
            ],
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.purple,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        ...details.map((detail) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 2),
          child: Text('• $detail', style: const TextStyle(fontSize: 13)),
        )),
      ],
    );
  }

  /// 🎬 Boutons d'action
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _shareVideo,
            icon: const Icon(Icons.share),
            label: const Text('Partager'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveToReport,
            icon: const Icon(Icons.save),
            label: const Text('Sauvegarder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _downloadVideo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎥 Téléchargement de la vidéo en cours...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareVideo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📤 Partage de la vidéo...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _saveToReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💾 Vidéo ajoutée au rapport d\'accident'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}

/// 🛣️ Painter pour dessiner la route
class RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fond d'herbe
    final grassPaint = Paint()
      ..color = Colors.green[300]!
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grassPaint);

    // Route principale horizontale
    final roadPaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.35, size.width, size.height * 0.3),
      roadPaint,
    );

    // Route secondaire verticale
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.35, 0, size.width * 0.3, size.height),
      roadPaint,
    );

    // Lignes blanches horizontales
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;

    for (double x = 0; x < size.width; x += 60) {
      canvas.drawLine(
        Offset(x, size.height * 0.5),
        Offset(x + 30, size.height * 0.5),
        linePaint,
      );
    }

    // Lignes blanches verticales
    for (double y = 0; y < size.height; y += 60) {
      canvas.drawLine(
        Offset(size.width * 0.5, y),
        Offset(size.width * 0.5, y + 30),
        linePaint,
      );
    }

    // Intersection
    final intersectionPaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.35,
        size.height * 0.35,
        size.width * 0.3,
        size.height * 0.3,
      ),
      intersectionPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 🎨 Painter pour l'animation des véhicules
class VehicleAnimationPainter extends CustomPainter {
  final double progress;
  final bool showImpact;
  final double impactProgress;

  VehicleAnimationPainter({
    required this.progress,
    required this.showImpact,
    required this.impactProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Véhicule 1 (Berline Noir - venant de la gauche)
    final vehicle1X = (size.width * 0.6 * progress) - 40;
    final vehicle1Y = size.height * 0.42;

    if (vehicle1X > -40) {
      // Ombre du véhicule 1
      paint.color = Colors.black.withValues(alpha: 0.3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(vehicle1X + 3, vehicle1Y + 3, 80, 40),
          const Radius.circular(8),
        ),
        paint,
      );

      // Corps du véhicule 1 (Noir)
      paint.color = Colors.black;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(vehicle1X, vehicle1Y, 80, 40),
          const Radius.circular(8),
        ),
        paint,
      );

      // Fenêtres véhicule 1
      paint.color = Colors.blue[100]!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(vehicle1X + 8, vehicle1Y + 8, 64, 24),
          const Radius.circular(4),
        ),
        paint,
      );

      // Phares
      paint.color = Colors.yellow[200]!;
      canvas.drawCircle(Offset(vehicle1X + 75, vehicle1Y + 12), 4, paint);
      canvas.drawCircle(Offset(vehicle1X + 75, vehicle1Y + 28), 4, paint);
    }

    // Véhicule 2 (Citadine Bleu - venant du haut)
    final vehicle2X = size.width * 0.42;
    final vehicle2Y = (size.height * 0.6 * progress) - 40;

    if (vehicle2Y > -40) {
      // Ombre du véhicule 2
      paint.color = Colors.black.withValues(alpha: 0.3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(vehicle2X + 3, vehicle2Y + 3, 40, 80),
          const Radius.circular(8),
        ),
        paint,
      );

      // Corps du véhicule 2 (Bleu)
      paint.color = Colors.blue[700]!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(vehicle2X, vehicle2Y, 40, 80),
          const Radius.circular(8),
        ),
        paint,
      );

      // Fenêtres véhicule 2
      paint.color = Colors.blue[100]!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(vehicle2X + 8, vehicle2Y + 8, 24, 64),
          const Radius.circular(4),
        ),
        paint,
      );

      // Phares
      paint.color = Colors.yellow[200]!;
      canvas.drawCircle(Offset(vehicle2X + 12, vehicle2Y + 75), 4, paint);
      canvas.drawCircle(Offset(vehicle2X + 28, vehicle2Y + 75), 4, paint);
    }

    // Effet d'impact
    if (showImpact && progress > 0.6) {
      final impactX = size.width * 0.5;
      final impactY = size.height * 0.5;

      // Explosion principale
      final explosionPaint = Paint()
        ..color = Colors.orange.withValues(alpha: impactProgress * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(impactX, impactY),
        50 * impactProgress,
        explosionPaint,
      );

      // Étincelles
      final sparkPaint = Paint()
        ..color = Colors.yellow.withValues(alpha: impactProgress * 0.9)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < 12; i++) {
        final angle = (i * 30) * (math.pi / 180);
        final sparkX = impactX + (60 * impactProgress * math.cos(angle));
        final sparkY = impactY + (60 * impactProgress * math.sin(angle));

        canvas.drawCircle(
          Offset(sparkX, sparkY),
          8 * impactProgress,
          sparkPaint,
        );
      }

      // Débris
      final debrisPaint = Paint()
        ..color = Colors.grey.withValues(alpha: impactProgress * 0.7)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < 8; i++) {
        final angle = (i * 45) * (math.pi / 180);
        final debrisX = impactX + (80 * impactProgress * math.cos(angle));
        final debrisY = impactY + (80 * impactProgress * math.sin(angle));

        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(debrisX, debrisY),
            width: 6 * impactProgress,
            height: 6 * impactProgress,
          ),
          debrisPaint,
        );
      }
    }

    // Trajectoires des véhicules (lignes pointillées)
    if (progress > 0.1) {
      final trajectoryPaint = Paint()
        ..color = Colors.red.withValues(alpha: 0.6)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      // Trajectoire véhicule 1 (horizontal)
      for (double x = 0; x < vehicle1X + 40; x += 20) {
        canvas.drawLine(
          Offset(x, vehicle1Y + 20),
          Offset(x + 10, vehicle1Y + 20),
          trajectoryPaint,
        );
      }

      // Trajectoire véhicule 2 (vertical)
      trajectoryPaint.color = Colors.blue.withValues(alpha: 0.6);
      for (double y = 0; y < vehicle2Y + 40; y += 20) {
        canvas.drawLine(
          Offset(vehicle2X + 20, y),
          Offset(vehicle2X + 20, y + 10),
          trajectoryPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
