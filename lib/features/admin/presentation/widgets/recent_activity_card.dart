import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/dashboard_data_provider.dart';

/// 🕒 Widget pour afficher l'activité récente
class RecentActivityCard extends ConsumerWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentActivity = ref.watch(recentActivityProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activité Récente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Naviguer vers la page complète d'activité
                  },
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contenu basé sur les données réelles
            recentActivity.when(
              data: (activities) {
                if (activities.isEmpty) {
                  return const Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Aucune activité récente',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: activities.asMap().entries.map((entry) {
                    final index = entry.key;
                    final activity = entry.value;

                    return Column(
                      children: [
                        _buildActivityItem(
                          icon: activity['icon'] as IconData,
                          color: activity['color'] as Color,
                          title: activity['title'] as String,
                          subtitle: activity['subtitle'] as String,
                          time: activity['time'] as String,
                        ),
                        if (index < activities.length - 1)
                          const Divider(height: 24),
                      ],
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Chargement de l\'activité...'),
                  ],
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(
                      'Erreur: ${error.toString()}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Row(
      children: [
        // Icône
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        
        // Contenu
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Temps
        Text(
          time,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
