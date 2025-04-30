import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class JoinReportScreen extends StatefulWidget {
  JoinReportScreen({Key? key}) : super(key: key);

  @override
  _JoinReportScreenState createState() => _JoinReportScreenState();

  // Ajoutez cette méthode statique à la classe JoinReportScreen
  static void navigateTo(BuildContext context) {
    Navigator.of(context).pushNamed('/report/join');
  }
}

class _JoinReportScreenState extends State<JoinReportScreen> {
  final Logger _logger = Logger();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rejoindre un constat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Rejoindre un constat existant',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Code d\'invitation',
                hintText: 'Entrez le code à 6 chiffres',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _joinReport,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Rejoindre'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _joinReport() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez entrer un code d\'invitation')),
      );
      return;
    }
    
    _logger.d('Tentative de rejoindre le constat avec le code: $code');
    
    setState(() {
      _isLoading = true;
    });
    
    // Simuler un délai de chargement
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fonctionnalité en cours de développement')),
        );
      }
    });
  }
  
  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
