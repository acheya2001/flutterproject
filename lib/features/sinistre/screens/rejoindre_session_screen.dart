import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../common/widgets/custom_app_bar.dart';
import '../../../common/widgets/gradient_background.dart';
import '../../../models/accident_session.dart';
import '../../../models/constat.dart';
import '../services/accident_session_service.dart';
import 'participant_form_screen.dart';

/// Écran pour rejoindre une session via code ou lien
class RejoindreSessionScreen extends StatefulWidget {
  final String? invitationCode;

  const RejoindreSessionScreen({
    Key? key,
    this.invitationCode,
  }) : super(key: key);

  @override
  State<RejoindreSessionScreen> createState() => _RejoindreSessionScreenState();
}

class _RejoindreSessionScreenState extends State<RejoindreSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  
  final AccidentSessionService _sessionService = AccidentSessionService();

  @override
  void initState() {
    super.initState();
    if (widget.invitationCode != null) {
      _codeController.text = widget.invitationCode!;
      _joinSession();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Rejoindre une Session',
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildCodeInput(),
            const SizedBox(height: 24),
            _buildJoinButton(),
            const SizedBox(height: 32),
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.group_add,
            size: 48,
            color: Colors.green[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Rejoindre un Constat',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saisissez le code d\'invitation reçu pour participer à la déclaration de sinistre',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Code d\'invitation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _codeController,
            decoration: InputDecoration(
              hintText: 'Ex: ACC-2024-12345 ou INV-...',
              prefixIcon: const Icon(Icons.confirmation_number),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez saisir un code d\'invitation';
              }
              if (!value.trim().startsWith('ACC-') && !value.trim().startsWith('INV-')) {
                return 'Format de code invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Le code commence par ACC- (session) ou INV- (invitation)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _joinSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login),
                  const SizedBox(width: 8),
                  Text(
                    'Rejoindre',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Comment ça marche ?',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoStep('1', 'Le créateur de la session vous envoie un code'),
          _buildInfoStep('2', 'Vous saisissez ce code pour rejoindre'),
          _buildInfoStep('3', 'Vous remplissez votre partie du constat'),
          _buildInfoStep('4', 'Vous signez électroniquement votre déclaration'),
        ],
      ),
    );
  }

  Widget _buildInfoStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinSession() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final code = _codeController.text.trim().toUpperCase();
      
      AccidentSession? session;
      Invitation? invitation;
      String? roleAssigne;

      if (code.startsWith('ACC-')) {
        // Code de session directe
        session = await _sessionService.getSessionByCode(code);
        if (session == null) {
          throw Exception('Session non trouvée avec ce code');
        }
        
        // Assigner automatiquement le prochain rôle disponible
        final participants = await _sessionService.getSessionParticipants(session.id);
        final rolesUtilises = participants.map((p) => p.role).toSet();
        
        for (final role in ['A', 'B', 'C', 'D']) {
          if (!rolesUtilises.contains(role)) {
            roleAssigne = role;
            break;
          }
        }
        
        if (roleAssigne == null) {
          throw Exception('Cette session est complète (maximum 4 véhicules)');
        }
        
      } else if (code.startsWith('INV-')) {
        // Code d'invitation spécifique
        invitation = await _sessionService.getInvitationByToken(code);
        if (invitation == null) {
          throw Exception('Invitation non trouvée avec ce code');
        }
        
        if (!invitation.isValid) {
          throw Exception('Cette invitation a expiré ou a déjà été utilisée');
        }
        
        session = await _sessionService.getSession(invitation.sessionId);
        if (session == null) {
          throw Exception('Session associée non trouvée');
        }
        
        roleAssigne = invitation.rolePropose;
        
        // Marquer l'invitation comme utilisée
        final user = FirebaseAuth.instance.currentUser;
        await _sessionService.useInvitation(invitation.id, user?.uid);
      }

      if (session == null || roleAssigne == null) {
        throw Exception('Erreur lors de la récupération de la session');
      }

      // Vérifier que la session est encore modifiable
      if (!session.canBeModified) {
        throw Exception('Cette session ne peut plus être modifiée');
      }

      // Vérifier les délais légaux
      if (!session.isInLegalDeadline) {
        _showDeadlineWarning(session, roleAssigne);
        return;
      }

      // Naviguer vers le formulaire de participant
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ParticipantFormScreen(
            session: session!,
            roleAssigne: roleAssigne!,
            isFromInvitation: invitation != null,
          ),
        ),
      );

    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.toString());
    }
  }

  void _showDeadlineWarning(AccidentSession session, String role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('Délai dépassé'),
          ],
        ),
        content: Text(
          'Le délai légal de déclaration (5 jours ouvrés) est dépassé pour cette session. '
          'Vous pouvez toujours participer, mais la déclaration sera marquée comme tardive.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isLoading = false);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ParticipantFormScreen(
                    session: session,
                    roleAssigne: role,
                    isFromInvitation: true,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Continuer quand même'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message.replaceFirst('Exception: ', '')),
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
