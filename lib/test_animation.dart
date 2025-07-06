import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 🎬 Test simple de l'animation de reconstitution
class TestAnimationPage extends StatefulWidget {
  const TestAnimationPage({super.key});

  @override
  State<TestAnimationPage> createState() => _TestAnimationPageState();
}

class _TestAnimationPageState extends State<TestAnimationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    
    // Démarrer l'animation automatiquement
    _animationController.repeat();
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
        title: const Text('🎬 Test Animation Reconstitution'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Zone d'animation
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Route
                      CustomPaint(
                        size: Size.infinite,
                        painter: SimpleRoadPainter(),
                      ),
                      
                      // Animation des véhicules
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: Size.infinite,
                            painter: SimpleVehicleAnimationPainter(
                              progress: _animationController.value,
                            ),
                          );
                        },
                      ),
                      
                      // Overlay d'information
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '🎥 Reconstitution 3D en cours...',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Contrôles
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Barre de progression
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _animationController.value,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
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
            ),
            
            const SizedBox(height: 16),
            
            // Informations
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🚗 VÉHICULES IMPLIQUÉS:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                  Text('• Berline Noir - Position: Nord'),
                  Text('• Citadine Bleu - Position: Sud'),
                  SizedBox(height: 8),
                  Text(
                    '💥 ANALYSE DE L\'IMPACT:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                  Text('• Direction: Latéral'),
                  Text('• Angle: 90°'),
                  Text('• Vitesse estimée: Modérée'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🛣️ Painter simple pour la route
class SimpleRoadPainter extends CustomPainter {
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

/// 🎨 Painter simple pour l'animation des véhicules
class SimpleVehicleAnimationPainter extends CustomPainter {
  final double progress;

  SimpleVehicleAnimationPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Véhicule 1 (Berline Noir - venant de la gauche)
    final vehicle1X = (size.width * 0.7 * progress) - 40;
    final vehicle1Y = size.height * 0.42;

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
        final angle = (i * 45) * (math.pi / 180);
        final sparkX = size.width * 0.5 + (40 * impactProgress * math.cos(angle));
        final sparkY = size.height * 0.5 + (40 * impactProgress * math.sin(angle));
        
        canvas.drawCircle(
          Offset(sparkX, sparkY),
          5 * impactProgress,
          sparkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
