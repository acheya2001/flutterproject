import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../constat/providers/collaborative_session_provider.dart';
import '../../constat/screens/conducteur_declaration_screen.dart';

/// 🎯 Widget professionnel pour rejoindre une session collaborative
/// 
/// Interface moderne avec validation en temps réel, feedback utilisateur
/// et gestion d'erreurs robuste.
class ProfessionalJoinSessionWidget extends StatefulWidget {
  final String? initialSessionCode;
  final VoidCallback? onCancel;

  const ProfessionalJoinSessionWidget({
    Key? key,
    this.initialSessionCode,
    this.onCancel,
  }) : super(key: key);

  @override
  State<ProfessionalJoinSessionWidget> createState() => _ProfessionalJoinSessionWidgetState();
}

class _ProfessionalJoinSessionWidgetState extends State<ProfessionalJoinSessionWidget>
    with TickerProviderStateMixin {
  final _sessionCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isValidCode = false;

  @override
  void initState() {
    super.initState();
    
    // Initialiser le code si fourni
    if (widget.initialSessionCode != null) {
      _sessionCodeController.text = widget.initialSessionCode!;
      _validateCode(widget.initialSessionCode!);
    }

    // Animations
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

    // Écouter les changements du provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollaborativeSessionProvider>().addListener(_onProviderChange);
    });
  }

  @override
  void dispose() {
    _sessionCodeController.dispose();
    _animationController.dispose();
    context.read<CollaborativeSessionProvider>().removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    final provider = context.read<CollaborativeSessionProvider>();
    
    if (provider.error != null) {
      _showErrorSnackBar(provider.error!);
      provider.clearMessages();
    }
    
    if (provider.successMessage != null) {
      _showSuccessSnackBar(provider.successMessage!);
      provider.clearMessages();
    }
  }

  void _validateCode(String code) {
    setState(() {
      _isValidCode = code.trim().length >= 4 && 
                    code.trim().toUpperCase().startsWith('SESS_');
    });
  }

  Future<void> _rejoindreSession() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final sessionProvider = context.read<CollaborativeSessionProvider>();

    if (authProvider.currentUser == null) {
      _showErrorSnackBar('Veuillez vous connecter d\'abord');
      return;
    }

    final sessionCode = _sessionCodeController.text.trim().toUpperCase();
    
    // Rejoindre la session
    final session = await sessionProvider.rejoindreSession(
      sessionCode,
      authProvider.currentUser!.id,
    );

    if (session != null && mounted) {
      // Trouver la position du conducteur
      final position = sessionProvider.getUserPosition(authProvider.currentUser!.id);
      
      if (position != null) {
        // Naviguer vers l'écran de déclaration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConducteurDeclarationScreen(
              sessionId: session.id,
              conducteurPosition: position,
              isCollaborative: true,
            ),
          ),
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSessionCodeInput(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 16),
                _buildHelpText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.login,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Rejoindre une Session',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Saisissez le code reçu par email pour participer au constat collaboratif',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Code de Session',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _sessionCodeController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'SESS_1234',
            prefixIcon: Icon(
              Icons.qr_code,
              color: _isValidCode ? const Color(0xFF10B981) : Colors.grey,
            ),
            suffixIcon: _isValidCode
                ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
          inputFormatters: [
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: _validateCode,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez saisir un code de session';
            }
            if (!value.trim().toUpperCase().startsWith('SESS_')) {
              return 'Le code doit commencer par SESS_';
            }
            if (value.trim().length < 8) {
              return 'Code trop court';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Consumer<CollaborativeSessionProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            if (widget.onCancel != null) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: provider.isLoading ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: provider.isLoading || !_isValidCode ? null : _rejoindreSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Rejoindre',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpText() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF6366F1),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Le code vous a été envoyé par email. Vérifiez vos spams si nécessaire.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formateur pour convertir en majuscules
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
