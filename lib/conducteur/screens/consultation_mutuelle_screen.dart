import 'package:flutter/material.dart';
import '../../models/collaborative_session_model.dart';
import '../../services/collaborative_data_sync_service.dart';

/// 👁️ Écran de consultation mutuelle des formulaires
class ConsultationMutuelleScreen extends StatefulWidget {
  final CollaborativeSession session;

  const ConsultationMutuelleScreen({
    Key? key,
    required this.session,
  }) : super(key: key);

  @override
  State<ConsultationMutuelleScreen> createState() => _ConsultationMutuelleScreenState();
}

class _ConsultationMutuelleScreenState extends State<ConsultationMutuelleScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
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
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Consultation Mutuelle',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo[600]!, Colors.indigo[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: CollaborativeDataSyncService.streamTousLesFormulaires(widget.session.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun formulaire disponible',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les formulaires apparaîtront ici une fois remplis',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            final formulaires = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header avec informations de session
                  _buildSessionHeader(),
                  
                  const SizedBox(height: 24),
                  
                  // Liste des formulaires
                  ...formulaires.map((formulaire) {
                    return _buildFormulaireCard(formulaire);
                  }).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 📋 Header avec informations de session
  Widget _buildSessionHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.visibility,
                  color: Colors.indigo[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consultation des Formulaires',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Session: ${widget.session.codeSession}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous pouvez consulter les formulaires des autres participants en lecture seule',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📄 Carte d'un formulaire
  Widget _buildFormulaireCard(Map<String, dynamic> formulaire) {
    final participantId = formulaire['participantId'] as String;
    final participant = widget.session.participants.firstWhere(
      (p) => p.userId == participantId,
      orElse: () => SessionParticipant(
        userId: participantId,
        nom: 'Inconnu',
        prenom: '',
        email: '',
        telephone: '',
        roleVehicule: '?',
        type: ParticipantType.inscrit,
        statut: ParticipantStatus.en_attente,
        estCreateur: false,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header du participant
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.green[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Avatar avec rôle
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      participant.roleVehicule,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${participant.prenom} ${participant.nom}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        participant.email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (participant.estCreateur)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Créateur',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Contenu du formulaire
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Véhicule sélectionné
                if (formulaire['vehiculeSelectionne'] != null)
                  _buildSectionFormulaire(
                    'Véhicule',
                    Icons.directions_car,
                    Colors.blue,
                    _buildVehiculeInfo(formulaire['vehiculeSelectionne']),
                  ),
                
                // Observations
                if (formulaire['observations'] != null && formulaire['observations'].isNotEmpty)
                  _buildSectionFormulaire(
                    'Observations',
                    Icons.note_alt,
                    Colors.orange,
                    Text(
                      formulaire['observations'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                        height: 1.4,
                      ),
                    ),
                  ),
                
                // Circonstances
                if (formulaire['circonstances'] != null && (formulaire['circonstances'] as List).isNotEmpty)
                  _buildSectionFormulaire(
                    'Circonstances',
                    Icons.list_alt,
                    Colors.purple,
                    _buildCirconstancesList(formulaire['circonstances']),
                  ),
                
                // Date de modification
                if (formulaire['dateModification'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Text(
                          'Modifié le ${_formatDate(formulaire['dateModification'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Section du formulaire
  Widget _buildSectionFormulaire(String titre, IconData icon, Color couleur, Widget contenu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: couleur, size: 20),
              const SizedBox(width: 8),
              Text(
                titre,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: couleur,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          contenu,
        ],
      ),
    );
  }

  /// 🚗 Informations du véhicule
  Widget _buildVehiculeInfo(Map<String, dynamic> vehicule) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${vehicule['marque']} ${vehicule['modele']}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Immatriculation: ${vehicule['immatriculation']}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          if (vehicule['numeroContrat'] != null)
            Text(
              'Contrat: ${vehicule['numeroContrat']}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
        ],
      ),
    );
  }

  /// 📝 Liste des circonstances
  Widget _buildCirconstancesList(List<dynamic> circonstances) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: circonstances.map((circonstance) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.purple[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            circonstance.toString(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.purple[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 📅 Formater la date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
