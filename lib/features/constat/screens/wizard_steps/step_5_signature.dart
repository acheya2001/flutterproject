import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../../../core/widgets/custom_button.dart';
import '../declaration_wizard_screen.dart';

/// ✍️ Étape 5: Signature électronique
class Step5Signature extends StatefulWidget {
  final WizardData wizardData;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const Step5Signature({
    super.key,
    required this.wizardData,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<Step5Signature> createState() => _Step5SignatureState();
}

class _Step5SignatureState extends State<Step5Signature> {
  late SignatureController _signatureController;
  bool _hasSignature = false;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 2,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    
    // Vérifier s'il y a déjà une signature
    _hasSignature = widget.wizardData.signature != null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de l'étape
          const Text(
            'Signature',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Signez pour valider votre déclaration',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),

          // Contenu principal
          Expanded(
            child: Column(
              children: [
                // Instructions
                _buildInstructions(),
                const SizedBox(height: 24),

                // Zone de signature
                Expanded(
                  child: _buildSignatureArea(),
                ),
                
                const SizedBox(height: 16),

                // Boutons de contrôle de la signature
                _buildSignatureControls(),
              ],
            ),
          ),

          // Boutons d'action
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Signez dans la zone ci-dessous avec votre doigt\n'
            '• Votre signature confirme l\'exactitude des informations\n'
            '• Une fois signée, la déclaration sera envoyée aux autres participants',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureArea() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // En-tête de la zone de signature
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Text(
              'Zone de signature',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Zone de signature
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: _hasSignature && widget.wizardData.signature != null
                  ? _buildExistingSignature()
                  : _buildSignaturePad(),
            ),
          ),

          // Ligne de signature
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
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
    );
  }

  Widget _buildSignaturePad() {
    return Signature(
      controller: _signatureController,
      backgroundColor: Colors.white,
    );
  }

  Widget _buildExistingSignature() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: Colors.green[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Signature enregistrée',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous avez déjà signé cette déclaration',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureControls() {
    if (_hasSignature && widget.wizardData.signature != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomButton(
            text: 'Modifier la signature',
            onPressed: _editSignature,
            backgroundColor: Colors.orange,
            icon: Icons.edit,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CustomButton(
          text: 'Effacer',
          onPressed: _clearSignature,
          backgroundColor: Colors.red[100],
          textColor: Colors.red[700],
          icon: Icons.clear,
        ),
        CustomButton(
          text: 'Sauvegarder',
          onPressed: _saveSignature,
          backgroundColor: Colors.green,
          icon: Icons.save,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Précédent',
            onPressed: widget.onPrevious,
            backgroundColor: Colors.grey[300],
            textColor: Colors.black87,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomButton(
            text: 'Suivant',
            onPressed: _hasSignature ? widget.onNext : null,
            icon: Icons.arrow_forward,
          ),
        ),
      ],
    );
  }

  void _clearSignature() {
    setState(() {
      _signatureController.clear();
    });
  }

  Future<void> _saveSignature() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez signer avant de sauvegarder'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final Uint8List? signature = await _signatureController.toPngBytes();
      if (signature != null) {
        setState(() {
          widget.wizardData.signature = signature.toString(); // TODO: Convertir en base64
          _hasSignature = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signature sauvegardée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editSignature() {
    setState(() {
      _hasSignature = false;
      widget.wizardData.signature = null;
      _signatureController.clear();
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }
}
