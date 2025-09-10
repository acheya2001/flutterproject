import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../conducteur/screens/modern_accident_type_screen.dart';
import '../../../conducteur/screens/modern_join_session_screen.dart';

/// 🎯 Onglet Sinistres complètement refait et propre
class SinistresTabClean extends StatefulWidget {
  const SinistresTabClean({Key? key}) : super(key: key);

  @override
  State<SinistresTabClean> createState() => _SinistresTabCleanState();
}

class _SinistresTabCleanState extends State<SinistresTabClean> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mes Sinistres'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _declareAccident,
            tooltip: 'Déclarer un accident',
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('collaborative_sessions')
          .where('participants', arrayContains: FirebaseAuth.instance.currentUser?.uid)
          .orderBy('dateCreation', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        print('🔍 [SINISTRES CLEAN] Stream state: ${snapshot.connectionState}');
        
        if (snapshot.hasError) {
          print('🔍 [SINISTRES CLEAN] Erreur: ${snapshot.error}');
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = snapshot.data?.docs ?? [];
        print('🔍 [SINISTRES CLEAN] Sessions trouvées: ${sessions.length}');

        if (sessions.isEmpty) {
          return _buildEmptyState();
        }

        return _buildSessionsList(sessions);
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text('Erreur: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune session collaborative',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première déclaration d\'accident',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _declareAccident,
            icon: const Icon(Icons.add),
            label: const Text('Déclarer un accident'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(List<QueryDocumentSnapshot> sessions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final data = session.data() as Map<String, dynamic>;
        
        print('🔍 [SINISTRES CLEAN] Session ${session.id}: $data');
        
        return _buildSessionCard(session.id, data);
      },
    );
  }

  Widget _buildSessionCard(String sessionId, Map<String, dynamic> data) {
    final codeSession = data['codeSession'] ?? 'N/A';
    final statutSession = data['statutSession'] ?? 'inconnu';
    final dateCreation = data['dateCreation'] as Timestamp?;
    final participants = data['participants'] as List? ?? [];
    final nombreVehicules = data['nombreVehicules'] ?? 0;
    
    print('🔍 [SINISTRES CLEAN] Carte session $sessionId:');
    print('  - Code: $codeSession');
    print('  - Statut: $statutSession');
    print('  - Participants: ${participants.length}');
    print('  - Véhicules: $nombreVehicules');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '# $codeSession',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const Spacer(),
                _buildStatusChip(statutSession),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${participants.length} participants'),
                const SizedBox(width: 16),
                Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('$nombreVehicules véhicules'),
              ],
            ),
            if (dateCreation != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy à HH:mm').format(dateCreation.toDate()),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _voirDetailsSession(sessionId, data),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Détails'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _rejoindreSesssion,
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String statut) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (statut.toLowerCase()) {
      case 'en_attente_participants':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        label = 'En attente';
        break;
      case 'en_cours':
      case 'en_cours_remplissage':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        label = 'En cours';
        break;
      case 'termine':
      case 'finalise':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        label = 'Terminé';
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        label = statut;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  void _declareAccident() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModernAccidentTypeScreen(),
      ),
    );
  }

  void _rejoindreSesssion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModernJoinSessionScreen(),
      ),
    );
  }

  void _voirDetailsSession(String sessionId, Map<String, dynamic> data) {
    print('🔍 [SINISTRES CLEAN] Voir détails session: $sessionId');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Détails de la session $sessionId')),
    );
  }
}
