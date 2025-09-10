import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/collaborative_session_model.dart';
import '../../services/collaborative_session_service.dart';
import '../../services/conducteur_data_service.dart';
import 'collaborative_form_screen.dart';
import 'guest_form_screen.dart';

/// 🔗 Écran pour rejoindre une session collaborative
class JoinSessionScreen extends StatefulWidget {
  final bool isRegisteredUser;

  const JoinSessionScreen({
    super.key,
    this.isRegisteredUser = true,
  });

  @override
  State<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends State<JoinSessionScreen>with TickerProviderStateMixin  {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showQRScanner = false;
  MobileScannerController? _scannerController;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
    _codeController.dispose();
    _animationController.dispose();
    _scannerController?.dispose();
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
              Colors.purple[600]!,
              Colors.blue[600]!,
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
                  child: _showQRScanner ? _buildQRScanner() : _buildFormulaire(),
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
                  'Rejoindre une session',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.isRegisteredUser ? 'Conducteur inscrit' : 'Invité',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _toggleQRScanner,
              icon: Icon(
                _showQRScanner ? Icons.keyboard : Icons.qr_code_scanner,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaire() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
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
                Icons.group_add,
                size: 60,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Titre et description
            const Text(
              'Entrez le code de session',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Saisissez le code à 6 caractères partagé par le créateur de la session',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            // Champ de saisie du code
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
              child: Column(
                children: [
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Code de session',
                      hintText: 'Ex: ABC123',
                      prefixIcon: const Icon(Icons.vpn_key),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer un code de session';
                      }
                      if (value.trim().length != 6) {
                        return 'Le code doit contenir 6 caractères';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (value.length == 6) {
                        // Auto-validation quand 6 caractères sont saisis
                        _rejoindreSession();
                      }
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Bouton rejoindre
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _rejoindreSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[600],
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
                                Icon(Icons.login, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Rejoindre la session',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Bouton QR Code
            Container(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _toggleQRScanner,
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: const Text(
                  'Scanner un QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Aide
            _buildSectionAide(),
          ],
        ),
      ),
    );
  }

  Widget _buildQRScanner() {
    return Container(
      margin: const EdgeInsets.all(24),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.qr_code_scanner, color: Colors.purple[600]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Scanner le QR Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _onQRCodeDetected,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionAide() {
    return Container(
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
              Icon(Icons.help_outline, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 8),
              Text(
                'Besoin d\'aide ?',
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
            '• Le code de session vous est fourni par le créateur\n'
            '• Il contient 6 caractères (lettres et chiffres)\n'
            '• Vous pouvez aussi scanner le QR Code partagé\n'
            '• La session expire après 24h',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleQRScanner() {
    setState(() {
      _showQRScanner = !_showQRScanner;
      if (_showQRScanner) {
        _scannerController = MobileScannerController();
      } else {
        _scannerController?.dispose();
        _scannerController = null;
      }
    });
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.startsWith('CONSTAT_TUNISIE:')) {
        final parts = code.split(':');
        if (parts.length >= 2) {
          final sessionCode = parts[1];
          _codeController.text = sessionCode;
          _toggleQRScanner();
          _rejoindreSession();
          break;
        }
      }
    }
  }

  Future<void> _rejoindreSession() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Obtenir les données du conducteur si inscrit
      Map<String, dynamic>? donneesUtilisateur;
      if (widget.isRegisteredUser) {
        donneesUtilisateur = await ConducteurDataService.recupererDonneesConducteur();
      }

      // Rejoindre la session
      final session = await CollaborativeSessionService.rejoindreSession(
        codeSession: _codeController.text.trim().toUpperCase(),
        nom: donneesUtilisateur?['nom'] ?? '',
        prenom: donneesUtilisateur?['prenom'] ?? '',
        email: donneesUtilisateur?['email'] ?? user.email ?? '',
        telephone: donneesUtilisateur?['telephone'] ?? '',
        type: widget.isRegisteredUser ? ParticipantType.inscrit : ParticipantType.invite_guest,
      );

      if (session != null) {
        // Naviguer vers le formulaire approprié
        if (widget.isRegisteredUser) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CollaborativeFormScreen(
                session: session,
                isCreator: false,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GuestFormScreen(
                session: session,
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Erreur: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
