import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/password_reset_service.dart';

/// 🔐 Dialogue de réinitialisation de mot de passe pour les admins compagnie
class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({Key? key}) : super(key: key);

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  List<Map<String, dynamic>> _admins = [];
  bool _isLoading = true;
  String? _selectedAdminId;
  Map<String, dynamic>? _selectedAdmin;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadAdmins();
    });
  }

  Future<void> _loadAdmins() async {
    if (mounted) setState(() {
      _isLoading = true;
    });

    try {
      final admins = await PasswordResetService.getAdminsForPasswordReset();
      if (mounted) setState(() {
        _admins = admins;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading ? _buildLoading() : _buildContent(),
            ),
            const SizedBox(height: 24),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Réinitialisation de mot de passe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sélectionnez un admin pour réinitialiser son mot de passe',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des admins...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_admins.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_rounded,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun admin compagnie trouvé',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sélectionnez un admin compagnie (${_admins.length} trouvé${_admins.length > 1 ? 's' : ''})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _admins.length,
            itemBuilder: (context, index) {
              final admin = _admins[index];
              final isSelected = _selectedAdminId == admin['id'];
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF059669).withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF059669) : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? const Color(0xFF059669) : Colors.grey.shade400,
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    admin['displayName'] ?? 'Sans nom',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF059669) : const Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '📧 ${admin['email']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '🏢 ${admin['compagnieNom'] ?? 'Compagnie inconnue'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: admin['isActive'] == true ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              admin['isActive'] == true ? 'Actif' : 'Inactif',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (admin['requirePasswordChange'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Changement requis',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: isSelected 
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF059669))
                    : null,
                  onTap: () {
                    if (mounted) setState(() {
                      _selectedAdminId = admin['id'];
                      _selectedAdmin = admin;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFF059669)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Annuler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF059669),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _selectedAdmin != null ? _resetPassword : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '🔐 Réinitialiser le mot de passe',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _resetPassword() async {
    if (_selectedAdmin == null) return;

    // Confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔐 Confirmer la réinitialisation'),
        content: Text(
          'Voulez-vous vraiment réinitialiser le mot de passe de :\n\n'
          '👤 ${_selectedAdmin!['displayName']}\n'
          '📧 ${_selectedAdmin!['email']}\n'
          '🏢 ${_selectedAdmin!['compagnieNom']}\n\n'
          'Un nouveau mot de passe sera généré automatiquement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Réinitialisation en cours...'),
          ],
        ),
      ),
    );

    try {
      final result = await PasswordResetService.resetAdminPassword(
        adminId: _selectedAdmin!['id'],
        adminEmail: _selectedAdmin!['email'],
      );

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        // Fermer le dialogue principal et retourner le résultat
        Navigator.of(context).pop(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

