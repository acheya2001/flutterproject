import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/accident_session.dart';

/// 📧 Écran de gestion des invitations pour conducteurs non-inscrits
class InvitationManagementScreen extends StatefulWidget {
  final AccidentSession session;

  const InvitationManagementScreen({
    super.key,
    required this.session,
  });

  @override
  State<InvitationManagementScreen> createState() => _InvitationManagementScreenState();
}

class _InvitationManagementScreenState extends State<InvitationManagementScreen> {
  final Map<String, TextEditingController> _telephoneControllers = {};
  final Map<String, TextEditingController> _emailControllers = {};
  final Map<String, bool> _invitationEnvoyee = {};

  @override
  void initState() {
    super.initState();
    _initialiserControllers();
  }

  void _initialiserControllers() {
    for (int i = 1; i < widget.session.nombreParticipants; i++) {
      final role = String.fromCharCode(65 + i); // B, C, D, E
      _telephoneControllers[role] = TextEditingController();
      _emailControllers[role] = TextEditingController();
      _invitationEnvoyee[role] = false;
    }
  }

  @override
  void dispose() {
    _telephoneControllers.values.forEach((controller) => controller.dispose());
    _emailControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inviter les Conducteurs'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // En-tête avec code de session
          _buildSessionHeader(),
          
          // Liste des invitations
          Expanded(
            child: _buildInvitationsList(),
          ),
          
          // Actions en bas
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildSessionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[200]!),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.share, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Code de Session',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.session.codePublic,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _copierCode,
                icon: const Icon(Icons.copy),
                tooltip: 'Copier le code',
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Text(
              'Les autres conducteurs peuvent rejoindre avec ce code depuis l\'écran d\'accueil de l\'application.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.session.nombreParticipants - 1, // Exclure le créateur (A)
      itemBuilder: (context, index) {
        final role = String.fromCharCode(66 + index); // B, C, D, E
        return _buildInvitationCard(role);
      },
    );
  }

  Widget _buildInvitationCard(String role) {
    final telephoneController = _telephoneControllers[role]!;
    final emailController = _emailControllers[role]!;
    final invitationEnvoyee = _invitationEnvoyee[role] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête du véhicule
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: invitationEnvoyee ? Colors.green[600] : Colors.blue[600],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        role,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Véhicule $role',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          invitationEnvoyee 
                              ? 'Invitation envoyée'
                              : 'En attente d\'invitation',
                          style: TextStyle(
                            fontSize: 14,
                            color: invitationEnvoyee ? Colors.green[700] : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (invitationEnvoyee)
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 24,
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Formulaire d'invitation
              if (!invitationEnvoyee) ...[
                TextFormField(
                  controller: telephoneController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    hintText: '+216 XX XXX XXX',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (optionnel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    hintText: 'exemple@email.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                
                const SizedBox(height: 16),
                
                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _partagerCode(role),
                        icon: const Icon(Icons.share),
                        label: const Text('Partager Code'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: telephoneController.text.isNotEmpty 
                            ? () => _envoyerInvitation(role)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.send),
                        label: const Text('Envoyer'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Invitation déjà envoyée
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Invitation envoyée',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Téléphone: ${telephoneController.text}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (emailController.text.isNotEmpty)
                              Text(
                                'Email: ${emailController.text}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _renvoyerInvitation(role),
                        child: const Text('Renvoyer'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Informations importantes
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange[600]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Les conducteurs non-inscrits pourront remplir leur partie sans créer de compte.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Bouton de partage global
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _partagerCodeGlobal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.share),
              label: const Text(
                'Partager le Code de Session',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Actions
  void _copierCode() {
    Clipboard.setData(ClipboardData(text: widget.session.codePublic));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copié dans le presse-papiers'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _partagerCode(String role) {
    final message = '''
🚗 Invitation Constat d'Accident

Vous êtes invité à participer au constat d'accident.

Code de session: ${widget.session.codePublic}
Votre rôle: Véhicule $role

📱 Pour rejoindre:
1. Téléchargez l'app "Constat Tunisie"
2. Choisissez "Rejoindre une session"
3. Saisissez le code: ${widget.session.codePublic}

⚠️ Important: Vous devez remplir votre partie dans les 5 jours.
''';

    Share.share(message, subject: 'Invitation Constat d\'Accident');
  }

  void _partagerCodeGlobal() {
    final message = '''
🚗 Session de Constat d'Accident

Code de session: ${widget.session.codePublic}
Nombre de véhicules: ${widget.session.nombreParticipants}

📱 Pour rejoindre:
1. Téléchargez l'app "Constat Tunisie"
2. Choisissez "Rejoindre une session"
3. Saisissez le code: ${widget.session.codePublic}

⚠️ Chaque conducteur doit remplir sa propre partie.
''';

    Share.share(message, subject: 'Session Constat d\'Accident');
  }

  Future<void> _envoyerInvitation(String role) async {
    final telephone = _telephoneControllers[role]!.text.trim();
    final email = _emailControllers[role]!.text.trim();

    if (telephone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un numéro de téléphone'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Afficher le loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // TODO: Implémenter l'envoi SMS/Email via Firebase Functions
      await Future.delayed(const Duration(seconds: 2)); // Simulation

      // Fermer le loading
      Navigator.pop(context);

      // Marquer comme envoyée
      if (mounted) setState(() {
        _invitationEnvoyee[role] = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitation envoyée au véhicule $role'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      // Fermer le loading
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _renvoyerInvitation(String role) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renvoyer l\'invitation'),
        content: Text('Voulez-vous renvoyer l\'invitation au véhicule $role ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Renvoyer'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _envoyerInvitation(role);
    }
  }
}

