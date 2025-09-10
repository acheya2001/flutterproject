import 'package:flutter/material.dart';
import '../../../services/agent_service.dart';

/// 🚨 Écran de gestion des sinistres
class SinistresScreen extends StatefulWidget {
  final Map<String, dynamic> agentData;
  final Map<String, dynamic> userData;

  const SinistresScreen({
    Key? key,
    required this.agentData,
    required this.userData,
  }) : super(key: key);

  @override
  State<SinistresScreen> createState() => _SinistresScreenState();
}

class _SinistresScreenState extends State<SinistresScreen> {
  List<Map<String, dynamic>> _sinistres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadSinistres();
    });
  }

  /// 🚨 Charger les sinistres
  Future<void> _loadSinistres() async {
    setState(() => _isLoading = true);

    try {
      final sinistres = await AgentService.getAgentSinistres(widget.agentData['id']);
      setState(() => _sinistres = sinistres);
    } catch (e) {
      debugPrint('[SINISTRES] ❌ Erreur chargement sinistres: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _declarerSinistre,
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.report_problem_rounded),
        label: const Text('Déclarer Sinistre'),
      ),
    );
  }

  /// 📋 Header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestion des Sinistres',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_sinistres.length} sinistre(s) traité(s)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
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
          CircularProgressIndicator(color: Color(0xFFEF4444)),
          SizedBox(height: 20),
          Text(
            'Chargement des sinistres...',
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
    if (_sinistres.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _sinistres.length,
      itemBuilder: (context, index) {
        final sinistre = _sinistres[index];
        return _buildSinistreCard(sinistre);
      },
    );
  }

  /// 🚨 Carte de sinistre
  Widget _buildSinistreCard(Map<String, dynamic> sinistre) {
    final statut = sinistre['statut'] ?? 'ouvert';
    Color statutColor;
    
    switch (statut) {
      case 'ouvert':
        statutColor = Colors.orange;
        break;
      case 'en_cours':
        statutColor = Colors.blue;
        break;
      case 'clos':
        statutColor = Colors.green;
        break;
      case 'rejete':
        statutColor = Colors.red;
        break;
      default:
        statutColor = Colors.grey;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: statutColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sinistre['numeroSinistre'] ?? 'N° non défini',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sinistre['typeSinistre'] ?? 'Type non défini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statut.toUpperCase(),
                    style: TextStyle(
                      color: statutColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSinistreInfo('Date', _formatDate(sinistre['dateSinistre'])),
                ),
                Expanded(
                  child: _buildSinistreInfo('Lieu', sinistre['lieuSinistre'] ?? 'N/A'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📝 Information du sinistre
  Widget _buildSinistreInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  /// 📭 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun sinistre déclaré',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Heureusement, aucun sinistre n\'a été déclaré',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _declarerSinistre,
            icon: const Icon(Icons.report_problem_rounded),
            label: const Text('Déclarer un Sinistre'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚨 Déclarer un sinistre
  void _declarerSinistre() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Déclaration de sinistre - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// 📅 Formater une date
  String _formatDate(dynamic date) {
    if (date == null) return 'Non défini';
    
    try {
      DateTime dateTime;
      if (date is DateTime) {
        dateTime = date;
      } else {
        dateTime = date.toDate();
      }
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Format invalide';
    }
  }
}

