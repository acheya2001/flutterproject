import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/session_repair_service.dart';

/// 🔧 Écran de diagnostic et réparation des sessions
class SessionDiagnosticScreen extends StatefulWidget {
  const SessionDiagnosticScreen({Key? key}) : super(key: key);

  @override
  State<SessionDiagnosticScreen> createState() => _SessionDiagnosticScreenState();
}

class _SessionDiagnosticScreenState extends State<SessionDiagnosticScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _sessions = [];
  Map<String, Map<String, dynamic>> _diagnostics = {};

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  /// 📋 Charger les sessions
  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);

    try {
      final sessionsQuery = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .orderBy('dateCreation', descending: true)
          .limit(50)
          .get();

      _sessions = sessionsQuery.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      setState(() {});
    } catch (e) {
      print('❌ Erreur chargement sessions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔍 Diagnostiquer une session
  Future<void> _diagnosticSession(String sessionId) async {
    try {
      final diagnostic = await SessionRepairService.diagnosticSession(sessionId);
      setState(() {
        _diagnostics[sessionId] = diagnostic;
      });
    } catch (e) {
      print('❌ Erreur diagnostic: $e');
    }
  }

  /// 🔧 Réparer une session
  Future<void> _repairSession(String sessionId) async {
    try {
      final success = await SessionRepairService.repairSpecificSession(sessionId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Session $sessionId réparée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recharger le diagnostic
        await _diagnosticSession(sessionId);
        await _loadSessions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Échec de la réparation de la session $sessionId'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur réparation: $e');
    }
  }

  /// 🚀 Réparer toutes les sessions
  Future<void> _repairAllSessions() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔧 Réparation globale'),
        content: const Text('Voulez-vous réparer toutes les sessions avec des problèmes de comptage ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Réparer tout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      
      try {
        await SessionRepairService.repairAllSessions();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Toutes les sessions ont été réparées'),
            backgroundColor: Colors.green,
          ),
        );
        
        await _loadSessions();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur réparation globale: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Diagnostic Sessions'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _repairAllSessions,
            icon: const Icon(Icons.build),
            tooltip: 'Réparer toutes les sessions',
          ),
          IconButton(
            onPressed: _loadSessions,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                final sessionId = session['id'] as String;
                final diagnostic = _diagnostics[sessionId];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(
                      'Session ${sessionId.substring(0, 8)}...',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Statut: ${session['statut'] ?? 'Inconnu'}'),
                        Text('Participants: ${(session['participants'] as List?)?.length ?? 0}/${session['nombreVehicules'] ?? 2}'),
                        if (diagnostic != null && diagnostic['needsRepair'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '⚠️ Nécessite réparation',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _diagnosticSession(sessionId),
                                  icon: const Icon(Icons.search, size: 16),
                                  label: const Text('Diagnostiquer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (diagnostic != null && diagnostic['needsRepair'] == true)
                                  ElevatedButton.icon(
                                    onPressed: () => _repairSession(sessionId),
                                    icon: const Icon(Icons.build, size: 16),
                                    label: const Text('Réparer'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                            if (diagnostic != null) ...[
                              const SizedBox(height: 16),
                              _buildDiagnosticDetails(diagnostic),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  /// 📊 Construire les détails du diagnostic
  Widget _buildDiagnosticDetails(Map<String, dynamic> diagnostic) {
    if (diagnostic.containsKey('error')) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Text(
          '❌ ${diagnostic['error']}',
          style: TextStyle(color: Colors.red[700]),
        ),
      );
    }

    final participants = diagnostic['participants'] as Map<String, dynamic>;
    final participantsInvites = diagnostic['participantsInvites'] as Map<String, dynamic>;
    final formulairesTermines = diagnostic['formulairesTermines'] as Map<String, dynamic>;
    final progression = diagnostic['progression'] as Map<String, dynamic>;
    final needsRepair = diagnostic['needsRepair'] as bool;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: needsRepair ? Colors.orange[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: needsRepair ? Colors.orange[200]! : Colors.green[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            needsRepair ? '⚠️ Problèmes détectés' : '✅ Session OK',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: needsRepair ? Colors.orange[700] : Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          Text('🚗 Véhicules attendus: ${diagnostic['nombreVehicules']}'),
          Text('👥 Participants: ${participants['total']}'),
          Text('🎯 Participants invités: ${participantsInvites['total']}'),
          Text('📋 Formulaires terminés (progression): ${progression['formulairesTermines'] ?? 0}'),
          Text('📋 Formulaires terminés (collection): ${formulairesTermines['dansCollection']}'),
          Text('📊 Progression: ${progression['pourcentage'] ?? 0}%'),
          Text('🔄 Statut: ${diagnostic['statut']}'),
        ],
      ),
    );
  }
}
