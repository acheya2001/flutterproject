import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/accident_session_complete_service.dart';
import '../../services/user_profile_service.dart';
import '../../models/accident_session_complete.dart';
import 'session_waiting_screen.dart';
import 'vehicle_selection_for_session_screen.dart';

/// 🎯 Écran de création de session et invitation des autres conducteurs
class SessionInvitationScreen extends StatefulWidget {
  final String typeAccident;
  final int nombreVehicules;

  const SessionInvitationScreen({
    super.key,
    required this.typeAccident,
    required this.nombreVehicules,
  });

  @override
  State<SessionInvitationScreen> createState() => _SessionInvitationScreenState();
}

class _SessionInvitationScreenState extends State<SessionInvitationScreen>
    with TickerProviderStateMixin {
  bool _isCreatingSession = false;
  AccidentSessionComplete? _session;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _creerSession();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _creerSession() async {
    setState(() {
      _isCreatingSession = true;
    });

    try {
      // Récupérer les vraies infos utilisateur
      final userProfile = await UserProfileService.getCurrentUserProfile();
      if (userProfile == null) {
        throw Exception('Impossible de récupérer les informations utilisateur');
      }

      final session = await AccidentSessionCompleteService.creerNouvelleSession(
        typeAccident: widget.typeAccident,
        nombreVehicules: widget.nombreVehicules,
        nomCreateur: userProfile['nom'] ?? 'Conducteur',
        prenomCreateur: userProfile['prenom'] ?? 'Utilisateur',
        emailCreateur: userProfile['email'] ?? '',
        telephoneCreateur: userProfile['telephone'] ?? '+216 XX XXX XXX',
      );

      setState(() {
        _session = session;
        _isCreatingSession = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isCreatingSession = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[400]!,
              Colors.purple[600]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Contenu principal
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isCreatingSession
                      ? _buildLoadingState()
                      : _session != null
                          ? _buildInvitationState()
                          : _buildErrorState(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Bouton retour
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Création de session',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${widget.typeAccident} - ${widget.nombreVehicules} véhicules',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 20),
          Text(
            'Création de la session en cours...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationState() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Titre principal
                const Text(
                  'Session créée avec succès !',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Partagez ce code avec les autres conducteurs',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 30),
                
                // Code de session
                _buildCodeSession(),
                
                const SizedBox(height: 30),
                
                // QR Code
                _buildQRCode(),
                
                const SizedBox(height: 30),
                
                // Options de partage
                _buildOptionsPartage(),
                
                const SizedBox(height: 30),
                
                // Statut des conducteurs
                _buildStatutConducteurs(),
                
                const SizedBox(height: 30),
                
                // Bouton continuer
                _buildBoutonContinuer(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCodeSession() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          const Text(
            'Code de session',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _session!.codeSession,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _copierCode,
                  icon: const Icon(Icons.copy, color: Colors.blue),
                  tooltip: 'Copier le code',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          const Text(
            'QR Code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: _session!.codeSession,
              version: QrVersions.auto,
              size: 150.0,
              backgroundColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            'Scannez avec l\'appareil photo',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsPartage() {
    return Column(
      children: [
        const Text(
          'Partager avec',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBoutonPartage(
              'WhatsApp',
              Icons.message,
              Colors.green,
              _partagerWhatsApp,
            ),
            _buildBoutonPartage(
              'SMS',
              Icons.sms,
              Colors.blue,
              _partagerSMS,
            ),
            _buildBoutonPartage(
              'Email',
              Icons.email,
              Colors.orange,
              _partagerEmail,
            ),
            _buildBoutonPartage(
              'Autre',
              Icons.share,
              Colors.purple,
              _partagerAutre,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBoutonPartage(String titre, IconData icon, Color couleur, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: couleur.withOpacity(0.3)),
            ),
            child: Icon(icon, color: couleur, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            titre,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatutConducteurs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          const Text(
            'Conducteurs connectés',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_session!.conducteurs.length}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Text(
                ' / ',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                ),
              ),
              Text(
                '${widget.nombreVehicules}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _session!.conducteurs.length == widget.nombreVehicules
                ? 'Tous les conducteurs sont connectés !'
                : 'En attente de ${widget.nombreVehicules - _session!.conducteurs.length} conducteur(s)',
            style: TextStyle(
              fontSize: 14,
              color: _session!.conducteurs.length == widget.nombreVehicules
                  ? Colors.green[700]
                  : Colors.orange[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBoutonContinuer() {
    final tousConnectes = _session!.conducteurs.length == widget.nombreVehicules;

    return Column(
      children: [
        // Bouton principal : Commencer maintenant (toujours disponible pour le créateur)
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _continuer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow, size: 24),
                const SizedBox(width: 8),
                Text(
                  tousConnectes
                      ? 'Commencer la déclaration'
                      : 'Commencer maintenant',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (!tousConnectes) ...[
          const SizedBox(height: 12),

          // Message informatif
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Vous pouvez commencer à remplir votre partie du constat. Les autres conducteurs pourront rejoindre et compléter leurs informations plus tard.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'Erreur lors de la création de la session',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _copierCode() {
    Clipboard.setData(ClipboardData(text: _session!.codeSession));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copié dans le presse-papiers'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _partagerWhatsApp() {
    final message = 'Code session accident: ${_session!.codeSession}\n'
        'Type: ${widget.typeAccident}\n'
        'Rejoignez la session dans l\'app Constat Tunisie';
    Share.share(message);
  }

  void _partagerSMS() {
    final message = 'Code session accident: ${_session!.codeSession}\n'
        'Type: ${widget.typeAccident}\n'
        'Rejoignez la session dans l\'app Constat Tunisie';
    Share.share(message);
  }

  void _partagerEmail() {
    final message = 'Code session accident: ${_session!.codeSession}\n'
        'Type: ${widget.typeAccident}\n'
        'Rejoignez la session dans l\'app Constat Tunisie';
    Share.share(message);
  }

  void _partagerAutre() {
    final message = 'Code session accident: ${_session!.codeSession}\n'
        'Type: ${widget.typeAccident}\n'
        'Rejoignez la session dans l\'app Constat Tunisie';
    Share.share(message);
  }

  void _continuer() {
    // Naviguer vers l'écran de sélection de véhicule pour conducteurs inscrits
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleSelectionForSessionScreen(
          session: _session!,
        ),
      ),
    );
  }
}
