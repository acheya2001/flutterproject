import 'package:flutter/material.dart';

class AdminsAgenceSectionWidget extends StatefulWidget {
  final String compagnieId;
  final VoidCallback onRefresh;

  const AdminsAgenceSectionWidget({
    Key? key,
    required this.compagnieId,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<AdminsAgenceSectionWidget> createState() => _AdminsAgenceSectionWidgetState();
}

class _AdminsAgenceSectionWidgetState extends State<AdminsAgenceSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.admin_panel_settings_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Gestion des Admins Agence',
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
