import 'package:flutter/material.dart';
import 'dart:async';

/// 🔄 Indicateur de synchronisation en temps réel
class RealTimeSyncIndicator extends StatefulWidget {
  final VoidCallback? onRefresh;
  final bool isConnected;
  final DateTime? lastUpdate;

  const RealTimeSyncIndicator({
    Key? key,
    this.onRefresh,
    this.isConnected = true,
    this.lastUpdate,
  }) : super(key: key);

  @override
  State<RealTimeSyncIndicator> createState() => _RealTimeSyncIndicatorState();
}

class _RealTimeSyncIndicatorState extends State<RealTimeSyncIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  Timer? _updateTimer;
  String _timeAgo = '';

  @override
  void initState() {
    super.initState();
    
    // Animation de pulsation pour l'indicateur de connexion
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Animation de rotation pour le bouton refresh
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Timer pour mettre à jour le "il y a X minutes"
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateTimeAgo();
    });

    _updateTimeAgo();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(RealTimeSyncIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lastUpdate != oldWidget.lastUpdate) {
      _updateTimeAgo();
    }
  }

  void _updateTimeAgo() {
    if (widget.lastUpdate != null) {
      final now = DateTime.now();
      final difference = now.difference(widget.lastUpdate!);
      
      setState(() {
        if (difference.inMinutes < 1) {
          _timeAgo = 'À l\'instant';
        } else if (difference.inMinutes < 60) {
          _timeAgo = 'Il y a ${difference.inMinutes} min';
        } else if (difference.inHours < 24) {
          _timeAgo = 'Il y a ${difference.inHours}h';
        } else {
          _timeAgo = 'Il y a ${difference.inDays}j';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isConnected 
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isConnected 
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicateur de connexion animé
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: widget.isConnected ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.6 * _pulseController.value),
                      blurRadius: 4 * _pulseController.value,
                      spreadRadius: 2 * _pulseController.value,
                    ),
                  ] : null,
                ),
              );
            },
          ),
          
          const SizedBox(width: 8),
          
          // Texte de statut
          Text(
            widget.isConnected ? 'Synchronisé' : 'Hors ligne',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.isConnected ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          
          // Temps de dernière mise à jour
          if (widget.lastUpdate != null && _timeAgo.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 12,
              color: Colors.grey.shade300,
            ),
            const SizedBox(width: 8),
            Text(
              _timeAgo,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          
          // Bouton de rafraîchissement
          if (widget.onRefresh != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _rotationController.forward().then((_) {
                  _rotationController.reset();
                });
                widget.onRefresh?.call();
              },
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * 3.14159,
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 📊 Widget de statistiques en temps réel
class RealTimeStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? previousValue;
  final IconData icon;
  final Color color;
  final bool isIncreasing;
  final VoidCallback? onTap;

  const RealTimeStatsCard({
    Key? key,
    required this.title,
    required this.value,
    this.previousValue,
    required this.icon,
    required this.color,
    this.isIncreasing = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasChange = previousValue != null && previousValue != value;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasChange ? color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasChange ? color.withOpacity(0.3) : Colors.grey.shade200,
            width: hasChange ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (hasChange)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isIncreasing ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isIncreasing ? Icons.arrow_upward : Icons.arrow_downward,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Nouveau',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔔 Widget de notification de changement
class ChangeNotificationBanner extends StatefulWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionText;

  const ChangeNotificationBanner({
    Key? key,
    required this.message,
    this.onDismiss,
    this.onAction,
    this.actionText,
  }) : super(key: key);

  @override
  State<ChangeNotificationBanner> createState() => _ChangeNotificationBannerState();
}

class _ChangeNotificationBannerState extends State<ChangeNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation.drive(
        Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.message,
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (widget.actionText != null && widget.onAction != null) ...[
              TextButton(
                onPressed: widget.onAction,
                child: Text(widget.actionText!),
              ),
            ],
            IconButton(
              onPressed: () {
                _controller.reverse().then((_) {
                  widget.onDismiss?.call();
                });
              },
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
