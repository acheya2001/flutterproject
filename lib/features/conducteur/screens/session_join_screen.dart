import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/providers/auth_provider.dart';
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

  Future<void> _rejoindreSession() async {
    if (_sessionCodeController.text.trim().isEmpty) {
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final sessionCode = _sessionCodeController.text.trim();
      final session = await sessionProvider.rejoindreSession(
        sessionCode,
        authProvider.currentUser!.id,
      );

      // Trouver la position du conducteur
      String? position;
      for (var entry in session.conducteursInfo.entries) {
        if (entry.value.email == authProvider.currentUser!.email) {
          position = entry.key;
          break;
        }
      }

      if (position == null) {
        throw Exception('Vous n\'êtes pas invité à cette session');
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConducteurDeclarationScreen(
              sessionId: session.id,
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
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
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
            _buildJoinButton(),
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.login,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rejoindre un Constat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Saisissez le code de session pour participer au constat collaboratif',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Code de Session',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _sessionCodeController,
            label: 'Code de session',
            hintText: 'SESS_12345',
            prefixIcon: Icons.qr_code,
            textCapitalization: TextCapitalization.characters,
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: _isLoading ? 'Connexion...' : 'Rejoindre la Session',
        onPressed: _isLoading ? null : _rejoindreSession,
        color: const Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.help_outline,
                color: Color(0xFF6366F1),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Besoin d\'aide ?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Le code de session vous a été envoyé par email\n'
            '• Il commence généralement par "SESS_"\n'
            '• Vérifiez vos spams si vous ne trouvez pas l\'email\n'
            '• Contactez l\'autre conducteur si nécessaire',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
