import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SessionInvitationCard extends StatelessWidget {
  final String sessionCode;
  final String lieuAccident;
  final DateTime dateCreation;
  final int nombreConducteurs;
  final int conducteursRejoints;
  final bool isComplete;
  final VoidCallback? onJoin;
  final VoidCallback? onShare;

  const SessionInvitationCard({
    super.key,
    required this.sessionCode,
    required this.lieuAccident,
    required this.dateCreation,
    required this.nombreConducteurs,
    required this.conducteursRejoints,
    this.isComplete = false,
    this.onJoin,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec code de session
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Session $sessionCode',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                GestureDetector(
                  onTap: () => _copyToClipboard(context, sessionCode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.copy,
                          size: 16,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sessionCode,
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Informations de l'accident
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lieuAccident,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  _formatDate(dateCreation),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progression des conducteurs
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  'Conducteurs',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '$conducteursRejoints/$nombreConducteurs',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            LinearProgressIndicator(
              value: nombreConducteurs > 0 ? conducteursRejoints / nombreConducteurs : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              ),
            ),

            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                if (onShare != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Partager'),
                    ),
                  ),
                if (onShare != null && onJoin != null) const SizedBox(width: 12),
                if (onJoin != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isComplete ? null : onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isComplete
                            ? const Color(0xFF10B981)
                            : const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isComplete ? 'Terminé' : 'Rejoindre'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code $text copié'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Aujourd\'hui ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateOnly == yesterday) {
      return 'Hier ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}