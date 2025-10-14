import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/collaborative_session_model.dart';
import '../../services/collaborative_session_service.dart';
import '../../services/collaborative_data_sync_service.dart';
import '../../services/constat_pdf_service.dart';
import '../../services/constat_agent_notification_service.dart';
import '../../services/complete_elegant_pdf_service.dart';
import '../../verification_agent_screen.dart';
import '../../test_notifications_simple.dart';
import '../../debug_agent_notifications.dart';
import '../../test_notification_simple.dart';
import '../../test_agent_notifications_dashboard.dart';
import '../../services/modern_tunisian_pdf_service.dart';
import '../../services/complete_elegant_pdf_service.dart';
import '../../services/complete_pdf_test_service.dart';
import '../../widgets/modern_pdf_generator_widget.dart';
import '../../services/constat_status_test_service.dart';
import 'modern_single_accident_info_screen.dart';
import 'modern_collaborative_sketch_screen.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

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

  // Controllers
  final TextEditingController _commentaireController = TextEditingController();

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
    _commentaireController.dispose();
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
      print('🔍 Chargement session: ${widget.session.id}');
      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(widget.session.id)
          .get();

      if (sessionDoc.exists) {
        print('✅ Session trouvée dans Firestore');
        _sessionData = CollaborativeSession.fromMap(sessionDoc.data() as Map<String, dynamic>, sessionDoc.id);

        // Charger les données communes (pour l'instant, utilisons les données de base)
        _donneesCommunes = sessionDoc.data() as Map<String, dynamic>?;
        print('✅ Données session chargées: ${_sessionData?.codeSession}');
      } else {
        print('❌ Session non trouvée dans Firestore: ${widget.session.id}');
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
        // Bouton d'actualisation
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
          const SizedBox(height: 16),
          _buildProgressionSignatures(),
          const SizedBox(height: 24),
          _buildEtapesProcessus(),
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(widget.session.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessionData = snapshot.data!.data() as Map<String, dynamic>;
        final participants = sessionData['participants'] as List? ?? [];
        final nombreVehicules = sessionData['nombreVehicules'] ?? 2;

        print('🔍 [PARTICIPANTS-TAB] ===== ANALYSE PARTICIPANTS =====');
        print('🔍 [PARTICIPANTS-TAB] Nombre de véhicules attendus: $nombreVehicules');
        print('🔍 [PARTICIPANTS-TAB] Participants trouvés: ${participants.length}');

        for (int i = 0; i < participants.length; i++) {
          final participant = participants[i];
          print('   - Participant $i: ${participant['nom']} ${participant['prenom']} (${participant['userId']})');
          print('     Statut: ${participant['statut']}, Role: ${participant['roleVehicule']}');
        }

        if (participants.length < nombreVehicules) {
          print('⚠️ [PARTICIPANTS-TAB] MANQUE ${nombreVehicules - participants.length} participant(s)!');
          print('⚠️ [PARTICIPANTS-TAB] Vérifiez si le 3ème conducteur a rejoint la session');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatutParticipants(),
              const SizedBox(height: 16),

              // Afficher un avertissement si des participants manquent
              if (participants.length < nombreVehicules)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Participants manquants',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                            Text(
                              '${nombreVehicules - participants.length} conducteur(s) n\'ont pas encore rejoint la session',
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              ...participants.map((participantData) {
                final participant = SessionParticipant.fromMap(participantData as Map<String, dynamic>);
                return _buildParticipantCard(participant);
              }),
            ],
          ),
        );
      },
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

  /// 📄 Onglet PDF Agent
  Widget _buildPDFAgentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description de la fonctionnalité
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notification des Agents d\'Assurance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Cette fonctionnalité permet de notifier automatiquement les agents d\'assurance responsables des véhicules impliqués dans l\'accident.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Statut de la session
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _sessionData?.statut.name == 'finalise'
                  ? Colors.green[50]
                  : Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _sessionData?.statut.name == 'finalise'
                    ? Colors.green[200]!
                    : Colors.orange[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _sessionData?.statut.name == 'finalise'
                      ? Icons.check_circle_outline
                      : Icons.warning_outlined,
                  color: _sessionData?.statut.name == 'finalise'
                      ? Colors.green[700]
                      : Colors.orange[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sessionData?.statut.name == 'finalise'
                            ? 'Session finalisée'
                            : 'Session non finalisée',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _sessionData?.statut.name == 'finalise'
                              ? Colors.green[800]
                              : Colors.orange[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _sessionData?.statut.name == 'finalise'
                            ? 'Vous pouvez maintenant utiliser les fonctionnalités PDF'
                            : 'Finalisez d\'abord la session pour pouvoir utiliser les fonctionnalités PDF',
                        style: TextStyle(
                          fontSize: 14,
                          color: _sessionData?.statut.name == 'finalise'
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Bouton Notifier les Agents
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sessionData?.statut.name == 'finalise'
                  ? _notifierAgents
                  : null,
              icon: const Icon(Icons.email, color: Colors.white),
              label: const Text(
                'Notifier les Agents',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _sessionData?.statut.name == 'finalise'
                    ? Colors.green[600]
                    : Colors.grey[400],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bouton Générer PDF Complet et Élégant
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sessionData?.statut.name == 'finalise'
                  ? () => _genererPDFCompletElegant()
                  : null,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text(
                'Générer PDF Complet et Élégant',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _sessionData?.statut.name == 'finalise'
                    ? Colors.purple[600]
                    : Colors.grey[400],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          if (_sessionData?.statut.name != 'finalise') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Le constat doit être finalisé avant d\'utiliser ces fonctionnalités',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Bouton test dashboard agent (temporaire)
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _ouvrirTestDashboardAgent,
              icon: const Icon(Icons.dashboard, color: Colors.white),
              label: const Text(
                '🧪 Test Dashboard Agent',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  /// 📧 Section Envoi aux Agents
  Widget _buildEnvoiAgentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.send,
                color: Colors.green[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Envoyer aux Agents d\'Assurance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Envoyez automatiquement le PDF du constat aux agents d\'assurance responsables de chaque conducteur.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Bouton d'envoi
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sessionData?.statut.name == 'finalise'
                  ? _notifierAgents
                  : null,
              icon: const Icon(Icons.email, color: Colors.white),
              label: const Text(
                'Notifier les Agents',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _sessionData?.statut.name == 'finalise'
                    ? Colors.green[600]
                    : Colors.grey[400],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          if (_sessionData?.statut.name != 'finalise') ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ Le constat doit être finalisé avant l\'envoi aux agents',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],


        ],
      ),
    );
  }

  /// 🇹🇳 Section PDF Tunisien
  Widget _buildPDFTunisienSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.picture_as_pdf,
                color: Colors.red[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'PDF Format Tunisien Officiel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Génère un PDF au format officiel tunisien conforme aux standards '
            'de l\'assurance automobile en Tunisie. Ce document peut être utilisé '
            'pour les démarches administratives officielles.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Contenu du PDF tunisien :',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          const SizedBox(height: 4),
          ...const [
            '• En-tête République Tunisienne',
            '• Cases 1-5 : Informations générales',
            '• Cases 6-14 : Détails par véhicule',
            '• Case 15 : Croquis et signatures',
            '• Format conforme aux assurances tunisiennes',
          ].map((item) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 2),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[700],
              ),
            ),
          )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sessionData != null ? _genererPDFTunisien : null,
              icon: const Icon(Icons.download),
              label: const Text('Générer PDF Tunisien'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Progression globale
  Widget _buildProgressionGlobale() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(widget.session.id)
          .snapshots(),
      builder: (context, snapshot) {
        int termines = 0;
        int signes = 0;
        int total = 0;
        double pourcentage = 0.0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final sessionData = snapshot.data!.data() as Map<String, dynamic>;
          final progression = sessionData['progression'] as Map<String, dynamic>? ?? {};
          final participants = sessionData['participants'] as List? ?? [];

          total = participants.length;
          termines = progression['formulairesTermines'] ?? 0;
          signes = progression['signaturesEffectuees'] ?? 0;

          print('🔍 [PROGRESSION-UI] ===== CALCUL PROGRESSION =====');
          print('🔍 [PROGRESSION-UI] Total participants: $total');
          print('🔍 [PROGRESSION-UI] Formulaires terminés: $termines');
          print('🔍 [PROGRESSION-UI] Signatures effectuées: $signes');
          print('🔍 [PROGRESSION-UI] Progression brute: $progression');

          // 🔥 CORRECTION: Logique simplifiée
          if (total > 0) {
            // Si tous les formulaires sont terminés ET toutes les signatures effectuées, alors 100%
            if (termines >= total && signes >= total) {
              pourcentage = 1.0;
              print('🔍 [PROGRESSION-UI] ✅ Tout terminé -> 100%');
            } else {
              // Sinon, calculer basé sur la moyenne des étapes complétées
              final progressionFormulaires = termines / total;
              final progressionSignatures = signes / total;
              pourcentage = (progressionFormulaires + progressionSignatures) / 2;
              print('🔍 [PROGRESSION-UI] 📊 Progression formulaires: ${(progressionFormulaires * 100).toInt()}%');
              print('🔍 [PROGRESSION-UI] 📊 Progression signatures: ${(progressionSignatures * 100).toInt()}%');
              print('🔍 [PROGRESSION-UI] 📊 Moyenne: ${(pourcentage * 100).toInt()}%');
            }
          }

          print('🔍 [PROGRESSION-UI] 🎯 RÉSULTAT FINAL: ${(pourcentage * 100).toInt()}%');
        }

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
            '${(pourcentage * 100).toInt()}% du processus terminé',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Formulaires: $termines/$total • Signatures: $signes/$total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  /// 📋 Étapes du processus avec coches vertes en temps réel
  Widget _buildEtapesProcessus() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(widget.session.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final sessionData = snapshot.data!.data() as Map<String, dynamic>;
        final progression = sessionData['progression'] as Map<String, dynamic>? ?? {};
        final participants = sessionData['participants'] as List? ?? [];
        final nombreVehicules = sessionData['nombreVehicules'] ?? 2;

        final participantsRejoints = progression['participantsRejoints'] ?? 0;
        final formulairesTermines = progression['formulairesTermines'] ?? 0;
        final croquisValides = progression['croquisValides'] ?? 0;
        final signaturesEffectuees = progression['signaturesEffectuees'] ?? 0;
        final statut = sessionData['statut'] ?? '';

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
                  Icon(Icons.list_alt, color: Colors.green[600], size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Étapes du processus',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildEtapeItem('1', 'Invitation des participants', participantsRejoints >= nombreVehicules),
              _buildEtapeItem('2', 'Remplissage des formulaires', formulairesTermines >= nombreVehicules),
              _buildEtapeItem('3', 'Validation du croquis', croquisValides >= nombreVehicules),
              _buildEtapeItem('4', 'Signatures électroniques', signaturesEffectuees >= nombreVehicules),
              _buildEtapeItem('5', 'Finalisation du constat', statut == 'finalise'),
            ],
          ),
        );
      },
    );
  }

  /// 📋 Item d'étape avec coche verte
  Widget _buildEtapeItem(String numero, String titre, bool complete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: complete ? Colors.green[600] : Colors.grey[400],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: complete
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      numero,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titre,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: complete ? Colors.green[800] : Colors.grey[700],
              ),
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
              const Expanded(
                child: Text(
                  'Informations de l\'accident',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(widget.session.id)
          .collection('participants_data')
          .snapshots(),
      builder: (context, snapshot) {
        int enAttente = 0;
        int enCours = 0;
        int termines = 0;

        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final statut = data['statut'] as String? ?? 'en_attente';

            switch (statut) {
              case 'en_attente':
                enAttente++;
                break;
              case 'en_cours':
                enCours++;
                break;
              case 'termine':
                termines++;
                break;
            }
          }
        }

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
      },
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

  /// ✍️ Progression des signatures avec comptage hybride
  Widget _buildProgressionSignatures() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(widget.session.id)
          .snapshots(),
      builder: (context, sessionSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sessions_collaboratives')
              .doc(widget.session.id)
              .collection('signatures')
              .snapshots(),
          builder: (context, signaturesSnapshot) {
            int signaturesEffectuees = 0;
            final total = _sessionData?.participants.length ?? 0;

            // Méthode 1: Compter depuis la sous-collection signatures
            final signaturesFromCollection = signaturesSnapshot.hasData ? signaturesSnapshot.data!.docs.length : 0;

            // Méthode 2: Compter depuis les statuts des participants
            int signaturesFromParticipants = 0;
            if (sessionSnapshot.hasData && sessionSnapshot.data!.exists) {
              final sessionData = sessionSnapshot.data!.data() as Map<String, dynamic>;
              final participants = sessionData['participants'] as List<dynamic>? ?? [];

              signaturesFromParticipants = participants.where((p) =>
                p['statut'] == 'signe' || p['aSigne'] == true
              ).length;
            }

            // Utiliser le maximum des deux méthodes disponibles
            signaturesEffectuees = signaturesFromCollection > signaturesFromParticipants
                ? signaturesFromCollection
                : signaturesFromParticipants;

            // Debug: Afficher les détails des signatures
            if (kDebugMode) {
              print('🔍 [DEBUG SIGNATURES] Session: ${widget.session.id}');
              print('🔍 [DEBUG SIGNATURES] Sous-collection: $signaturesFromCollection');
              print('🔍 [DEBUG SIGNATURES] Participants: $signaturesFromParticipants');
              print('🔍 [DEBUG SIGNATURES] Final: $signaturesEffectuees/$total');
            }

            final pourcentageSignatures = total > 0 ? (signaturesEffectuees / total) : 0.0;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Signatures électroniques',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$signaturesEffectuees/$total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: pourcentageSignatures,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(pourcentageSignatures * 100).toInt()}% des participants ont signé',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final estCreateur = widget.session.conducteurCreateur == currentUserId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernCollaborativeSketchScreen(
          session: widget.session,
          readOnly: !estCreateur, // 🔒 Seul le créateur peut modifier
        ),
      ),
    );
  }

  /// 🎯 Section PDF Complet et Élégant (NOUVEAU)
  Widget _buildPDFCompletElegantSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[50]!, Colors.blue[50]!],
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
                  gradient: LinearGradient(
                    colors: [Colors.purple[600]!, Colors.blue[600]!],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PDF COMPLET ET ÉLÉGANT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                    Text(
                      'NOUVEAU - Toutes les données de tous les participants',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ce générateur PDF révolutionnaire récupère TOUTES les données des formulaires '
            'de TOUS les participants (2, 3, 4+ conducteurs) et génère un rapport '
            'totalement complet, élégant et professionnel. Parfait pour l\'envoi aux agents d\'assurance.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.purple[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✨ CONTENU DU PDF COMPLET :',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
                const SizedBox(height: 8),
                ...const [
                  '🎨 Page de couverture élégante avec République Tunisienne',
                  '📋 Informations générales complètes et résumé',
                  '👤 Page détaillée pour CHAQUE participant avec TOUTES ses données',
                  '🚨 Circonstances, dégâts et témoins de chaque participant',
                  '📊 Tableau récapitulatif de tous les participants',
                  '🎨 Croquis et signatures avec détails techniques',
                  '💡 Page finale avec recommandations et contacts utiles',
                ].map((item) => Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple[700],
                    ),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sessionData != null ? _genererPDFCompletElegant : null,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Générer PDF Complet et Élégant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
            ),
          ),

          // Bouton de test (uniquement en mode debug)
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.science, color: Colors.amber[700], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'MODE TEST - Développement uniquement',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _testerPDFAvecDonneesCompletes,
                          icon: const Icon(Icons.bug_report, size: 16),
                          label: const Text('Test PDF Complet', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _nettoyerDonneesTest,
                          icon: const Icon(Icons.cleaning_services, size: 16),
                          label: const Text('Nettoyer', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amber[700],
                            side: BorderSide(color: Colors.amber[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🎯 Générer le PDF complet et élégant (NOUVEAU)
  Future<void> _genererPDFCompletElegant() async {
    if (_sessionData == null) return;

    try {
      // Afficher un indicateur de chargement élégant
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[600]!, Colors.blue[600]!],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Génération du PDF complet...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Récupération de toutes les données des participants',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Générer le PDF complet
      final pdfUrl = await CompleteElegantPdfService.genererConstatCompletElegant(
        sessionId: _sessionData!.id,
      );

      // Fermer le dialog de chargement
      if (mounted) Navigator.of(context).pop();

      // Afficher le succès avec design élégant
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[600]!, Colors.blue[600]!],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'PDF Complet Généré !',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre rapport complet et élégant a été généré avec succès.\n'
                  'Il contient toutes les données de tous les participants.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          try {
                            // Vérifier si c'est une URL ou un fichier local
                            if (pdfUrl.startsWith('http://') || pdfUrl.startsWith('https://')) {
                              // C'est une URL en ligne (Cloudinary)
                              final uri = Uri.parse(pdfUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🌐 PDF ouvert dans le navigateur'),
                                    duration: const Duration(seconds: 3),
                                    backgroundColor: Colors.green[600],
                                  ),
                                );
                              } else {
                                throw Exception('Impossible d\'ouvrir l\'URL');
                              }
                            } else {
                              // C'est un fichier local
                              final file = File(pdfUrl);
                              if (await file.exists()) {
                                final result = await OpenFile.open(pdfUrl);
                                if (result.type != ResultType.done) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('PDF sauvegardé dans: $pdfUrl'),
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Fichier PDF non trouvé: $pdfUrl'),
                                    duration: const Duration(seconds: 3),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur ouverture PDF: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Ouvrir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Fermer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      if (kDebugMode) {
        print('✅ [SESSION_DETAILS] PDF complet élégant généré: $pdfUrl');
      }

    } catch (e) {
      // Fermer le dialog de chargement si ouvert
      if (mounted) Navigator.of(context).pop();

      // Afficher l'erreur avec design élégant
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de Génération',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Une erreur s\'est produite lors de la génération du PDF complet:\n$e',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ),
        );
      }

      if (kDebugMode) {
        print('❌ [SESSION_DETAILS] Erreur génération PDF complet: $e');
      }
    }
  }

  /// 🇹🇳 Générer le PDF au format tunisien
  Future<void> _genererPDFTunisien() async {
    if (_sessionData == null) return;

    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Génération du PDF tunisien...'),
            ],
          ),
        ),
      );

      // Générer le PDF
      final pdfUrl = await ModernTunisianPdfService.genererConstatModerne(
        sessionId: _sessionData!.id,
      );

      // Fermer le dialog de chargement
      if (mounted) Navigator.of(context).pop();

      // Afficher le succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('PDF tunisien généré avec succès !'),
                    Text(
                      'Sauvegardé dans Téléchargements',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    // Vérifier si le fichier existe
                    final file = File(pdfUrl);
                    if (await file.exists()) {
                      // Ouvrir le PDF avec l'application par défaut
                      final result = await OpenFile.open(pdfUrl);
                      if (result.type != ResultType.done) {
                        // Si l'ouverture échoue, afficher le chemin
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('PDF sauvegardé dans: $pdfUrl'),
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Fichier non trouvé: $pdfUrl'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur ouverture PDF: $e'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Ouvrir',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
        );
      }

      if (kDebugMode) {
        print('✅ [SESSION_DETAILS] PDF tunisien généré: $pdfUrl');
      }

    } catch (e) {
      // Fermer le dialog de chargement si ouvert
      if (mounted) Navigator.of(context).pop();

      // Afficher l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Erreur génération PDF: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
        );
      }

      if (kDebugMode) {
        print('❌ [SESSION_DETAILS] Erreur génération PDF tunisien: $e');
      }
    }
  }

  void _gererValidationCroquis() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validation du croquis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Que pensez-vous du croquis proposé ?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Commentaire (optionnel)',
                border: OutlineInputBorder(),
                hintText: 'Ajoutez un commentaire...',
              ),
              maxLines: 3,
              controller: _commentaireController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => _validerCroquis(false, currentUserId),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Refuser'),
          ),
          ElevatedButton(
            onPressed: () => _validerCroquis(true, currentUserId),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accepter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 🎯 Valider ou refuser le croquis
  Future<void> _validerCroquis(bool accepte, String userId) async {
    Navigator.pop(context); // Fermer le dialog

    try {
      await CollaborativeDataSyncService.validerCroquis(
        sessionId: widget.session.id,
        participantId: userId,
        accepte: accepte,
        commentaire: _commentaireController.text.trim().isEmpty
            ? null
            : _commentaireController.text.trim(),
      );

      // Nettoyer le commentaire
      _commentaireController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accepte ? 'Croquis accepté avec succès' : 'Croquis refusé',
            ),
            backgroundColor: accepte ? Colors.green : Colors.orange,
          ),
        );

        // Recharger les données de la session
        _chargerDonneesSession();
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

  /// 📄 Générer le PDF du constat complet
  Future<void> _genererPdf() async {
    if (_sessionData == null) return;

    try {
      // Afficher le loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Génération du PDF...'),
            ],
          ),
        ),
      );

      // Récupérer toutes les données de la session
      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(_sessionData!.id)
          .get();

      if (!sessionDoc.exists) {
        throw Exception('Session non trouvée');
      }

      final sessionData = sessionDoc.data()!;

      // Générer le PDF
      final pdfFile = await ConstatPdfService.genererPdfConstat(
        sessionId: _sessionData!.id,
        sessionData: sessionData,
      );

      // Fermer le loading
      Navigator.pop(context);

      // Afficher les options
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF généré avec succès'),
          content: const Text('Que souhaitez-vous faire avec le PDF ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ConstatPdfService.partagerPdf(pdfFile);
              },
              child: const Text('Partager'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ConstatPdfService.imprimerPdf(pdfFile);
              },
              child: const Text('Imprimer'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );

    } catch (e) {
      // Fermer le loading si ouvert
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Afficher l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur génération PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🧪 Tester le PDF avec des données complètes (mode debug uniquement)
  Future<void> _testerPDFAvecDonneesCompletes() async {
    if (!kDebugMode) return;

    try {
      // Afficher un indicateur de chargement pour le test
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber[600]!, Colors.orange[600]!],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Test en cours...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Création de données de test complètes\net génération du PDF',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Créer une session de test et générer le PDF
      final pdfPath = await CompletePdfTestService.creerSessionTestEtGenererPDF();

      // Fermer le dialog de chargement
      if (mounted) Navigator.of(context).pop();

      // Afficher le succès
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[600]!, Colors.teal[600]!],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Test Réussi !',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Session de test créée avec 3 participants\n'
                  'et PDF complet généré avec succès !',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          try {
                            // Vérifier si c'est une URL ou un fichier local
                            if (pdfPath.startsWith('http://') || pdfPath.startsWith('https://')) {
                              // C'est une URL en ligne (Cloudinary)
                              final uri = Uri.parse(pdfPath);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🌐 PDF ouvert dans le navigateur'),
                                    duration: const Duration(seconds: 3),
                                    backgroundColor: Colors.green[600],
                                  ),
                                );
                              } else {
                                throw Exception('Impossible d\'ouvrir l\'URL');
                              }
                            } else {
                              // C'est un fichier local
                              final file = File(pdfPath);
                              if (await file.exists()) {
                                final result = await OpenFile.open(pdfPath);
                                if (result.type != ResultType.done) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('PDF sauvegardé dans: $pdfPath'),
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Fichier PDF non trouvé: $pdfPath'),
                                    duration: const Duration(seconds: 3),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur ouverture PDF: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Ouvrir PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                        child: const Text('Fermer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      print('✅ [TEST] PDF de test généré: $pdfPath');

    } catch (e) {
      // Fermer le dialog de chargement si ouvert
      if (mounted) Navigator.of(context).pop();

      // Afficher l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur test PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      print('❌ [TEST] Erreur test PDF: $e');
    }
  }

  /// 🧹 Nettoyer les données de test (mode debug uniquement)
  Future<void> _nettoyerDonneesTest() async {
    if (!kDebugMode) return;

    try {
      await CompletePdfTestService.nettoyerDonneesTest();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Données de test nettoyées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur nettoyage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🔧 Recalculer le statut de session avec la nouvelle logique
  Future<void> _recalculerStatutSession() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔧 Recalcul du statut en cours...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Appeler la nouvelle méthode de recalcul
      await CollaborativeSessionService.forcerRecalculStatutSession(widget.session.id);

      // Recharger les données pour voir les changements
      await _chargerDonneesSession();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Statut de session recalculé avec succès!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur recalcul statut: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur recalcul statut: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// 🚨 Correction directe pour résoudre les problèmes de statut persistants
  Future<void> _correctionDirecte() async {
    try {
      // Demander confirmation à l'utilisateur
      final confirmation = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🚨 Correction Directe'),
          content: const Text(
            'Cette action va analyser et corriger toutes les sessions avec des statuts incorrects.\n\n'
            'Voulez-vous continuer ?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Corriger'),
            ),
          ],
        ),
      );

      if (confirmation != true) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 Correction directe en cours...'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Appeler la méthode de correction directe
      await CollaborativeSessionService.corrigerStatutSessionProblematique();

      // Recharger les données pour voir les changements
      await _chargerDonneesSession();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Correction directe terminée avec succès!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur correction directe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur correction directe: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// 🔧 Forcer le recalcul de la progression (débogage)
  Future<void> _forcerRecalculProgression() async {
    try {
      print('🔧 [DEBUG] Forçage du recalcul de progression...');

      // Appeler la méthode de recalcul du service
      await CollaborativeSessionService.forcerRecalculStatutSession(widget.session.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔧 Progression recalculée'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ [DEBUG] Erreur recalcul progression: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🔍 Diagnostiquer la session (débogage)
  Future<void> _diagnostiquerSession() async {
    try {
      print('🔍 [DIAGNOSTIC] ===== DIAGNOSTIC SESSION =====');

      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(widget.session.id)
          .get();

      if (!sessionDoc.exists) {
        print('❌ [DIAGNOSTIC] Session non trouvée !');
        return;
      }

      final sessionData = sessionDoc.data()!;
      final nombreVehicules = sessionData['nombreVehicules'] ?? 0;
      final participants = sessionData['participants'] as List? ?? [];
      final statut = sessionData['statut'] ?? '';

      print('🔍 [DIAGNOSTIC] Configuration session :');
      print('   - ID: ${widget.session.id}');
      print('   - Code: ${sessionData['codeSession']}');
      print('   - Nombre véhicules configuré: $nombreVehicules');
      print('   - Participants actuels: ${participants.length}');
      print('   - Statut: $statut');
      print('   - Créateur: ${sessionData['conducteurCreateur']}');

      print('🔍 [DIAGNOSTIC] Détail participants :');
      for (int i = 0; i < participants.length; i++) {
        final participant = participants[i];
        print('   $i. ${participant['nom']} ${participant['prenom']} (${participant['roleVehicule']})');
        print('      UserID: ${participant['userId']}');
        print('      Statut: ${participant['statut']}');
        print('      A signé: ${participant['aSigne']}');
      }

      if (participants.length < nombreVehicules) {
        print('⚠️ [DIAGNOSTIC] PROBLÈME DÉTECTÉ :');
        print('   - Manque ${nombreVehicules - participants.length} participant(s)');
        print('   - Vérifiez si tous les conducteurs ont rejoint la session');
        print('   - Code de session à partager: ${sessionData['codeSession']}');
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🔍 Diagnostic Session'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Véhicules configurés: $nombreVehicules'),
                  Text('Participants présents: ${participants.length}'),
                  Text('Statut: $statut'),
                  const SizedBox(height: 16),
                  if (participants.length < nombreVehicules) ...[
                    const Text(
                      '⚠️ Participants manquants',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Manque: ${nombreVehicules - participants.length} conducteur(s)'),
                    const SizedBox(height: 8),
                    Text('Code à partager: ${sessionData['codeSession']}'),
                  ] else ...[
                    const Text(
                      '✅ Tous les participants présents',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      print('❌ [DIAGNOSTIC] Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur diagnostic: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ⚙️ Corriger la configuration de la session (débogage)
  Future<void> _corrigerConfigurationSession() async {
    try {
      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(widget.session.id)
          .get();

      if (!sessionDoc.exists) {
        print('❌ Session non trouvée !');
        return;
      }

      final sessionData = sessionDoc.data()!;
      final nombreVehicules = sessionData['nombreVehicules'] ?? 0;
      final participants = sessionData['participants'] as List? ?? [];

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚙️ Corriger Configuration'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Configuration actuelle: $nombreVehicules véhicules'),
                Text('Participants présents: ${participants.length}'),
                const SizedBox(height: 16),
                const Text('Que voulez-vous faire ?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              if (participants.length < nombreVehicules)
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _ajusterNombreVehicules(participants.length);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: Text('Ajuster à ${participants.length} véhicules'),
                ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _afficherCodeSession();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Partager code session'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur correction: $e');
    }
  }

  /// 🔧 Ajuster le nombre de véhicules dans la session
  Future<void> _ajusterNombreVehicules(int nouveauNombre) async {
    try {
      print('🔧 Ajustement nombre véhicules: $nouveauNombre');

      await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(widget.session.id)
          .update({
        'nombreVehicules': nouveauNombre,
      });

      // Forcer le recalcul de la progression
      await CollaborativeSessionService.forcerRecalculStatutSession(widget.session.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Configuration ajustée à $nouveauNombre véhicules'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Recharger les données
      await _chargerDonneesSession();

    } catch (e) {
      print('❌ Erreur ajustement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 📱 Afficher le code de session pour partage
  void _afficherCodeSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📱 Code de Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'Code à partager:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.session.codeSession,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Le 3ème conducteur doit:\n'
              '1. Ouvrir l\'app Constat Tunisie\n'
              '2. Choisir "Rejoindre une session"\n'
              '3. Saisir ce code',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// 🧪 Tester les statuts des constats (debug)
  Future<void> _testerStatuts() async {
    try {
      print('🧪 [TEST] Début test statuts pour session: ${widget.session.id}');

      // Afficher un dialog de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('🧪 Test des statuts en cours...'),
              SizedBox(height: 8),
              Text(
                'Vérification et simulation du flux complet',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Lancer le test complet
      await ConstatStatusTestService.testerFluxComplet(widget.session.id!);

      // Fermer le dialog de chargement
      if (mounted) Navigator.of(context).pop();

      // Afficher le résultat
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🧪 Test Terminé'),
            content: const Text(
              'Le test du flux de statuts a été exécuté.\n\n'
              'Consultez les logs de debug pour voir les détails.\n\n'
              'Les statuts ont été mis à jour dans la base de données.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _chargerDonneesSession(); // Recharger pour voir les changements
                },
                child: const Text('Actualiser'),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      // Fermer le dialog de chargement si ouvert
      if (mounted) Navigator.of(context).pop();

      print('❌ [TEST] Erreur test statuts: $e');

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('❌ Erreur'),
            content: Text('Erreur lors du test: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  /// 🧪 Tester la notification des agents (debug)
  Future<void> _testerNotificationAgents() async {
    try {
      print('🧪 [DEBUG] Début test notification agents');

      // Afficher un dialog de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('🧪 Test en cours...'),
              SizedBox(height: 8),
              Text(
                'Vérification des contrats et agents',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Tester avec la session actuelle
      final resultat = await ConstatAgentNotificationService.envoyerConstatAuxAgents(
        sessionId: widget.session.id,
      );

      // Fermer le dialog de chargement
      if (mounted) Navigator.of(context).pop();

      // Afficher le résultat détaillé
      _afficherResultatTest(resultat);
    } catch (e) {
      print('❌ [DEBUG] Erreur test: $e');
      if (mounted) Navigator.of(context).pop();
      _afficherErreurEnvoi(e.toString());
    }
  }

  /// 🧪 Afficher le résultat du test
  void _afficherResultatTest(Map<String, dynamic> resultat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: Colors.purple),
            SizedBox(width: 8),
            Text('🧪 Résultat du test'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📊 Résumé:'),
              const SizedBox(height: 8),
              Text('• Succès: ${resultat['success']}'),
              Text('• Total agents: ${resultat['totalAgents'] ?? 0}'),
              Text('• Notifications réussies: ${resultat['notificationsReussies'] ?? 0}'),
              Text('• Notifications échouées: ${resultat['notificationsEchouees'] ?? 0}'),

              if (resultat['error'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    '❌ Erreur: ${resultat['error']}',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Text(
                '💡 Vérifiez les logs dans la console pour plus de détails',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
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

  /// 🔍 Ouvrir l'écran de vérification des agents
  void _ouvrirVerificationAgent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VerificationAgentScreen(),
      ),
    );
  }

  /// 📋 Ouvrir le test simple des notifications
  void _ouvrirTestSimple() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TestNotificationsSimple(),
      ),
    );
  }

  /// 🔍 Ouvrir le debug des notifications agent
  void _ouvrirDebugNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DebugAgentNotifications(),
      ),
    );
  }

  /// 🧪 Ouvrir le test simple de notification
  void _ouvrirTestSimpleNotification() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TestNotificationSimple(),
      ),
    );
  }

  /// 🧪 Ouvrir le test du dashboard agent
  void _ouvrirTestDashboardAgent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TestAgentNotificationsDashboard(),
      ),
    );
  }



  /// 📱 Notifier les agents d'assurance
  Future<void> _notifierAgents() async {
    try {
      // Afficher un dialog de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Notification des agents...'),
              SizedBox(height: 8),
              Text(
                'Identification des agents et création des notifications',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Envoyer le PDF aux agents
      final resultat = await ConstatAgentNotificationService.envoyerConstatAuxAgents(
        sessionId: widget.session.id,
      );

      // Fermer le dialog de chargement
      if (mounted) Navigator.of(context).pop();

      // Afficher le résultat
      if (resultat['success']) {
        _afficherResultatEnvoi(resultat);
      } else {
        _afficherErreurEnvoi(resultat['error']);
      }

    } catch (e) {
      // Fermer le dialog de chargement
      if (mounted) Navigator.of(context).pop();

      print('❌ Erreur envoi PDF agents: $e');
      _afficherErreurEnvoi(e.toString());
    }
  }

  /// ✅ Afficher le résultat des notifications
  void _afficherResultatEnvoi(Map<String, dynamic> resultat) {
    final notificationsReussies = resultat['notificationsReussies'] ?? 0;
    final notificationsEchouees = resultat['notificationsEchouees'] ?? 0;
    final totalAgents = resultat['totalAgents'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              notificationsEchouees == 0 ? Icons.check_circle : Icons.warning,
              color: notificationsEchouees == 0 ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Résultat des notifications'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 Résumé:'),
            const SizedBox(height: 8),
            Text('• Total agents: $totalAgents'),
            Text('• Notifications réussies: $notificationsReussies'),
            if (notificationsEchouees > 0) Text('• Notifications échouées: $notificationsEchouees'),

            if (notificationsReussies > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ PDF envoyé avec succès',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Les agents d\'assurance ont été notifiés et peuvent consulter le constat dans leur dashboard.',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// ❌ Afficher une erreur d'envoi
  void _afficherErreurEnvoi(String erreur) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Erreur d\'envoi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Une erreur s\'est produite lors de la notification des agents:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                erreur,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Veuillez réessayer plus tard ou contacter le support technique.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
