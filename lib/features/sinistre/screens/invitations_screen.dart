import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../common/widgets/custom_app_bar.dart';
import '../../../common/widgets/gradient_background.dart';
import '../../../models/accident_session.dart';
import '../../../models/constat.dart';
import '../services/accident_session_service.dart';
import 'participant_form_screen.dart';

/// Écran d'invitations pour ajouter d'autres conducteurs (Écran 3)
class InvitationsScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> vehiculeData;

  const InvitationsScreen({
    Key? key,
    required this.sessionId,
    required this.vehiculeData,
  }) : super(key: key);

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  bool _isLoading = false;
  AccidentSession? _session;
  List<Invitation> _invitations = [];
  
  final AccidentSessionService _sessionService = AccidentSessionService();

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    setState(() => _isLoading = true);
    
    try {
      _session = await _sessionService.getSession(widget.sessionId);
      if (_session == null) {
        throw Exception('Session non trouvée');
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Erreur lors du chargement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Inviter les Conducteurs',
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_session == null) {
      return const Center(child: Text('Session non trouvée'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildSessionInfo(),
          const SizedBox(height: 32),
          _buildInvitationMethods(),
          const SizedBox(height: 32),
          _buildActiveInvitations(),
          const SizedBox(height: 32),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          Icon(
            Icons.group_add,
            size: 48,
            color: Colors.blue[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Inviter les Autres Conducteurs',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Partagez le code ou le lien pour que les autres conducteurs puissent rejoindre la déclaration',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Informations de la session',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Code Session', _session!.codePublic),
          _buildInfoRow('Votre Véhicule', '${widget.vehiculeData['marque']} ${widget.vehiculeData['modele']}'),
          _buildInfoRow('Immatriculation', widget.vehiculeData['immatriculation']),
          _buildInfoRow('Statut', _getStatusLabel(_session!.statut)),
          _buildInfoRow(
            'Délai Légal',
            _session!.isInLegalDeadline 
                ? 'Dans les délais (${_session!.deadlineDeclaration.difference(DateTime.now()).inDays} jours restants)'
                : 'Délai dépassé',
            color: _session!.isInLegalDeadline ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color ?? Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Méthodes d\'invitation',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildInvitationCard(
          icon: Icons.qr_code,
          title: 'QR Code',
          subtitle: 'Générer un QR code à scanner',
          color: Colors.blue,
          onTap: () => _showQRCode(),
        ),
        const SizedBox(height: 12),
        _buildInvitationCard(
          icon: Icons.link,
          title: 'Lien de Partage',
          subtitle: 'Créer un lien à envoyer',
          color: Colors.green,
          onTap: () => _createShareLink(),
        ),
        const SizedBox(height: 12),
        _buildInvitationCard(
          icon: Icons.content_copy,
          title: 'Code Session',
          subtitle: 'Copier le code de la session',
          color: Colors.orange,
          onTap: () => _copySessionCode(),
        ),
      ],
    );
  }

  Widget _buildInvitationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildActiveInvitations() {
    if (_invitations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune invitation envoyée',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Utilisez les méthodes ci-dessus pour inviter d\'autres conducteurs',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
                height: 1.3,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invitations actives',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ..._invitations.map((invitation) => _buildInvitationItem(invitation)),
      ],
    );
  }

  Widget _buildInvitationItem(Invitation invitation) {
    final isExpired = !invitation.isValid;
    final isUsed = invitation.isUsed;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired || isUsed ? Colors.grey[300]! : Colors.blue[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUsed 
                  ? Colors.green[100] 
                  : isExpired 
                      ? Colors.grey[100] 
                      : Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUsed 
                  ? Icons.check 
                  : isExpired 
                      ? Icons.access_time 
                      : Icons.person_add,
              color: isUsed 
                  ? Colors.green 
                  : isExpired 
                      ? Colors.grey 
                      : Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Véhicule ${invitation.rolePropose}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isUsed 
                      ? 'Utilisée' 
                      : isExpired 
                          ? 'Expirée' 
                          : 'En attente',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isUsed 
                        ? Colors.green 
                        : isExpired 
                            ? Colors.grey 
                            : Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!isUsed && !isExpired)
            IconButton(
              onPressed: () => _shareInvitation(invitation),
              icon: const Icon(Icons.share, size: 20),
              tooltip: 'Partager',
            ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _continueToMyForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit),
                const SizedBox(width: 8),
                Text(
                  'Remplir ma partie du constat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _skipInvitations,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continuer sans inviter (déclaration unilatérale)'),
          ),
        ),
      ],
    );
  }

  void _showQRCode() async {
    try {
      setState(() => _isLoading = true);
      
      // Créer une invitation pour le prochain véhicule disponible
      final nextRole = _getNextAvailableRole();
      if (nextRole == null) {
        throw Exception('Maximum 4 véhicules autorisés');
      }
      
      final invitation = await _sessionService.createInvitation(widget.sessionId, nextRole);
      
      setState(() {
        _invitations.add(invitation);
        _isLoading = false;
      });
      
      showDialog(
        context: context,
        builder: (context) => _QRCodeDialog(
          invitation: invitation,
          sessionCode: _session!.codePublic,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Erreur lors de la création du QR code: $e');
    }
  }

  Future<void> _createShareLink() async {
    try {
      setState(() => _isLoading = true);
      
      final nextRole = _getNextAvailableRole();
      if (nextRole == null) {
        throw Exception('Maximum 4 véhicules autorisés');
      }
      
      final invitation = await _sessionService.createInvitation(widget.sessionId, nextRole);
      
      setState(() {
        _invitations.add(invitation);
        _isLoading = false;
      });
      
      final link = 'https://constat.tunisie.app/join/${invitation.urlToken}';
      
      await Share.share(
        'Rejoignez ma déclaration de sinistre:\n\n'
        'Code: ${invitation.urlToken}\n'
        'Lien: $link\n\n'
        'Ou scannez le QR code dans l\'application.',
        subject: 'Invitation - Déclaration de Sinistre',
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Erreur lors de la création du lien: $e');
    }
  }

  void _copySessionCode() {
    Clipboard.setData(ClipboardData(text: _session!.codePublic));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check, color: Colors.white),
            const SizedBox(width: 8),
            Text('Code copié: ${_session!.codePublic}'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareInvitation(Invitation invitation) {
    final link = 'https://constat.tunisie.app/join/${invitation.urlToken}';
    
    Share.share(
      'Rejoignez ma déclaration de sinistre (Véhicule ${invitation.rolePropose}):\n\n'
      'Code: ${invitation.urlToken}\n'
      'Lien: $link\n\n'
      'Ou scannez le QR code dans l\'application.',
      subject: 'Invitation - Déclaration de Sinistre',
    );
  }

  void _continueToMyForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParticipantFormScreen(
          session: _session!,
          roleAssigne: 'A', // Le créateur est toujours le véhicule A
          isFromInvitation: false,
          vehiculeData: widget.vehiculeData,
        ),
      ),
    );
  }

  void _skipInvitations() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déclaration unilatérale'),
        content: const Text(
          'Vous allez procéder à une déclaration unilatérale. '
          'Les autres conducteurs ne pourront pas participer à cette déclaration. '
          'Êtes-vous sûr de vouloir continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _continueToMyForm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  String? _getNextAvailableRole() {
    final usedRoles = _invitations.map((i) => i.rolePropose).toSet();
    usedRoles.add('A'); // Le créateur occupe toujours le rôle A
    
    for (final role in ['B', 'C', 'D']) {
      if (!usedRoles.contains(role)) {
        return role;
      }
    }
    return null;
  }

  String _getStatusLabel(String statut) {
    switch (statut) {
      case AccidentSession.STATUT_BROUILLON:
        return 'Brouillon';
      case AccidentSession.STATUT_EN_ATTENTE_INVITES:
        return 'En attente d\'invités';
      case AccidentSession.STATUT_PARTIES_EN_SAISIE:
        return 'Saisie en cours';
      case AccidentSession.STATUT_PRET_A_SIGNER:
        return 'Prêt à signer';
      case AccidentSession.STATUT_SIGNATURE_EN_COURS:
        return 'Signature en cours';
      case AccidentSession.STATUT_SIGNE_VALIDE:
        return 'Signé et validé';
      default:
        return statut;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message.replaceFirst('Exception: ', '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Dialog pour afficher le QR Code
class _QRCodeDialog extends StatelessWidget {
  final Invitation invitation;
  final String sessionCode;

  const _QRCodeDialog({
    required this.invitation,
    required this.sessionCode,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('QR Code d\'Invitation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: QrImageView(
              data: invitation.urlToken,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Code: ${invitation.urlToken}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Véhicule ${invitation.rolePropose}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        ElevatedButton(
          onPressed: () {
            final link = 'https://constat.tunisie.app/join/${invitation.urlToken}';
            Share.share(
              'Rejoignez ma déclaration de sinistre (Véhicule ${invitation.rolePropose}):\n\n'
              'Code: ${invitation.urlToken}\n'
              'Lien: $link\n\n'
              'Ou scannez ce QR code dans l\'application.',
              subject: 'Invitation - Déclaration de Sinistre',
            );
          },
          child: const Text('Partager'),
        ),
      ],
    );
  }
}
