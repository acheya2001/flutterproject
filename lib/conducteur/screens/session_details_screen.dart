import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/collaborative_session_model.dart';
import '../../services/collaborative_session_service.dart';
import '../../services/collaborative_data_sync_service.dart';
import 'modern_single_accident_info_screen.dart';
import 'modern_collaborative_sketch_screen.dart';

/// 🎯 Écran "Détails de session" pour les sinistres collaboratifs
/// 
/// Cet écran regroupe toutes les informations d'un sinistre collaboratif :
/// - Informations générales (communes à tous)
/// - Liste des conducteurs participants avec statut
/// - Accès aux formulaires (édition perso / lecture autres)
/// - Croquis collaboratif (accord/désaccord)
/// - Indicateur global de progression
/// - Finalisation et génération PDF
class SessionDetailsScreen extends StatefulWidget {
  final CollaborativeSession session;
  final String currentUserId;

  const SessionDetailsScreen({
    Key? key,
    required this.session,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  CollaborativeSession? _sessionData;
  Map<String, dynamic>? _donneesCommunes;
  bool _isLoading = true;
  String? _errorMessage;

  // Services
  final CollaborativeSessionService _sessionService = CollaborativeSessionService();
  final CollaborativeDataSyncService _syncService = CollaborativeDataSyncService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _chargerDonneesSession();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 📊 Charger les données de la session
  Future<void> _chargerDonneesSession() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Charger les données de session
      final sessionDoc = await FirebaseFirestore.instance
          .collection('collaborative_sessions')
          .doc(widget.session.id)
          .get();

      if (sessionDoc.exists) {
        _sessionData = CollaborativeSession.fromMap(sessionDoc.data() as Map<String, dynamic>, sessionDoc.id);

        // Charger les données communes (pour l'instant, utilisons les données de base)
        _donneesCommunes = sessionDoc.data() as Map<String, dynamic>?;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }

  /// 🎨 AppBar avec design moderne
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.indigo[600],
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails de session',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Session ${widget.session.codeSession}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _chargerDonneesSession,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualiser',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(
            icon: Icon(Icons.info_outline, size: 20),
            text: 'Infos',
          ),
          Tab(
            icon: Icon(Icons.people_outline, size: 20),
            text: 'Participants',
          ),
          Tab(
            icon: Icon(Icons.description_outlined, size: 20),
            text: 'Formulaires',
          ),
          Tab(
            icon: Icon(Icons.draw_outlined, size: 20),
            text: 'Croquis',
          ),
        ],
      ),
    );
  }

  /// ❌ Widget d'erreur
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Une erreur inconnue s\'est produite',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _chargerDonneesSession,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 Contenu principal avec onglets
  Widget _buildContent() {
    if (_sessionData == null) {
      return const Center(
        child: Text('Aucune donnée de session disponible'),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildInfosGeneralesTab(),
        _buildParticipantsTab(),
        _buildFormulairesTab(),
        _buildCroquisTab(),
      ],
    );
  }

  /// 📊 Onglet Informations générales
  Widget _buildInfosGeneralesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressionGlobale(),
          const SizedBox(height: 24),
          _buildInfosSession(),
          const SizedBox(height: 24),
          _buildInfosAccident(),
        ],
      ),
    );
  }

  /// 👥 Onglet Participants
  Widget _buildParticipantsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatutParticipants(),
          const SizedBox(height: 16),
          ..._sessionData!.participants.map((participant) => 
            _buildParticipantCard(participant)
          ),
        ],
      ),
    );
  }

  /// 📝 Onglet Formulaires
  Widget _buildFormulairesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAccesFormulaires(),
        ],
      ),
    );
  }

  /// 🎨 Onglet Croquis
  Widget _buildCroquisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCroquisCollaboratif(),
        ],
      ),
    );
  }

  /// 📊 Progression globale
  Widget _buildProgressionGlobale() {
    final termines = _sessionData!.participants
        .where((p) => p.formulaireStatus == FormulaireStatus.termine)
        .length;
    final total = _sessionData!.participants.length;
    final pourcentage = total > 0 ? (termines / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[600]!, Colors.indigo[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Progression globale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$termines/$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: pourcentage,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Text(
            '${(pourcentage * 100).toInt()}% des formulaires terminés',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Informations de session
  Widget _buildInfosSession() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.indigo[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Informations de session',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Session ID', _sessionData!.codeSession, Icons.tag),
          _buildInfoRow('Créateur', _sessionData!.conducteurCreateur, Icons.person),
          _buildInfoRow('Type d\'accident', _sessionData!.typeAccident, Icons.car_crash),
          _buildInfoRow('Nombre de véhicules', '${_sessionData!.nombreVehicules}', Icons.directions_car),
          _buildInfoRow('Statut', _getStatutText(_sessionData!.statut), Icons.flag,
            color: _getStatutColor(_sessionData!.statut)),
          _buildInfoRow('Date de création',
            _formatDate(_sessionData!.dateCreation), Icons.calendar_today),
        ],
      ),
    );
  }

  /// 🚗 Informations de l'accident (données communes)
  Widget _buildInfosAccident() {
    if (_donneesCommunes == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Données communes non disponibles',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le créateur n\'a pas encore rempli les informations communes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.red[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Informations de l\'accident',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Verrouillé',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_donneesCommunes!['date'] != null)
            _buildInfoRow('Date', _donneesCommunes!['date'], Icons.calendar_today),
          if (_donneesCommunes!['heure'] != null)
            _buildInfoRow('Heure', _donneesCommunes!['heure'], Icons.access_time),
          if (_donneesCommunes!['lieu'] != null)
            _buildInfoRow('Lieu', _donneesCommunes!['lieu'], Icons.place),
          if (_donneesCommunes!['temoins'] != null && _donneesCommunes!['temoins'].isNotEmpty)
            _buildInfoRow('Témoins', '${_donneesCommunes!['temoins'].length} témoin(s)', Icons.people),
          if (_donneesCommunes!['blesses'] != null)
            _buildInfoRow('Blessés', _donneesCommunes!['blesses'] ? 'Oui' : 'Non', Icons.local_hospital,
              color: _donneesCommunes!['blesses'] ? Colors.red : Colors.green),
          if (_donneesCommunes!['degats_materiels'] != null)
            _buildInfoRow('Dégâts matériels', _donneesCommunes!['degats_materiels'] ? 'Oui' : 'Non', Icons.build,
              color: _donneesCommunes!['degats_materiels'] ? Colors.orange : Colors.green),
        ],
      ),
    );
  }

  /// 📊 Statut des participants
  Widget _buildStatutParticipants() {
    final enAttente = _sessionData!.participants
        .where((p) => p.formulaireStatus == FormulaireStatus.en_attente)
        .length;
    final enCours = _sessionData!.participants
        .where((p) => p.formulaireStatus == FormulaireStatus.en_cours)
        .length;
    final termines = _sessionData!.participants
        .where((p) => p.formulaireStatus == FormulaireStatus.termine)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatutItem(
              'En attente',
              enAttente,
              Colors.grey[400]!,
              Icons.hourglass_empty,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatutItem(
              'En cours',
              enCours,
              Colors.orange[400]!,
              Icons.edit,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatutItem(
              'Terminés',
              termines,
              Colors.green[400]!,
              Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Item de statut
  Widget _buildStatutItem(String label, int count, Color color, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 👤 Carte d'un participant
  Widget _buildParticipantCard(SessionParticipant participant) {
    final isCurrentUser = participant.userId == widget.currentUserId;
    final statusColor = _getFormulaireStatusColor(participant.formulaireStatus);
    final statusIcon = _getFormulaireStatusIcon(participant.formulaireStatus);
    final statusText = _getFormulaireStatusText(participant.formulaireStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: Colors.indigo[300]!, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: isCurrentUser ? Colors.indigo[100] : Colors.grey[200],
                child: Text(
                  participant.roleVehicule,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser ? Colors.indigo[700] : Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Nom et info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${participant.prenom} ${participant.nom}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.indigo[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Vous',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.indigo[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        if (participant.estCreateur) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Créateur',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.purple[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      participant.email,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Statut
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _ouvrirFormulaire(participant, isCurrentUser),
                  icon: Icon(
                    isCurrentUser ? Icons.edit : Icons.visibility,
                    size: 16,
                  ),
                  label: Text(
                    isCurrentUser ? 'Modifier mon formulaire' : 'Voir le formulaire',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isCurrentUser ? Colors.indigo[600] : Colors.grey[600],
                    side: BorderSide(
                      color: isCurrentUser ? Colors.indigo[300]! : Colors.grey[300]!,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📝 Accès aux formulaires
  Widget _buildAccesFormulaires() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vous pouvez modifier votre formulaire tant que la session n\'est pas clôturée. Les formulaires des autres participants sont en lecture seule.',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Liste des formulaires
        ...widget.session.participants.map((participant) {
          final isCurrentUser = participant.userId == widget.currentUserId;
          return _buildFormulaireCard(participant, isCurrentUser);
        }),
      ],
    );
  }

  /// 📝 Carte de formulaire
  Widget _buildFormulaireCard(SessionParticipant participant, bool isCurrentUser) {
    final statusColor = _getFormulaireStatusColor(participant.formulaireStatus);
    final statusIcon = _getFormulaireStatusIcon(participant.formulaireStatus);
    final statusText = _getFormulaireStatusText(participant.formulaireStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: Colors.indigo[300]!, width: 2)
            : Border.all(color: Colors.grey[200]!),
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
              CircleAvatar(
                radius: 16,
                backgroundColor: isCurrentUser ? Colors.indigo[100] : Colors.grey[200],
                child: Text(
                  participant.roleVehicule,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isCurrentUser ? Colors.indigo[700] : Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formulaire ${participant.roleVehicule}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${participant.prenom} ${participant.nom}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _ouvrirFormulaire(participant, isCurrentUser),
              icon: Icon(
                isCurrentUser ? Icons.edit : Icons.visibility,
                size: 16,
              ),
              label: Text(
                isCurrentUser ? 'Modifier mon formulaire' : 'Consulter en lecture seule',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentUser ? Colors.indigo[600] : Colors.grey[600],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Croquis collaboratif
  Widget _buildCroquisCollaboratif() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.draw,
                color: Colors.purple[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Le croquis est créé par le conducteur A. Les autres participants peuvent l\'approuver ou exprimer leur désaccord.',
                  style: TextStyle(
                    color: Colors.purple[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.draw_outlined,
                    color: Colors.purple[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Croquis de l\'accident',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Aperçu du croquis
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aperçu du croquis',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Actions pour le croquis
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _voirCroquisComplet,
                      icon: const Icon(Icons.fullscreen, size: 16),
                      label: const Text('Voir en grand'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _gererValidationCroquis,
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Valider/Refuser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Méthodes utilitaires
  Widget _buildInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: color ?? const Color(0xFF1E293B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatutText(SessionStatus statut) {
    switch (statut) {
      case SessionStatus.creation:
        return 'Création';
      case SessionStatus.attente_participants:
        return 'En attente';
      case SessionStatus.en_cours:
        return 'En cours';
      case SessionStatus.validation_croquis:
        return 'Validation croquis';
      case SessionStatus.pret_signature:
        return 'Prêt signature';
      case SessionStatus.signe:
        return 'Signé';
      case SessionStatus.finalise:
        return 'Finalisé';
      case SessionStatus.annule:
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }

  Color _getStatutColor(SessionStatus statut) {
    switch (statut) {
      case SessionStatus.creation:
        return Colors.orange;
      case SessionStatus.attente_participants:
        return Colors.amber;
      case SessionStatus.en_cours:
        return Colors.blue;
      case SessionStatus.validation_croquis:
        return Colors.purple;
      case SessionStatus.pret_signature:
        return Colors.indigo;
      case SessionStatus.signe:
        return Colors.green;
      case SessionStatus.finalise:
        return Colors.teal;
      case SessionStatus.annule:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getFormulaireStatusColor(FormulaireStatus status) {
    switch (status) {
      case FormulaireStatus.en_attente:
        return Colors.grey[400]!;
      case FormulaireStatus.en_cours:
        return Colors.orange[400]!;
      case FormulaireStatus.termine:
        return Colors.green[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  IconData _getFormulaireStatusIcon(FormulaireStatus status) {
    switch (status) {
      case FormulaireStatus.en_attente:
        return Icons.hourglass_empty;
      case FormulaireStatus.en_cours:
        return Icons.edit;
      case FormulaireStatus.termine:
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  String _getFormulaireStatusText(FormulaireStatus status) {
    switch (status) {
      case FormulaireStatus.en_attente:
        return 'En attente';
      case FormulaireStatus.en_cours:
        return 'En cours';
      case FormulaireStatus.termine:
        return 'Terminé';
      default:
        return 'Inconnu';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Actions
  void _ouvrirFormulaire(SessionParticipant participant, bool isCurrentUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernSingleAccidentInfoScreen(
          typeAccident: widget.session.typeAccident,
          session: widget.session,
          isCollaborative: true,
          isCreator: participant.estCreateur,
          isRegisteredUser: true,
          readOnly: !isCurrentUser, // 🔒 Mode lecture seule pour les autres participants
          participantId: participant.userId, // 👤 ID du participant à consulter
        ),
      ),
    );
  }

  void _voirCroquisComplet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernCollaborativeSketchScreen(
          session: widget.session,
        ),
      ),
    );
  }

  void _gererValidationCroquis() {
    // TODO: Implémenter la gestion de validation/refus du croquis
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validation du croquis'),
        content: const Text('Fonctionnalité de validation/refus du croquis à implémenter.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
