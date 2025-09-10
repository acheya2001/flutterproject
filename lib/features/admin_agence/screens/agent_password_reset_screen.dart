import 'package:flutter/material.dart';
import '../../../services/agent_password_reset_service.dart';

/// 🔧 Écran pour réinitialiser le mot de passe des agents
class AgentPasswordResetScreen extends StatefulWidget {
  const AgentPasswordResetScreen({Key? key}) : super(key: key);

  @override
  State<AgentPasswordResetScreen> createState() => _AgentPasswordResetScreenState();
}

class _AgentPasswordResetScreenState extends State<AgentPasswordResetScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _agentsWithTempPassword = [];

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadAgentsWithTempPassword();
    });
  }

  Future<void> _loadAgentsWithTempPassword() async {
    final agents = await AgentPasswordResetService.getAgentsWithTemporaryPassword();
    if (mounted) setState(() {
      _agentsWithTempPassword = agents;
    });
  }

  Future<void> _setTemporaryPassword() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Veuillez remplir tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AgentPasswordResetService.setTemporaryPassword(
        agentEmail: _emailController.text.trim(),
        temporaryPassword: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: Colors.green,
          ),
        );

        // Vider les champs
        _emailController.clear();
        _passwordController.clear();

        // Recharger la liste
        _loadAgentsWithTempPassword();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Réinitialisation Mot de Passe Agent'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formulaire de réinitialisation
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_reset, color: Colors.orange.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'Définir un mot de passe temporaire',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Email de l'agent
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email de l\'agent',
                        hintText: 'testagent@gmail.com',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    
                    // Mot de passe temporaire
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe temporaire',
                        hintText: 'agent123',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Bouton de réinitialisation
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _setTemporaryPassword,
                        icon: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_reset),
                        label: Text(_isLoading ? 'Définition...' : 'Définir le mot de passe'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Liste des agents avec mot de passe temporaire
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'Agents avec mot de passe temporaire',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_agentsWithTempPassword.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Aucun agent avec mot de passe temporaire',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _agentsWithTempPassword.length,
                        itemBuilder: (context, index) {
                          final agent = _agentsWithTempPassword[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange.shade100,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                              title: Text('${agent['prenom']} ${agent['nom']}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(agent['email']),
                                  Text(
                                    'Mot de passe: ${agent['temporaryPassword']}',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.lock_clock,
                                color: Colors.orange.shade600,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Card(
              elevation: 2,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Saisissez l\'email de l\'agent créé (testagent@gmail.com)\n'
                      '2. Définissez un mot de passe temporaire simple (ex: agent123)\n'
                      '3. L\'agent pourra se connecter avec ces identifiants\n'
                      '4. Le mot de passe temporaire sera supprimé après la première connexion',
                      style: TextStyle(fontSize: 14),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

