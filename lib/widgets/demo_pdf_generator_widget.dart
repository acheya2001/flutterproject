import 'package:flutter/material.dart';
import '../services/test_data_complete_generator.dart';
import '../services/constat_tunisien_officiel_pdf.dart';

/// 🎯 Widget pour générer un PDF de démonstration complet
class DemoPdfGeneratorWidget extends StatefulWidget {
  @override
  _DemoPdfGeneratorWidgetState createState() => _DemoPdfGeneratorWidgetState();
}

class _DemoPdfGeneratorWidgetState extends State<DemoPdfGeneratorWidget> {
  bool _isGenerating = false;
  String? _lastGeneratedSessionId;
  String? _lastGeneratedPdfPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🇹🇳 Générateur PDF Démo'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[800]!, Colors.blue[600]!],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Icon(Icons.picture_as_pdf, size: 48, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    'PDF TUNISIEN COMPLET',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Génération avec données complètes pour démonstration',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 30),
            
            // Contenu du PDF
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Contenu du PDF de démonstration :',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 15),
                    
                    _buildFeatureItem('🇹🇳', 'Couverture République Tunisienne officielle'),
                    _buildFeatureItem('📋', 'Cases 1-5 du constat (Date, Lieu, Blessés, Dégâts, Témoins)'),
                    _buildFeatureItem('🚗', 'Véhicule A: BMW Serie 3 - Données complètes'),
                    _buildFeatureItem('🚗', 'Véhicule B: Mercedes Classe C - Données complètes'),
                    _buildFeatureItem('🚗', 'Véhicule C: Peugeot 308 - Données complètes'),
                    _buildFeatureItem('🏢', 'Assurances: STAR, AMI, GAT avec contrats'),
                    _buildFeatureItem('👤', 'Conducteurs: Noms, adresses, permis, téléphones'),
                    _buildFeatureItem('🚦', 'Circonstances traduites en français'),
                    _buildFeatureItem('💥', 'Points de choc et dégâts détaillés'),
                    _buildFeatureItem('📋', 'Page circonstances détaillées'),
                    _buildFeatureItem('🎨', 'Croquis d\'intersection avec images'),
                    _buildFeatureItem('✍️', 'Signatures électroniques réelles'),
                    _buildFeatureItem('📸', 'Photos d\'accident documentées'),
                    _buildFeatureItem('👥', 'Témoins avec coordonnées complètes'),
                    _buildFeatureItem('⚖️', 'Validation légale tunisienne'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 30),
            
            // Bouton de génération
            ElevatedButton(
              onPressed: _isGenerating ? null : _genererPdfDemo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isGenerating
                  ? Row(
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
                        SizedBox(width: 10),
                        Text('Génération en cours...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'GÉNÉRER PDF COMPLET',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
            
            SizedBox(height: 20),
            
            // Résultats
            if (_lastGeneratedSessionId != null) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600]),
                          SizedBox(width: 10),
                          Text(
                            'PDF généré avec succès !',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Session ID: $_lastGeneratedSessionId',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.green[700],
                        ),
                      ),
                      if (_lastGeneratedPdfPath != null) ...[
                        SizedBox(height: 5),
                        Text(
                          'Fichier: ${_lastGeneratedPdfPath!.split('/').last}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            
            Spacer(),
            
            // Note
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[600]),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ce PDF contient des données de démonstration complètes pour faire de belles captures d\'écran.',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _genererPdfDemo() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // 1. Créer les données de test complètes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎯 Création des données de démonstration...'),
          backgroundColor: Colors.blue[600],
        ),
      );

      final sessionId = await TestDataCompleteGenerator.creerSessionCompleteDemo();

      // 2. Générer le PDF
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📄 Génération du PDF...'),
          backgroundColor: Colors.orange[600],
        ),
      );

      final pdfPath = await ConstatTunisienOfficielPdf.genererConstatOfficiel(
        sessionId: sessionId,
      );

      setState(() {
        _lastGeneratedSessionId = sessionId;
        _lastGeneratedPdfPath = pdfPath;
      });

      // Afficher le succès avec option de téléchargement
      _showSuccessDialog(context, sessionId, pdfPath);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  /// 🎉 Dialog de succès avec options
  void _showSuccessDialog(BuildContext context, String sessionId, String pdfPath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 28),
              SizedBox(width: 10),
              Text(
                'PDF Généré !',
                style: TextStyle(
                  color: Colors.green[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🇹🇳 Constat Tunisien Officiel créé avec succès !',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Contenu du PDF:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('✅ 8 pages complètes', style: TextStyle(fontSize: 12)),
                    Text('✅ 3 véhicules avec données complètes', style: TextStyle(fontSize: 12)),
                    Text('✅ Signatures électroniques', style: TextStyle(fontSize: 12)),
                    Text('✅ Croquis d\'accident', style: TextStyle(fontSize: 12)),
                    Text('✅ Photos documentées', style: TextStyle(fontSize: 12)),
                    Text('✅ Conforme réglementation tunisienne', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.green[600], size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le PDF a été téléchargé automatiquement dans votre dossier de téléchargements.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fermer'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // Optionnel: partager le PDF
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📤 Fonctionnalité de partage disponible'),
                    backgroundColor: Colors.blue[600],
                  ),
                );
              },
              icon: Icon(Icons.share),
              label: Text('Partager'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}
