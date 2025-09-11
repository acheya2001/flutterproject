import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/collaborative_session_model.dart';
import '../../services/collaborative_session_service.dart';
import '../../services/collaborative_data_sync_service.dart';
import '../../services/signature_otp_service.dart';
import '../../services/conducteur_data_service.dart';
import 'session_invitation_screen.dart';
import 'collaborative_form_screen.dart';
import 'consultation_mutuelle_screen.dart';
import 'collaborative_sketch_validation_screen.dart';
import 'modern_single_accident_info_screen.dart';
import 'modern_collaborative_sketch_screen.dart';

import 'participant_form_view_screen.dart';
import 'signature_otp_screen.dart';
import '../../utils/safe_snackbar.dart';
import 'modern_single_accident_info_screen_minimal.dart';
import '../../widgets/collaborative_participants_status_widget.dart';

/// 📊 Dashboard de gestion de session collaborative
class SessionDashboardScreen extends StatefulWidget {
  final CollaborativeSession session;

  const SessionDashboardScreen({
    super.key,
    required this.session,
  });

  @override
  State<SessionDashboardScreen> createState() => _SessionDashboardScreenState();
}

class _SessionDashboardScreenState extends State<SessionDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  CollaborativeSession? _sessionActuelle;

  @override
  void initState() {
    super.initState();
    _sessionActuelle = widget.session;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 🔄 Stream des données de session en temps réel
  Stream<Map<String, dynamic>?> _getSessionDataStream() {
    return FirebaseFirestore.instance
        .collection('collaborative_sessions')
        .doc(widget.session.id)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;

      print('📊 Données session reçues: ${data.keys}');
      print('👥 Participants: ${data['participants']?.length ?? 0}');
      print('📈 Progression: ${data['progression']}');

      return data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo[600]!,
              Colors.blue[700]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: StreamBuilder<Map<String, dynamic>?>(
                  stream: _getSessionDataStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erreur: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final sessionData = snapshot.data;
                    if (sessionData == null) {
                      return const Center(
                        child: Text(
                          'Session non trouvée',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildContenuAvecDonnees(sessionData),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Session Collaborative',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Code: ${widget.session.codeSession}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getCouleurStatut(widget.session.statut),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getLibelleStatut(widget.session.statut),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenu(CollaborativeSession? sessionData) {
    if (sessionData == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progression générale
          _buildSectionProgression(sessionData),

          const SizedBox(height: 24),

          // Participants
          _buildSectionParticipants(sessionData),

          const SizedBox(height: 24),

          // Actions rapides
          _buildSectionActions(sessionData),

          const SizedBox(height: 24),

          // Étapes du processus
          _buildSectionEtapes(sessionData),
        ],
      ),
    );
  }

  Widget _buildSectionProgression(CollaborativeSession sessionData) {
    final progression = sessionData.progression;
    final total = sessionData.nombreVehicules;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
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
                  color: Colors.indigo[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics, color: Colors.indigo[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Progression de la session',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Participants rejoints
          _buildProgressionItem(
            'Participants rejoints',
            progression.participantsRejoints,
            total,
            Colors.blue,
            Icons.people,
          ),
          
          const SizedBox(height: 12),
          
          // Formulaires terminés
          _buildProgressionItem(
            'Formulaires terminés',
            progression.formulairesTermines,
            total,
            Colors.green,
            Icons.assignment_turned_in,
          ),
          
          const SizedBox(height: 12),
          
          // Croquis validés
          _buildProgressionItem(
            'Croquis validés',
            progression.croquisValides,
            total,
            Colors.orange,
            Icons.draw,
          ),
          
          const SizedBox(height: 12),
          
          // Signatures effectuées
          _buildProgressionItem(
            'Signatures effectuées',
            progression.signaturesEffectuees,
            total,
            Colors.purple,
            Icons.edit,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionItem(String label, int actuel, int total, Color couleur, IconData icone) {
    final pourcentage = total > 0 ? (actuel / total) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, color: couleur, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$actuel/$total',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: couleur,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: pourcentage,
          backgroundColor: couleur.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(couleur),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildSectionParticipants(CollaborativeSession sessionData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
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
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.group, color: Colors.green[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Participants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (sessionData.participants.length < sessionData.nombreVehicules)
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SessionInvitationScreen(session: sessionData),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Inviter'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          ...(sessionData.participants.map((participant) => _buildParticipantCard(participant, sessionData))),
          
          // Slots vides
          ...List.generate(
            sessionData.nombreVehicules - sessionData.participants.length,
            (index) => _buildSlotVide(index + sessionData.participants.length),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(SessionParticipant participant, CollaborativeSession sessionData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCouleurStatutParticipant(participant.statut).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCouleurStatutParticipant(participant.statut).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getCouleurStatutParticipant(participant.statut),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                participant.roleVehicule,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${participant.prenom} ${participant.nom}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      participant.estCreateur ? Icons.star : Icons.person,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      participant.estCreateur ? 'Créateur' : _getLibelleTypeParticipant(participant.type),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCouleurStatutParticipant(participant.statut).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getLibelleStatutParticipant(participant.statut),
                  style: TextStyle(
                    color: _getCouleurStatutParticipant(participant.statut),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (participant.statut == ParticipantStatus.formulaire_fini ||
                  participant.statut == ParticipantStatus.croquis_valide ||
                  participant.statut == ParticipantStatus.signe)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParticipantFormViewScreen(
                        session: sessionData,
                        participant: participant,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility, size: 12, color: Colors.blue[700]),
                        const SizedBox(width: 2),
                        Text(
                          'Voir',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlotVide(int index) {
    final roles = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
    final role = index < roles.length ? roles[index] : 'X';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                role,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'En attente d\'un conducteur...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Véhicule $role',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
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
                Icon(Icons.schedule, color: Colors.orange[600], size: 14),
                const SizedBox(width: 4),
                Text(
                  'Libre',
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionActions(CollaborativeSession sessionData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
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
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.flash_on, color: Colors.purple[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Actions rapides',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildBoutonAction(
                  'Mon formulaire',
                  Icons.edit_document,
                  Colors.blue,
                  () => _ouvrirFormulaireAccident(sessionData),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBoutonAction(
                  'Croquis',
                  Icons.draw,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ModernCollaborativeSketchScreen(
                        session: sessionData,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildBoutonAction(
                  'Inviter',
                  Icons.share,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SessionInvitationScreen(session: sessionData),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBoutonAction(
                  sessionData.statut == SessionStatus.pret_signature ? 'Signer' : 'Finaliser',
                  sessionData.statut == SessionStatus.pret_signature ? Icons.edit : Icons.check_circle,
                  Colors.purple,
                  sessionData.statut == SessionStatus.pret_signature ? _signerConstat :
                  (sessionData.progression.peutFinaliser ? _finaliserSession : null),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoutonAction(String label, IconData icone, Color couleur, VoidCallback? onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icone, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: couleur,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildSectionEtapes(CollaborativeSession sessionData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
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
                  color: Colors.teal[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.timeline, color: Colors.teal[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Étapes du processus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildEtapeItem('1', 'Invitation des participants', sessionData.progression.participantsRejoints == sessionData.nombreVehicules),
          _buildEtapeItem('2', 'Remplissage des formulaires', sessionData.progression.formulairesTermines == sessionData.nombreVehicules),
          _buildEtapeItem('3', 'Validation du croquis', sessionData.progression.croquisValides == sessionData.nombreVehicules),
          _buildEtapeItem('4', 'Signatures électroniques', sessionData.progression.signaturesEffectuees == sessionData.nombreVehicules),
          _buildEtapeItem('5', 'Finalisation du constat', sessionData.statut == SessionStatus.finalise),
        ],
      ),
    );
  }

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
          if (complete)
            Icon(Icons.check_circle, color: Colors.green[600], size: 20),
        ],
      ),
    );
  }

  bool _estCreateur() {
    // TODO: Vérifier si l'utilisateur actuel est le créateur
    return true; // Placeholder
  }

  Future<void> _signerConstat() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Vérifier si l'utilisateur a déjà signé
      final dejaSigneUtilisateur = await SignatureOTPService.aDejaSigneUtilisateur(widget.session.id, user.uid);

      if (dejaSigneUtilisateur) {
        SafeSnackBar.showWarning(context, 'Vous avez déjà signé ce constat');
        return;
      }

      // Obtenir le numéro de téléphone
      final donneesUtilisateur = await ConducteurDataService.recupererDonneesConducteur();
      final telephone = donneesUtilisateur?['conducteur']?['telephone'] ?? '';

      if (telephone.isEmpty) {
        SafeSnackBar.showError(context, 'Numéro de téléphone requis pour la signature');
        return;
      }

      // Naviguer vers l'écran de signature
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignatureOTPScreen(
            session: widget.session,
            telephone: telephone,
          ),
        ),
      );
    } catch (e) {
      SafeSnackBar.showError(context, 'Erreur: $e');
    }
  }

  void _ouvrirFormulaireAccident(CollaborativeSession sessionData) {
    print('🔥 DÉBUT _ouvrirFormulaireAccident - Navigation vers ModernSingleAccidentInfoScreen');

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            print('🔥 Construction de ModernSingleAccidentInfoScreen...');
            return ModernSingleAccidentInfoScreen(
              typeAccident: sessionData.typeAccident,
              session: sessionData,
              isCollaborative: true,
              isCreator: true,
              isRegisteredUser: true,
            );
          },
        ),
      );
      print('🔥 Navigation vers ModernSingleAccidentInfoScreen RÉUSSIE');
    } catch (e) {
      print('🔥 ERREUR navigation vers ModernSingleAccidentInfoScreen: $e');
      print('🔥 Stack trace: ${StackTrace.current}');

      // En cas d'erreur, afficher un message à l'utilisateur
      SafeSnackBar.showError(context, 'Erreur lors de l\'ouverture du formulaire: $e');
    }
  }

  void _finaliserSession() {
    // TODO: Implémenter la finalisation de session
    SafeSnackBar.showWarning(context, 'Finalisation de session - À implémenter');
  }

  Color _getCouleurStatut(SessionStatus statut) {
    switch (statut) {
      case SessionStatus.creation:
        return Colors.blue[600]!;
      case SessionStatus.attente_participants:
        return Colors.orange[600]!;
      case SessionStatus.en_cours:
        return Colors.purple[600]!;
      case SessionStatus.validation_croquis:
        return Colors.indigo[600]!;
      case SessionStatus.pret_signature:
        return Colors.teal[600]!;
      case SessionStatus.signe:
        return Colors.green[600]!;
      case SessionStatus.finalise:
        return Colors.green[800]!;
      case SessionStatus.annule:
        return Colors.red[600]!;
    }
  }

  String _getLibelleStatut(SessionStatus statut) {
    switch (statut) {
      case SessionStatus.creation:
        return 'Création';
      case SessionStatus.attente_participants:
        return 'En attente';
      case SessionStatus.en_cours:
        return 'En cours';
      case SessionStatus.validation_croquis:
        return 'Validation';
      case SessionStatus.pret_signature:
        return 'Signature';
      case SessionStatus.signe:
        return 'Signé';
      case SessionStatus.finalise:
        return 'Finalisé';
      case SessionStatus.annule:
        return 'Annulé';
    }
  }

  Color _getCouleurStatutParticipant(ParticipantStatus statut) {
    switch (statut) {
      case ParticipantStatus.en_attente:
        return Colors.orange[600]!;
      case ParticipantStatus.rejoint:
        return Colors.blue[600]!;
      case ParticipantStatus.formulaire_fini:
        return Colors.green[600]!;
      case ParticipantStatus.croquis_valide:
        return Colors.purple[600]!;
      case ParticipantStatus.signe:
        return Colors.green[800]!;
    }
  }

  String _getLibelleStatutParticipant(ParticipantStatus statut) {
    switch (statut) {
      case ParticipantStatus.en_attente:
        return 'En attente';
      case ParticipantStatus.rejoint:
        return 'Rejoint';
      case ParticipantStatus.formulaire_fini:
        return 'Formulaire OK';
      case ParticipantStatus.croquis_valide:
        return 'Croquis OK';
      case ParticipantStatus.signe:
        return 'Signé';
    }
  }

  String _getLibelleTypeParticipant(ParticipantType type) {
    switch (type) {
      case ParticipantType.inscrit:
        return 'Inscrit';
      case ParticipantType.invite_guest:
        return 'Invité';
    }
  }

  /// 🎨 Construire le contenu avec les données Firestore directes
  Widget _buildContenuAvecDonnees(Map<String, dynamic> sessionData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progression générale
          _buildSectionProgressionDirecte(sessionData),

          const SizedBox(height: 24),

          // Participants
          _buildSectionParticipantsDirects(sessionData),

          const SizedBox(height: 24),

          // Actions rapides
          _buildSectionActionsDirectes(sessionData),

          const SizedBox(height: 24),

          // Étapes du processus
          _buildSectionEtapesDirectes(sessionData),
        ],
      ),
    );
  }

  /// 📊 Section progression avec données directes
  Widget _buildSectionProgressionDirecte(Map<String, dynamic> sessionData) {
    final progression = sessionData['progression'] as Map<String, dynamic>? ?? {};
    final participants = sessionData['participants'] as List<dynamic>? ?? [];
    final nombreVehicules = sessionData['nombreVehicules'] ?? 2;

    // Calculer les vraies statistiques
    final participantsRejoints = participants.length;
    final formulairesTermines = participants.where((p) => p['statut'] == 'termine' || p['formulaireComplete'] == true).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Progression de la session',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Participants rejoints
          _buildProgressionItem(
            'Participants rejoints',
            participantsRejoints,
            nombreVehicules,
            Colors.blue,
            Icons.people,
          ),

          const SizedBox(height: 12),

          // Formulaires terminés
          _buildProgressionItem(
            'Formulaires terminés',
            formulairesTermines,
            nombreVehicules,
            Colors.green,
            Icons.assignment_turned_in,
          ),

          const SizedBox(height: 12),

          // Progression globale
          _buildProgressionGlobale(formulairesTermines, nombreVehicules),
        ],
      ),
    );
  }

  /// 👥 Section participants avec données directes
  Widget _buildSectionParticipantsDirects(Map<String, dynamic> sessionData) {
    final participants = sessionData['participants'] as List<dynamic>? ?? [];
    final nombreVehicules = sessionData['nombreVehicules'] ?? 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.indigo[600], size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Participants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (participants.length < nombreVehicules)
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SessionInvitationScreen(session: widget.session),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Inviter'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Liste des participants
          ...participants.map((participantData) => _buildParticipantCardDirect(participantData)),

          // Slots vides
          ...List.generate(
            nombreVehicules - participants.length,
            (index) => _buildSlotVide(index + participants.length),
          ),
        ],
      ),
    );
  }

  /// 👤 Carte participant avec données directes
  Widget _buildParticipantCardDirect(Map<String, dynamic> participantData) {
    final nom = participantData['nom'] ?? 'Conducteur';
    final prenom = participantData['prenom'] ?? '';
    final statut = participantData['statut'] ?? 'en_attente';
    final roleVehicule = participantData['roleVehicule'] ?? 'A';
    final estCreateur = participantData['estCreateur'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: _getCouleurStatutParticipantDirect(statut),
            child: Text(
              roleVehicule,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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
                      '$nom $prenom',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (estCreateur) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'CRÉATEUR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getLibelleStatutParticipantDirect(statut),
                  style: TextStyle(
                    color: _getCouleurStatutParticipantDirect(statut),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (statut == 'termine')
            IconButton(
              onPressed: () {
                // TODO: Voir le formulaire du participant
              },
              icon: Icon(Icons.visibility, color: Colors.blue[600]),
              tooltip: 'Voir le formulaire',
            ),
        ],
      ),
    );
  }

  /// 🎨 Couleur du statut participant (données directes)
  Color _getCouleurStatutParticipantDirect(String statut) {
    switch (statut) {
      case 'en_attente':
        return Colors.orange[600]!;
      case 'rejoint':
        return Colors.blue[600]!;
      case 'termine':
      case 'formulaire_fini':
        return Colors.green[600]!;
      case 'croquis_valide':
        return Colors.purple[600]!;
      case 'signe':
        return Colors.green[800]!;
      default:
        return Colors.grey[600]!;
    }
  }

  /// 📝 Libellé du statut participant (données directes)
  String _getLibelleStatutParticipantDirect(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'rejoint':
        return 'Rejoint';
      case 'termine':
      case 'formulaire_fini':
        return 'Formulaire terminé';
      case 'croquis_valide':
        return 'Croquis validé';
      case 'signe':
        return 'Signé';
      default:
        return 'Statut inconnu';
    }
  }

  /// 🎯 Actions avec données directes
  Widget _buildSectionActionsDirectes(Map<String, dynamic> sessionData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: Colors.orange[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Actions rapides',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Actions disponibles
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModernSingleAccidentInfoScreen(
                  typeAccident: widget.session.typeAccident,
                  session: widget.session,
                  isCollaborative: true,
                  isCreator: true,
                  isRegisteredUser: true,
                ),
              ),
            ),
            icon: const Icon(Icons.edit),
            label: const Text('Continuer mon formulaire'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModernCollaborativeSketchScreen(
                  session: widget.session,
                ),
              ),
            ),
            icon: const Icon(Icons.draw),
            label: const Text('Voir le croquis'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Étapes avec données directes
  Widget _buildSectionEtapesDirectes(Map<String, dynamic> sessionData) {
    final participants = sessionData['participants'] as List<dynamic>? ?? [];
    final nombreVehicules = sessionData['nombreVehicules'] ?? 2;
    final formulairesTermines = participants.where((p) => p['statut'] == 'termine').length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
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

          _buildEtapeItem('1', 'Invitation des participants', participants.length == nombreVehicules),
          _buildEtapeItem('2', 'Remplissage des formulaires', formulairesTermines == nombreVehicules),
          _buildEtapeItem('3', 'Validation du croquis', false), // TODO: calculer
          _buildEtapeItem('4', 'Signatures électroniques', false), // TODO: calculer
          _buildEtapeItem('5', 'Finalisation du constat', sessionData['statut'] == 'finalise'),
        ],
      ),
    );
  }

  /// 📊 Progression globale
  Widget _buildProgressionGlobale(int termine, int total) {
    final pourcentage = total > 0 ? (termine / total * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progression globale',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              '$pourcentage%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: pourcentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[600]!),
        ),
      ],
    );
  }
}
