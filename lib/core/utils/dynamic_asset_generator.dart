import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';

class DynamicAssetGenerator {
  static final Logger _logger = Logger();
  static bool _initialized = false;
  static final Map<String, Uint8List> _imageCache = {};

  /// Initialise le générateur d'assets dynamiques
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _logger.i('Initialisation du générateur d\'assets dynamiques');
      // Précharger les assets nécessaires ici si besoin
      _initialized = true;
      _logger.i('Générateur d\'assets dynamiques initialisé avec succès');
    } catch (e, stackTrace) {
      _logger.e('Erreur lors de l\'initialisation du générateur d\'assets dynamiques', e, stackTrace);
      rethrow;
    }
  }

  /// Génère un logo dynamique
  static Future<Widget> generateLogo({double height = 100.0}) async {
    try {
      // Essayer d'abord de charger le logo depuis les assets
      return Image.asset(
        'assets/images/logo.png',
        height: height,
      );
    } catch (e) {
      _logger.w('Logo non trouvé dans les assets, génération d\'un logo dynamique');
      
      // Fallback: générer un logo dynamique
      return FutureBuilder<Uint8List>(
        future: _generateLogoImage(height.toInt(), height.toInt()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: height,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          
          if (snapshot.hasError || !snapshot.hasData) {
            _logger.e('Erreur lors de la génération du logo', snapshot.error);
            return Container(
              height: height,
              width: height,
              color: Colors.blue.shade100,
              child: Center(
                child: Icon(
                  Icons.car_crash,
                  size: height * 0.6,
                  color: Colors.blue,
                ),
              ),
            );
          }
          
          return Image.memory(
            snapshot.data!,
            height: height,
          );
        },
      );
    }
  }

  /// Génère un avatar dynamique
  static Future<Widget> generateAvatar({
    required String text,
    double radius = 20.0,
    Color? backgroundColor,
  }) async {
    final initials = _getInitials(text);
    final color = backgroundColor ?? _getColorFromText(text);
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Génère une image placeholder
  static Future<Widget> generatePlaceholder({
    required double width,
    required double height,
    String? text,
  }) async {
    try {
      // Vérifier la connectivité
      final hasInternet = await _checkInternetConnection();
      
      if (hasInternet) {
        // Essayer de charger une image en ligne
        return FutureBuilder<Uint8List>(
          future: _fetchPlaceholderImage(width.toInt(), height.toInt(), text ?? 'Placeholder'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingPlaceholder(width, height);
            }
            
            if (snapshot.hasError || !snapshot.hasData) {
              _logger.w('Erreur lors du chargement de l\'image en ligne, utilisation d\'une image locale', snapshot.error);
              return _buildLocalPlaceholder(width, height, text);
            }
            
            return Image.memory(
              snapshot.data!,
              width: width,
              height: height,
              fit: BoxFit.cover,
            );
          },
        );
      } else {
        // Pas de connexion Internet, utiliser une image locale
        return _buildLocalPlaceholder(width, height, text);
      }
    } catch (e) {
      _logger.e('Erreur lors de la génération du placeholder', e);
      return _buildLocalPlaceholder(width, height, text);
    }
  }

  /// Génère une image de logo
  static Future<Uint8List> _generateLogoImage(int width, int height) async {
    // Vérifier si l'image est déjà en cache
    final cacheKey = 'logo_${width}x$height';
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }
    
    // Créer un recorder pour dessiner l'image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Dessiner le fond
    final paint = Paint()..color = Colors.blue;
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);
    
    // Dessiner le texte
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'CT',
        style: TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset(
        (width - textPainter.width) / 2, 
        (height - textPainter.height) / 2
      )
    );
    
    // Convertir en image
    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    
    // Mettre en cache
    _imageCache[cacheKey] = bytes;
    
    return bytes;
  }

  /// Récupère une image placeholder depuis Internet
  static Future<Uint8List> _fetchPlaceholderImage(int width, int height, String text) async {
    try {
      // Utiliser picsum.photos au lieu de via.placeholder.com
      final url = 'https://picsum.photos/$width/$height?random=1';
      
      // Utiliser le cache manager pour éviter de télécharger plusieurs fois la même image
      final file = await DefaultCacheManager().getSingleFile(url);
      return await file.readAsBytes();
    } catch (e) {
      _logger.e('Erreur lors du chargement de l\'image placeholder', e);
      // Fallback vers une image générée localement
      return _generateBasicImage(width, height, text);
    }
  }

  /// Génère une image basique avec du texte
  static Future<Uint8List> _generateBasicImage(int width, int height, String text) async {
    // Vérifier si l'image est déjà en cache
    final cacheKey = 'basic_${width}x${height}_$text';
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }
    
    // Créer un recorder pour dessiner l'image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Dessiner le fond
    final paint = Paint()..color = Colors.grey.shade200;
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);
    
    // Dessiner le texte
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: Colors.black54, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: width.toDouble() - 20);
    textPainter.paint(
      canvas, 
      Offset((width - textPainter.width) / 2, (height - textPainter.height) / 2)
    );
    
    // Convertir en image
    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    
    // Mettre en cache
    _imageCache[cacheKey] = bytes;
    
    return bytes;
  }

  /// Construit un widget placeholder pendant le chargement
  static Widget _buildLoadingPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Construit un widget placeholder local
  static Widget _buildLocalPlaceholder(double width, double height, String? text) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image,
              size: width * 0.3,
              color: Colors.grey.shade400,
            ),
            if (text != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  text,
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Vérifie la connexion Internet
  static Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Obtient les initiales à partir d'un texte
  static String _getInitials(String text) {
    if (text.isEmpty) return '?';
    
    final words = text.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.length == 1 && words[0].isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    
    return '?';
  }

  /// Obtient une couleur à partir d'un texte
  static Color _getColorFromText(String text) {
    if (text.isEmpty) return Colors.blue;
    
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    
    final hash = text.hashCode.abs();
    return colors[hash % colors.length];
  }
}