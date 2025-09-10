import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/collaborative_session_model.dart';
import '../../services/session_code_service.dart';
import '../../services/collaborative_session_service.dart';
import 'modern_single_accident_info_screen.dart';
import 'session_dashboard_screen.dart';


/// 📤 Écran d'invitation pour partager une session collaborative
class SessionInvitationScreen extends StatefulWidget {
  final CollaborativeSession session;

  const SessionInvitationScreen({
    super.key,
    required this.session,
  });

  @override
  State<SessionInvitationScreen> createState() => _SessionInvitationScreenState();
}

class _SessionInvitationScreenState extends State<SessionInvitationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              Colors.blue[600]!,
              Colors.blue[800]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildContenu(),
                  ),
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
          const Expanded(
            child: Text(
              'Inviter des conducteurs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
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
              '${widget.session.participants.length}/${widget.session.nombreVehicules}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Carte d'invitation principale
          _buildCarteInvitation(),
          
          const SizedBox(height: 24),
          
          // QR Code
          _buildSectionQRCode(),
          
          const SizedBox(height: 24),
          
          // Participants actuels
          _buildSectionParticipants(),
          
          const SizedBox(height: 24),
          
          // Instructions
          _buildSectionInstructions(),

          const SizedBox(height: 24),

          // Bouton pour continuer vers le formulaire
          _buildBoutonContinuer(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCarteInvitation() {
    return SessionCodeService.creerCarteInvitation(
      codeSession: widget.session.codeSession,
      typeAccident: widget.session.typeAccident,
      nombreVehicules: widget.session.nombreVehicules,
      onPartager: _partagerSession,
      onCopier: _copierCode,
    );
  }

  Widget _buildSectionQRCode() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.qr_code, color: Colors.blue[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'QR Code de session',
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
          SessionCodeService.genererQRCodeWidget(
            codeSession: widget.session.codeSession,
            typeAccident: widget.session.typeAccident,
            size: 180,
          ),
          const SizedBox(height: 12),
          Text(
            'Scannez ce QR code pour rejoindre rapidement',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionParticipants() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
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
                child: Icon(Icons.people, color: Colors.green[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Participants actuels',
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
          ...widget.session.participants.map((participant) => _buildParticipantCard(participant)),
          
          // Slots vides
          ...List.generate(
            widget.session.nombreVehicules - widget.session.participants.length,
            (index) => _buildSlotVide(index + widget.session.participants.length),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(SessionParticipant participant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green[600],
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
                Text(
                  participant.estCreateur ? 'Créateur de session' : 'Participant',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  'Rejoint',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontSize: 12,
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
                Icon(Icons.schedule, color: Colors.orange[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  'En attente',
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 12,
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

  Widget _buildSectionInstructions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
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
                child: Icon(Icons.info_outline, color: Colors.purple[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Comment inviter ?',
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
          _buildEtapeInstruction(
            numero: '1',
            titre: 'Partagez le code',
            description: 'Utilisez le bouton "Partager" ou copiez le code de session',
            icone: Icons.share,
          ),
          _buildEtapeInstruction(
            numero: '2',
            titre: 'Les autres téléchargent l\'app',
            description: 'Ils doivent installer "Constat Tunisie" s\'ils ne l\'ont pas',
            icone: Icons.download,
          ),
          _buildEtapeInstruction(
            numero: '3',
            titre: 'Ils rejoignent la session',
            description: 'En entrant le code ou en scannant le QR code',
            icone: Icons.qr_code_scanner,
          ),
          _buildEtapeInstruction(
            numero: '4',
            titre: 'Constat collaboratif',
            description: 'Chacun remplit sa partie du formulaire',
            icone: Icons.edit_document,
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeInstruction({
    required String numero,
    required String titre,
    required String description,
    required IconData icone,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.purple[600],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
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
          Icon(icone, color: Colors.purple[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _partagerSession() {
    SessionCodeService.partagerCodeSession(
      codeSession: widget.session.codeSession,
      typeAccident: widget.session.typeAccident,
      context: context,
    );
  }

  void _copierCode() {
    Clipboard.setData(ClipboardData(text: widget.session.codeSession));
    SessionCodeService.copierCode(
      codeSession: widget.session.codeSession,
      context: context,
    );
  }

  Widget _buildBoutonContinuer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _continuerVersFormulaire,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dashboard, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Accéder au dashboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Créateur',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continuerVersFormulaire() {
    // 🎯 Redirection vers le dashboard de session pour accéder aux boutons (formulaire, croquis, inviter)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SessionDashboardScreen(session: widget.session),
      ),
    );
  }
}
