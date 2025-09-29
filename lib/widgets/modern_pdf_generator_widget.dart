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
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.picture_as_pdf,
            size: 60,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            '📄 PDF Agent',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Fonctionnalité PDF en développement',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Session: ${widget.session.id}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
