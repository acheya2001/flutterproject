// lib/presentation/screens/report/start_report_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:constat_tunisie/core/providers/auth_provider.dart';
import 'package:constat_tunisie/core/theme/app_theme.dart';
import 'package:constat_tunisie/data/services/report_service.dart';

class StartReportScreen extends StatefulWidget {
  const StartReportScreen({super.key});

  @override
  State<StartReportScreen> createState() => _StartReportScreenState();
}

class _StartReportScreenState extends State<StartReportScreen> {
  final ReportService _reportService = ReportService();
  bool _isLoading = false;
  String? _invitationCode;
  final TextEditingController _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Constat'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Constat Amiable d\'Accident Automobile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bienvenue ${user?.displayName ?? ""}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Comment souhaitez-vous procéder?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Options
                  _buildOptionCard(
                    title: 'Créer un nouveau constat',
                    description: 'Vous êtes sur place avec l\'autre conducteur',
                    icon: Icons.add_circle,
                    color: Colors.blue,
                    onTap: () => _startNewReport(context),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildOptionCard(
                    title: 'Rejoindre un constat existant',
                    description: 'L\'autre conducteur a déjà créé un constat',
                    icon: Icons.group_add,
                    color: Colors.green,
                    onTap: () => _showJoinDialog(context),
                  ),
                  
                  if (_invitationCode != null) ...[
                    const SizedBox(height: 24),
                    
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Code d\'invitation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _invitationCode!,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () => _copyToClipboard(_invitationCode!),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Partagez ce code avec l\'autre conducteur pour qu\'il puisse rejoindre votre constat.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                radius: 24,
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startNewReport(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Générer un code d'invitation
      final code = _reportService.generateInvitationCode();
      setState(() {
        _invitationCode = code;
        _isLoading = false;
      });
      
      // Naviguer vers l'écran de création de constat
      Navigator.of(context).pushNamed(
        '/report/create',
        arguments: {'invitationCode': code},
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _showJoinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejoindre un constat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez le code d\'invitation fourni par l\'autre conducteur:'),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Code d\'invitation',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _joinReport(context),
            child: const Text('Rejoindre'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinReport(BuildContext context) async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un code d\'invitation')),
      );
      return;
    }
    
    Navigator.of(context).pop(); // Fermer le dialogue
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final report = await _reportService.getReportByInvitationCode(code);
      
      setState(() {
        _isLoading = false;
      });
      
      if (report != null) {
        Navigator.of(context).pushNamed(
          '/report/join',
          arguments: {'reportId': report.id, 'invitationCode': code},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code d\'invitation invalide')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _copyToClipboard(String text) {
    // Implémenter la copie dans le presse-papier
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copié dans le presse-papier')),
    );
  }
}