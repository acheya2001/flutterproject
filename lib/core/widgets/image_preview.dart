import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImagePreview extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;
  final VoidCallback onTap;
  final String placeholder;
  final double height;
  final double width;
  final BoxFit fit;

  const ImagePreview({
    Key? key,
    this.imageFile,
    this.imageUrl,
    required this.onTap,
    required this.placeholder,
    this.height = 150,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImageWidget(),
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (imageFile != null) {
      return Image.file(
        imageFile!,
        fit: fit,
        width: width,
        height: height,
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            placeholder,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cliquez pour ajouter',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 8),
          Text(
            'Erreur de chargement',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cliquez pour réessayer',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}