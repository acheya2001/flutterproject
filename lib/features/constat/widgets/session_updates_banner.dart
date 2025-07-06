import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_constat_model.dart';
import '../providers/collaborative_session_riverpod_provider.dart';

/// 🔔 Banner de notifications pour les mises à jour de session
/// 
/// Affiche les notifications en temps réel quand d'autres conducteurs
/// rejoignent la session ou terminent leur partie du constat.
class SessionUpdatesBanner extends ConsumerStatefulWidget {
  final String currentUserPosition;

  const SessionUpdatesBanner({
    Key? key,
    required this.currentUserPosition,
  }) : super(key: key);

  @override
  ConsumerState<SessionUpdatesBanner> createState() => _SessionUpdatesBannerState();
}

class _SessionUpdatesBannerState extends ConsumerState<SessionUpdatesBanner>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  SessionConstatModel? _previousSession;
  String? _lastNotification;
  bool _showNotification = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkForUpdates(SessionConstatModel? currentSession) {
    if (currentSession == null) return;
    
    if (_previousSession == null) {
      _previousSession = currentSession;
      return;
    }
    
    // Vérifier les nouveaux conducteurs qui ont rejoint
    for (final entry in currentSession.conducteursInfo.entries) {
      final position = entry.key;
      final conducteur = entry.value;
      final previousConducteur = _previousSession!.conducteursInfo[position];
      
      // Ignorer sa propre position
      if (position == widget.currentUserPosition) continue;
      
      // Nouveau conducteur qui a rejoint
      if (previousConducteur?.hasJoined != true && conducteur.hasJoined) {
        final name = conducteur.conducteurInfo != null 
            ? '${conducteur.conducteurInfo!.prenom} ${conducteur.conducteurInfo!.nom}'
            : 'Conducteur $position';
        _showUpdateNotification(
          '👋 $name a rejoint la session',
          Colors.blue,
          Icons.person_add,
        );
      }
      
      // Conducteur qui a terminé
      if (previousConducteur?.isCompleted != true && conducteur.isCompleted) {
        final name = conducteur.conducteurInfo != null 
            ? '${conducteur.conducteurInfo!.prenom} ${conducteur.conducteurInfo!.nom}'
            : 'Conducteur $position';
        _showUpdateNotification(
          '✅ $name a terminé son constat',
          Colors.green,
          Icons.check_circle,
        );
      }
    }
    
    _previousSession = currentSession;
  }

  void _showUpdateNotification(String message, Color color, IconData icon) {
    if (_lastNotification == message) return; // Éviter les doublons
    
    setState(() {
      _lastNotification = message;
      _showNotification = true;
    });
    
    _animationController.forward();
    
    // Masquer automatiquement après 4 secondes
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showNotification = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(collaborativeSessionProvider).currentSession;
    
    // Vérifier les mises à jour
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates(session);
    });
    
    if (!_showNotification || _lastNotification == null) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation.drive(Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        )),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981),
                  const Color(0xFF10B981).withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _lastNotification!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () {
                    _animationController.reverse().then((_) {
                      if (mounted) {
                        setState(() {
                          _showNotification = false;
                        });
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


