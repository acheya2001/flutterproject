import 'package:flutter/material.dart';
import '../../models/accident_session.dart';
import '../../models/vehicule_model.dart';

/// 📧 Écran 3 - Invitations (temporaire)
class AccidentInvitationsScreen extends StatefulWidget {
  final AccidentSession session;
  final VehiculeModel vehiculeCreateur;

  const AccidentInvitationsScreen({
    Key? key,
    required this.session,
    required this.vehiculeCreateur,
  }) : super(key: key);

  @override
  State<AccidentInvitationsScreen> createState() => _AccidentInvitationsScreenState();
}

class _AccidentInvitationsScreenState extends State<AccidentInvitationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Invitations',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Écran en construction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Session créée: ${widget.session.codePublic}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
