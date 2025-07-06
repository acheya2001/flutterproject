import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/services/session_service.dart';

import '../../auth/providers/auth_provider.dart';
import '../../constat/providers/session_provider.dart';
import '../../constat/models/session_constat_model.dart';
import '../../constat/models/conducteur_session_info.dart';
import '../widgets/session_invitation_card.dart';
import '../widgets/modern_join_session_dialog.dart';
import 'conducteur_declaration_screen.dart';

class InvitationsScreen extends ConsumerStatefulWidget {
  const InvitationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends ConsumerState<InvitationsScreen> {
  List<SessionConstatModel> _invitations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProviderInstance = ref.read(authProvider);
      if (authProviderInstance.currentUser == null) {
        return;
      }

      final sessionProvider = SessionProvider(
        sessionService: SessionService(),
      );

      // Simuler des invitations pour la démo
      await Future.delayed(const Duration(milliseconds: 1000));
      
      final mockInvitations = [
        SessionConstatModel(
          id: 'session_1',
          sessionCode: 'ABC123',
          nombreConducteurs: 2,
          dateAccident: DateTime.now().subtract(const Duration(hours: 2)),
          lieuAccident: 'Avenue Habib Bourguiba, Tunis',
          createdBy: 'other_user',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
          status: SessionStatus.inProgress,
          invitationsSent: ['creator@test.com', authProviderInstance.currentUser!.email],
          validationStatus: {'A': true, 'B': false},
          conducteursInfo: {
            'A': ConducteurSessionInfo(
              position: 'A',
              userId: 'other_user',
              email: 'creator@test.com',
              isInvited: false,
              hasJoined: true,
              isCompleted: false,
              joinedAt: DateTime.now().subtract(const Duration(hours: 3)),
              isProprietaire: true,
            ),
            'B': ConducteurSessionInfo(
              position: 'B',
              userId: null,
              email: authProviderInstance.currentUser!.email,
              isInvited: true,
              hasJoined: false,
              isCompleted: false,
              joinedAt: null,
              isProprietaire: true,
            ),
          },
        ),
        SessionConstatModel(
          id: 'session_2',
          sessionCode: 'XYZ789',
          nombreConducteurs: 3,
          dateAccident: DateTime.now().subtract(const Duration(days: 1)),
          lieuAccident: 'Route de Sfax, Sousse',
          createdBy: 'another_user',
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
          status: SessionStatus.inProgress,
          invitationsSent: ['creator2@test.com', 'userb@test.com', authProviderInstance.currentUser!.email],
          validationStatus: {'A': true, 'B': true, 'C': false},
          conducteursInfo: {
            'A': ConducteurSessionInfo(
              position: 'A',
              userId: 'another_user',
              email: 'creator2@test.com',
              isInvited: false,
              hasJoined: true,
              isCompleted: true,
              joinedAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
              isProprietaire: true,
            ),
            'B': ConducteurSessionInfo(
              position: 'B',
              userId: 'user_b',
              email: 'userb@test.com',
              isInvited: true,
              hasJoined: true,
              isCompleted: false,
              joinedAt: DateTime.now().subtract(const Duration(hours: 20)),
              isProprietaire: true,
            ),
            'C': ConducteurSessionInfo(
              position: 'C',
              userId: null,
              email: authProviderInstance.currentUser!.email,
              isInvited: true,
              hasJoined: false,
              isCompleted: false,
              joinedAt: null,
              isProprietaire: true,
            ),
          },
        ),
      ];

      setState(() {
        _invitations = mockInvitations;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[InvitationsScreen] Erreur chargement invitations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rejoindreSession(SessionConstatModel session) async {
    try {
      final authProviderInstance = ref.read(authProvider);
      if (authProviderInstance.currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Trouver la position du conducteur
      String? position;
      for (var entry in session.conducteursInfo.entries) {
        if (entry.value.email == authProviderInstance.currentUser!.email) {
          position = entry.key;
          break;
        }
      }

      if (position == null) {
        throw Exception('Position non trouvée dans la session');
      }

      final sessionProvider = SessionProvider(
        sessionService: SessionService(),
      );

      // Marquer le conducteur comme ayant rejoint
      await sessionProvider.marquerConducteurRejoint(
        sessionId: session.id!,
        position: position,
        userId: authProviderInstance.currentUser!.id,
      );

      // Naviguer vers l'écran de déclaration
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConducteurDeclarationScreen(
              sessionId: session.id!,
              conducteurPosition: position!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _getConducteursRejoints(SessionConstatModel session) {
    return session.conducteursInfo.values
        .where((info) => info.hasJoined)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Mes Invitations',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _invitations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadInvitations,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _invitations.length,
                    itemBuilder: (context, index) {
                      final session = _invitations[index];
                      return SessionInvitationCard(
                        sessionCode: session.sessionCode,
                        sessionId: session.id,
                        dateAccident: session.dateAccident,
                        lieuAccident: session.lieuAccident,
                        nombreConducteurs: session.nombreConducteurs,
                        conducteursRejoints: _getConducteursRejoints(session),
                        onJoin: () => _rejoindreSession(session),
                        onShare: () {
                          // TODO: Implémenter le partage
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonctionnalité de partage bientôt disponible'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const ModernJoinSessionDialog(),
          );
        },
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Rejoindre avec code'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.mail_outline,
                size: 60,
                color: Color(0xFF9CA3AF),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Aucune invitation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Vous n\'avez pas encore reçu d\'invitation à des sessions collaboratives.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const ModernJoinSessionDialog(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.vpn_key),
              label: const Text(
                'Rejoindre avec un code',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
