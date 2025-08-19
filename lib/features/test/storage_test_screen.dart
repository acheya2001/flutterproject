import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_storage_service.dart';
import '../../services/imgur_storage_service.dart';
import '../../services/supabase_storage_service.dart';

/// 🧪 Écran de test pour les services de stockage
class StorageTestScreen extends StatefulWidget {
  const StorageTestScreen({Key? key}) : super(key: key);

  @override
  State<StorageTestScreen> createState() => _StorageTestScreenState();
}

class _StorageTestScreenState extends State<StorageTestScreen> {
  File? _selectedImage;
  String _testResults = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test des Services de Stockage'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sélection d'image
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune image sélectionnée',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            
            const SizedBox(height: 20),
            
            // Bouton de sélection
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Sélectionner une image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Boutons de test
            if (_selectedImage != null) ...[
              const Text(
                'Tester les services :',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildTestButton(
                'Test Cloudinary (25GB gratuit)',
                Colors.orange,
                () => _testCloudinary(),
              ),
              
              const SizedBox(height: 12),
              
              _buildTestButton(
                'Test Imgur (illimité gratuit)',
                Colors.green,
                () => _testImgur(),
              ),
              
              const SizedBox(height: 12),
              
              _buildTestButton(
                'Test Supabase (1GB gratuit)',
                Colors.purple,
                () => _testSupabase(),
              ),
              
              const SizedBox(height: 12),
              
              _buildTestButton(
                'Test Système Hybride',
                Colors.blue,
                () => _testHybrid(),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Résultats
            if (_testResults.isNotEmpty) ...[
              const Text(
                'Résultats des tests :',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _testResults,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(text),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _testResults = '';
      });
    }
  }

  Future<void> _testCloudinary() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isLoading = true;
      _testResults += '\n🌐 Test Cloudinary...\n';
    });

    try {
      final url = await CloudinaryStorageService.uploadImage(
        imageFile: _selectedImage!,
        folder: 'test',
        publicId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() {
        if (url != null) {
          _testResults += '✅ Cloudinary: SUCCESS\n';
          _testResults += 'URL: $url\n';
        } else {
          _testResults += '❌ Cloudinary: FAILED\n';
          _testResults += 'Vérifiez vos clés API dans cloudinary_storage_service.dart\n';
        }
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ Cloudinary: ERROR\n';
        _testResults += 'Erreur: $e\n';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testImgur() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isLoading = true;
      _testResults += '\n🌍 Test Imgur...\n';
    });

    try {
      final url = await ImgurStorageService.uploadImage(
        imageFile: _selectedImage!,
        title: 'Test image',
        description: 'Test depuis l\'app',
      );

      setState(() {
        if (url != null) {
          _testResults += '✅ Imgur: SUCCESS\n';
          _testResults += 'URL: $url\n';
        } else {
          _testResults += '❌ Imgur: FAILED\n';
          _testResults += 'Vérifiez votre Client ID dans imgur_storage_service.dart\n';
        }
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ Imgur: ERROR\n';
        _testResults += 'Erreur: $e\n';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testSupabase() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isLoading = true;
      _testResults += '\n📦 Test Supabase...\n';
    });

    try {
      final url = await SupabaseStorageService.uploadImage(
        imageFile: _selectedImage!,
        path: 'test/test_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      setState(() {
        if (url != null) {
          _testResults += '✅ Supabase: SUCCESS\n';
          _testResults += 'URL: $url\n';
        } else {
          _testResults += '❌ Supabase: FAILED\n';
          _testResults += 'Vérifiez votre configuration dans supabase_storage_service.dart\n';
        }
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ Supabase: ERROR\n';
        _testResults += 'Erreur: $e\n';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testHybrid() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isLoading = true;
      _testResults += '\n🔄 Test Système Hybride...\n';
    });

    try {
      final result = await HybridStorageService.uploadImage(
        imageFile: _selectedImage!,
        vehiculeId: 'test_vehicule',
        type: 'test',
      );

      setState(() {
        if (result['success'] == true) {
          _testResults += '✅ Système Hybride: SUCCESS\n';
          _testResults += 'Storage: ${result['storage']}\n';
          _testResults += 'URL: ${result['url']}\n';
          _testResults += 'Message: ${result['message']}\n';
        } else {
          _testResults += '❌ Système Hybride: FAILED\n';
          _testResults += 'Message: ${result['message']}\n';
        }
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ Système Hybride: ERROR\n';
        _testResults += 'Erreur: $e\n';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }
}
