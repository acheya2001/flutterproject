import 'package:flutter/material.dart';
import '../../models/accident_session_complete.dart';
import '../../services/accident_session_complete_service.dart';
import 'accident_form_step1_infos_generales.dart';
import 'vehicle_selection_for_session_screen.dart';

/// ⏳ Écran d'attente et de synchronisation des conducteurs
class SessionWaitingScreen extends StatefulWidget {
  final AccidentSessionComplete session;

  const SessionWaitingScreen({
    super.key,
    required this.session,
  });

  @override
  State<SessionWaitingScreen> createState() => _SessionWaitingScreenState();
}

class _SessionWaitingScreenState extends State<SessionWaitingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  AccidentSessionComplete? _sessionActuelle;

  @override
  void initState() {
    super.initState();
    _sessionActuelle = widget.session;
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
              Colors.green[400]!,
              Colors.blue[600]!,
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<AccidentSessionComplete?>(
            stream: AccidentSessionCompleteService.ecouterSession(widget.session.id),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                _sessionActuelle = snapshot.data!;
              }

              return Column(
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
                      child: _buildContenu(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Icône de synchronisation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.sync,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          const Text(
            'Session synchronisée',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Code: ${_sessionActuelle?.codeSession ?? ''}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Message de confirmation
          _buildMessageConfirmation(),
          
          const SizedBox(height: 30),
          
          // Liste des conducteurs connectés
          _buildListeConducteurs(),
          
          const SizedBox(height: 30),
          
          // Informations de la session
          _buildInfosSession(),
          
          const SizedBox(height: 30),
          
          // Instructions
          _buildInstructions(),
          
          const SizedBox(height: 30),
          
          // Bouton commencer
          _buildBoutonCommencer(),
        ],
      ),
    );
  }

  Widget _buildMessageConfirmation() {
    final tousConnectes = (_sessionActuelle?.conducteurs.length ?? 0) >=
                         (_sessionActuelle?.nombreVehicules ?? 1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tousConnectes ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tousConnectes ? Colors.green[200]! : Colors.blue[200]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            tousConnectes ? Icons.check_circle : Icons.people,
            color: tousConnectes ? Colors.green[600] : Colors.blue[600],
            size: 48,
          ),

          const SizedBox(height: 16),

          Text(
            tousConnectes
                ? 'Tous les conducteurs sont connectés !'
                : 'Session créée avec succès !',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tousConnectes ? Colors.green : Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            tousConnectes
                ? 'Vous pouvez maintenant commencer à remplir la déclaration d\'accident ensemble.'
                : 'Vous pouvez commencer à remplir votre partie du constat. Les autres conducteurs pourront rejoindre plus tard.',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListeConducteurs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conducteurs connectés (${_sessionActuelle?.conducteurs.length ?? 0})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          ...(_sessionActuelle?.conducteurs ?? []).map((conducteur) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  // Avatar du véhicule
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        conducteur.roleVehicule,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Infos conducteur
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${conducteur.prenom} ${conducteur.nom}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Véhicule ${conducteur.roleVehicule}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Statut
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: conducteur.estCreateur ? Colors.orange[100] : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      conducteur.estCreateur ? 'CRÉATEUR' : 'CONNECTÉ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: conducteur.estCreateur ? Colors.orange[700] : Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInfosSession() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations de la session',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoRow('Type d\'accident', _sessionActuelle?.typeAccident ?? ''),
          _buildInfoRow('Nombre de véhicules', '${_sessionActuelle?.nombreVehicules ?? 0}'),
          _buildInfoRow('Statut', _sessionActuelle?.statut ?? ''),
          _buildInfoRow('Créé le', _formatDate(_sessionActuelle?.dateCreation)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.amber[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Instructions importantes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            '• Chaque conducteur ne peut modifier que les informations de son véhicule\n'
            '• Les informations générales sont partagées entre tous\n'
            '• Toutes les modifications sont synchronisées en temps réel\n'
            '• La signature finale est requise de tous les conducteurs',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoutonCommencer() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _commencerDeclaration,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, size: 24),
            SizedBox(width: 8),
            Text(
              'Commencer la déclaration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _commencerDeclaration() {
    // Naviguer vers l'écran de sélection de véhicule pour conducteurs inscrits
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleSelectionForSessionScreen(
          session: _sessionActuelle!,
        ),
      ),
    );
  }
}
