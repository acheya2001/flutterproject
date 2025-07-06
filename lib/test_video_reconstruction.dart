import 'package:flutter/material.dart';
import 'features/constat/widgets/ai_integration_demo.dart';

/// 🎬 Test de la reconstitution vidéo IA
class TestVideoReconstruction extends StatelessWidget {
  const TestVideoReconstruction({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Reconstitution Vidéo IA',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: const AIIntegrationDemo(sessionId: 'test-session-123'),
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() {
  runApp(const TestVideoReconstruction());
}
