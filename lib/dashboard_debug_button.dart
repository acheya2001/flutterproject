import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:constat_tunisie/presentation/screens/debug/debug_screen.dart';

class DashboardDebugButton extends StatelessWidget {
  final Logger _logger = Logger();
  
  // Utiliser super.key au lieu de key: key
  DashboardDebugButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        _logger.d('Accès au mode débogage');
        Navigator.of(context).pushNamed('/debug');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withAlpha(77)), // Utiliser withAlpha au lieu de withOpacity
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bug_report, size: 48, color: Colors.grey.withAlpha(128)), // Utiliser withAlpha au lieu de withOpacity
            SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
