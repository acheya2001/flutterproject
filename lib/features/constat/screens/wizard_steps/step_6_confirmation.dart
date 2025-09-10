import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_button.dart';
import '../declaration_wizard_screen.dart';

/// ✅ Étape 6: Confirmation et soumission
class Step6Confirmation extends StatefulWidget {
  final WizardData wizardData;
  final VoidCallback onSubmit;
  final VoidCallback onPrevious;
  final bool isLoading;

  const Step6Confirmation({
    super.key,
    required this.wizardData,
    required this.onSubmit,
    required this.onPrevious,
    required this.isLoading,
  });

  @override
  State<Step6Confirmation> createState() => _Step6ConfirmationState();
}

class _Step6ConfirmationState extends State<Step6Confirmation> {
  bool _acceptTerms = false;
  bool _confirmAccuracy = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de l'étape
          const Text(
            'Confirmation',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vérifiez vos informations avant de soumettre',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),

          // Contenu principal
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Résumé de la déclaration
                  _buildSummarySection(),
                  const SizedBox(height: 24),

                  // Confirmations requises
                  _buildConfirmationSection(),
                  const SizedBox(height: 24),

                  // Informations importantes
                  _buildImportantInfo(),
                ],
              ),
            ),
          ),

          // Boutons d'action
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Résumé de votre déclaration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // Cartes de résumé
        _buildSummaryCard(
          'Date et lieu',
          [
            'Date: ${_formatDate(widget.wizardData.dateAccident)}',
            'Lieu: ${widget.wizardData.location?.address ?? 'Non renseigné'}',
            if (widget.wizardData.description?.isNotEmpty == true)
              'Description: ${widget.wizardData.description}',
          ],
          Icons.location_on,
          Colors.blue,
        ),

        const SizedBox(height: 12),

        _buildSummaryCard(
          'Véhicules',
          widget.wizardData.vehicles.map((v) => 
            '${v.plate ?? 'Immat. non renseignée'} - ${v.brand ?? ''} ${v.model ?? ''}'
            '${v.isOwnerBoolean ? ' (Mon véhicule)' : ''}'
          ).toList(),
          Icons.directions_car,
          Colors.green,
        ),

        const SizedBox(height: 12),

        _buildSummaryCard(
          'Participants invités',
          widget.wizardData.participants.isEmpty
              ? ['Aucun participant invité']
              : widget.wizardData.participants.map((p) => 
                  '${p['emailOrPhone']} - ${(p['role'] as dynamic).displayName}'
                ).toList(),
          Icons.people,
          Colors.orange,
        ),

        const SizedBox(height: 12),

        _buildSummaryCard(
          'Pièces jointes',
          widget.wizardData.attachments.isEmpty
              ? ['Aucune pièce jointe']
              : widget.wizardData.attachments.map((a) => 
                  _getAttachmentTitle(a['type'])
                ).toList(),
          Icons.attach_file,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, List<String> items, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $item',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirmations requises',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        CheckboxListTile(
          title: const Text('Exactitude des informations'),
          subtitle: const Text(
            'Je certifie que toutes les informations fournies sont exactes et complètes',
          ),
          value: _confirmAccuracy,
          onChanged: (value) {
            if (mounted) setState(() {
              _confirmAccuracy = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),

        CheckboxListTile(
          title: const Text('Conditions d\'utilisation'),
          subtitle: const Text(
            'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
          ),
          value: _acceptTerms,
          onChanged: (value) {
            if (mounted) setState(() {
              _acceptTerms = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildImportantInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Important',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Une fois soumise, votre déclaration sera envoyée aux autres participants\n'
            '• Vous recevrez une notification quand tous les participants auront signé\n'
            '• Un rapport final sera généré automatiquement\n'
            '• Votre compagnie d\'assurance sera notifiée',
            style: TextStyle(
              fontSize: 14,
              color: Colors.amber[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canSubmit = _confirmAccuracy && _acceptTerms && !widget.isLoading;

    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Précédent',
            onPressed: widget.isLoading ? null : widget.onPrevious,
            backgroundColor: Colors.grey[300],
            textColor: Colors.black87,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomButton(
            text: widget.isLoading ? 'Soumission...' : 'Soumettre la déclaration',
            onPressed: canSubmit ? widget.onSubmit : null,
            icon: widget.isLoading ? null : Icons.send,
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non renseignée';
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getAttachmentTitle(String type) {
    switch (type) {
      case 'carte_identite':
        return 'Carte d\'identité';
      case 'permis_conduire':
        return 'Permis de conduire';
      case 'carte_grise':
        return 'Carte grise';
      case 'attestation_assurance':
        return 'Attestation d\'assurance';
      case 'accident_photo':
        return 'Photo de l\'accident';
      default:
        return 'Document';
    }
  }
}

