import 'package:flutter/material.dart';

class ParametresSectionWidget extends StatefulWidget {
  final String compagnieId;
  final VoidCallback onRefresh;

  const ParametresSectionWidget({
    Key? key,
    required this.compagnieId,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<ParametresSectionWidget> createState() => _ParametresSectionWidgetState();
}

class _ParametresSectionWidgetState extends State<ParametresSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Paramètres de la Compagnie',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Section en cours de développement',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
