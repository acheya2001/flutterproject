import 'package:flutter/material.dart';

/// 📊 Widget carte KPI pour le dashboard assureur
class KPICardWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final VoidCallback? onTap;

  const KPICardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.05),
                color.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec icône
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  if (trend != null) _buildTrendIndicator(),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Valeur principale
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Titre
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📈 Indicateur de tendance
  Widget _buildTrendIndicator() {
    if (trend == null) return const SizedBox();
    
    final isPositive = trend!.startsWith('+');
    final isNegative = trend!.startsWith('-');
    
    Color trendColor;
    IconData trendIcon;
    
    if (isPositive) {
      trendColor = Colors.green;
      trendIcon = Icons.trending_up;
    } else if (isNegative) {
      trendColor = Colors.red;
      trendIcon = Icons.trending_down;
    } else {
      trendColor = Colors.grey;
      trendIcon = Icons.trending_flat;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trendIcon,
            color: trendColor,
            size: 12,
          ),
          const SizedBox(width: 2),
          Text(
            trend!,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: trendColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 📊 Widget KPI étendu avec plus de détails
class ExtendedKPICardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? trend;
  final List<KPIDetail>? details;
  final VoidCallback? onTap;

  const ExtendedKPICardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
    this.details,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.05),
                color.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (trend != null) _buildTrendIndicator(),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Valeur principale
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Titre
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Sous-titre
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              
              // Détails supplémentaires
              if (details != null && details!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                ...details!.map((detail) => _buildDetailRow(detail)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 📈 Indicateur de tendance
  Widget _buildTrendIndicator() {
    if (trend == null) return const SizedBox();
    
    final isPositive = trend!.startsWith('+');
    final isNegative = trend!.startsWith('-');
    
    Color trendColor;
    IconData trendIcon;
    
    if (isPositive) {
      trendColor = Colors.green;
      trendIcon = Icons.trending_up;
    } else if (isNegative) {
      trendColor = Colors.red;
      trendIcon = Icons.trending_down;
    } else {
      trendColor = Colors.grey;
      trendIcon = Icons.trending_flat;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trendIcon,
            color: trendColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            trend!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: trendColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Ligne de détail
  Widget _buildDetailRow(KPIDetail detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            detail.icon,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Text(
            detail.label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            detail.value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// 📋 Modèle pour les détails KPI
class KPIDetail {
  final String label;
  final String value;
  final IconData icon;

  KPIDetail({
    required this.label,
    required this.value,
    required this.icon,
  });
}

/// 📊 Widget grille de KPIs
class KPIGridWidget extends StatelessWidget {
  final List<KPIData> kpis;
  final int crossAxisCount;
  final double childAspectRatio;

  const KPIGridWidget({
    super.key,
    required this.kpis,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        final kpi = kpis[index];
        return KPICardWidget(
          title: kpi.title,
          value: kpi.value,
          icon: kpi.icon,
          color: kpi.color,
          trend: kpi.trend,
          onTap: kpi.onTap,
        );
      },
    );
  }
}

/// 📊 Modèle de données KPI
class KPIData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final VoidCallback? onTap;

  KPIData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.onTap,
  });
}
