import 'package:flutter/material.dart';
import '../../models/collaborative_session_model.dart';
import '../../services/collaborative_session_service.dart';

/// 👁️ Écran de consultation des formulaires des autres participants (lecture seule)
class ParticipantFormViewScreen extends StatefulWidget {
  final CollaborativeSession session;
  final SessionParticipant participant;

  const ParticipantFormViewScreen({
    super.key,
    required this.session,
    required this.participant,
  });

  @override
  State<ParticipantFormViewScreen> createState() => _ParticipantFormViewScreenState();
}

class _ParticipantFormViewScreenState extends State<ParticipantFormViewScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  Map<String, dynamic>? _donneesFormulaire;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _chargerDonneesFormulaire();
    _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple[600]!,
              Colors.indigo[700]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContenu(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Formulaire de ${widget.participant.prenom} ${widget.participant.nom}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Véhicule ${widget.participant.roleVehicule} • Lecture seule',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  _getLibelleStatut(widget.participant.statut),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenu() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Chargement du formulaire...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_donneesFormulaire == null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 64,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Formulaire non rempli',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ce participant n\'a pas encore terminé son formulaire.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Informations personnelles
          _buildSectionInfosPersonnelles(),
          
          const SizedBox(height: 16),
          
          // Circonstances
          _buildSectionCirconstances(),
          
          const SizedBox(height: 16),
          
          // Points de choc
          _buildSectionPointsChoc(),
          
          const SizedBox(height: 16),
          
          // Dégâts
          _buildSectionDegats(),
          
          const SizedBox(height: 16),
          
          // Observations
          _buildSectionObservations(),
        ],
      ),
    );
  }

  Widget _buildSectionInfosPersonnelles() {
    final donneesPersonnelles = _donneesFormulaire!['donneesPersonnelles'] as Map<String, dynamic>?;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: Colors.purple[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Informations personnelles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Lecture seule',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (donneesPersonnelles != null) ...[
            _buildInfoRow('👤 Nom complet', '${donneesPersonnelles['prenom']} ${donneesPersonnelles['nom']}'),
            _buildInfoRow('📞 Téléphone', donneesPersonnelles['telephone'] ?? 'Non renseigné'),
            _buildInfoRow('📧 Email', donneesPersonnelles['email'] ?? 'Non renseigné'),
            _buildInfoRow('🚗 Véhicule', '${donneesPersonnelles['marque']} ${donneesPersonnelles['modele']}'),
            _buildInfoRow('🔢 Immatriculation', donneesPersonnelles['immatriculation'] ?? 'Non renseigné'),
            _buildInfoRow('🏢 Assurance', donneesPersonnelles['compagnie'] ?? 'Non renseigné'),
          ] else ...[
            const Text(
              'Informations personnelles non disponibles',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCirconstances() {
    final circonstances = List<String>.from(_donneesFormulaire!['circonstances'] ?? []);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.list_alt, color: Colors.blue[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Circonstances déclarées',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (circonstances.isNotEmpty) ...[
            ...circonstances.map((circonstance) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      circonstance,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ] else ...[
            const Text(
              'Aucune circonstance déclarée',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionPointsChoc() {
    final pointsChoc = List<String>.from(_donneesFormulaire!['pointsChoc'] ?? []);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.my_location, color: Colors.orange[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Points de choc initial',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (pointsChoc.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pointsChoc.map((point) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Text(
                  point,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800],
                  ),
                ),
              )).toList(),
            ),
          ] else ...[
            const Text(
              'Aucun point de choc déclaré',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionDegats() {
    final degats = List<String>.from(_donneesFormulaire!['degatsApparents'] ?? []);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.build, color: Colors.red[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Dégâts apparents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (degats.isNotEmpty) ...[
            ...degats.map((degat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      degat,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ] else ...[
            const Text(
              'Aucun dégât déclaré',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionObservations() {
    final observations = _donneesFormulaire!['observations'] as String? ?? '';
    final remarques = _donneesFormulaire!['remarques'] as String? ?? '';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.note_alt, color: Colors.purple[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Observations et remarques',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (observations.isNotEmpty) ...[
            const Text(
              'Observations :',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                observations,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          if (remarques.isNotEmpty) ...[
            const Text(
              'Remarques :',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                remarques,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
          
          if (observations.isEmpty && remarques.isEmpty) ...[
            const Text(
              'Aucune observation ou remarque',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _chargerDonneesFormulaire() async {
    try {
      final donnees = await CollaborativeSessionService.obtenirDonneesFormulaire(
        widget.session.id,
        widget.participant.userId,
      );
      
      if (mounted) setState(() {
        _donneesFormulaire = donnees;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement formulaire: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getLibelleStatut(ParticipantStatus statut) {
    switch (statut) {
      case ParticipantStatus.en_attente:
        return 'En attente';
      case ParticipantStatus.rejoint:
        return 'Rejoint';
      case ParticipantStatus.formulaire_fini:
        return 'Terminé';
      case ParticipantStatus.croquis_valide:
        return 'Validé';
      case ParticipantStatus.signe:
        return 'Signé';
    }
  }
}

