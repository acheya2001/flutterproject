import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/collaborative_session_model.dart';
import '../../services/signature_otp_service.dart';
import 'session_dashboard_screen.dart';

/// ✍️ Écran de signature électronique avec OTP
class SignatureOTPScreen extends StatefulWidget {
  final CollaborativeSession session;
  final String telephone;

  const SignatureOTPScreen({
    super.key,
    required this.session,
    required this.telephone,
  });

  @override
  State<SignatureOTPScreen> createState() => _SignatureOTPScreenState();
}

class _SignatureOTPScreenState extends State<SignatureOTPScreen>with TickerProviderStateMixin  {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _otpEnvoye = false;
  String? _otpGenere; // Pour le mode debug
  int _tempsRestant = 300; // 5 minutes
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _timerController = AnimationController(
      duration: const Duration(seconds: 300), // 5 minutes
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
    _envoyerOTP();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _animationController.dispose();
    _timerController.dispose();
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
              Colors.green[600]!,
              Colors.teal[700]!,
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
                  child: _buildContenu(),
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
              'Signature électronique',
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.security, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'Sécurisé',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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

  Widget _buildContenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.edit_document,
              size: 60,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Titre et description
          const Text(
            'Signature du constat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Saisissez le code reçu par SMS pour signer électroniquement le constat d\'accident',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // Formulaire OTP
          Container(
            padding: const EdgeInsets.all(24),
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
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Statut OTP
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _otpEnvoye ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _otpEnvoye ? Colors.green[200]! : Colors.orange[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _otpEnvoye ? Icons.check_circle : Icons.schedule,
                          color: _otpEnvoye ? Colors.green[600] : Colors.orange[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _otpEnvoye ? 'Code envoyé !' : 'Envoi en cours...',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _otpEnvoye ? Colors.green[800] : Colors.orange[800],
                                ),
                              ),
                              Text(
                                'SMS envoyé au ${widget.telephone}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _otpEnvoye ? Colors.green[600] : Colors.orange[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Champ OTP
                  TextFormField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: 'Code de vérification',
                      hintText: 'Entrez le code à 6 chiffres',
                      prefixIcon: Icon(Icons.security),
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer le code';
                      }
                      if (value.trim().length != 6) {
                        return 'Le code doit contenir 6 chiffres';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (value.length == 6) {
                        _verifierOTP();
                      }
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Bouton signer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifierOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Signer le constat',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Bouton renvoyer
                  TextButton.icon(
                    onPressed: _otpEnvoye ? _renvoyerOTP : null,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Renvoyer le code'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green[700],
                    ),
                  ),
                  
                  // Debug info (à supprimer en production)
                  if (_otpGenere != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.yellow[300]!),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '🚧 MODE DEBUG',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            'Code OTP: $_otpGenere',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Information sécurité
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white.withOpacity(0.8)),
                    const SizedBox(width: 8),
                    Text(
                      'Signature électronique sécurisée',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Votre signature a la même valeur juridique qu\'une signature manuscrite\n'
                  '• Le code OTP expire dans 5 minutes\n'
                  '• Une fois signé, le constat ne peut plus être modifié\n'
                  '• Le document sera automatiquement envoyé aux assurances',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _envoyerOTP() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final otpGenere = await SignatureOTPService.genererOTPSignature(
        sessionId: widget.session.id,
        userId: user.uid,
        telephone: widget.telephone,
      );

      if (mounted) setState(() {
        _otpEnvoye = true;
        _otpGenere = otpGenere; // Pour le debug
      });

      // Démarrer le timer
      _timerController.forward();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Erreur envoi OTP: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifierOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final succes = await SignatureOTPService.verifierEtSigner(
        sessionId: widget.session.id,
        userId: user.uid,
        otpSaisi: _otpController.text.trim(),
      );

      if (succes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Constat signé avec succès !'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Retourner au dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SessionDashboardScreen(session: widget.session),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('$e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _renvoyerOTP() async {
    if (mounted) setState(() {
      _otpEnvoye = false;
      _otpGenere = null;
      _otpController.clear();
    });
    
    _timerController.reset();
    await _envoyerOTP();
  }
}

