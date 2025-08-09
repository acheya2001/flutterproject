import 'package:flutter/material.dart';
import '../../../services/admin_agence_service.dart';

/// 👁️ Écran de détails d'un agent
class AgentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> agentData;
  final Map<String, dynamic> agenceData;

  const AgentDetailsScreen({
    Key? key,
    required this.agentData,
    required this.agenceData,
  }) : super(key: key);

  @override
  State<AgentDetailsScreen> createState() => _AgentDetailsScreenState();
}

class _AgentDetailsScreenState extends State<AgentDetailsScreen> {
  late Map<String, dynamic> _agentData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _agentData = Map.from(widget.agentData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Contenu principal
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading ? _buildLoadingContent() : _buildMainContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Header
  Widget _buildHeader() {
    final isActive = _agentData['isActive'] == true;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              '${_agentData['prenom']?[0] ?? ''}${_agentData['nom']?[0] ?? ''}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_agentData['prenom']} ${_agentData['nom']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Agent - ${widget.agenceData['nom']}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive 
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? Colors.green : Colors.red,
              ),
            ),
            child: Text(
              isActive ? 'ACTIF' : 'INACTIF',
              style: TextStyle(
                color: isActive ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔄 Contenu de chargement
  Widget _buildLoadingContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF10B981)),
          SizedBox(height: 20),
          Text(
            'Mise à jour en cours...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 📱 Contenu principal
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations personnelles
          _buildPersonalInfoCard(),
          const SizedBox(height: 24),
          
          // Informations professionnelles
          _buildProfessionalInfoCard(),
          const SizedBox(height: 24),
          
          // Historique et métadonnées
          _buildHistoryCard(),
          const SizedBox(height: 30),
          
          // Actions
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// 👤 Carte informations personnelles
  Widget _buildPersonalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.person_rounded,
                color: Color(0xFF10B981),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Informations Personnelles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildDetailRow('Prénom', _agentData['prenom']),
          _buildDetailRow('Nom', _agentData['nom']),
          _buildDetailRow('Email', _agentData['email']),
          _buildDetailRow('Téléphone', _agentData['telephone']),
          if (_agentData['cin'] != null && _agentData['cin'].toString().isNotEmpty)
            _buildDetailRow('CIN', _agentData['cin']),
          if (_agentData['adresse'] != null && _agentData['adresse'].toString().isNotEmpty)
            _buildDetailRow('Adresse', _agentData['adresse']),
        ],
      ),
    );
  }

  /// 🏢 Carte informations professionnelles
  Widget _buildProfessionalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.work_rounded,
                color: Color(0xFF10B981),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Informations Professionnelles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildDetailRow('Rôle', _agentData['role'] ?? 'Agent'),
          _buildDetailRow('Agence', _agentData['agenceNom']),
          _buildDetailRow('Compagnie', _agentData['compagnieNom']),
          _buildDetailRow('Statut', _agentData['isActive'] == true ? 'Actif' : 'Inactif'),
          _buildDetailRow('Status', _agentData['status'] ?? 'Non défini'),
        ],
      ),
    );
  }

  /// 📊 Carte historique
  Widget _buildHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: Color(0xFF10B981),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Historique & Métadonnées',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_agentData['createdAt'] != null)
            _buildDetailRow('Date de création', _formatDate(_agentData['createdAt'])),
          if (_agentData['updatedAt'] != null)
            _buildDetailRow('Dernière modification', _formatDate(_agentData['updatedAt'])),
          _buildDetailRow('Créé par', _agentData['createdBy'] ?? 'Non défini'),
          _buildDetailRow('Origine', _agentData['origin'] ?? 'Non définie'),
          if (_agentData['statusChangedAt'] != null)
            _buildDetailRow('Statut modifié le', _formatDate(_agentData['statusChangedAt'])),
        ],
      ),
    );
  }

  /// 📝 Ligne de détail
  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'Non défini',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Boutons d'action
  Widget _buildActionButtons() {
    final isActive = _agentData['isActive'] == true;
    
    return Column(
      children: [
        // Première ligne : Modifier et Changer statut
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _editAgent,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Modifier'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _toggleStatus,
                icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded),
                label: Text(isActive ? 'Désactiver' : 'Activer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Deuxième ligne : Supprimer
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _deleteAgent,
            icon: const Icon(Icons.delete_rounded),
            label: const Text('Supprimer l\'Agent'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// ✏️ Modifier l'agent
  void _editAgent() {
    // TODO: Implémenter l'édition d'agent
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modification d\'agent - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// 🔄 Changer le statut
  void _toggleStatus() async {
    final isActive = _agentData['isActive'] == true;
    final newStatus = !isActive;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${newStatus ? 'Activer' : 'Désactiver'} l\'agent'),
        content: Text(
          'Voulez-vous vraiment ${newStatus ? 'activer' : 'désactiver'} cet agent ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.red,
            ),
            child: Text(newStatus ? 'Activer' : 'Désactiver'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      final result = await AdminAgenceService.toggleAgentStatus(
        agentId: _agentData['id'],
        newStatus: newStatus,
        reason: newStatus ? 'Réactivation par admin agence' : 'Désactivation par admin agence',
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        setState(() {
          _agentData['isActive'] = newStatus;
          _agentData['status'] = newStatus ? 'actif' : 'inactif';
        });
      }
    }
  }

  /// 🗑️ Supprimer l'agent
  void _deleteAgent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'agent'),
        content: Text(
          'Voulez-vous vraiment supprimer l\'agent ${_agentData['prenom']} ${_agentData['nom']} ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      final result = await AdminAgenceService.deleteAgent(_agentData['id']);

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        Navigator.pop(context, true); // Retourner avec succès
      }
    }
  }

  /// 📅 Formater une date
  String _formatDate(dynamic date) {
    if (date == null) return 'Non défini';
    
    try {
      if (date is DateTime) {
        return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        final dateTime = date.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Format invalide';
    }
  }
}
