import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 👁️ Écran de détails d'une agence
class AgenceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> agenceData;
  final Map<String, dynamic> userData;

  const AgenceDetailsScreen({
    Key? key,
    required this.agenceData,
    required this.userData,
  }) : super(key: key);

  @override
  State<AgenceDetailsScreen> createState() => _AgenceDetailsScreenState();
}

class _AgenceDetailsScreenState extends State<AgenceDetailsScreen> {
  Map<String, dynamic>? _adminAgence;
  List<Map<String, dynamic>> _agents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadAgenceDetails();
    });
  }

  /// 📊 Charger les détails de l'agence
  Future<void> _loadAgenceDetails() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger l'admin agence s'il existe ET est actif
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin_agence')
          .where('agenceId', isEqualTo: widget.agenceData['id'])
          .where('isActive', isEqualTo: true) // Seulement les admins actifs
          .limit(1)
          .get();

      if (adminSnapshot.docs.isNotEmpty) {
        _adminAgence = adminSnapshot.docs.first.data();
        _adminAgence!['id'] = adminSnapshot.docs.first.id;
      }
      
      // Charger les agents de l'agence
      final agentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: widget.agenceData['id'])
          .get();
      
      _agents = agentsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
    } catch (e) {
      debugPrint('Erreur chargement détails agence: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  /// 🎨 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.agenceData['nom'] ?? 'Détails Agence',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontSize: 18,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _loadAgenceDetails,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  /// ⏳ État de chargement
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
      ),
    );
  }

  /// 📱 Contenu principal
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations générales de l'agence
          _buildAgenceInfoCard(),
          const SizedBox(height: 20),
          
          // Admin agence
          _buildAdminAgenceCard(),
          const SizedBox(height: 20),
          
          // Agents de l'agence
          _buildAgentsCard(),
          const SizedBox(height: 20),
          
          // Statistiques
          _buildStatisticsCard(),
        ],
      ),
    );
  }

  /// 🏢 Carte informations agence
  Widget _buildAgenceInfoCard() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Color(0xFF667EEA),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations Générales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Code: ${widget.agenceData['code'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.agenceData['isActive'] != false 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.agenceData['isActive'] != false 
                        ? Colors.green 
                        : Colors.red,
                  ),
                ),
                child: Text(
                  widget.agenceData['isActive'] != false ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: widget.agenceData['isActive'] != false 
                        ? Colors.green 
                        : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Détails
          _buildDetailRow(Icons.location_on_rounded, 'Adresse', widget.agenceData['adresse']),
          _buildDetailRow(Icons.map_rounded, 'Gouvernorat', widget.agenceData['gouvernorat']),
          _buildDetailRow(Icons.phone_rounded, 'Téléphone', widget.agenceData['telephone']),
          _buildDetailRow(Icons.email_rounded, 'Email', widget.agenceData['emailContact']),
          _buildDetailRow(Icons.business_center_rounded, 'Compagnie', widget.agenceData['compagnieNom']),
          if (widget.agenceData['description'] != null && widget.agenceData['description'].isNotEmpty)
            _buildDetailRow(Icons.description_rounded, 'Description', widget.agenceData['description']),
        ],
      ),
    );
  }

  /// 👨‍💼 Carte admin agence
  Widget _buildAdminAgenceCard() {
    final hasAdmin = widget.agenceData['hasAdminAgence'] == true;
    
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasAdmin 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasAdmin 
                      ? Icons.admin_panel_settings_rounded
                      : Icons.person_off_rounded,
                  color: hasAdmin ? Colors.green : Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  hasAdmin ? 'Admin Agence' : 'Aucun Admin Agence',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (hasAdmin && _adminAgence != null) ...[
            // Informations admin
            _buildDetailRow(Icons.person_rounded, 'Nom', '${_adminAgence!['prenom']} ${_adminAgence!['nom']}'),
            _buildDetailRow(Icons.email_rounded, 'Email', _adminAgence!['email']),
            _buildDetailRow(Icons.phone_rounded, 'Téléphone', _adminAgence!['telephone']),
            _buildDetailRow(Icons.credit_card_rounded, 'CIN', _adminAgence!['cin']),
            
            Row(
              children: [
                Icon(Icons.circle, 
                    size: 12, 
                    color: _adminAgence!['isActive'] == true ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Text(
                  _adminAgence!['isActive'] == true ? 'Actif' : 'Inactif',
                  style: TextStyle(
                    color: _adminAgence!['isActive'] == true ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_rounded, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cette agence n\'a pas d\'admin assigné. Vous pouvez en créer un ou en affecter un existant.',
                      style: TextStyle(color: Colors.orange),
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

  /// 👥 Carte agents
  Widget _buildAgentsCard() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Agents (${_agents.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_agents.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_rounded, color: Colors.grey),
                  SizedBox(width: 12),
                  Text(
                    'Aucun agent assigné à cette agence',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...(_agents.take(5).map((agent) => _buildAgentItem(agent))),
            if (_agents.length > 5) ...[
              const SizedBox(height: 8),
              Text(
                'Et ${_agents.length - 5} autres agents...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// 📊 Carte statistiques
  Widget _buildStatisticsCard() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Agents', _agents.length.toString(), Icons.people_rounded, Colors.blue),
              ),
              Expanded(
                child: _buildStatItem('Constats', widget.agenceData['nombreConstats']?.toString() ?? '0', Icons.description_rounded, Colors.green),
              ),
              Expanded(
                child: _buildStatItem('Experts', widget.agenceData['nombreExperts']?.toString() ?? '0', Icons.engineering_rounded, Colors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📝 Ligne de détail
  Widget _buildDetailRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 Item agent
  Widget _buildAgentItem(Map<String, dynamic> agent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(
              '${agent['prenom']?[0] ?? ''}${agent['nom']?[0] ?? ''}',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${agent['prenom']} ${agent['nom']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  agent['email'] ?? 'Email non défini',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: agent['isActive'] == true 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              agent['isActive'] == true ? 'Actif' : 'Inactif',
              style: TextStyle(
                color: agent['isActive'] == true ? Colors.green : Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Item statistique
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

