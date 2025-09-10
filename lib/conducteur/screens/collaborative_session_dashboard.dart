import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/collaborative_session_state_service.dart';
import '../../models/collaborative_session_model.dart';
import 'modern_single_accident_info_screen.dart';

/// 📊 Dashboard pour suivre l'état d'une session collaborative
class CollaborativeSessionDashboard extends StatefulWidget {
  final CollaborativeSession session;

  const CollaborativeSessionDashboard({
    Key? key,
    required this.session,
  }) : super(key: key);

  @override
  State<CollaborativeSessionDashboard> createState() => _CollaborativeSessionDashboardState();
}

class _CollaborativeSessionDashboardState extends State<CollaborativeSessionDashboard> {
  Map<String, dynamic> _statutSession = {};
  Map<String, Map<String, dynamic>> _formulairesParticipants = {};
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    try {
      final statut = await CollaborativeSessionStateService.obtenirStatutSession(
        sessionId: widget.session.id!,
      );
      
      final formulaires = await CollaborativeSessionStateService.obtenirTousLesFormulaires(
        sessionId: widget.session.id!,
      );

      if (mounted) {
        setState(() {
          _statutSession = statut;
          _formulairesParticipants = formulaires;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement dashboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Session ${widget.session.codeSession}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          // Bouton pour retourner au dashboard
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Retour au dashboard',
            onPressed: () {
              _retournerAuDashboard();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargerDonnees,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatutGlobal(),
                  const SizedBox(height: 24),
                  _buildListeParticipants(),
                  const SizedBox(height: 24),
                  _buildActionsSession(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _retournerAuDashboard,
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.home),
        label: const Text('Dashboard'),
      ),
    );
  }

  Widget _buildStatutGlobal() {
    final pourcentage = _statutSession['pourcentageCompletion'] ?? 0;
    final termines = _statutSession['termines'] ?? 0;
    final total = _statutSession['totalParticipants'] ?? 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.indigo, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Progression globale',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            LinearProgressIndicator(
              value: pourcentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                pourcentage == 100 ? Colors.green : Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              '$termines/$total participants ont terminé ($pourcentage%)',
              style: const TextStyle(fontSize: 16),
            ),
            
            if (pourcentage == 100) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'Session complète ! Prêt pour génération PDF',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListeParticipants() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: Colors.indigo, size: 24),
                const SizedBox(width: 12),
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
            
            ...widget.session.participants.map((participant) {
              final formulaire = _formulairesParticipants[participant.id];
              final statut = formulaire?['statut'] ?? 'non_commence';
              final estCurrentUser = participant.id == _currentUserId;
              
              return _buildParticipantCard(participant, statut, estCurrentUser, formulaire);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCard(
    SessionParticipant participant,
    String statut,
    bool estCurrentUser,
    Map<String, dynamic>? formulaire,
  ) {
    Color couleurStatut;
    IconData iconeStatut;
    String texteStatut;

    switch (statut) {
      case 'termine':
        couleurStatut = Colors.green;
        iconeStatut = Icons.check_circle;
        texteStatut = 'Terminé';
        break;
      case 'en_cours':
        couleurStatut = Colors.orange;
        iconeStatut = Icons.pending;
        texteStatut = 'En cours';
        break;
      default:
        couleurStatut = Colors.grey;
        iconeStatut = Icons.radio_button_unchecked;
        texteStatut = 'Non commencé';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: estCurrentUser ? Colors.indigo[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estCurrentUser ? Colors.indigo[300]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: couleurStatut,
            child: Icon(iconeStatut, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${participant.nom} ${participant.prenom}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: estCurrentUser ? Colors.indigo[800] : Colors.black87,
                  ),
                ),
                Text(
                  participant.email,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  texteStatut,
                  style: TextStyle(
                    color: couleurStatut,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          if (estCurrentUser) ...[
            ElevatedButton.icon(
              onPressed: () => _ouvrirFormulaire(participant),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Mon formulaire'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ] else if (statut == 'termine') ...[
            OutlinedButton.icon(
              onPressed: () => _consulterFormulaire(participant, formulaire!),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('Consulter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsSession() {
    final sessionComplete = _statutSession['sessionComplete'] ?? false;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.indigo, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (sessionComplete) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _genererPDF,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Générer le PDF consolidé'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              Text(
                'En attente que tous les participants terminent leur formulaire...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Bouton pour retourner au dashboard
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _retournerAuDashboard,
                icon: const Icon(Icons.home),
                label: const Text('Retour au Dashboard Principal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.indigo[600],
                  side: BorderSide(color: Colors.indigo[600]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirFormulaire(SessionParticipant participant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernSingleAccidentInfoScreen(
          typeAccident: 'accident_collaboratif',
          session: widget.session,
          isCollaborative: true,
          roleVehicule: participant.roleVehicule,
          isCreator: widget.session.createurId == participant.id,
          isRegisteredUser: participant.type == ParticipantType.inscrit,
        ),
      ),
    ).then((_) => _chargerDonnees());
  }

  void _consulterFormulaire(SessionParticipant participant, Map<String, dynamic> formulaire) {
    // TODO: Implémenter la consultation en lecture seule
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Consultation du formulaire de ${participant.nom} ${participant.prenom}'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  void _genererPDF() {
    // TODO: Implémenter la génération PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération PDF en cours...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 🏠 Retourner au dashboard conducteur
  void _retournerAuDashboard() {
    // Navigation directe vers le dashboard conducteur
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/conducteur-dashboard',
      (route) => false,
    );
  }
}
