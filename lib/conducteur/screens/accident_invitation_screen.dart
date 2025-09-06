import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/sinistre_tracking_service.dart';
import 'constat_complet_screen.dart';
import '../../features/sinistre/screens/accident_type_selection_screen.dart';

/// 👥 Écran d'invitation des autres conducteurs
class AccidentInvitationScreen extends StatefulWidget {
  final String sinistreId;
  final Map<String, dynamic> vehiculeSelectionne;
  final String accidentType;
  final int vehicleCount;

  const AccidentInvitationScreen({
    Key? key,
    required this.sinistreId,
    required this.vehiculeSelectionne,
    required this.accidentType,
    required this.vehicleCount,
  }) : super(key: key);

  @override
  State<AccidentInvitationScreen> createState() => _AccidentInvitationScreenState();
}

class _AccidentInvitationScreenState extends State<AccidentInvitationScreen> {
  late String _sessionCode;
  int _participantsConnected = 1; // Vous êtes déjà connecté
  bool _isWaiting = true;

  @override
  void initState() {
    super.initState();
    _sessionCode = widget.sinistreId.substring(0, 8).toUpperCase();
    _startListeningForParticipants();
  }

  /// 👂 Écouter les participants qui rejoignent
  void _startListeningForParticipants() {
    // TODO: Implémenter l'écoute en temps réel des participants
    // Pour l'instant, simulation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _participantsConnected = 1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Inviter les autres conducteurs'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _continueAlone,
            child: const Text(
              'Continuer seul',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // En-tête avec QR Code
            _buildQRCodeSection(),
            
            const SizedBox(height: 32),
            
            // Code de session
            _buildSessionCodeSection(),
            
            const SizedBox(height: 32),
            
            // Participants connectés
            _buildParticipantsSection(),
            
            const SizedBox(height: 32),
            
            // Options de partage
            _buildSharingOptions(),
            
            const SizedBox(height: 32),
            
            // Instructions
            _buildInstructions(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  /// 📱 Section QR Code
  Widget _buildQRCodeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '📱 QR Code de Session',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: 'CONSTAT_SESSION:${widget.sinistreId}',
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Les autres conducteurs peuvent scanner ce code',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔢 Section code de session
  Widget _buildSessionCodeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        children: [
          const Text(
            '🔢 Code de Session',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[300]!, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _sessionCode,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _copySessionCode,
                  icon: Icon(Icons.copy, color: Colors.blue[600]),
                  tooltip: 'Copier le code',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Partagez ce code avec les autres conducteurs',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  /// 👥 Section participants
  Widget _buildParticipantsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.green[600], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Participants connectés',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_participantsConnected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildParticipantItem('Vous', 'Créateur de la session', true),
          if (_participantsConnected > 1)
            _buildParticipantItem('Conducteur 2', 'Connecté', true),
          if (_participantsConnected < 2)
            _buildParticipantItem('En attente...', 'Pas encore connecté', false),
        ],
      ),
    );
  }

  /// 👤 Item participant
  Widget _buildParticipantItem(String name, String status, bool isConnected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isConnected ? Colors.green[100] : Colors.grey[200],
            child: Icon(
              isConnected ? Icons.person : Icons.person_outline,
              color: isConnected ? Colors.green[600] : Colors.grey[500],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isConnected)
            Icon(Icons.check_circle, color: Colors.green[600], size: 20),
        ],
      ),
    );
  }

  /// 📤 Options de partage
  Widget _buildSharingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📤 Partager la session',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildShareButton(
                'SMS',
                Icons.sms,
                Colors.green[600]!,
                _shareViaSMS,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildShareButton(
                'Email',
                Icons.email,
                Colors.blue[600]!,
                _shareViaEmail,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildShareButton(
                'Autre',
                Icons.share,
                Colors.orange[600]!,
                _shareGeneral,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 🔘 Bouton de partage
  Widget _buildShareButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📋 Instructions
  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '1. Partagez le QR code ou le code de session\n'
            '2. Les autres conducteurs doivent ouvrir l\'app\n'
            '3. Cliquer sur "Rejoindre une session"\n'
            '4. Scanner le QR code ou saisir le code\n'
            '5. Attendre que tous rejoignent puis continuer',
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// ⬇️ Actions du bas
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _continueAlone,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              child: const Text('Continuer seul'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _participantsConnected > 1 ? _startConstat : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _participantsConnected > 1 
                    ? 'Démarrer le constat'
                    : 'En attente...',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Copier le code de session
  void _copySessionCode() {
    Clipboard.setData(ClipboardData(text: _sessionCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copié dans le presse-papiers'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 📱 Partager via SMS
  void _shareViaSMS() {
    final message = 'Rejoignez ma session de constat d\'accident avec le code: $_sessionCode\n'
                   'Téléchargez l\'app Constat Tunisie et cliquez sur "Rejoindre une session"';
    Share.share(message);
  }

  /// 📧 Partager via Email
  void _shareViaEmail() {
    final message = 'Bonjour,\n\n'
                   'Vous êtes impliqué dans un accident avec moi. '
                   'Pour remplir le constat collaboratif, rejoignez ma session avec le code: $_sessionCode\n\n'
                   'Étapes:\n'
                   '1. Téléchargez l\'app "Constat Tunisie"\n'
                   '2. Cliquez sur "Rejoindre une session"\n'
                   '3. Saisissez le code: $_sessionCode\n\n'
                   'Merci';
    Share.share(message);
  }

  /// 📤 Partage général
  void _shareGeneral() {
    final message = 'Code de session constat: $_sessionCode\n'
                   'App: Constat Tunisie → Rejoindre une session';
    Share.share(message);
  }

  /// ▶️ Continuer seul (garde le véhicule sélectionné pour les inscrits)
  void _continueAlone() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ConstatCompletScreen(
          sinistreId: widget.sinistreId,
          vehiculeSelectionne: widget.vehiculeSelectionne, // ✅ Garde le véhicule sélectionné
          accidentType: widget.accidentType,
          vehicleCount: widget.vehicleCount,
          isCollaborative: false,
          conducteurLetter: 'A', // Premier conducteur = A
          sessionData: null, // Pas de session collaborative
        ),
      ),
    );
  }

  /// 🚀 Démarrer le constat collaboratif
  void _startConstat() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ConstatCompletScreen(
          sinistreId: widget.sinistreId,
          vehiculeSelectionne: widget.vehiculeSelectionne,
          accidentType: widget.accidentType,
          vehicleCount: widget.vehicleCount,
          isCollaborative: true,
          conducteurLetter: 'A', // Premier conducteur = A
          sessionData: null, // Données de session à implémenter
        ),
      ),
    );
  }
}
