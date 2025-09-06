import 'package:flutter/material.dart';
import '../../../services/admin_agence_alerts_service.dart';

/// 🚨 Widget pour afficher les alertes de l'agence
class AlertsPanel extends StatefulWidget {
  final String agenceId;
  final VoidCallback? onAlertTap;

  const AlertsPanel({
    Key? key,
    required this.agenceId,
    this.onAlertTap,
  }) : super(key: key);

  @override
  State<AlertsPanel> createState() => _AlertsPanelState();
}

class _AlertsPanelState extends State<AlertsPanel> {
  Map<String, dynamic>? _alerts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  /// 🚨 Charger les alertes
  Future<void> _loadAlerts() async {
    try {
      final alerts = await AdminAgenceAlertsService.getAgenceAlerts(widget.agenceId);
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[ALERTS_PANEL] ❌ Erreur chargement: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_alerts == null) {
      return _buildErrorState();
    }

    final summary = _alerts!['summary'] as Map<String, dynamic>;
    
    if (summary['total'] == 0) {
      return _buildNoAlertsState();
    }

    return _buildAlertsContent();
  }

  /// ⏳ État de chargement
  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// ❌ État d'erreur
  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.grey.shade400,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Aucune alerte
  Widget _buildNoAlertsState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF10B981),
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Aucune alerte',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tout fonctionne parfaitement !',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// 🚨 Contenu des alertes
  Widget _buildAlertsContent() {
    final summary = _alerts!['summary'] as Map<String, dynamic>;
    final expiringContracts = _alerts!['expiringContracts'] as List<dynamic>;
    final performanceAlerts = _alerts!['performance'] as List<dynamic>;
    final financialAlerts = _alerts!['financial'] as List<dynamic>;
    final systemAlerts = _alerts!['system'] as List<dynamic>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec résumé
          _buildAlertsHeader(summary),
          const SizedBox(height: 16),

          // Alertes urgentes
          if (summary['high'] > 0) ...[
            _buildAlertSection(
              'Alertes Urgentes',
              Icons.warning_rounded,
              const Color(0xFFEF4444),
              [...expiringContracts, ...performanceAlerts, ...financialAlerts, ...systemAlerts]
                  .where((alert) => alert['severity'] == 'high')
                  .take(3)
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Contrats expirants
          if (expiringContracts.isNotEmpty) ...[
            _buildAlertSection(
              'Contrats Expirants',
              Icons.schedule_rounded,
              const Color(0xFFF59E0B),
              expiringContracts.take(3).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Bouton voir tout
          if (summary['total'] > 3)
            Center(
              child: TextButton(
                onPressed: widget.onAlertTap,
                child: Text(
                  'Voir toutes les alertes (${summary['total']})',
                  style: const TextStyle(
                    color: Color(0xFF667EEA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 📊 Header des alertes
  Widget _buildAlertsHeader(Map<String, dynamic> summary) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: summary['hasUrgentAlerts'] 
                ? const Color(0xFFEF4444).withOpacity(0.1)
                : const Color(0xFFF59E0B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            summary['hasUrgentAlerts'] ? Icons.warning_rounded : Icons.info_outline,
            color: summary['hasUrgentAlerts'] 
                ? const Color(0xFFEF4444)
                : const Color(0xFFF59E0B),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${summary['total']} Alertes',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                summary['hasUrgentAlerts'] 
                    ? '${summary['high']} urgentes, ${summary['medium']} modérées'
                    : 'Surveillance recommandée',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loadAlerts,
          icon: const Icon(Icons.refresh_rounded),
          iconSize: 20,
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  /// 📋 Section d'alertes
  Widget _buildAlertSection(
    String title,
    IconData icon,
    Color color,
    List<dynamic> alerts,
  ) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...alerts.map((alert) => _buildAlertItem(alert)).toList(),
      ],
    );
  }

  /// 🚨 Item d'alerte
  Widget _buildAlertItem(Map<String, dynamic> alert) {
    final severity = alert['severity'] as String;
    final color = _getSeverityColor(severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'] ?? 'Alerte',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (alert['message'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    alert['message'],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (alert['daysUntilExpiry'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${alert['daysUntilExpiry']}j',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 🎨 Couleur selon la sévérité
  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF3B82F6);
      default:
        return Colors.grey;
    }
  }
}
