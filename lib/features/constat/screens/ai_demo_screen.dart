import 'package:flutter/material.dart';
import '../../../core/widgets/custom_app_bar.dart';

class AiDemoScreen extends StatefulWidget {
  const AiDemoScreen({super.key});

  @override
  State<AiDemoScreen> createState() => _AiDemoScreenState();
}

class _AiDemoScreenState extends State<AiDemoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: '🤖 Démo IA',
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              'Démo IA',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Fonctionnalité en développement',
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