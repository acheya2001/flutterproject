import 'package:flutter/material.dart';
import '../models/collaborative_session_model.dart';

/// 📄 Widget moderne pour générer et envoyer des PDFs aux agents
class ModernPDFGeneratorWidget extends StatefulWidget {
  final CollaborativeSession session;
  final VoidCallback? onPDFGenerated;

  const ModernPDFGeneratorWidget({
    Key? key,
    required this.session,
    this.onPDFGenerated,
  }) : super(key: key);

  @override
  State<ModernPDFGeneratorWidget> createState() => _ModernPDFGeneratorWidgetState();
}

class _ModernPDFGeneratorWidgetState extends State<ModernPDFGeneratorWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📄 PDF Agent'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          'Fonctionnalité PDF en développement',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
