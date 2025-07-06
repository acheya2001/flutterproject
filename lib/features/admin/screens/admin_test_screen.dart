import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';
import '../../../models/admin_models.dart';

class AdminTestScreen extends StatefulWidget {
  const AdminTestScreen({super.key});

  @override
  State<AdminTestScreen> createState() => _AdminTestScreenState();
}

class _AdminTestScreenState extends State<AdminTestScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  String _resultMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Système Admin'),
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tests du Système d\'Administration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTestButton(
                      'Initialiser Super Admin',
                      'Créer le compte administrateur par défaut',
                      Icons.admin_panel_settings,
                      Colors.red,
                      _testInitializeSuperAdmin,
                    ),
                    const SizedBox(height: 8),
                    _buildTestButton(
                      'Créer Compagnie Test',
                      'Créer une compagnie d\'assurance de test',
                      Icons.business,
                      Colors.blue,
                      _testCreateCompagnie,
                    ),
                    const SizedBox(height: 8),
                    _buildTestButton(
                      'Créer Agence Test',
                      'Créer une agence de test',
                      Icons.store,
                      Colors.green,
                      _testCreateAgence,
                    ),
                    const SizedBox(height: 8),
                    _buildTestButton(
                      'Créer Agent Test',
                      'Créer un agent d\'assurance de test',
                      Icons.person,
                      Colors.orange,
                      _testCreateAgent,
                    ),
                    const SizedBox(height: 8),
                    _buildTestButton(
                      'Lister Compagnies',
                      'Afficher toutes les compagnies',
                      Icons.list,
                      Colors.purple,
                      _testListCompagnies,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Test en cours...'),
                    ],
                  ),
                ),
              ),
            if (_resultMessage.isNotEmpty)
              Card(
                color: _resultMessage.startsWith('✅') 
                    ? Colors.green[50] 
                    : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Résultat du Test',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _resultMessage.startsWith('✅') 
                              ? Colors.green[800] 
                              : Colors.red[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _resultMessage,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testInitializeSuperAdmin() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      await _adminService.initialiserSuperAdmin();
      setState(() {
        _resultMessage = '✅ Super admin initialisé avec succès!\n'
            'Email: admin@constat-tunisie.tn\n'
            'Mot de passe: AdminConstat2024!';
      });
    } catch (e) {
      setState(() {
        _resultMessage = '❌ Erreur: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testCreateCompagnie() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      final compagnie = CompagnieAssurance(
        id: '',
        nom: 'Star Assurance Test',
        siret: '12345678901234',
        adresseSiege: '123 Avenue Habib Bourguiba, Tunis',
        telephone: '+216 71 123 456',
        email: 'contact@star-test.tn',
        logoUrl: 'https://example.com/logo.png',
        dateCreation: DateTime.now(),
        description: 'Compagnie de test créée automatiquement',
      );

      final compagnieId = await _adminService.creerCompagnie(compagnie);
      setState(() {
        _resultMessage = '✅ Compagnie créée avec succès!\n'
            'ID: $compagnieId\n'
            'Nom: ${compagnie.nom}';
      });
    } catch (e) {
      setState(() {
        _resultMessage = '❌ Erreur: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testCreateAgence() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      // D'abord, récupérer une compagnie existante
      final compagnies = await _adminService.obtenirCompagnies();
      if (compagnies.isEmpty) {
        setState(() {
          _resultMessage = '❌ Aucune compagnie trouvée. Créez d\'abord une compagnie.';
        });
        return;
      }

      final compagnie = compagnies.first;
      final agence = AgenceAssurance(
        id: '',
        compagnieId: compagnie.id,
        nom: 'Agence Tunis Centre Test',
        code: 'TUN001',
        adresse: '456 Rue de la Liberté, Tunis',
        gouvernorat: 'Tunis',
        ville: 'Tunis',
        telephone: '+216 71 456 789',
        email: 'tunis@star-test.tn',
        responsableId: 'temp_responsable',
        dateCreation: DateTime.now(),
      );

      final agenceId = await _adminService.creerAgence(agence);
      setState(() {
        _resultMessage = '✅ Agence créée avec succès!\n'
            'ID: $agenceId\n'
            'Nom: ${agence.nom}\n'
            'Code: ${agence.code}';
      });
    } catch (e) {
      setState(() {
        _resultMessage = '❌ Erreur: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testCreateAgent() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      // Récupérer une agence existante
      final compagnies = await _adminService.obtenirCompagnies();
      if (compagnies.isEmpty) {
        setState(() {
          _resultMessage = '❌ Aucune compagnie trouvée. Créez d\'abord une compagnie.';
        });
        return;
      }

      final agences = await _adminService.obtenirAgences(compagnies.first.id);
      if (agences.isEmpty) {
        setState(() {
          _resultMessage = '❌ Aucune agence trouvée. Créez d\'abord une agence.';
        });
        return;
      }

      final agence = agences.first;
      final agent = AgentAssurance(
        id: '',
        compagnieId: agence.compagnieId,
        agenceId: agence.id,
        nom: 'Ben Ali',
        prenom: 'Ahmed',
        email: 'ahmed.benali@star-test.tn',
        telephone: '+216 98 123 456',
        matricule: 'AGT001',
        poste: 'Agent Commercial',
        dateCreation: DateTime.now(),
        dateEmbauche: DateTime.now(),
      );

      final agentId = await _adminService.creerAgent(
        agent: agent,
        motDePasse: 'Agent123!',
      );

      setState(() {
        _resultMessage = '✅ Agent créé avec succès!\n'
            'ID: $agentId\n'
            'Nom: ${agent.nomComplet}\n'
            'Email: ${agent.email}\n'
            'Matricule: ${agent.matricule}';
      });
    } catch (e) {
      setState(() {
        _resultMessage = '❌ Erreur: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testListCompagnies() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      final compagnies = await _adminService.obtenirCompagnies();
      
      if (compagnies.isEmpty) {
        setState(() {
          _resultMessage = '📋 Aucune compagnie trouvée.';
        });
      } else {
        final buffer = StringBuffer('✅ ${compagnies.length} compagnie(s) trouvée(s):\n\n');
        for (int i = 0; i < compagnies.length; i++) {
          final compagnie = compagnies[i];
          buffer.writeln('${i + 1}. ${compagnie.nom}');
          buffer.writeln('   SIRET: ${compagnie.siret}');
          buffer.writeln('   Email: ${compagnie.email}');
          buffer.writeln('   Statut: ${compagnie.active ? "Active" : "Inactive"}');
          buffer.writeln();
        }
        
        setState(() {
          _resultMessage = buffer.toString();
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = '❌ Erreur: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
