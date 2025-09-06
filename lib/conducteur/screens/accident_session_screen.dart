import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/accident_session.dart';
import '../../models/accident_participant.dart';
import '../../services/accident_session_service.dart';
import 'participant_form_screen.dart';

/// 🚨 Écran principal de session d'accident collaborative
class AccidentSessionScreen extends StatefulWidget {
  final AccidentSession session;

  const AccidentSessionScreen({
    Key? key,
    required this.session,
  }) : super(key: key);

  @override
  State<AccidentSessionScreen> createState() => _AccidentSessionScreenState();
}

class _AccidentSessionScreenState extends State<AccidentSessionScreen> {
  late AccidentSession _session;
  List<AccidentParticipant> _participants = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _chargerParticipants();
  }

  /// 📋 Charger les participants de la session
  void _chargerParticipants() {
    AccidentSessionService.getParticipantsSession(_session.id).listen((participants) {
      setState(() {
        _participants = participants;
      });
    });
  }

  /// 👥 Rejoindre en tant que partie A ou B
  Future<void> _rejoindreSesssion(String partie) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final participant = await AccidentSessionService.ajouterParticipant(
        sessionId: _session.id,
        partie: partie,
      );

      // Naviguer vers le formulaire de participant
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ParticipantFormScreen(
            session: _session,
            participant: participant,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 📤 Partager le code de session
  void _partagerCode() {
    final message = '''
🚨 Déclaration d'Accident - Invitation

Vous êtes invité(e) à participer à une déclaration d'accident collaborative.

📍 Lieu: ${_session.localisation['adresse'] ?? 'Non spécifié'}
📅 Date: ${_session.dateOuverture != null ? '${_session.dateOuverture.day}/${_session.dateOuverture.month}/${_session.dateOuverture.year}' : 'Non spécifiée'}

🔑 Code de session: ${_session.codePublic}

Pour rejoindre:
1. Ouvrez l'application Constat Tunisie
2. Choisissez "Rejoindre une Session"
3. Saisissez le code: ${_session.codePublic}

⏰ Délai légal: 5 jours ouvrés pour déclarer le sinistre
    ''';

    Share.share(message, subject: 'Invitation - Déclaration d\'Accident');
  }

  /// 📱 Afficher le QR Code
  void _afficherQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code de Session'),
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
                data: _session.codePublic,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Code: ${_session.codePublic}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scannez ce QR code pour rejoindre la session',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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
              Clipboard.setData(ClipboardData(text: _session.codePublic));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copié dans le presse-papiers')),
              );
            },
            child: const Text('Copier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partieAExiste = _participants.any((p) => p.partie == 'A');
    final partieBExiste = _participants.any((p) => p.partie == 'B');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Session ${_session.codePublic}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red[600],
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _partagerCode,
            icon: const Icon(Icons.share),
            tooltip: 'Partager le code',
          ),
          IconButton(
            onPressed: _afficherQRCode,
            icon: const Icon(Icons.qr_code),
            tooltip: 'Afficher QR Code',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informations de la session
            _buildSessionInfoCard(),

            const SizedBox(height: 24),

            // Code de partage
            _buildShareCodeCard(),

            const SizedBox(height: 24),

            // Participants
            _buildParticipantsSection(partieAExiste, partieBExiste),

            const SizedBox(height: 24),

            // Statut et actions
            _buildStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Informations de l\'Accident',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.location_on,
              'Lieu',
              _session.localisation['adresse'] ?? 'Non spécifié',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              'Date',
              _session.dateOuverture != null
                  ? '${_session.dateOuverture.day}/${_session.dateOuverture.month}/${_session.dateOuverture.year}'
                  : 'Non spécifiée',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time,
              'Heure',
              _session.dateOuverture != null
                  ? '${_session.dateOuverture.hour.toString().padLeft(2, '0')}:${_session.dateOuverture.minute.toString().padLeft(2, '0')}'
                  : 'Non spécifiée',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.schedule,
              'Délai légal',
              _session.isInLegalDeadline
                  ? 'Dans les délais'
                  : 'Délai dépassé',
              color: _session.isInLegalDeadline ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCodeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.share,
                  color: Colors.green[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Inviter l\'autre partie',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Code de session:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _session.codePublic,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _session.codePublic));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copié!')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copier le code',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _partagerCode,
                    icon: const Icon(Icons.share),
                    label: const Text('Partager'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _afficherQRCode,
                    icon: const Icon(Icons.qr_code),
                    label: const Text('QR Code'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection(bool partieAExiste, bool partieBExiste) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Colors.orange[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Participants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Partie A
            _buildPartieCard('A', partieAExiste),
            const SizedBox(height: 12),
            
            // Partie B
            _buildPartieCard('B', partieBExiste),
          ],
        ),
      ),
    );
  }

  Widget _buildPartieCard(String partie, bool existe) {
    final participant = _participants.firstWhere(
      (p) => p.partie == partie,
      orElse: () => AccidentParticipant(
        id: '',
        sessionId: '',
        userId: '',
        partie: partie,
        statut: '',
        nomConducteur: '',
        prenomConducteur: '',
        adresseConducteur: '',
        telephoneConducteur: '',
        marqueVehicule: '',
        typeVehicule: '',
        numeroImmatriculation: '',
        nomAssurance: '',
        numeroPolice: '',
        conducteurHabituel: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: existe ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: existe ? Colors.green[300]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: existe ? Colors.green[600] : Colors.grey[400],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                partie,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partie $partie',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  existe 
                      ? '${participant.prenomConducteur} ${participant.nomConducteur}'
                      : 'En attente...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (!existe)
            ElevatedButton(
              onPressed: _isLoading ? null : () => _rejoindreSesssion(partie),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Rejoindre'),
            )
          else
            Icon(
              Icons.check_circle,
              color: Colors.green[600],
              size: 24,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: Colors.purple[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Statut de la Session',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AccidentSessionStatut.getLibelle(_session.statut),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[800],
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

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color ?? Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
}

/// 📊 Classe pour les libellés de statut
class AccidentSessionStatut {
  static String getLibelle(String statut) {
    switch (statut) {
      case AccidentSession.STATUT_BROUILLON:
        return 'Brouillon';
      case AccidentSession.STATUT_EN_ATTENTE_INVITES:
        return 'En attente des invités';
      case AccidentSession.STATUT_PARTIES_EN_SAISIE:
        return 'Parties en saisie';
      case AccidentSession.STATUT_PRET_A_SIGNER:
        return 'Prêt à signer';
      case AccidentSession.STATUT_SIGNATURE_EN_COURS:
        return 'Signature en cours';
      case AccidentSession.STATUT_SIGNE_VALIDE:
        return 'Signé et validé';
      case AccidentSession.STATUT_TRANSMIS_AUX_ASSUREURS:
        return 'Transmis aux assureurs';
      case AccidentSession.STATUT_RETOUR_POUR_COMPLEMENT:
        return 'Retour pour complément';
      case AccidentSession.STATUT_SOUS_EXPERTISE:
        return 'Sous expertise';
      case AccidentSession.STATUT_INDEMNISE:
        return 'Indemnisé';
      case AccidentSession.STATUT_CLOTURE:
        return 'Clôturé';
      case AccidentSession.STATUT_REFUS_DE_SIGNER:
        return 'Refus de signer';
      default:
        return statut;
    }
  }
}
