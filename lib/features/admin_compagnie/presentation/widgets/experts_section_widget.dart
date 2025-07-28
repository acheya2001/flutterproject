import 'package:flutter/material.dart';

class ExpertsSectionWidget extends StatefulWidget {
  final String compagnieId;
  final VoidCallback onRefresh;

  const ExpertsSectionWidget({
    Key? key,
    required this.compagnieId,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<ExpertsSectionWidget> createState() => _ExpertsSectionWidgetState();
}

class _ExpertsSectionWidgetState extends State<ExpertsSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.engineering_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Gestion des Experts',
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
