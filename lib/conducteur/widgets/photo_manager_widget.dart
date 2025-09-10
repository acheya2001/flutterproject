import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// 📸 Widget pour gérer les photos avec prévisualisation
class PhotoManagerWidget extends StatefulWidget {
  final Function(List<String>) onPhotosChanged;
  final List<String> photosInitiales;

  const PhotoManagerWidget({
    Key? key,
    required this.onPhotosChanged,
    this.photosInitiales = const [],
  }) : super(key: key);

  @override
  State<PhotoManagerWidget> createState() => _PhotoManagerWidgetState();
}

class _PhotoManagerWidgetState extends State<PhotoManagerWidget> {
  List<String> _photosPaths = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _photosPaths = List.from(widget.photosInitiales);
  }

  Future<void> _ajouterPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        if (mounted) setState(() {
          _photosPaths.add(image.path);
        });
        widget.onPhotosChanged(_photosPaths);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Photo ajoutée (${_photosPaths.length}/10)'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Erreur: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _ajouterPhotoGalerie() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        if (mounted) setState(() {
          _photosPaths.add(image.path);
        });
        widget.onPhotosChanged(_photosPaths);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Photo ajoutée (${_photosPaths.length}/10)'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Erreur: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _supprimerPhoto(int index) {
    if (mounted) setState(() {
      _photosPaths.removeAt(index);
    });
    widget.onPhotosChanged(_photosPaths);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete, color: Colors.white),
            const SizedBox(width: 8),
            Text('Photo supprimée (${_photosPaths.length}/10)'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _voirPhoto(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PhotoViewerScreen(photoPath: path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.green[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Photos de l\'Accident',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      '${_photosPaths.length}/10 photos ajoutées',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Boutons d'ajout - Plus visibles
          Column(
            children: [
              // Bouton principal - Appareil photo
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _photosPaths.length < 10 ? _ajouterPhoto : null,
                  icon: const Icon(Icons.camera_alt, size: 24),
                  label: const Text(
                    '📸 Prendre une Photo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Bouton secondaire - Galerie
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _photosPaths.length < 10 ? _ajouterPhotoGalerie : null,
                  icon: const Icon(Icons.photo_library, size: 20),
                  label: const Text(
                    '🖼️ Choisir depuis la Galerie',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Colors.green[600]!, width: 2),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Grille de photos
          if (_photosPaths.isEmpty) ...[
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Aucune photo ajoutée',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _photosPaths.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _voirPhoto(_photosPaths[index]),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_photosPaths[index]),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              print('❌ Erreur chargement image: $error');
                              return Container(
                                color: Colors.red[100],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error, color: Colors.red[600], size: 24),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Erreur\nimage',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 10, color: Colors.red),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _supprimerPhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Conseils
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recommandé: Vue générale, dégâts, plaques, documents',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2980B9),
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
}

/// 📱 Écran de visualisation d'une photo
class _PhotoViewerScreen extends StatelessWidget {
  final String photoPath;

  const _PhotoViewerScreen({required this.photoPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Photo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            File(photoPath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[400], size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Impossible de charger l\'image',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chemin: $photoPath',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Retour'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

