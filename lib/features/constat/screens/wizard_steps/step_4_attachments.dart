import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/custom_button.dart';
import '../declaration_wizard_screen.dart';

/// 📎 Étape 4: Gestion des pièces jointes
class Step4Attachments extends StatefulWidget {
  final WizardData wizardData;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const Step4Attachments({
    super.key,
    required this.wizardData,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<Step4Attachments> createState() => _Step4AttachmentsState();
}

class _Step4AttachmentsState extends State<Step4Attachments> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de l'étape
          const Text(
            'Photos et documents',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez des photos de l\'accident et vos documents',
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
                  // Section photos de l'accident
                  _buildPhotosSection(),
                  const SizedBox(height: 32),

                  // Section documents
                  _buildDocumentsSection(),
                  const SizedBox(height: 32),

                  // Liste des pièces jointes
                  if (widget.wizardData.attachments.isNotEmpty)
                    _buildAttachmentsList(),
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

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos de l\'accident',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Prenez des photos des véhicules, des dégâts et de la scène',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Prendre une photo',
                onPressed: () => _pickImage(ImageSource.camera, 'accident_photo'),
                icon: Icons.camera_alt,
                backgroundColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Galerie',
                onPressed: () => _pickImage(ImageSource.gallery, 'accident_photo'),
                icon: Icons.photo_library,
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documents',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ajoutez vos documents d\'identité et d\'assurance',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),

        // Grille des types de documents
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildDocumentButton(
              'Carte d\'identité',
              Icons.credit_card,
              'carte_identite',
              Colors.purple,
            ),
            _buildDocumentButton(
              'Permis de conduire',
              Icons.card_membership,
              'permis_conduire',
              Colors.orange,
            ),
            _buildDocumentButton(
              'Carte grise',
              Icons.description,
              'carte_grise',
              Colors.teal,
            ),
            _buildDocumentButton(
              'Attestation assurance',
              Icons.security,
              'attestation_assurance',
              Colors.indigo,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentButton(String title, IconData icon, String type, Color color) {
    final hasDocument = widget.wizardData.attachments.any((att) => att['type'] == type);

    return InkWell(
      onTap: () => _showDocumentOptions(type, title),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasDocument ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasDocument ? color : Colors.grey[300]!,
            width: hasDocument ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasDocument ? Icons.check_circle : icon,
              color: hasDocument ? color : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: hasDocument ? color : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pièces jointes (${widget.wizardData.attachments.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.wizardData.attachments.length,
          itemBuilder: (context, index) {
            final attachment = widget.wizardData.attachments[index];
            return _buildAttachmentCard(attachment, index);
          },
        ),
      ],
    );
  }

  Widget _buildAttachmentCard(Map<String, dynamic> attachment, int index) {
    final file = attachment['file'] as File;
    final type = attachment['type'] as String;
    final isImage = type.contains('photo') || type.contains('image');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: isImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  _getDocumentIcon(type),
                  color: Colors.grey[600],
                ),
        ),
        title: Text(
          _getAttachmentTitle(type),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeAttachment(index),
        ),
      ),
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
            onPressed: widget.onNext,
            icon: Icons.arrow_forward,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        if (mounted) setState(() {
          widget.wizardData.attachments.add({
            'file': File(image.path),
            'type': type,
            'timestamp': DateTime.now(),
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDocumentOptions(String type, String title) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('Prendre une photo de $title'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera, type);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery, type);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Annuler'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _removeAttachment(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la pièce jointe'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette pièce jointe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (mounted) setState(() {
                widget.wizardData.attachments.removeAt(index);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(String type) {
    switch (type) {
      case 'carte_identite':
        return Icons.credit_card;
      case 'permis_conduire':
        return Icons.card_membership;
      case 'carte_grise':
        return Icons.description;
      case 'attestation_assurance':
        return Icons.security;
      default:
        return Icons.attach_file;
    }
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

