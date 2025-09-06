import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../common/widgets/custom_app_bar.dart';
import '../../../common/widgets/gradient_background.dart';
import 'creation_session_screen.dart';
import 'rejoindre_session_screen.dart';
import '../../../conducteur/screens/modern_join_session_screen.dart';
import '../../../conducteur/screens/guest_registration_form_screen.dart';
import '../../../services/modern_sinistre_service.dart';
import '../../../conducteur/screens/accident_choice_screen.dart';
import '../../../conducteur/screens/constat_complet_screen.dart';
import '../../../conducteur/screens/accident_vehicle_selection_screen.dart';

/// Écran de choix rapide pour déclarer un sinistre ou rejoindre une session
class SinistreChoixRapideScreen extends StatefulWidget {
  const SinistreChoixRapideScreen({Key? key}) : super(key: key);

  @override
  State<SinistreChoixRapideScreen> createState() => _SinistreChoixRapideScreenState();
}

class _SinistreChoixRapideScreenState extends State<SinistreChoixRapideScreen>
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
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Déclaration de Sinistre',
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            _buildHeader(),
                            const SizedBox(height: 60),
                            _buildActionButtons(),
                            const SizedBox(height: 40),
                            _buildInfoSection(),
                            const SizedBox(height: 100), // Remplace Spacer
                            _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[400]!, Colors.orange[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.car_crash,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Constat Digital',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Déclarez votre sinistre rapidement\net en toute sécurité',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionCard(
          icon: Icons.add_circle_outline,
          title: 'Déclarer un Sinistre',
          subtitle: 'Créer une nouvelle déclaration\net inviter les autres conducteurs',
          color: Colors.blue,
          onTap: () => _navigateToCreationSession(),
        ),
        const SizedBox(height: 20),
        _buildActionCard(
          icon: Icons.qr_code_scanner,
          title: 'Rejoindre une Session',
          subtitle: 'Scanner un QR code ou saisir\nun code d\'invitation',
          color: Colors.green,
          onTap: () => _showJoinOptions(),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
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
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Informations importantes',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('⏰', 'Délai légal : 5 jours ouvrés'),
          _buildInfoItem('📱', 'Constat 100% digital et sécurisé'),
          _buildInfoItem('✍️', 'Signature électronique certifiée'),
          _buildInfoItem('📄', 'PDF automatiquement transmis aux assureurs'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'En cas d\'urgence, appelez d\'abord les secours\npuis procédez à la déclaration',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withOpacity(0.7),
        height: 1.4,
      ),
    );
  }

  void _navigateToCreationSession() {
    // 🚀 Navigation vers la sélection de véhicule puis invitation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AccidentVehicleSelectionScreen(),
      ),
    );
  }

  void _showJoinOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildJoinOptionsModal(),
    );
  }

  Widget _buildJoinOptionsModal() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Rejoindre une Session',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildJoinOption(
                icon: Icons.qr_code_scanner,
                title: 'Scanner QR Code',
                subtitle: 'Utiliser l\'appareil photo pour scanner',
                onTap: () => _scanQRCode(),
              ),
              const SizedBox(height: 16),
              _buildJoinOption(
                icon: Icons.keyboard,
                title: 'Saisir le Code',
                subtitle: 'Entrer manuellement le code d\'invitation',
                onTap: () => _showCodeInput(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJoinOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scanQRCode() async {
    Navigator.pop(context); // Fermer le modal
    
    // Demander permission caméra
    final permission = await Permission.camera.request();
    if (permission.isGranted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRScannerScreen(
            onCodeDetected: (code) {
              Navigator.pop(context);
              _showUserTypeDialogWithCode(code);
            },
          ),
        ),
      );
    } else {
      _showPermissionDeniedDialog();
    }
  }

  void _showCodeInput() {
    Navigator.pop(context); // Fermer le modal
    _showUserTypeDialog();
  }

  void _showUserTypeDialog() {
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

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission requise'),
        content: const Text(
          'L\'accès à la caméra est nécessaire pour scanner le QR code. '
          'Veuillez autoriser l\'accès dans les paramètres.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Paramètres'),
          ),
        ],
      ),
    );
  }

  void _showUserTypeDialogWithCode(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Type de conducteur'),
        content: Text('Code détecté: $code\n\nÊtes-vous déjà inscrit dans l\'application ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _joinAsGuest(code);
            },
            child: const Text('Non, je suis invité'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ModernJoinSessionScreen(codeSession: code),
                ),
              );
            },
            child: const Text('Oui, je suis inscrit'),
          ),
        ],
      ),
    );
  }
}

/// Écran de scan QR Code
class QRScannerScreen extends StatefulWidget {
  final Function(String) onCodeDetected;

  const QRScannerScreen({
    Key? key,
    required this.onCodeDetected,
  }) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black,
              child: Center(
                child: const Text(
                  'Placez le QR code dans le cadre',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (isScanning && barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        isScanning = false;
        HapticFeedback.lightImpact();
        _handleQRCode(barcode.rawValue!);
      }
    }
  }

  void _handleQRCode(String code) {
    Navigator.pop(context);
    _showUserTypeDialogWithCode(code);
  }

  void _showUserTypeDialogWithCode(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Type de conducteur'),
        content: Text('Code détecté: $code\n\nÊtes-vous déjà inscrit dans l\'application ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onCodeDetected(code);
            },
            child: const Text('Non, je suis invité'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ModernJoinSessionScreen(codeSession: code),
                ),
              );
            },
            child: const Text('Oui, je suis inscrit'),
          ),
        ],
      ),
    );
  }
}
