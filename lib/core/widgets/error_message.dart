import 'package:flutter/material.dart';

class ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorMessage({
    Key? key,
    required this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Erreur',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.red.shade700,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRetry,
                child: const Text('Réessayer'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}