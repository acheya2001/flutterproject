import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../services/expert_pdf_service.dart';

/// 📋 Écran de détails de mission pour l'expert
class MissionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> mission;
  final Map<String, dynamic>? expertData;

  const MissionDetailsScreen({
    Key? key,
    required this.mission,
    this.expertData,
  }) : super(key: key);

  @override
  State<MissionDetailsScreen> createState() => _MissionDetailsScreenState();
}

class _MissionDetailsScreenState extends State<MissionDetailsScreen> {
  Map<String, dynamic>? _constatData;
  Map<String, dynamic>? _sinistreData;
  bool _isLoading = true;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadMissionData();
  }

  /// 📋 Charger les données de la mission
  Future<void> _loadMissionData() async {
    setState(() => _isLoading = true);
    try {
      // Charger les données du constat
      final constatId = widget.mission['constatId'];
      if (constatId != null) {
        final constatDoc = await FirebaseFirestore.instance
            .collection('constats')
            .doc(constatId)
            .get();
        
        if (constatDoc.exists) {
          _constatData = constatDoc.data()!;
          _constatData!['id'] = constatDoc.id;
        }
      }

      // Charger les données du sinistre
      final sinistreId = widget.mission['sinistreId'];
      if (sinistreId != null) {
        final sinistreDoc = await FirebaseFirestore.instance
            .collection('sinistres')
            .doc(sinistreId)
            .get();
        
        if (sinistreDoc.exists) {
          _sinistreData = sinistreDoc.data()!;
          _sinistreData!['id'] = sinistreDoc.id;
        }
      }

    } catch (e) {
      debugPrint('[MISSION_DETAILS] ❌ Erreur chargement données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingWidget() : _buildBody(),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  /// 📱 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Mission ${widget.mission['numeroConstat'] ?? 'N/A'}'),
      backgroundColor: const Color(0xFF667EEA),
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  /// ⏳ Widget de chargement
  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
      ),
    );
  }

  /// 📱 Corps principal
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMissionInfoCard(),
          const SizedBox(height: 16),
          if (_constatData != null) _buildConstatCard(),
          const SizedBox(height: 16),
          if (_sinistreData != null) _buildSinistreCard(),
          const SizedBox(height: 100), // Espace pour les boutons du bas
        ],
      ),
    );
  }

  /// 📋 Carte d'informations de la mission
  Widget _buildMissionInfoCard() {
    final statut = widget.mission['statut'] ?? 'assignee';
    final dateAssignation = widget.mission['dateAssignation'] as Timestamp?;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Informations Mission',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(statut),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('N° Constat', widget.mission['numeroConstat'] ?? 'N/A'),
          const SizedBox(height: 8),
          if (dateAssignation != null)
            _buildInfoRow(
              'Date d\'assignation',
              DateFormat('dd/MM/yyyy à HH:mm').format(dateAssignation.toDate()),
            ),
          const SizedBox(height: 8),
          _buildInfoRow('Expert', '${widget.expertData?['prenom']} ${widget.expertData?['nom']}'),
        ],
      ),
    );
  }

  /// 📄 Carte du constat
  Widget _buildConstatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description, color: Color(0xFF667EEA), size: 24),
              SizedBox(width: 12),
              Text(
                'Détails du Constat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Date accident', _constatData?['dateAccident'] ?? 'N/A'),
          _buildDetailRow('Lieu accident', _constatData?['lieuAccident'] ?? 'N/A'),
          _buildDetailRow('Circonstances', _constatData?['circonstances'] ?? 'N/A'),
          _buildDetailRow('Dégâts matériels', _constatData?['degatsMateriels'] ?? 'N/A'),
          _buildDetailRow('Blessés', _constatData?['blesses'] ?? 'Non'),
        ],
      ),
    );
  }

  /// 🚗 Carte du sinistre
  Widget _buildSinistreCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.car_crash, color: Color(0xFF667EEA), size: 24),
              SizedBox(width: 12),
              Text(
                'Informations Sinistre',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('N° Sinistre', _sinistreData?['numeroSinistre'] ?? 'N/A'),
          _buildDetailRow('Type sinistre', _sinistreData?['typeSinistre'] ?? 'N/A'),
          _buildDetailRow('Statut', _sinistreData?['statut'] ?? 'N/A'),
          _buildDetailRow('Montant estimé', '${_sinistreData?['montantEstime'] ?? 0} DT'),
        ],
      ),
    );
  }

  /// 📋 Ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// 📋 Ligne de détail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🏷️ Label du statut
  String _getStatusLabel(String statut) {
    switch (statut) {
      case 'assignee':
        return 'En attente';
      case 'en_cours':
        return 'En cours';
      case 'terminee':
        return 'Terminée';
      default:
        return 'Inconnu';
    }
  }

  /// 🔘 Actions du bas
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isGeneratingPdf ? null : _generateExpertisePdf,
              icon: _isGeneratingPdf
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isGeneratingPdf ? 'Génération...' : 'Générer PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _markAsCompleted,
              icon: const Icon(Icons.check_circle),
              label: const Text('Terminer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📄 Générer le PDF d'expertise
  Future<void> _generateExpertisePdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      await ExpertPdfService.generateExpertisePdf(
        mission: widget.mission,
        constatData: _constatData,
        sinistreData: _sinistreData,
        expertData: widget.expertData,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF d\'expertise généré avec succès'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la génération du PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  /// ✅ Marquer comme terminé
  Future<void> _markAsCompleted() async {
    try {
      await FirebaseFirestore.instance
          .collection('missions_expertise')
          .doc(widget.mission['id'])
          .update({
        'statut': 'terminee',
        'dateTerminaison': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mission marquée comme terminée'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
