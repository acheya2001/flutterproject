import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/constat_pdf_service.dart';

/// 📄 Écran des constats PDF reçus pour les agents
class ConstatsRecusScreen extends StatefulWidget {
  const ConstatsRecusScreen({Key? key}) : super(key: key);

  @override
  State<ConstatsRecusScreen> createState() => _ConstatsRecusScreenState();
}

class _ConstatsRecusScreenState extends State<ConstatsRecusScreen> {
  List<Map<String, dynamic>> _envois = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, non_lu, lu

  @override
  void initState() {
    super.initState();
    _loadEnvois();
  }

  /// 📋 Charger les envois de constats
  Future<void> _loadEnvois() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final envois = await ConstatPdfService.getEnvoisForAgent(user.uid);
      setState(() => _envois = envois);
    } catch (e) {
      debugPrint('[CONSTATS_RECUS] ❌ Erreur chargement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔍 Filtrer les envois
  List<Map<String, dynamic>> get _filteredEnvois {
    switch (_filter) {
      case 'non_lu':
        return _envois.where((envoi) => envoi['lu'] == false).toList();
      case 'lu':
        return _envois.where((envoi) => envoi['lu'] == true).toList();
      default:
        return _envois;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Constats PDF Reçus'),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEnvois,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEnvois.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _filteredEnvois.length,
                        itemBuilder: (context, index) {
                          return _buildEnvoiCard(_filteredEnvois[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// 🔍 Barre de filtres
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            'Filtrer:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tous', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Non lus', 'non_lu'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Lus', 'lu'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🏷️ Chip de filtre
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    final nonLusCount = _envois.where((e) => e['lu'] == false).length;
    
    return FilterChip(
      label: Text(
        value == 'non_lu' && nonLusCount > 0 ? '$label ($nonLusCount)' : label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF64748B),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filter = value);
      },
      selectedColor: const Color(0xFF667EEA),
      backgroundColor: Colors.grey.shade100,
      checkmarkColor: Colors.white,
    );
  }

  /// 📭 État vide
  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_filter) {
      case 'non_lu':
        message = 'Aucun constat non lu';
        icon = Icons.mark_email_read;
        break;
      case 'lu':
        message = 'Aucun constat lu';
        icon = Icons.drafts;
        break;
      default:
        message = 'Aucun constat reçu';
        icon = Icons.inbox;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les constats PDF envoyés par les conducteurs apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 📄 Carte d'envoi de constat
  Widget _buildEnvoiCard(Map<String, dynamic> envoi) {
    final isRead = envoi['lu'] == true;
    final sinistreInfo = envoi['sinistreInfo'] as Map<String, dynamic>? ?? {};
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isRead ? null : Border.all(
          color: const Color(0xFF667EEA),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Row(
              children: [
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF667EEA),
                      shape: BoxShape.circle,
                    ),
                  ),
                if (!isRead) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Constat PDF - ${sinistreInfo['numeroSinistre'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(envoi['dateEnvoi']),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.grey.shade100 : const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isRead ? 'Lu' : 'Nouveau',
                    style: TextStyle(
                      color: isRead ? Colors.grey.shade600 : const Color(0xFF667EEA),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Informations du sinistre
            _buildInfoRow('Type d\'accident', sinistreInfo['typeAccident'] ?? 'N/A'),
            _buildInfoRow('Lieu', sinistreInfo['lieuAccident'] ?? 'N/A'),
            _buildInfoRow('Date accident', _formatDate(sinistreInfo['dateAccident'])),
            _buildInfoRow('Fichier', envoi['fileName'] ?? 'constat.pdf'),

            if (envoi['message'] != null && envoi['message'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Message du conducteur:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      envoi['message'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Actions
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openPdf(envoi),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('Ouvrir PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showSinistreDetails(envoi),
                  icon: const Icon(Icons.info, size: 16),
                  label: const Text('Détails'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📝 Ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📅 Formater la date
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is String) {
      dateTime = DateTime.tryParse(date) ?? DateTime.now();
    } else {
      return 'N/A';
    }
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 📄 Ouvrir le PDF
  Future<void> _openPdf(Map<String, dynamic> envoi) async {
    try {
      // Marquer comme lu
      if (envoi['lu'] != true) {
        await ConstatPdfService.markAsRead(envoi['id']);
        setState(() {
          envoi['lu'] = true;
        });
      }

      // Ouvrir le PDF
      final pdfUrl = envoi['pdfUrl'];
      if (pdfUrl != null) {
        final uri = Uri.parse(pdfUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Impossible d\'ouvrir le PDF');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur ouverture PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 👁️ Afficher les détails du sinistre
  void _showSinistreDetails(Map<String, dynamic> envoi) {
    final sinistreInfo = envoi['sinistreInfo'] as Map<String, dynamic>? ?? {};
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails ${sinistreInfo['numeroSinistre'] ?? 'N/A'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Numéro sinistre', sinistreInfo['numeroSinistre'] ?? 'N/A'),
              _buildDetailRow('Type accident', sinistreInfo['typeAccident'] ?? 'N/A'),
              _buildDetailRow('Date accident', _formatDate(sinistreInfo['dateAccident'])),
              _buildDetailRow('Lieu', sinistreInfo['lieuAccident'] ?? 'N/A'),
              _buildDetailRow('Fichier PDF', envoi['fileName'] ?? 'N/A'),
              _buildDetailRow('Date envoi', _formatDate(envoi['dateEnvoi'])),
              _buildDetailRow('Statut', envoi['lu'] == true ? 'Lu' : 'Non lu'),
              if (envoi['message'] != null && envoi['message'].toString().isNotEmpty)
                _buildDetailRow('Message', envoi['message']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openPdf(envoi);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA)),
            child: const Text('Ouvrir PDF'),
          ),
        ],
      ),
    );
  }

  /// 📝 Ligne de détail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
