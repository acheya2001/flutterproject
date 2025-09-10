import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/constat_officiel_model.dart';
import '../services/constat_officiel_service.dart';
import '../widgets/constat_header_widget.dart';
import '../widgets/constat_partie_widget.dart';
import '../widgets/constat_croquis_widget.dart';
import '../widgets/constat_circumstances_widget.dart';
import '../../../core/widgets/custom_button.dart';

/// 📋 Écran principal du constat amiable officiel
class ConstatOfficielScreen extends StatefulWidget {
  final String? sinistreId;
  final List<String>? vehicleIds; // IDs des véhicules sélectionnés

  const ConstatOfficielScreen({
    super.key,
    this.sinistreId,
    this.vehicleIds,
  });

  @override
  State<ConstatOfficielScreen> createState() => _ConstatOfficielScreenState();
}

class _ConstatOfficielScreenState extends State<ConstatOfficielScreen> {
  final PageController _pageController = PageController();
  final ConstatOfficielService _service = ConstatOfficielService();
  
  ConstatOfficielModel? _constat;
  bool _isLoading = true;
  bool _isSaving = false;
  int _currentPage = 0;
  String? _currentUserId;

  // Contrôleurs pour les données générales
  final TextEditingController _lieuController = TextEditingController();
  final TextEditingController _heureController = TextEditingController();
  final TextEditingController _observationsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _initializeConstat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _lieuController.dispose();
    _heureController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _initializeConstat() async {
    try {
      if (widget.sinistreId != null) {
        // Charger un constat existant
        _constat = await _service.getConstat(widget.sinistreId!);
      } else {
        // Créer un nouveau constat
        _constat = await _service.createNewConstat(
          vehicleIds: widget.vehicleIds ?? [],
          currentUserId: _currentUserId!,
        );
      }

      if (_constat != null) {
        _populateControllers();
      }
    } catch (e) {
      _showError('Erreur lors du chargement du constat: $e');
    } finally {
      if (mounted) setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateControllers() {
    if (_constat != null) {
      _lieuController.text = _constat!.lieuAccident ?? '';
      _heureController.text = _constat!.heureAccident ?? '';
      _observationsController.text = _constat!.observations.join('\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Constat Amiable'),
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_constat == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Constat Amiable'),
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Erreur lors du chargement du constat'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Constat Amiable d\'Accident Automobile'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveConstat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur de progression
          _buildProgressIndicator(),
          
          // Contenu principal
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                if (mounted) setState(() {
                  _currentPage = index;
                });
              },
              children: [
                // Page 1: Informations générales
                _buildGeneralInfoPage(),
                
                // Pages pour chaque partie (véhicule)
                ..._constat!.parties.map((partie) => _buildPartiePage(partie)),
                
                // Page croquis
                _buildCroquisPage(),
                
                // Page circonstances
                _buildCircumstancesPage(),
                
                // Page signatures
                _buildSignaturesPage(),
              ],
            ),
          ),
          
          // Navigation
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalPages = 4 + _constat!.parties.length; // Général + Parties + Croquis + Circonstances + Signatures
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Étape ${_currentPage + 1} sur $totalPages',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _getPageTitle(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentPage + 1) / totalPages,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    if (_currentPage == 0) return 'Informations générales';
    if (_currentPage <= _constat!.parties.length) {
      final partieIndex = _currentPage - 1;
      return 'Véhicule ${_constat!.parties[partieIndex].partieId}';
    }
    if (_currentPage == _constat!.parties.length + 1) return 'Croquis de l\'accident';
    if (_currentPage == _constat!.parties.length + 2) return 'Circonstances';
    return 'Signatures';
  }

  Widget _buildGeneralInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstatHeaderWidget(
        constat: _constat!,
        lieuController: _lieuController,
        heureController: _heureController,
        onChanged: _updateConstat,
      ),
    );
  }

  Widget _buildPartiePage(ConstatPartieModel partie) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstatPartieWidget(
        partie: partie,
        isEditable: partie.isEditable,
        onChanged: (updatedPartie) {
          _updatePartie(updatedPartie);
        },
      ),
    );
  }

  Widget _buildCroquisPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstatCroquisWidget(
        constat: _constat!,
        onChanged: _updateConstat,
      ),
    );
  }

  Widget _buildCircumstancesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstatCircumstancesWidget(
        constat: _constat!,
        onChanged: _updateConstat,
      ),
    );
  }

  Widget _buildSignaturesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signatures des conducteurs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ..._constat!.parties.map((partie) => _buildSignatureSection(partie)),
          
          const SizedBox(height: 32),
          
          if (_allPartiesSigned())
            CustomButton(
              text: 'Finaliser le constat',
              onPressed: _finalizeConstat,
              icon: Icons.check_circle,
              backgroundColor: Colors.green,
            ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection(ConstatPartieModel partie) {
    final canSign = partie.conducteurUid == _currentUserId && !partie.isSigned;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Véhicule ${partie.partieId} - ${partie.nomConducteur ?? 'Conducteur'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            if (partie.isSigned) ...[
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Signé le ${_formatDate(partie.signedAt!)}',
                    style: TextStyle(color: Colors.green[600]),
                  ),
                ],
              ),
            ] else if (canSign) ...[
              CustomButton(
                text: 'Signer',
                onPressed: () => _signPartie(partie),
                icon: Icons.edit,
                backgroundColor: Colors.blue,
              ),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.pending, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  Text(
                    'En attente de signature',
                    style: TextStyle(color: Colors.orange[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    final totalPages = 4 + _constat!.parties.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: CustomButton(
                text: 'Précédent',
                onPressed: _previousPage,
                backgroundColor: Colors.grey[300],
                textColor: Colors.black87,
              ),
            ),
          
          if (_currentPage > 0) const SizedBox(width: 16),
          
          if (_currentPage < totalPages - 1)
            Expanded(
              child: CustomButton(
                text: 'Suivant',
                onPressed: _nextPage,
                icon: Icons.arrow_forward,
              ),
            ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    final totalPages = 4 + _constat!.parties.length;
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateConstat(ConstatOfficielModel updatedConstat) {
    if (mounted) setState(() {
      _constat = updatedConstat;
    });
    _saveConstat();
  }

  void _updatePartie(ConstatPartieModel updatedPartie) {
    if (_constat != null) {
      final parties = List<ConstatPartieModel>.from(_constat!.parties);
      final index = parties.indexWhere((p) => p.partieId == updatedPartie.partieId);
      if (index != -1) {
        parties[index] = updatedPartie;
        _updateConstat(_constat!.copyWith(parties: parties));
      }
    }
  }

  Future<void> _saveConstat() async {
    if (_constat == null || _isSaving) return;

    if (mounted) setState(() {
      _isSaving = true;
    });

    try {
      await _service.updateConstat(_constat!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Constat sauvegardé'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Erreur lors de la sauvegarde: $e');
    } finally {
      if (mounted) setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _signPartie(ConstatPartieModel partie) async {
    // TODO: Implémenter la signature électronique
    final updatedPartie = partie.copyWith(
      signature: 'signature_${DateTime.now().millisecondsSinceEpoch}',
      signedAt: DateTime.now(),
      isSigned: true,
    );
    _updatePartie(updatedPartie);
  }

  bool _allPartiesSigned() {
    return _constat!.parties.every((partie) => partie.isSigned);
  }

  Future<void> _finalizeConstat() async {
    if (_constat == null) return;

    try {
      final finalizedConstat = _constat!.copyWith(
        isCompleted: true,
        isSigned: true,
        lastUpdatedAt: DateTime.now(),
      );
      
      await _service.updateConstat(finalizedConstat);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Constat finalisé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Erreur lors de la finalisation: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}


