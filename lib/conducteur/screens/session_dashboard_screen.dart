import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  final TextEditingController _commentaireController = TextEditingController();

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
    _commentaireController.dispose();
    super.dispose();
  }

  /// 🔄 Stream des données de session en temps réel
  Stream<Map<String, dynamic>?> _getSessionDataStream() {
    return FirebaseFirestore.instance
        .collection('sessions_collaboratives')
        .doc(widget.session.id)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        print('❌ Session non trouvée: ${widget.session.id}');
        return null;
      }

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
                  () {
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                    final estCreateur = sessionData.conducteurCreateur == currentUserId;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModernCollaborativeSketchScreen(
                          session: sessionData,
                          readOnly: !estCreateur, // 🔒 Seul le créateur peut modifier
                        ),
                      ),
                    );
                  },
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
      label: Flexible(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: couleur,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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

  /// 📊 Calculer les validations de croquis
  bool _calculerValidationsCroquis(Map<String, dynamic> sessionData) {
    try {
      final validationsCroquis = sessionData['validationsCroquis'] as Map<String, dynamic>? ?? {};
      final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);

      // Compter les validations acceptées
      final validationsAcceptees = validationsCroquis.values
          .where((validation) => validation['accepte'] == true)
          .length;

      return validationsAcceptees >= participants.length;
    } catch (e) {
      print('❌ Erreur calcul validations croquis: $e');
      return false;
    }
  }

  /// 📊 Calculer les signatures
  bool _calculerSignatures(Map<String, dynamic> sessionData) {
    try {
      final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);

      // Compter les participants qui ont signé
      int signaturesEffectuees = 0;
      for (final participant in participants) {
        final statut = participant['statut'] as String? ?? '';
        if (statut == 'signe') {
          signaturesEffectuees++;
        }
      }

      return signaturesEffectuees >= participants.length;
    } catch (e) {
      print('❌ Erreur calcul signatures: $e');
      return false;
    }
  }

  /// 🎨 Bouton de validation du croquis avec vérification
  Widget _buildBoutonValidationCroquis(Map<String, dynamic> sessionData) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(sessionData['id'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final validationsCroquis = data?['validationsCroquis'] as Map<String, dynamic>? ?? {};
        final aDejaValide = validationsCroquis.containsKey(currentUserId);

        if (aDejaValide) {
          final validation = validationsCroquis[currentUserId] as Map<String, dynamic>;
          final accepte = validation['accepte'] as bool;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accepte ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accepte ? Colors.green[300]! : Colors.orange[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  accepte ? Icons.check_circle : Icons.cancel,
                  color: accepte ? Colors.green[600] : Colors.orange[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    accepte ? 'Vous avez accepté ce croquis' : 'Vous avez refusé ce croquis',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accepte ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ElevatedButton.icon(
          onPressed: _validerCroquis,
          icon: const Icon(Icons.check_circle),
          label: const Text('Valider le croquis'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
        );
      },
    );
  }

  /// 🎯 Valider le croquis
  void _validerCroquis() {
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
            onPressed: () => _confirmerValidationCroquis(false, currentUserId),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Refuser'),
          ),
          ElevatedButton(
            onPressed: () => _confirmerValidationCroquis(true, currentUserId),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accepter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 🎯 Confirmer la validation du croquis
  Future<void> _confirmerValidationCroquis(bool accepte, String userId) async {
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
        SafeSnackBar.showSuccess(
          context,
          accepte ? 'Croquis accepté avec succès' : 'Croquis refusé'
        );

        // Les données se mettent à jour automatiquement via le StreamBuilder
      }
    } catch (e) {
      if (mounted) {
        SafeSnackBar.showError(context, 'Erreur: $e');
      }
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

          // Validations du croquis (pour le créateur)
          if (_estCreateur(sessionData)) ...[
            _buildSectionValidationsCroquis(sessionData),
            const SizedBox(height: 24),
          ],

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
    final formulairesTermines = participants.where((p) =>
      p['statut'] == 'formulaire_fini' ||
      p['statut'] == 'termine' ||
      p['formulaireComplete'] == true
    ).length;

    // Calculer les validations de croquis
    final validationsCroquis = sessionData['validationsCroquis'] as Map<String, dynamic>? ?? {};
    final croquisValides = validationsCroquis.values
        .where((validation) => validation['accepte'] == true)
        .length;

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

          // Validations du croquis
          _buildProgressionItem(
            'Validations du croquis',
            croquisValides,
            nombreVehicules,
            Colors.purple,
            Icons.check_circle,
          ),

          const SizedBox(height: 12),

          // Signatures effectuées (avec StreamBuilder pour compter en temps réel)
          _buildProgressionSignatures(sessionData['id'], nombreVehicules),

          const SizedBox(height: 12),

          // Progression globale
          _buildProgressionGlobaleComplete(sessionData),
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
              Row(
                children: [
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
                  if (kDebugMode) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _verifierStatuts(sessionData['id']),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Vérifier', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange[600],
                      ),
                    ),
                  ],
                ],
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

    // Debug: Afficher les données du participant
    if (kDebugMode) {
      print('🔍 [PARTICIPANT] ${participantData['userId']} - Nom: $nom $prenom - Statut: $statut - Données: $participantData');
    }

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
                    Expanded(
                      child: Text(
                        '$nom $prenom',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
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
          if (statut == 'formulaire_fini' || statut == 'termine')
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
      case 'formulaire_fini':
      case 'termine':
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
      case 'formulaire_fini':
      case 'termine':
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
            onPressed: () {
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
            },
            icon: const Icon(Icons.draw),
            label: const Text('Voir le croquis'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          const SizedBox(height: 12),

          // Bouton de validation du croquis (avec vérification)
          _buildBoutonValidationCroquis(sessionData),
        ],
      ),
    );
  }

  /// 📋 Étapes avec données directes
  Widget _buildSectionEtapesDirectes(Map<String, dynamic> sessionData) {
    final participants = sessionData['participants'] as List<dynamic>? ?? [];
    final nombreVehicules = sessionData['nombreVehicules'] ?? 2;
    final formulairesTermines = participants.where((p) =>
      p['statut'] == 'termine' ||
      p['formulaireStatus'] == 'termine' ||
      p['formulaireComplete'] == true
    ).length;

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
          _buildEtapeItem('3', 'Validation du croquis', _calculerValidationsCroquis(sessionData)),
          _buildEtapeSignatures(sessionData['id'], nombreVehicules),
          _buildEtapeItem('5', 'Finalisation du constat', sessionData['statut'] == 'finalise'),
        ],
      ),
    );
  }

  /// ✍️ Étape signatures avec comptage hybride
  Widget _buildEtapeSignatures(String sessionId, int nombreVehicules) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .snapshots(),
      builder: (context, sessionSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sessions_collaboratives')
              .doc(sessionId)
              .collection('signatures')
              .snapshots(),
          builder: (context, signaturesSnapshot) {
            int signaturesEffectuees = 0;

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

            // Utiliser le maximum des deux méthodes
            signaturesEffectuees = math.max(signaturesFromCollection, signaturesFromParticipants);
            final estComplete = signaturesEffectuees >= nombreVehicules;

            return _buildEtapeItem('4', 'Signatures électroniques', estComplete);
          },
        );
      },
    );
  }

  /// ✍️ Progression des signatures avec comptage hybride (sous-collection + participants)
  Widget _buildProgressionSignatures(String sessionId, int nombreVehicules) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .snapshots(),
      builder: (context, sessionSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sessions_collaboratives')
              .doc(sessionId)
              .collection('signatures')
              .snapshots(),
          builder: (context, signaturesSnapshot) {
            int signaturesEffectuees = 0;

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

            // Utiliser le maximum des deux méthodes
            signaturesEffectuees = math.max(signaturesFromCollection, signaturesFromParticipants);

            // 🐛 Debug: Afficher les détails des signatures
            if (kDebugMode) {
              print('🔍 [DEBUG] Signatures sous-collection: $signaturesFromCollection');
              print('🔍 [DEBUG] Signatures participants: $signaturesFromParticipants');
              print('🔍 [DEBUG] Signatures finales: $signaturesEffectuees');
            }

            return Column(
              children: [
                _buildProgressionItem(
                  'Signatures effectuées',
                  signaturesEffectuees,
                  nombreVehicules,
                  Colors.green,
                  Icons.edit,
                ),

              ],
            );
          },
        );
      },
    );
  }

  /// 📊 Progression globale complète
  Widget _buildProgressionGlobaleComplete(Map<String, dynamic> sessionData) {
    final participants = sessionData['participants'] as List<dynamic>? ?? [];
    final nombreVehicules = sessionData['nombreVehicules'] ?? 2;

    // Calculer les statistiques
    final participantsRejoints = participants.length;
    final formulairesTermines = participants.where((p) =>
      p['statut'] == 'formulaire_fini' ||
      p['statut'] == 'termine' ||
      p['formulaireComplete'] == true
    ).length;

    final validationsCroquis = sessionData['validationsCroquis'] as Map<String, dynamic>? ?? {};
    final croquisValides = validationsCroquis.values
        .where((validation) => validation['accepte'] == true)
        .length;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(sessionData['id'])
          .snapshots(),
      builder: (context, sessionSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sessions_collaboratives')
              .doc(sessionData['id'])
              .collection('signatures')
              .snapshots(),
          builder: (context, signaturesSnapshot) {
            // Comptage hybride des signatures
            int signaturesEffectuees = 0;
            final signaturesFromCollection = signaturesSnapshot.hasData ? signaturesSnapshot.data!.docs.length : 0;

            int signaturesFromParticipants = 0;
            if (sessionSnapshot.hasData && sessionSnapshot.data!.exists) {
              final currentSessionData = sessionSnapshot.data!.data() as Map<String, dynamic>;
              final currentParticipants = currentSessionData['participants'] as List<dynamic>? ?? [];

              signaturesFromParticipants = currentParticipants.where((p) =>
                p['statut'] == 'signe' || p['aSigne'] == true
              ).length;
            }

            signaturesEffectuees = math.max(signaturesFromCollection, signaturesFromParticipants);

        // Calculer la progression globale (chaque étape = 25%)
        int pourcentage = 0;
        if (participantsRejoints >= nombreVehicules) pourcentage += 25;
        if (formulairesTermines >= nombreVehicules) pourcentage += 25;
        if (croquisValides >= nombreVehicules) pourcentage += 25;
        if (signaturesEffectuees >= nombreVehicules) pourcentage += 25;

        Color couleurProgression;
        if (pourcentage >= 75) {
          couleurProgression = Colors.green;
        } else if (pourcentage >= 50) {
          couleurProgression = Colors.orange;
        } else if (pourcentage >= 25) {
          couleurProgression = Colors.blue;
        } else {
          couleurProgression = Colors.grey;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: couleurProgression.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: couleurProgression.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: couleurProgression, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Progression globale',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '$pourcentage%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: couleurProgression,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: pourcentage / 100,
                backgroundColor: couleurProgression.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(couleurProgression),
                minHeight: 8,
              ),

              // Bouton de finalisation quand progression = 100%
              if (pourcentage == 100) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _finaliserConstat(sessionData),
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text(
                      'Finaliser le constat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],

              // Bouton de debug pour les signatures (en mode développement)
              if (pourcentage < 100) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _debuggerSignatures(sessionData['id']),
                        icon: const Icon(Icons.bug_report, color: Colors.orange),
                        label: const Text(
                          'Debug',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _forcerMiseAJourSignatures(sessionData['id']),
                        icon: const Icon(Icons.refresh, color: Colors.purple),
                        label: const Text(
                          'Fix',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.purple,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.purple),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
          },
        );
      },
    );
  }

  /// 📊 Progression globale (ancienne méthode)
  Widget _buildProgressionGlobale(int termine, int total) {
    // Calculer la progression en tenant compte des étapes :
    // 1. Participants rejoints (25%)
    // 2. Formulaires terminés (50%)
    // 3. Croquis validé (75%)
    // 4. Signatures effectuées (100%)

    final pourcentageFormulaires = total > 0 ? (termine / total * 50).round() : 0;
    final pourcentage = pourcentageFormulaires; // Pour l'instant, on se base sur les formulaires

    Color couleurProgression;
    if (pourcentage >= 75) {
      couleurProgression = Colors.green;
    } else if (pourcentage >= 50) {
      couleurProgression = Colors.orange;
    } else if (pourcentage >= 25) {
      couleurProgression = Colors.blue;
    } else {
      couleurProgression = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleurProgression.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleurProgression.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: couleurProgression,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Progression globale',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: couleurProgression,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pourcentage%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: pourcentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(couleurProgression),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            '$termine/$total formulaires terminés',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 Vérifier si l'utilisateur actuel est le créateur
  bool _estCreateur(Map<String, dynamic> sessionData) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return sessionData['conducteurCreateur'] == currentUserId;
  }

  /// 🎨 Section validations du croquis (pour le créateur)
  Widget _buildSectionValidationsCroquis(Map<String, dynamic> sessionData) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: CollaborativeDataSyncService.ecouterValidationsCroquis(
        sessionId: sessionData['id'],
      ),
      builder: (context, snapshot) {
        final validations = snapshot.data ?? {};

        if (validations.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                    Icon(Icons.draw, color: Colors.purple[600]),
                    const SizedBox(width: 12),
                    const Text(
                      'Validations du croquis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'En attente des validations des autres participants...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                  Icon(Icons.draw, color: Colors.purple[600]),
                  const SizedBox(width: 12),
                  const Text(
                    'Validations du croquis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...validations.entries.map((entry) {
                final participantId = entry.key;
                final validation = entry.value as Map<String, dynamic>;
                final accepte = validation['accepte'] as bool;
                final raison = validation['raison'] as String? ?? '';

                return _buildValidationCard(participantId, accepte, raison);
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  /// 🎨 Carte de validation individuelle
  Widget _buildValidationCard(String participantId, bool accepte, String raison) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accepte ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accepte ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            accepte ? Icons.check_circle : Icons.cancel,
            color: accepte ? Colors.green[600] : Colors.red[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Participant ${participantId.substring(0, 8)}...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  accepte ? 'Croquis accepté' : 'Croquis refusé',
                  style: TextStyle(
                    color: accepte ? Colors.green[700] : Colors.red[700],
                    fontSize: 12,
                  ),
                ),
                if (!accepte && raison.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Raison: $raison',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🧪 Méthode de test pour ajouter une signature
  Future<void> _testSignature(String sessionId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ [TEST] Utilisateur non connecté');
        return;
      }

      print('🧪 [TEST] === DÉBUT TEST SIGNATURE ===');
      print('🧪 [TEST] Session ID: $sessionId');
      print('🧪 [TEST] User ID: ${currentUser.uid}');

      // Créer une signature de test (base64 d'un petit carré rouge)
      const testSignatureBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';

      await CollaborativeSessionService.ajouterSignature(
        sessionId: sessionId,
        userId: currentUser.uid,
        signatureBase64: testSignatureBase64,
        roleVehicule: 'conducteur_a',
      );

      print('✅ [TEST] Signature de test ajoutée');
      print('🧪 [TEST] === FIN TEST SIGNATURE ===');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signature de test ajoutée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ [TEST] Erreur test signature: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🏁 Finaliser le constat et générer le PDF
  Future<void> _finaliserConstat(Map<String, dynamic> sessionData) async {
    try {
      // Afficher un dialogue de confirmation
      final confirmation = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Finaliser le constat'),
            ],
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir finaliser ce constat ?\n\n'
            'Cette action va :\n'
            '• Générer un PDF du constat\n'
            '• L\'envoyer aux agents d\'assurance\n'
            '• Verrouiller définitivement la session\n\n'
            'Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
              ),
              child: const Text(
                'Finaliser',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirmation != true) return;

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Finalisation en cours...'),
            ],
          ),
        ),
      );

      // Finaliser la session
      await CollaborativeSessionService.finaliserSession(sessionData['id']);

      // Fermer le dialogue de chargement
      if (mounted) Navigator.of(context).pop();

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Constat finalisé avec succès !'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      // Fermer le dialogue de chargement si ouvert
      if (mounted) Navigator.of(context).pop();

      print('❌ Erreur finalisation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Erreur: $e',
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// 🐛 Déboguer les signatures
  Future<void> _debuggerSignatures(String sessionId) async {
    try {
      await CollaborativeSessionService.debuggerSignatures(sessionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Debug terminé - Vérifiez la console pour les détails',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Erreur debug: $e',
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🔍 Vérifier et corriger les statuts des participants
  Future<void> _verifierStatuts(String sessionId) async {
    try {
      await CollaborativeSessionService.verifierEtCorrigerStatuts(sessionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Vérification des statuts terminée'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur vérification statuts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Erreur: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🐛 Méthode de débogage pour vérifier les signatures
  Future<void> _debugSignatures(String sessionId) async {
    try {
      print('🔍 [DEBUG] === DÉBUT DEBUG SIGNATURES ===');

      // 1. Vérifier la sous-collection signatures
      final signaturesSnapshot = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('signatures')
          .get();

      print('🔍 [DEBUG] Signatures dans sous-collection: ${signaturesSnapshot.docs.length}');
      for (final doc in signaturesSnapshot.docs) {
        print('🔍 [DEBUG] - Signature ID: ${doc.id}');
        print('🔍 [DEBUG] - Data: ${doc.data()}');
      }

      // 2. Vérifier les participants dans le document principal
      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .get();

      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        final participants = sessionData['participants'] as List<dynamic>? ?? [];

        print('🔍 [DEBUG] Participants: ${participants.length}');
        for (final participant in participants) {
          print('🔍 [DEBUG] - Participant: ${participant['userId']} - Statut: ${participant['statut']}');
        }
      }

      print('🔍 [DEBUG] === FIN DEBUG SIGNATURES ===');

      // Afficher un snackbar avec les résultats
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug: ${signaturesSnapshot.docs.length} signatures trouvées'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ [DEBUG] Erreur debug: $e');
    }
  }

  /// 🔄 Forcer la mise à jour de la progression des signatures
  Future<void> _forcerMiseAJourSignatures(String sessionId) async {
    try {
      print('🔄 [FIX] Début correction progression signatures');

      // Afficher un indicateur de chargement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('🔄 Correction en cours...'),
              ],
            ),
            backgroundColor: Colors.purple,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Appeler la fonction de correction
      await CollaborativeSessionService.forcerMiseAJourProgressionSignatures(sessionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✅ Progression signatures corrigée !'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      print('✅ [FIX] Correction progression signatures terminée');

    } catch (e) {
      print('❌ [FIX] Erreur correction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('❌ Erreur correction: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
