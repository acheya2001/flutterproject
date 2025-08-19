import 'package:flutter/material.dart';

/// 🌈 Widget de fond avec dégradé moderne
class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry? begin;
  final AlignmentGeometry? end;
  final List<double>? stops;
  final bool animated;
  final Duration animationDuration;

  const GradientBackground({
    Key? key,
    required this.child,
    this.colors,
    this.begin,
    this.end,
    this.stops,
    this.animated = false,
    this.animationDuration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultColors = [
      Colors.blue.shade50,
      Colors.indigo.shade50,
      Colors.white,
    ];

    if (animated) {
      return _AnimatedGradientBackground(
        colors: colors ?? defaultColors,
        begin: begin ?? Alignment.topLeft,
        end: end ?? Alignment.bottomRight,
        stops: stops,
        duration: animationDuration,
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin ?? Alignment.topLeft,
          end: end ?? Alignment.bottomRight,
          colors: colors ?? defaultColors,
          stops: stops,
        ),
      ),
      child: child,
    );
  }
}

/// 🎨 Fond avec dégradé animé
class _AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final List<double>? stops;
  final Duration duration;

  const _AnimatedGradientBackground({
    required this.child,
    required this.colors,
    required this.begin,
    required this.end,
    this.stops,
    required this.duration,
  });

  @override
  State<_AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<_AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: widget.begin,
              end: widget.end,
              colors: widget.colors.map((color) {
                return Color.lerp(
                  color,
                  color.withOpacity(0.7),
                  _animation.value,
                )!;
              }).toList(),
              stops: widget.stops,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// 🌟 Fond avec particules animées
class ParticleBackground extends StatefulWidget {
  final Widget child;
  final Color particleColor;
  final int particleCount;
  final double particleSize;

  const ParticleBackground({
    Key? key,
    required this.child,
    this.particleColor = Colors.white,
    this.particleCount = 50,
    this.particleSize = 2.0,
  }) : super(key: key);

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _particles = List.generate(
      widget.particleCount,
      (index) => Particle(),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade900,
                Colors.indigo.shade900,
                Colors.purple.shade900,
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(
                particles: _particles,
                animation: _animationController.value,
                color: widget.particleColor,
                size: widget.particleSize,
              ),
              size: Size.infinite,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

/// Classe pour représenter une particule
class Particle {
  late double x;
  late double y;
  late double speedX;
  late double speedY;
  late double opacity;

  Particle() {
    x = (DateTime.now().millisecondsSinceEpoch % 1000) / 1000.0;
    y = (DateTime.now().microsecondsSinceEpoch % 1000) / 1000.0;
    speedX = (DateTime.now().millisecondsSinceEpoch % 100 - 50) / 10000.0;
    speedY = (DateTime.now().microsecondsSinceEpoch % 100 - 50) / 10000.0;
    opacity = (DateTime.now().millisecondsSinceEpoch % 100) / 100.0;
  }

  void update() {
    x += speedX;
    y += speedY;

    if (x < 0 || x > 1) speedX = -speedX;
    if (y < 0 || y > 1) speedY = -speedY;

    x = x.clamp(0.0, 1.0);
    y = y.clamp(0.0, 1.0);
  }
}

/// Painter pour dessiner les particules
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animation;
  final Color color;
  final double size;

  ParticlePainter({
    required this.particles,
    required this.animation,
    required this.color,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      particle.update();
      
      final x = particle.x * canvasSize.width;
      final y = particle.y * canvasSize.height;
      
      paint.color = color.withOpacity(particle.opacity * 0.6);
      canvas.drawCircle(
        Offset(x, y),
        size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 🌊 Fond avec effet de vagues
class WaveBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final double height;

  const WaveBackground({
    Key? key,
    required this.child,
    this.colors = const [Colors.blue, Colors.indigo],
    this.height = 200,
  }) : super(key: key);

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: widget.colors,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: WavePainter(
                animation: _animationController.value,
                color: Colors.white.withOpacity(0.1),
              ),
              size: Size(double.infinity, widget.height),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

/// Painter pour dessiner les vagues
class WavePainter extends CustomPainter {
  final double animation;
  final Color color;

  WavePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 20.0;
    final waveLength = size.width / 2;

    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height - 
          waveHeight * 
          (1 + 
           0.5 * (x / waveLength + animation * 2) * 3.14159) +
          waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
