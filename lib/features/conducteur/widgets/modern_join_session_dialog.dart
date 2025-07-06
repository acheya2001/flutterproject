import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/email_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../constat/providers/session_provider.dart';
import '../screens/conducteur_declaration_screen.dart';

class ModernJoinSessionDialog extends ConsumerStatefulWidget {
  const ModernJoinSessionDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<ModernJoinSessionDialog> createState() => _ModernJoinSessionDialogState();
}

class _ModernJoinSessionDialogState extends ConsumerState<ModernJoinSessionDialog>
    with TickerProviderStateMixin {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _rejoindreSession() async {
    final code = _codeController.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez saisir un code de session';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[ModernJoinDialog] Tentative de rejoindre la session: $code');
      
      final authProviderInstance = ref.read(authProvider);
      if (authProviderInstance.currentUser == null) {
        throw Exception('Vous devez être connecté pour rejoindre une session');
      }

      final sessionProvider = SessionProvider(
        sessionService: SessionService(),
      );

      // Rechercher la session par code
      final session = await sessionProvider.rechercherSessionParCode(code);
      
      if (session == null) {
        throw Exception('Session non trouvée. Vérifiez le code.');
      }

      debugPrint('[ModernJoinDialog] Session trouvée: ${session.id}');

      // Vérifier si l'utilisateur peut rejoindre cette session
      final userEmail = authProviderInstance.currentUser!.email;
      final canJoin = session.conducteursInfo.values.any((info) => 
        info.email == userEmail && info.isInvited && !info.hasJoined
      );

      if (!canJoin) {
        throw Exception('Vous n\'êtes pas autorisé à rejoindre cette session ou vous l\'avez déjà rejointe.');
      }

      // Trouver la position du conducteur
      String? position;
      for (var entry in session.conducteursInfo.entries) {
        if (entry.value.email == userEmail) {
          position = entry.key;
          break;
        }
      }

      if (position == null) {
        throw Exception('Position non trouvée dans la session');
      }

      debugPrint('[ModernJoinDialog] Position trouvée: $position');

      // Marquer le conducteur comme ayant rejoint
      await sessionProvider.marquerConducteurRejoint(
        sessionId: session.id!,
        position: position,
        userId: authProviderInstance.currentUser!.id,
      );

      debugPrint('[ModernJoinDialog] Conducteur marqué comme rejoint');

      // Fermer le dialog et naviguer
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConducteurDeclarationScreen(
              sessionId: session.id!,
              conducteurPosition: position!,
            ),
          ),
        );
      }

    } catch (e) {
      debugPrint('[ModernJoinDialog] Erreur: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header avec icône
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.group_add,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Titre
                      const Text(
                        'Rejoindre une session',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Sous-titre
                      const Text(
                        'Entrez le code reçu par email',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Champ de saisie du code
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _errorMessage != null 
                                ? const Color(0xFFEF4444) 
                                : const Color(0xFFE5E7EB),
                            width: 2,
                          ),
                          color: const Color(0xFFF9FAFB),
                        ),
                        child: TextField(
                          controller: _codeController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: 'ABC123',
                            hintStyle: TextStyle(
                              color: Color(0xFFD1D5DB),
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(20),
                          ),
                          onChanged: (value) {
                            if (_errorMessage != null) {
                              setState(() {
                                _errorMessage = null;
                              });
                            }
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Message d'erreur
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEF4444)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFEF4444),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Boutons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Annuler',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _rejoindreSession,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Rejoindre',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
