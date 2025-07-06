import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../constat/models/session_constat_model.dart'; // Importer le modèle
import '../../constat/providers/session_provider.dart';
import 'conducteur_declaration_screen.dart';

class SessionJoinScreen extends StatefulWidget {
  final String? sessionCode;

  const SessionJoinScreen({Key? key, this.sessionCode}) : super(key: key);

  @override
  State<SessionJoinScreen> createState() => _SessionJoinScreenState();
}

class _SessionJoinScreenState extends State<SessionJoinScreen> {
  final _sessionCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.sessionCode != null) {
      _sessionCodeController.text = widget.sessionCode!;
    }
  }

  @override
  void dispose() {
    _sessionCodeController.dispose();
    super.dispose();
  }

  Future<void> _rejoindreSession(BuildContext context) async {
    final sessionCode = _sessionCodeController.text.trim().toUpperCase();

    if (sessionCode.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un code de session'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProviderState = Provider.of<AuthProvider>(context, listen: false);
      final sessionProviderState = Provider.of<SessionProvider>(context, listen: false);

      if (authProviderState.currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      debugPrint('[SessionJoin] === TENTATIVE DE REJOINDRE SESSION ===');
      debugPrint('[SessionJoin] Code: $sessionCode');
      debugPrint('[SessionJoin] User: ${authProviderState.currentUser!.id}');

      // Afficher un dialogue de progression
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Connexion à la session $sessionCode...'),
              ],
            ),
          ),
        );
      }

      final SessionConstatModel? session = await sessionProviderState.rejoindreSession(
        sessionCode,
        authProviderState.currentUser!.id,
      );

      // Fermer le dialogue de progression
      if (mounted) Navigator.pop(context);

      if (session == null) {
        throw Exception('Session non trouvée ou impossible de rejoindre.');
      }

      debugPrint('[SessionJoin] ✅ Session rejointe avec succès');

      // Trouver la position du conducteur
      String? positionConducteur;
      for (final entry in session.conducteursInfo.entries) {
        if (entry.value.userId == authProviderState.currentUser!.id) {
          positionConducteur = entry.key;
          break;
        }
      }

      if (positionConducteur == null) {
        throw Exception('Position non trouvée dans la session');
      }

      String? position;
      // Null check for session before accessing conducteursInfo
      if (session.conducteursInfo.isNotEmpty) {
          for (var entry in session.conducteursInfo.entries) {
            // Check both userId and email for matching
            if (entry.value.userId == authProviderState.currentUser!.id ||
                (entry.value.email != null && entry.value.email == authProviderState.currentUser!.email)) {
              position = entry.key;
              break;
            }
          }
      }

      if (position == null) {
        throw Exception('Vous n\'êtes pas invité à cette session ou votre email/ID ne correspond pas.');
      }

      if (!mounted) return;

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Connecté à la session en tant que conducteur $position'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );

      // Naviguer vers l'écran de déclaration collaborative
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConducteurDeclarationScreen(
            sessionId: session.id,
            conducteurPosition: position!,
            isCollaborative: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Rejoindre un Constat',
        backgroundColor: Color(0xFF6366F1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildSessionCodeInput(),
            const SizedBox(height: 32),
            _buildJoinButton(() => _rejoindreSession(context)),
            const Spacer(),
            _buildHelpSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).round()), // Corrected
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.login, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rejoindre un Constat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 4),
                Text('Saisissez le code de session pour participer au constat collaboratif', style: TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCodeInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [ BoxShadow(color: Colors.black.withAlpha((0.05 * 255).round()), blurRadius: 10, offset: const Offset(0, 2)) ], // Corrected
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Code de Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
          const SizedBox(height: 16),
          CustomTextField(controller: _sessionCodeController, label: 'Code de session', hintText: 'SESS_12345', prefixIcon: Icons.qr_code, textCapitalization: TextCapitalization.characters),
        ],
      ),
    );
  }

  Widget _buildJoinButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: _isLoading ? 'Connexion...' : 'Rejoindre la Session',
        onPressed: _isLoading ? null : onPressed,
        color: const Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [ const Icon(Icons.help_outline, color: Color(0xFF6366F1), size: 20), const SizedBox(width: 8), Text('Besoin d\'aide ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800))]),
          const SizedBox(height: 8),
          Text('• Le code de session vous a été envoyé par email\n• Il commence généralement par "SESS_"\n• Vérifiez vos spams si vous ne trouvez pas l\'email\n• Contactez l\'autre conducteur si nécessaire', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}