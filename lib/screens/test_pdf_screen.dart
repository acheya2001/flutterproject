import 'package:flutter/material.dart';
import '../services/test_pdf_service.dart';

/// 🧪 Écran de test pour le générateur PDF de constat tunisien
class TestPdfScreen extends StatelessWidget {
  const TestPdfScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test PDF Constat Tunisien'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête avec icône
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        size: 60,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Générateur PDF Constat Tunisien',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Testez la génération de PDF pour les constats d\'accident automobile en Tunisie',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Boutons d'action
                Expanded(
                  child: Column(
                    children: [
                      // Bouton principal - Générer PDF
                      _buildActionButton(
                        context: context,
                        icon: Icons.picture_as_pdf,
                        title: 'Générer PDF de Test',
                        subtitle: 'Créer un PDF avec des données d\'exemple',
                        color: Colors.green,
                        onTap: () => TestPdfService.testerGenerationPdf(context),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Bouton secondaire - Voir les données
                      _buildActionButton(
                        context: context,
                        icon: Icons.data_object,
                        title: 'Voir les Données de Test',
                        subtitle: 'Afficher les statistiques des données utilisées',
                        color: Colors.blue,
                        onTap: () => TestPdfService.afficherStatistiques(context),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Bouton info
                      _buildActionButton(
                        context: context,
                        icon: Icons.info_outline,
                        title: 'À propos du Service',
                        subtitle: 'Informations sur le générateur PDF',
                        color: Colors.orange,
                        onTap: () => _afficherInfos(context),
                      ),
                    ],
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Les PDF générés sont sauvegardés localement et uploadés sur Cloudinary',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🎨 Construire un bouton d'action stylisé
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ℹ️ Afficher les informations sur le service
  void _afficherInfos(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 10),
            Text('À propos du Service PDF'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🇹🇳 Générateur PDF Constat Tunisien',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Fonctionnalités:'),
              Text('• Génération automatique de PDF'),
              Text('• Format officiel tunisien'),
              Text('• Support multi-véhicules'),
              Text('• Intégration croquis et signatures'),
              Text('• Sauvegarde locale et cloud'),
              SizedBox(height: 10),
              Text(
                'Technologies utilisées:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Flutter PDF'),
              Text('• Cloudinary Storage'),
              Text('• Firebase Integration'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
