import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/constat_agent_notification_service.dart';

/// 📋 Écran des constats reçus par l'agent
class AgentConstatsScreen extends StatefulWidget {
  const AgentConstatsScreen({super.key});

  @override
  State<AgentConstatsScreen> createState() => _AgentConstatsScreenState();
}

class _AgentConstatsScreenState extends State<AgentConstatsScreen> {
  final String? _agentId = FirebaseAuth.instance.currentUser?.uid;
  String _filtreStatut = 'tous';

  @override
  Widget build(BuildContext context) {
    if (_agentId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Erreur: Agent non connecté'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Mes Constats'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filtreStatut = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'tous', child: Text('Tous les constats')),
              const PopupMenuItem(value: 'nouveau', child: Text('Nouveaux')),
              const PopupMenuItem(value: 'vu', child: Text('Vus')),
              const PopupMenuItem(value: 'traite', child: Text('Traités')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatistiques(),
          Expanded(child: _buildListeConstats()),
        ],
      ),
    );
  }

  /// 📊 Widget des statistiques
  Widget _buildStatistiques() {
    return StreamBuilder<QuerySnapshot>(
      stream: ConstatAgentNotificationService.getConstatsAgent(_agentId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final constats = snapshot.data!.docs;
        final nouveaux = constats.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['statutTraitement'] == 'nouveau';
        }).length;

        final traites = constats.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['statutTraitement'] == 'traite';
        }).length;

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total', constats.length, Colors.blue),
              _buildStatCard('Nouveaux', nouveaux, Colors.orange),
              _buildStatCard('Traités', traites, Colors.green),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String titre, int valeur, Color couleur) {
    return Column(
      children: [
        Text(
          valeur.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: couleur,
          ),
        ),
        Text(
          titre,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 📋 Widget de la liste des constats
  Widget _buildListeConstats() {
    return StreamBuilder<QuerySnapshot>(
      stream: ConstatAgentNotificationService.getConstatsAgent(_agentId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final constats = snapshot.data?.docs ?? [];

        // Filtrer selon le statut sélectionné
        final constatsFiltres = constats.where((doc) {
          if (_filtreStatut == 'tous') return true;
          final data = doc.data() as Map<String, dynamic>;
          return data['statutTraitement'] == _filtreStatut;
        }).toList();

        if (constatsFiltres.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _filtreStatut == 'tous' 
                      ? 'Aucun constat reçu'
                      : 'Aucun constat $_filtreStatut',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: constatsFiltres.length,
          itemBuilder: (context, index) {
            final constatDoc = constatsFiltres[index];
            final constatData = constatDoc.data() as Map<String, dynamic>;
            return _buildConstatCard(constatDoc.id, constatData);
          },
        );
      },
    );
  }

  /// 🎯 Widget d'une carte de constat
  Widget _buildConstatCard(String constatId, Map<String, dynamic> data) {
    final statut = data['statutTraitement'] as String? ?? 'nouveau';
    final isNouveau = statut == 'nouveau';
    
    Color statutColor;
    IconData statutIcon;
    
    switch (statut) {
      case 'nouveau':
        statutColor = Colors.orange;
        statutIcon = Icons.fiber_new;
        break;
      case 'vu':
        statutColor = Colors.blue;
        statutIcon = Icons.visibility;
        break;
      case 'traite':
        statutColor = Colors.green;
        statutIcon = Icons.check_circle;
        break;
      default:
        statutColor = Colors.grey;
        statutIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isNouveau ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNouveau 
            ? BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _ouvrirDetailConstat(constatId, data),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut
              Row(
                children: [
                  Icon(statutIcon, color: statutColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    statut.toUpperCase(),
                    style: TextStyle(
                      color: statutColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Code: ${data['codeConstat']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informations client
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Client: ${data['clientNom']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Informations accident
              Row(
                children: [
                  const Icon(Icons.directions_car, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Véhicule ${data['clientRole']} - ${data['nombreVehicules']} véhicules',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Date
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(data['dateEnvoiPdf']),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Actions
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _telechargerPDF(data['pdfUrl']),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  if (isNouveau)
                    ElevatedButton.icon(
                      onPressed: () => _marquerCommeVu(constatId),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Marquer vu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📅 Formater une date
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Date inconnue';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Date invalide';
    }
    
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// 📥 Télécharger le PDF
  Future<void> _telechargerPDF(String? pdfUrl) async {
    if (pdfUrl == null || pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Lien PDF non disponible')),
      );
      return;
    }

    try {
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Impossible d\'ouvrir le lien';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur ouverture PDF: $e')),
      );
    }
  }

  /// 👁️ Marquer comme vu
  Future<void> _marquerCommeVu(String constatId) async {
    await ConstatAgentNotificationService.marquerConstatVu(constatId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Constat marqué comme vu')),
    );
  }

  /// 📋 Ouvrir le détail du constat
  void _ouvrirDetailConstat(String constatId, Map<String, dynamic> data) {
    // TODO: Implémenter l'écran de détail
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Constat ${data['codeConstat']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${data['clientNom']}'),
            Text('Véhicule: ${data['clientRole']}'),
            Text('Type: ${data['typeAccident']}'),
            Text('Statut: ${data['statutTraitement']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
