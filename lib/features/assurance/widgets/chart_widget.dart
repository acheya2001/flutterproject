import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 📈 Widget graphiques pour le dashboard assureur
class ChartWidget extends StatefulWidget {
  final String compagnieId;
  final Color color;

  const ChartWidget({
    super.key,
    required this.compagnieId,
    required this.color,
  });

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<ChartData> _evolutionData = [];
  List<ChartData> _repartitionData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
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
              children: [
                Icon(Icons.bar_chart, color: widget.color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Évolution des Sinistres',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadChartData,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Graphique en barres simple
              _buildSimpleBarChart(),
              
              const SizedBox(height: 20),
              
              // Répartition par type
              _buildPieChartLegend(),
            ],
          ],
        ),
      ),
    );
  }

  /// 📊 Graphique en barres simple
  Widget _buildSimpleBarChart() {
    if (_evolutionData.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    final maxValue = _evolutionData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _evolutionData.map((data) {
          final height = (data.value / maxValue) * 160;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Valeur
                  Text(
                    data.value.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Barre
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Label
                  Text(
                    data.label,
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 🥧 Légende du graphique circulaire
  Widget _buildPieChartLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Répartition par Gravité',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: widget.color,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildLegendItem('Léger', Colors.green, 45),
            ),
            Expanded(
              child: _buildLegendItem('Modéré', Colors.orange, 35),
            ),
            Expanded(
              child: _buildLegendItem('Grave', Colors.red, 20),
            ),
          ],
        ),
      ],
    );
  }

  /// 📋 Item de légende
  Widget _buildLegendItem(String label, Color color, int percentage) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  /// 📊 Charger les données des graphiques
  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Générer des données d'évolution simulées
      final now = DateTime.now();
      final evolutionData = <ChartData>[];
      
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthName = _getMonthName(month.month);
        
        // Simuler des données basées sur le mois
        final value = 20 + (i * 5) + (month.month % 3) * 10;
        
        evolutionData.add(ChartData(
          label: monthName,
          value: value.toDouble(),
        ));
      }

      // Données de répartition simulées
      final repartitionData = [
        ChartData(label: 'Léger', value: 45),
        ChartData(label: 'Modéré', value: 35),
        ChartData(label: 'Grave', value: 20),
      ];

      setState(() {
        _evolutionData = evolutionData;
        _repartitionData = repartitionData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Erreur lors du chargement des graphiques: $e');
    }
  }

  /// 📅 Obtenir le nom du mois
  String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return months[month];
  }
}

/// 📊 Modèle de données pour les graphiques
class ChartData {
  final String label;
  final double value;

  ChartData({
    required this.label,
    required this.value,
  });
}

/// 📈 Widget graphique linéaire simple
class SimpleLineChart extends StatelessWidget {
  final List<ChartData> data;
  final Color color;
  final double height;

  const SimpleLineChart({
    super.key,
    required this.data,
    required this.color,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('Aucune donnée'),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: LineChartPainter(data: data, color: color),
        child: Container(),
      ),
    );
  }
}

/// 🎨 Painter pour le graphique linéaire
class LineChartPainter extends CustomPainter {
  final List<ChartData> data;
  final Color color;

  LineChartPainter({
    required this.data,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final valueRange = maxValue - minValue;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i].value - minValue) / valueRange) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Dessiner les points
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
