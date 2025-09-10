import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/contract_number_service.dart';

/// 🔢 Widget pour afficher et gérer le numéro de contrat automatique
class ContractNumberWidget extends StatefulWidget {
  final String compagnieId;
  final String agenceId;
  final String? typeContrat;
  final Function(String) onNumberGenerated;
  final String? initialNumber;

  const ContractNumberWidget({
    Key? key,
    required this.compagnieId,
    required this.agenceId,
    this.typeContrat,
    required this.onNumberGenerated,
    this.initialNumber,
  }) : super(key: key);

  @override
  State<ContractNumberWidget> createState() => _ContractNumberWidgetState();
}

class _ContractNumberWidgetState extends State<ContractNumberWidget> {
  String? _numeroContrat;
  bool _isGenerating = false;
  bool _isUnique = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    if (widget.initialNumber != null) {
      _numeroContrat = widget.initialNumber;
      _checkUniqueness();
    } else {
      _generateNumber();
    }
    _loadStats();
  }

  /// 🔢 Générer un nouveau numéro de contrat
  Future<void> _generateNumber() async {
    setState(() => _isGenerating = true);

    try {
      final numero = await ContractNumberService.generateUniqueContractNumber(
        compagnieId: widget.compagnieId,
        agenceId: widget.agenceId,
        typeContrat: widget.typeContrat,
      );

      if (mounted) setState(() {
        _numeroContrat = numero;
        _isUnique = true;
      });

      widget.onNumberGenerated(numero);
      await _loadStats();
    } catch (e) {
      print('❌ Erreur génération numéro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la génération: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  /// 🔍 Vérifier l'unicité du numéro
  Future<void> _checkUniqueness() async {
    if (_numeroContrat == null) return;

    final isUnique = await ContractNumberService.isContractNumberUnique(_numeroContrat!);
    setState(() => _isUnique = isUnique);
  }

  /// 📊 Charger les statistiques
  Future<void> _loadStats() async {
    try {
      final stats = await ContractNumberService.getContractNumberStats(
        compagnieId: widget.compagnieId,
        agenceId: widget.agenceId,
      );
      setState(() => _stats = stats);
    } catch (e) {
      print('❌ Erreur chargement stats: $e');
    }
  }

  /// 📋 Copier le numéro dans le presse-papiers
  void _copyToClipboard() {
    if (_numeroContrat != null) {
      Clipboard.setData(ClipboardData(text: _numeroContrat!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Numéro copié dans le presse-papiers'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.confirmation_number,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Numéro de Contrat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      'Généré automatiquement',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _isGenerating ? null : _generateNumber,
                icon: _isGenerating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue.shade600,
                        ),
                      )
                    : Icon(
                        Icons.refresh,
                        color: Colors.blue.shade600,
                      ),
                tooltip: 'Générer un nouveau numéro',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Numéro de contrat
          if (_numeroContrat != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isUnique ? Colors.white : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isUnique ? Colors.blue.shade200 : Colors.red.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isUnique ? Icons.check_circle : Icons.warning,
                    color: _isUnique ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _numeroContrat!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isUnique ? Colors.blue.shade800 : Colors.red.shade800,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          _isUnique ? 'Numéro unique ✓' : 'Attention: Numéro déjà utilisé !',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isUnique ? Colors.green.shade600 : Colors.red.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _copyToClipboard,
                    icon: Icon(
                      Icons.copy,
                      color: Colors.blue.shade600,
                      size: 18,
                    ),
                    tooltip: 'Copier',
                  ),
                ],
              ),
            ),
          ],

          // Statistiques
          if (_stats != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Ce mois',
                      '${_stats!['contratsThisMonth']}',
                      Icons.calendar_month,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Cette année',
                      '${_stats!['contratsThisYear']}',
                      Icons.calendar_today,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Prochain',
                      '#${_stats!['nextMonthlyNumber']}',
                      Icons.arrow_forward,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 📊 Construire un item de statistique
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

