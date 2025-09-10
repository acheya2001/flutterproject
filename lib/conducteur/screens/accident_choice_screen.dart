import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/accident_session_service.dart';
import '../../models/accident_session.dart';
import 'modern_accident_type_screen.dart';
import 'modern_single_accident_info_screen.dart';
import 'modern_join_session_screen.dart';
import 'guest_registration_form_screen.dart';
import 'join_session_registered_screen.dart';
import 'modern_accident_type_screen.dart';
import '../../services/modern_sinistre_service.dart';

/// 🚨 Écran de choix : Déclarer un sinistre ou Rejoindre une session
class AccidentChoiceScreen extends StatefulWidget {
  const AccidentChoiceScreen({Key? key}) : super(key: key);

  @override
  State<AccidentChoiceScreen> createState() => _AccidentChoiceScreenState();
}

class _AccidentChoiceScreenState extends State<AccidentChoiceScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// 🆕 Déclarer un nouveau sinistre
  void _declarerNouveauSinistre() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ModernAccidentTypeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
      ),
    );
  }

  /// 🔗 Rejoindre une session (conducteur inscrit)
  void _rejoindreSesssionInscrit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const JoinSessionRegisteredScreen(),
      ),
    );
  }

  /// 🔍 Rejoindre une session avec un code
  Future<void> _rejoindreSesssionParCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      if (mounted) setState(() {
        _errorMessage = 'Veuillez saisir un code de session';
      });
      return;
    }

    if (mounted) setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await AccidentSessionService.rejoindreSesssionParCode(code);
      
      if (session == null) {
        if (mounted) setState(() {
          _errorMessage = 'Code de session invalide ou session introuvable';
        });
        return;
      }

      // Naviguer vers l'écran de session
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ModernSingleAccidentInfoScreen(typeAccident: 'Sortie de route'),
        ),
      );
    } catch (e) {
      if (mounted) setState(() {
        _errorMessage = 'Erreur lors de la connexion à la session: $e';
      });
    } finally {
      if (mounted) setState(() {
        _isLoading = false;
      });
    }
  }

  /// 📱 Scanner un QR code
  void _scannerQRCode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onCodeScanned: (code) {
            _codeController.text = code;
            _rejoindreSesssionParCode();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Déclaration de Sinistre',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red[600],
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header avec icône
            Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.car_crash,
                    size: 80,
                    color: Colors.red[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Que souhaitez-vous faire ?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choisissez une option pour continuer',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Option 1: Déclarer un nouveau sinistre
            _buildOptionCard(
              icon: Icons.add_circle_outline,
              title: 'Déclarer un Sinistre',
              subtitle: 'Créer une nouvelle déclaration d\'accident',
              color: Colors.blue,
              onTap: _declarerNouveauSinistre,
            ),

            const SizedBox(height: 16),

            // Option 2: Rejoindre une session
            _buildOptionCard(
              icon: Icons.group_add,
              title: 'Rejoindre une Session',
              subtitle: 'Participer à une déclaration existante',
              color: Colors.green,
              onTap: _rejoindreSesssionInscrit,
            ),

            const SizedBox(height: 32),

            // Informations légales
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber[700],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Rappel : Vous avez 5 jours ouvrés pour déclarer un sinistre à votre assureur.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Type de conducteur'),
        content: const Text('Êtes-vous déjà inscrit dans l\'application ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToGuestJoin();
            },
            child: const Text('Non, je suis invité'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToRegisteredJoin();
            },
            child: const Text('Oui, je suis inscrit'),
          ),
        ],
      ),
    );
  }

  void _navigateToRegisteredJoin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModernJoinSessionScreen(),
      ),
    );
  }

  void _navigateToGuestJoin() {
    // Demander le code d'abord
    _showCodeInputDialog();
  }

  void _showCodeInputDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code de session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Saisissez le code de la session à rejoindre :'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                hintText: 'Ex: ABC123',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _joinAsGuest(code);
              }
            },
            child: const Text('Rejoindre'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinAsGuest(String code) async {
    try {
      // Vérifier que la session existe
      final result = await ModernSinistreService.rejoindreSesssionInvite(
        codeSession: code.toUpperCase(),
      );

      if (result['success']) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GuestRegistrationFormScreen(
              sessionData: result['sessionData'],
              sessionId: result['sessionId'],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Session non trouvée')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}

/// 📱 Écran de scan QR Code
class QRScannerScreen extends StatefulWidget {
  final Function(String) onCodeScanned;

  const QRScannerScreen({
    Key? key,
    required this.onCodeScanned,
  }) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner le QR Code'),
        backgroundColor: Colors.red[600],
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    widget.onCodeScanned(barcode.rawValue!);
                    return;
                  }
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Placez le QR code dans le cadre pour le scanner',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

