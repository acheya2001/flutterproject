import 'package:flutter/material.dart';
import '../../../services/session_repair_service.dart';

/// 🔧 Bouton de réparation rapide pour les sessions
class SessionRepairButton extends StatefulWidget {
  final String sessionId;
  final VoidCallback? onRepaired;

  const SessionRepairButton({
    Key? key,
    required this.sessionId,
    this.onRepaired,
  }) : super(key: key);

  @override
  State<SessionRepairButton> createState() => _SessionRepairButtonState();
}

class _SessionRepairButtonState extends State<SessionRepairButton> {
  bool _isRepairing = false;
  bool _needsRepair = false;
  Map<String, dynamic>? _diagnostic;

  @override
  void initState() {
    super.initState();
    _checkIfNeedsRepair();
  }

  /// 🔍 Vérifier si la session a besoin de réparation
  Future<void> _checkIfNeedsRepair() async {
    try {
      final diagnostic = await SessionRepairService.diagnosticSession(widget.sessionId);
      
      if (mounted) {
        setState(() {
          _diagnostic = diagnostic;
          _needsRepair = diagnostic['needsRepair'] == true;
        });
      }
    } catch (e) {
      print('❌ Erreur vérification réparation: $e');
    }
  }

  /// 🔧 Réparer la session
  Future<void> _repairSession() async {
    setState(() => _isRepairing = true);

    try {
      final success = await SessionRepairService.repairSpecificSession(widget.sessionId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✅ Session réparée avec succès'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Recharger le diagnostic
        await _checkIfNeedsRepair();
        
        // Notifier le parent
        widget.onRepaired?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('❌ Échec de la réparation'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('❌ Erreur: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRepairing = false);
      }
    }
  }

  /// 📊 Afficher les détails du diagnostic
  void _showDiagnosticDetails() {
    if (_diagnostic == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 8),
            Text('🔍 Diagnostic Session'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_diagnostic!.containsKey('error'))
                Text(
                  '❌ ${_diagnostic!['error']}',
                  style: const TextStyle(color: Colors.red),
                )
              else ...[
                _buildDiagnosticRow('🚗 Véhicules attendus', '${_diagnostic!['nombreVehicules']}'),
                _buildDiagnosticRow('👥 Participants', '${(_diagnostic!['participants'] as Map)['total']}'),
                _buildDiagnosticRow('🎯 Participants invités', '${(_diagnostic!['participantsInvites'] as Map)['total']}'),
                _buildDiagnosticRow('📋 Formulaires (progression)', '${(_diagnostic!['progression'] as Map)['formulairesTermines'] ?? 0}'),
                _buildDiagnosticRow('📋 Formulaires (collection)', '${(_diagnostic!['formulairesTermines'] as Map)['dansCollection']}'),
                _buildDiagnosticRow('📊 Progression', '${(_diagnostic!['progression'] as Map)['pourcentage'] ?? 0}%'),
                _buildDiagnosticRow('🔄 Statut', '${_diagnostic!['statut']}'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _needsRepair ? Colors.orange[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _needsRepair ? Colors.orange[200]! : Colors.green[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _needsRepair ? Icons.warning : Icons.check_circle,
                        color: _needsRepair ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _needsRepair ? 'Réparation nécessaire' : 'Session OK',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _needsRepair ? Colors.orange[700] : Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (_needsRepair)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _repairSession();
              },
              icon: const Icon(Icons.build, size: 16),
              label: const Text('Réparer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_needsRepair && _diagnostic != null) {
      // Session OK, pas besoin d'afficher le bouton
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700]),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Problème de comptage détecté',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Les participants ne sont pas correctement comptabilisés',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _showDiagnosticDetails,
                icon: const Icon(Icons.info, size: 16),
                label: const Text('Détails'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange[700],
                  side: BorderSide(color: Colors.orange[300]!),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isRepairing ? null : _repairSession,
                icon: _isRepairing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.build, size: 16),
                label: Text(_isRepairing ? 'Réparation...' : 'Réparer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
