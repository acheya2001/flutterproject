import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 🧠 Widget pour l'analyse IA de l'accident
class AIAnalysisWidget extends StatefulWidget {
  final List<String> photos;
  final Map<String, dynamic> accidentData;
  final Function(Map<String, dynamic>) onAnalysisComplete;

  const AIAnalysisWidget({
    super.key,
    required this.photos,
    required this.accidentData,
    required this.onAnalysisComplete,
  });

  @override
  State<AIAnalysisWidget> createState() => _AIAnalysisWidgetState();
}

class _AIAnalysisWidgetState extends State<AIAnalysisWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _analysisController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  bool _isAnalyzing = false;
  bool _analysisComplete = false;
  Map<String, dynamic>? _analysisResult;
  
  final List<String> _analysisSteps = [
    'Chargement des photos...',
    'Détection des véhicules...',
    'Analyse des dégâts...',
    'Évaluation de la gravité...',
    'Génération du rapport...',
  ];
  
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    
    _analysisController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _analysisController.repeat();
  }

  @override
  void dispose() {
    _analysisController.dispose();
    _progressController.dispose();
    super.dispose();
  }

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
          
          // État de l'analyse
          if (!_analysisComplete && !_isAnalyzing)
            _buildReadyState()
          else if (_isAnalyzing)
            _buildAnalyzingState()
          else
            _buildResultState(),
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
          colors: [Colors.purple[50]!, Colors.purple[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analyse IA Avancée',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    Text(
                      'Intelligence artificielle pour analyser votre accident',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (_analysisComplete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'TERMINÉ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '🤖 Notre IA analyse vos photos et données pour générer un rapport détaillé '
            'et estimer les dégâts automatiquement.',
            style: TextStyle(fontSize: 14, color: Colors.purple[700]),
          ),
        ],
      ),
    );
  }

  /// ✅ État prêt pour l'analyse
  Widget _buildReadyState() {
    final canAnalyze = widget.photos.isNotEmpty && widget.accidentData.isNotEmpty;
    
    return Column(
      children: [
        // Prérequis
        _buildPrerequisites(),
        
        const SizedBox(height: 20),
        
        // Bouton d'analyse
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canAnalyze ? _startAnalysis : null,
            icon: const Icon(Icons.psychology),
            label: const Text('Lancer l\'Analyse IA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        if (!canAnalyze)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '⚠️ Veuillez d\'abord remplir les informations et ajouter des photos',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  /// 📋 Prérequis pour l'analyse
  Widget _buildPrerequisites() {
    final hasPhotos = widget.photos.isNotEmpty;
    final hasData = widget.accidentData.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Prérequis pour l\'Analyse',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 12),
          _buildPrerequisiteItem(
            'Photos de l\'accident',
            hasPhotos ? '${widget.photos.length} photo(s) ajoutée(s)' : 'Aucune photo',
            hasPhotos,
          ),
          _buildPrerequisiteItem(
            'Informations de l\'accident',
            hasData ? 'Formulaire rempli' : 'Formulaire incomplet',
            hasData,
          ),
        ],
      ),
    );
  }

  /// ✅ Item prérequis
  Widget _buildPrerequisiteItem(String title, String subtitle, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isComplete ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isComplete ? Colors.black : Colors.grey[600],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isComplete ? Colors.green[600] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ⏳ État en cours d'analyse
  Widget _buildAnalyzingState() {
    return Column(
      children: [
        // Animation de chargement
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _analysisController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _analysisController.value * 2 * math.pi,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.purple[300]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Analyse en cours...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _analysisSteps[_currentStep],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Barre de progression
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Column(
              children: [
                LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_progressAnimation.value * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// 📊 État résultat
  Widget _buildResultState() {
    if (_analysisResult == null) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Résumé de l'analyse
        _buildAnalysisSummary(),
        
        const SizedBox(height: 16),
        
        // Détails de l'analyse
        _buildAnalysisDetails(),
        
        const SizedBox(height: 16),
        
        // Actions
        _buildAnalysisActions(),
      ],
    );
  }

  /// 📊 Résumé de l'analyse
  Widget _buildAnalysisSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Analyse Terminée',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_analysisResult!['confiance']}% confiance',
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
            _analysisResult!['resume'] ?? 'Analyse complétée avec succès',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// 📋 Détails de l'analyse
  Widget _buildAnalysisDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Détails de l\'Analyse',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Véhicules détectés', '${_analysisResult!['vehicules_detectes']}'),
          _buildDetailRow('Gravité des dégâts', _analysisResult!['gravite']),
          _buildDetailRow('Coût estimé', '${_analysisResult!['cout_estime']} TND'),
          _buildDetailRow('Type d\'impact', _analysisResult!['type_impact']),
          _buildDetailRow('Responsabilité estimée', '${_analysisResult!['responsabilite']}%'),
        ],
      ),
    );
  }

  /// 📊 Ligne de détail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎬 Actions de l'analyse
  Widget _buildAnalysisActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: _restartAnalysis,
            icon: const Icon(Icons.refresh),
            label: const Text('Relancer'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _acceptAnalysis,
            icon: const Icon(Icons.check),
            label: const Text('Accepter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// 🚀 Démarrer l'analyse
  void _startAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _currentStep = 0;
    });

    _progressController.forward();

    // Simuler les étapes d'analyse
    for (int i = 0; i < _analysisSteps.length; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _currentStep = i;
        });
      }
    }

    // Générer un résultat simulé
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _analysisComplete = true;
        _analysisResult = _generateMockAnalysis();
      });
      
      _analysisController.stop();
      widget.onAnalysisComplete(_analysisResult!);
    }
  }

  /// 🔄 Relancer l'analyse
  void _restartAnalysis() {
    setState(() {
      _isAnalyzing = false;
      _analysisComplete = false;
      _analysisResult = null;
      _currentStep = 0;
    });
    
    _progressController.reset();
    _analysisController.repeat();
  }

  /// ✅ Accepter l'analyse
  void _acceptAnalysis() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Analyse acceptée et intégrée au rapport'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 🎲 Générer une analyse simulée
  Map<String, dynamic> _generateMockAnalysis() {
    final random = math.Random();
    final gravites = ['Léger', 'Modéré', 'Grave'];
    final impacts = ['Frontal', 'Latéral', 'Arrière'];
    
    return {
      'vehicules_detectes': random.nextInt(2) + 1,
      'gravite': gravites[random.nextInt(gravites.length)],
      'cout_estime': (random.nextInt(5000) + 500),
      'type_impact': impacts[random.nextInt(impacts.length)],
      'responsabilite': random.nextInt(100),
      'confiance': random.nextInt(20) + 80,
      'resume': 'L\'IA a analysé ${widget.photos.length} photo(s) et détecté des dégâts ${gravites[random.nextInt(gravites.length)].toLowerCase()}s.',
    };
  }
}
