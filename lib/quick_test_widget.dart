import 'package:flutter/material.dart';

/// 🧪 Widget de test rapide - À ajouter temporairement dans n'importe quel écran
class QuickTestWidget extends StatelessWidget {
  const QuickTestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      right: 20,
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/test/storage');
        },
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.science),
        label: const Text('TEST'),
      ),
    );
  }
}
