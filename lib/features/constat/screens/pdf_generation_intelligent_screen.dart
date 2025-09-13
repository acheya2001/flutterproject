import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/intelligent_constat_pdf_service.dart';
import '../../../services/intelligent_notification_service.dart';

/// 📄 Écran de génération PDF intelligent pour constats multi-véhicules
class PDFGenerationIntelligentScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> sessionData;

  const PDFGenerationIntelligentScreen({
    Key? key,
    required this.sessionId,
    required this.sessionData,
  }) : super(key: key);

  @override
  State<PDFGenerationIntelligentScreen> createState() => _PDFGenerationIntelligentScreenState();
}

class _PDFGenerationIntelligentScreenState extends State<PDFGenerationIntelligentScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  
  bool _isGenerating = false;
  bool _isCompleted = false;
  String? _pdfUrl;
  String? _errorMessage;
  
  double _currentProgress = 0.0;
  String _currentStep = 'Initialisation...';
  
  final List<String> _steps = [
    'Chargement des données de session...',
    'Compilation des informations véhicules...',
    'Génération de la page de couverture...',
    'Création des pages détaillées par véhicule...',
    'Intégration du croquis collaboratif...',
    'Ajout des signatures certifiées...',
    'Finalisation du document PDF...',
    'Upload vers Firebase Storage...',
    'Identification des agents responsables...',
    'Envoi des notifications personnalisées...',
    'Transmission terminée avec succès !',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 🚀 Démarrer la génération PDF intelligente
  Future<void> _startIntelligentGeneration() async {
    setState(() {
      _isGenerating = true;
      _isCompleted = false;
      _errorMessage = null;
      _currentProgress = 0.0;
    });

    try {
      // Étapes de génération avec progression
      for (int i = 0; i < _steps.length; i++) {
        setState(() {
          _currentStep = _steps[i];
          _currentProgress = (i + 1) / _steps.length;
        });
        
        _animationController.forward();
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Actions spécifiques selon l'étape
        switch (i) {
          case 6: // Finalisation du document PDF
            _pdfUrl = await IntelligentConstatPdfService.genererConstatMultiVehicules(
              sessionId: widget.sessionId,
              sessionData: widget.sessionData,
            );
            break;
          case 9: // Envoi des notifications
            if (_pdfUrl != null) {
              await IntelligentNotificationService.transmettreConstatAuxAgents(
                sessionId: widget.sessionId,
                pdfUrl: _pdfUrl!,
                sessionData: widget.sessionData,
              );
            }
            break;
        }
        
        _animationController.reset();
      }

      // Mettre à jour le statut de la session
      await _updateSessionStatus();
      
      setState(() {
        _isGenerating = false;
        _isCompleted = true;
      });

    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Erreur lors de la génération: $e';
      });
    }
  }

  /// 📊 Mettre à jour le statut de la session
  Future<void> _updateSessionStatus() async {
    await FirebaseFirestore.instance
        .collection('collaborative_sessions')
        .doc(widget.sessionId)
        .update({
      'status': 'COMPLETED',
      'progression.global': 100,
      'finalisation.pdfUrl': _pdfUrl,
      'finalisation.pdfGeneratedAt': FieldValue.serverTimestamp(),
      'finalisation.transmissionStatus.completedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('📄 Génération PDF Intelligent'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // En-tête avec informations session
            _buildSessionHeader(),
            const SizedBox(height: 32),
            
            // Zone de progression
            Expanded(
              child: _buildProgressSection(),
            ),
            
            // Boutons d'action
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// 📋 En-tête avec informations de session
  Widget _buildSessionHeader() {
    final participants = widget.sessionData['participants'] as List<dynamic>? ?? [];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[800]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Constat Multi-Véhicules',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Session: ${widget.sessionId}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          Text(
            'Véhicules impliqués: ${participants.length}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 📈 Section de progression
  Widget _buildProgressSection() {
    if (!_isGenerating && !_isCompleted && _errorMessage == null) {
      return _buildInitialState();
    } else if (_isGenerating) {
      return _buildGeneratingState();
    } else if (_isCompleted) {
      return _buildCompletedState();
    } else {
      return _buildErrorState();
    }
  }

  /// 🎯 État initial
  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy,
            size: 80,
            color: Colors.blue[600],
          ),
          const SizedBox(height: 24),
          Text(
            'Génération PDF Intelligente',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Le système va générer un PDF adaptatif selon le nombre\n'
            'de véhicules et transmettre automatiquement aux\n'
            'agents d\'assurance responsables.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// ⚙️ État de génération
  Widget _buildGeneratingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Indicateur de progression circulaire
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: _currentProgress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  ),
                ),
              ),
              Center(
                child: Text(
                  '${(_currentProgress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Étape actuelle
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_progressAnimation.value * 0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  _currentStep,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// ✅ État terminé
  Widget _buildCompletedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.green[600],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'PDF Généré avec Succès !',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Le constat a été généré et transmis automatiquement\n'
            'aux agents d\'assurance responsables.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (_pdfUrl != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.link, color: Colors.green[600]),
                  const SizedBox(height: 8),
                  Text(
                    'PDF disponible',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Le document est accessible via le lien sécurisé',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ❌ État d'erreur
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[600],
          ),
          const SizedBox(height: 24),
          Text(
            'Erreur de Génération',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Text(
              _errorMessage ?? 'Une erreur inconnue s\'est produite',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎮 Boutons d'action
  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          if (!_isGenerating && !_isCompleted) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _startIntelligentGeneration,
                icon: const Icon(Icons.smart_toy),
                label: const Text('Générer PDF Intelligent'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else if (_isCompleted) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: const Text('Terminer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else if (_errorMessage != null) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
