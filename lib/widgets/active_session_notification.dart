import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/collaborative_session_model.dart';
import '../conducteur/screens/collaborative_session_dashboard.dart';

/// 🔔 Widget de notification pour session collaborative active
class ActiveSessionNotification extends StatefulWidget {
  const ActiveSessionNotification({Key? key}) : super(key: key);

  @override
  State<ActiveSessionNotification> createState() => _ActiveSessionNotificationState();
}

class _ActiveSessionNotificationState extends State<ActiveSessionNotification>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  Map<String, dynamic>? _sessionActive;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
    _chargerSessionActive();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 🔍 Charger la session active de l'utilisateur
  Future<void> _chargerSessionActive() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Chercher les sessions où l'utilisateur est créateur et actives
      final sessionsCreateur = await FirebaseFirestore.instance
          .collection('collaborative_sessions')
          .where('createurId', isEqualTo: user.uid)
          .where('statut', whereIn: ['en_cours', 'en_attente'])
          .limit(1)
          .get();

      // Chercher les sessions où l'utilisateur est participant et actives
      final sessionsParticipant = await FirebaseFirestore.instance
          .collection('collaborative_sessions')
          .where('participantsIds', arrayContains: user.uid)
          .where('statut', whereIn: ['en_cours', 'en_attente'])
          .limit(1)
          .get();

      Map<String, dynamic>? sessionTrouvee;

      if (sessionsCreateur.docs.isNotEmpty) {
        final doc = sessionsCreateur.docs.first;
        sessionTrouvee = doc.data();
        sessionTrouvee['id'] = doc.id;
        sessionTrouvee['roleUtilisateur'] = 'createur';
      } else if (sessionsParticipant.docs.isNotEmpty) {
        final doc = sessionsParticipant.docs.first;
        sessionTrouvee = doc.data();
        sessionTrouvee['id'] = doc.id;
        sessionTrouvee['roleUtilisateur'] = 'participant';
      }

      if (mounted) {
        setState(() {
          _sessionActive = sessionTrouvee;
          _isLoading = false;
        });
      }

    } catch (e) {
      print('❌ Erreur chargement session active: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_sessionActive == null) {
      return const SizedBox.shrink();
    }

    final code = _sessionActive!['code'] ?? _sessionActive!['codeSession'] ?? 'Session';
    final roleUtilisateur = _sessionActive!['roleUtilisateur'] ?? 'participant';
    final nombreVehicules = _sessionActive!['nombreVehicules'] ?? 2;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo[600]!,
                  Colors.indigo[800]!,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _ouvrirSessionDashboard,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Icône animée
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.group_work,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Informations
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Session Active: $code',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: roleUtilisateur == 'createur' 
                                        ? Colors.green[400] 
                                        : Colors.blue[400],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    roleUtilisateur == 'createur' ? 'CRÉATEUR' : 'PARTICIPANT',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$nombreVehicules véhicules • Touchez pour gérer',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Flèche
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.8),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 🚪 Ouvrir le dashboard de session
  void _ouvrirSessionDashboard() {
    try {
      final session = CollaborativeSession(
        id: _sessionActive!['id'] ?? '',
        codeSession: _sessionActive!['code'] ?? _sessionActive!['codeSession'] ?? '',
        qrCodeData: _sessionActive!['qrCodeData'] ?? '',
        typeAccident: _sessionActive!['typeAccident'] ?? 'accident_collaboratif',
        nombreVehicules: _sessionActive!['nombreVehicules'] ?? 2,
        statut: SessionStatus.en_cours,
        conducteurCreateur: _sessionActive!['createurId'] ?? '',
        participants: [],
        progression: SessionProgress(
          participantsRejoints: 0,
          formulairesTermines: 0,
          croquisValides: 0,
          signaturesEffectuees: 0,
          croquisCree: false,
          peutFinaliser: false,
        ),
        parametres: SessionSettings(
          autoValidationCroquis: false,
          timeoutMinutes: 1440,
          notificationsActives: true,
          modeDebug: false,
        ),
        dateCreation: _sessionActive!['dateCreation'] != null 
            ? (_sessionActive!['dateCreation'] as Timestamp).toDate()
            : DateTime.now(),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollaborativeSessionDashboard(session: session),
          settings: const RouteSettings(name: '/session-dashboard'),
        ),
      );
    } catch (e) {
      print('❌ Erreur ouverture session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
