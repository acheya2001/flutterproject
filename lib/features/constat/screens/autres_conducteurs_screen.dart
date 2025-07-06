import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../models/session_constat_model.dart';
import '../widgets/conducteur_readonly_view.dart';
import '../providers/collaborative_session_riverpod_provider.dart';

/// 👥 Écran de visualisation des autres conducteurs
/// 
/// Permet à un conducteur de voir les informations saisies par les autres
/// conducteurs de la session collaborative en mode lecture seule.
class AutresConducteursScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String currentUserPosition;

  const AutresConducteursScreen({
    Key? key,
    required this.sessionId,
    required this.currentUserPosition,
  }) : super(key: key);

  @override
  ConsumerState<AutresConducteursScreen> createState() => _AutresConducteursScreenState();
}

class _AutresConducteursScreenState extends ConsumerState<AutresConducteursScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les données de la session si nécessaire
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshSession();
    });
  }

  Future<void> _refreshSession() async {
    // Ici vous pouvez ajouter la logique pour rafraîchir les données
    // depuis Firestore si nécessaire
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = ref.watch(collaborativeSessionProvider);
    final session = sessionProvider.currentSession;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Autres conducteurs',
        backgroundColor: Color(0xFF6366F1),
      ),
      body: session == null 
          ? _buildLoadingState()
          : _buildContent(session),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshSession,
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des informations...'),
        ],
      ),
    );
  }

  Widget _buildContent(SessionConstatModel session) {
    final otherConducteurs = session.conducteursInfo.entries
        .where((entry) => entry.key != widget.currentUserPosition)
        .toList();

    if (otherConducteurs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshSession,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(session),
            const SizedBox(height: 16),
            ...otherConducteurs.map((entry) => 
              ConducteurReadonlyView(
                conducteurInfo: entry.value,
                position: entry.key,
                title: _getConducteurTitle(entry.key, entry.value),
              ),
            ),
            const SizedBox(height: 80), // Espace pour le FAB
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SessionConstatModel session) {
    final totalConducteurs = session.nombreConducteurs;
    final conducteursRejoints = session.conducteursInfo.values
        .where((c) => c.hasJoined)
        .length;
    final conducteursTermines = session.conducteursInfo.values
        .where((c) => c.isCompleted)
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.group,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session collaborative',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Code: ${session.sessionCode}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                'Rejoints',
                '$conducteursRejoints/$totalConducteurs',
                Icons.people,
                Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Terminés',
                '$conducteursTermines/$totalConducteurs',
                Icons.check_circle,
                Colors.white.withValues(alpha: 0.9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun autre conducteur',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous êtes le seul conducteur dans cette session pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _getConducteurTitle(String position, dynamic conducteurInfo) {
    if (!conducteurInfo.hasJoined) {
      return 'Conducteur $position (En attente)';
    }
    
    if (conducteurInfo.conducteurInfo != null) {
      final info = conducteurInfo.conducteurInfo;
      return 'Conducteur $position - ${info.prenom} ${info.nom}';
    }
    
    return 'Conducteur $position';
  }
}
