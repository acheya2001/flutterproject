import 'package:flutter/material.dart';

class SinistresSectionWidget extends StatefulWidget {
  final String compagnieId;
  final VoidCallback onRefresh;

  const SinistresSectionWidget({
    Key? key,
    required this.compagnieId,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<SinistresSectionWidget> createState() => _SinistresSectionWidgetState();
}

class _SinistresSectionWidgetState extends State<SinistresSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Gestion des Sinistres',
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
