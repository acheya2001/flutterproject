import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// 📸 Widget pour capturer les photos de l'accident
class PhotoCaptureWidget extends StatefulWidget {
  final Function(List<String>) onPhotosChanged;

  const PhotoCaptureWidget({
    super.key,
    required this.onPhotosChanged,
  });

  @override
  State<PhotoCaptureWidget> createState() => _PhotoCaptureWidgetState();
}

class _PhotoCaptureWidgetState extends State<PhotoCaptureWidget> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _photos = [];
  
  final List<Map<String, dynamic>> _photoTypes = [
    {
      'title': 'Vue d\'ensemble',
      'description': 'Photo générale de la scène d\'accident',
      'icon': Icons.landscape,
      'required': true,
    },
    {
      'title': 'Dégâts véhicule',
      'description': 'Photos détaillées des dégâts sur votre véhicule',
      'icon': Icons.directions_car,
      'required': true,
    },
    {
      'title': 'Autre véhicule',
      'description': 'Photos de l\'autre véhicule impliqué',
      'icon': Icons.car_crash,
      'required': false,
    },
    {
      'title': 'Environnement',
      'description': 'Signalisation, route, obstacles...',
      'icon': Icons.traffic,
      'required': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildHeader(),
          
          const SizedBox(height: 20),
          
          // Guide photos
          _buildPhotoGuide(),
          
          const SizedBox(height: 20),
          
          // Photos prises
          _buildPhotoGrid(),
          
          const SizedBox(height: 20),
          
          // Boutons d'action
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// 📋 En-tête
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photos de l\'Accident',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'Prenez des photos claires et détaillées',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _photos.length >= 2 ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_photos.length}/8',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '📸 Prenez au minimum 2 photos pour une déclaration complète. '
            'Plus vous avez de photos, plus l\'analyse sera précise.',
            style: TextStyle(fontSize: 14, color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }

  /// 📋 Guide des types de photos
  Widget _buildPhotoGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Types de Photos Recommandées',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 12),
        ...(_photoTypes.map((type) => _buildPhotoTypeCard(type))),
      ],
    );
  }

  /// 🎯 Carte type de photo
  Widget _buildPhotoTypeCard(Map<String, dynamic> type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: type['required'] ? Colors.orange[200]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: type['required'] ? Colors.orange[100] : Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              type['icon'],
              color: type['required'] ? Colors.orange[700] : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      type['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (type['required'])
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'REQUIS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  type['description'],
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

  /// 🖼️ Grille des photos
  Widget _buildPhotoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📷 Photos Prises (${_photos.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 12),
        if (_photos.isEmpty)
          _buildEmptyState()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              return _buildPhotoItem(_photos[index], index);
            },
          ),
      ],
    );
  }

  /// 🚫 État vide
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_a_photo,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune photo ajoutée',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur les boutons ci-dessous pour ajouter des photos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 📸 Item photo
  Widget _buildPhotoItem(XFile photo, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(photo.path),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 🎬 Boutons d'action
  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _takePhoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Prendre Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _takePhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _clearAllPhotos,
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              label: const Text(
                'Supprimer toutes les photos',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 📸 Prendre une photo
  void _takePhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          _photos.add(photo);
        });
        _updatePhotos();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Photo ajoutée avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la prise de photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🗑️ Supprimer une photo
  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
    _updatePhotos();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Photo supprimée'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 🧹 Supprimer toutes les photos
  void _clearAllPhotos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer toutes les photos ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _photos.clear();
      });
      _updatePhotos();
    }
  }

  /// 🔄 Mettre à jour la liste des photos
  void _updatePhotos() {
    final photoPaths = _photos.map((photo) => photo.path).toList();
    widget.onPhotosChanged(photoPaths);
  }
}
