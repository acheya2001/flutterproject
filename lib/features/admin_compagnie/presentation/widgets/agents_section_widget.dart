import 'package:flutter/material.dart';

class AgentsSectionWidget extends StatefulWidget {
  final String compagnieId;
  final VoidCallback onRefresh;

  const AgentsSectionWidget({
    Key? key,
    required this.compagnieId,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<AgentsSectionWidget> createState() => _AgentsSectionWidgetState();
}

class _AgentsSectionWidgetState extends State<AgentsSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Gestion des Agents',
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
