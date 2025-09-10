import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';

/// 📝 Écran de signature électronique
class SignatureScreen extends StatefulWidget {
  final String title;
  final String subtitle;

  const SignatureScreen({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  late SignatureController _signatureController;
  bool _hasSignature = false;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    // Écouter les changements de signature
    _signatureController.addListener(() {
      setState(() {
        _hasSignature = _signatureController.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_hasSignature)
            IconButton(
              onPressed: _effacerSignature,
              icon: const Icon(Icons.clear),
              tooltip: 'Effacer',
            ),
        ],
      ),
      body: Column(
        children: [
          // Header avec informations
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Zone de signature
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.touch_app, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Signez avec votre doigt dans la zone ci-dessous',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Zone de signature
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _hasSignature ? Colors.green : Colors.grey[300]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Signature(
                          controller: _signatureController,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Ligne de signature
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Column(
                      children: [
                        Container(
                          height: 1,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Signature du déclarant',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Boutons d'action
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Annuler'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _hasSignature ? _validerSignature : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🗑️ Effacer la signature
  void _effacerSignature() {
    _signatureController.clear();
  }

  /// ✅ Valider et retourner la signature
  void _validerSignature() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez signer avant de valider'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final Uint8List? signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes != null && mounted) {
        Navigator.of(context).pop(signatureBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la signature: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
