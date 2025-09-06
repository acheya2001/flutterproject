import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/cloudinary_service.dart';

class CompleterDocumentsScreen extends StatefulWidget {
  final String demandeId;
  final List<String> documentsManquants;

  const CompleterDocumentsScreen({
    Key? key,
    required this.demandeId,
    required this.documentsManquants,
  }) : super(key: key);

  @override
  State<CompleterDocumentsScreen> createState() => _CompleterDocumentsScreenState();
}

class _CompleterDocumentsScreenState extends State<CompleterDocumentsScreen> {
  final Map<String, File?> _uploadedImages = {};
  final Map<String, String?> _uploadedUrls = {};
  bool _isUploading = false;

  // Mapping des documents
  final Map<String, String> _documentMapping = {
    'CIN Recto': 'cinRectoUrl',
    'CIN Verso': 'cinVersoUrl',
    'Permis Recto': 'permisRectoUrl',
    'Permis Verso': 'permisVersoUrl',
    'Carte Grise Recto': 'carteGriseRectoUrl',
    'Carte Grise Verso': 'carteGriseVersoUrl',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('📄 Compléter Documents'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête informatif
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Documents Manquants',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Votre dossier est incomplet. Merci de fournir les documents suivants pour continuer le traitement de votre demande :',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Liste des documents manquants
            ...widget.documentsManquants.map((document) {
              final fieldKey = _documentMapping[document];
              if (fieldKey == null) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildDocumentUploadCard(document, fieldKey),
              );
            }).toList(),

            const SizedBox(height: 32),

            // Bouton soumettre
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit() ? _submitDocuments : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Envoi en cours...'),
                        ],
                      )
                    : const Text(
                        '✅ Envoyer les Documents',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUploadCard(String documentName, String fieldKey) {
    final hasImage = _uploadedImages[fieldKey] != null;
    final hasUrl = _uploadedUrls[fieldKey] != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasImage || hasUrl ? Colors.green[300]! : Colors.grey[300]!,
          width: hasImage || hasUrl ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image,
                color: hasImage || hasUrl ? Colors.green[600] : Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  documentName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasImage || hasUrl ? Colors.green[700] : Colors.black87,
                  ),
                ),
              ),
              if (hasImage || hasUrl)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '✓ Ajouté',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (hasImage)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(_uploadedImages[fieldKey]!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, 
                       size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Appuyez pour ajouter',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(fieldKey, ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Caméra'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[600],
                    side: BorderSide(color: Colors.blue[300]!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(fieldKey, ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Galerie'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green[600],
                    side: BorderSide(color: Colors.green[300]!),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(String fieldKey, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _uploadedImages[fieldKey] = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _canSubmit() {
    return widget.documentsManquants.every((document) {
      final fieldKey = _documentMapping[document];
      return fieldKey != null && _uploadedImages[fieldKey] != null;
    }) && !_isUploading;
  }

  Future<void> _submitDocuments() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Upload des images vers Cloudinary
      for (final document in widget.documentsManquants) {
        final fieldKey = _documentMapping[document];
        if (fieldKey != null && _uploadedImages[fieldKey] != null) {
          final url = await CloudinaryService.uploadImage(_uploadedImages[fieldKey]!, 'documents');
          _uploadedUrls[fieldKey] = url;
        }
      }

      // Mise à jour de la demande dans Firestore
      final updateData = <String, dynamic>{
        'statut': 'affectee', // Retour vers l'agent pour vérification
        'documentsCompletes': true,
        'dateCompletionDocuments': FieldValue.serverTimestamp(),
      };

      // Ajouter les URLs des nouveaux documents
      _uploadedUrls.forEach((key, value) {
        if (value != null) {
          updateData[key] = value;
        }
      });

      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(widget.demandeId)
          .update(updateData);

      // Récupérer les informations de la demande pour notifier l'agent
      final demandeDoc = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(widget.demandeId)
          .get();

      final demandeData = demandeDoc.data();
      final agentId = demandeData?['agentId'];
      final numeroContrat = demandeData?['numero'] ?? widget.demandeId;

      // Notification à l'agent
      if (agentId != null) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .add({
          'type': 'documents_completes',
          'titre': 'Documents complétés',
          'message': 'Le conducteur a ajouté les documents manquants pour la demande $numeroContrat. Vous pouvez maintenant continuer le traitement.',
          'demandeId': widget.demandeId,
          'agentId': agentId,
          'dateCreation': FieldValue.serverTimestamp(),
          'lu': false,
          'priorite': 'normale',
        });

        print('✅ Notification envoyée à l\'agent $agentId');
      } else {
        print('⚠️ Aucun agent assigné à cette demande');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Documents envoyés avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}
