import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/admin_compagnie_crud_service.dart';

/// 📋 Écran de détails et CRUD pour un Admin Compagnie
class AdminCompagnieDetailsScreen extends StatefulWidget {
  final String adminId;
  final String adminName;

  const AdminCompagnieDetailsScreen({
    Key? key,
    required this.adminId,
    required this.adminName,
  }) : super(key: key);

  @override
  State<AdminCompagnieDetailsScreen> createState() => _AdminCompagnieDetailsScreenState();
}

class _AdminCompagnieDetailsScreenState extends State<AdminCompagnieDetailsScreen> {
  Map<String, dynamic>? _adminData;
  bool _isLoading = true;
  bool _isEditing = false;

  // Contrôleurs pour l'édition
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadAdminData();
    });
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await AdminCompagnieCrudService.getAdminCompagnieById(widget.adminId);
      setState(() {
        _adminData = data;
        _isLoading = false;
        
        // Initialiser les contrôleurs
        if (data != null) {
          _prenomController.text = data['prenom'] ?? '';
          _nomController.text = data['nom'] ?? '';
          _telephoneController.text = data['telephone'] ?? '';
          _emailController.text = data['email'] ?? '';
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.adminName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (!_isEditing && _adminData != null) ...[
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Modifier',
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'deactivate',
                  child: Row(
                    children: [
                      Icon(
                        _adminData!['isActive'] ? Icons.block_rounded : Icons.check_circle_rounded,
                        color: _adminData!['isActive'] ? Colors.red : Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(_adminData!['isActive'] ? 'Désactiver' : 'Réactiver'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (_isEditing) ...[
            IconButton(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save_rounded),
              tooltip: 'Sauvegarder',
            ),
            IconButton(
              onPressed: () => setState(() => _isEditing = false),
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Annuler',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
              ),
            )
          : _adminData == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Admin non trouvé',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPersonalInfoCard(),
                      const SizedBox(height: 16),
                      _buildCompanyInfoCard(),
                      const SizedBox(height: 16),
                      _buildAccountInfoCard(),
                      const SizedBox(height: 16),
                      _buildPermissionsCard(),
                    ],
                  ),
                ),
    );
  }

  /// 👤 Carte des informations personnelles
  Widget _buildPersonalInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.3)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Informations Personnelles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (_isEditing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ÉDITION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoField(
                  'Prénom',
                  _adminData!['prenom'] ?? 'Non défini',
                  Icons.person_outline_rounded,
                  controller: _prenomController,
                ),
                const SizedBox(height: 16),
                _buildInfoField(
                  'Nom',
                  _adminData!['nom'] ?? 'Non défini',
                  Icons.badge_outlined,
                  controller: _nomController,
                ),
                const SizedBox(height: 16),
                _buildInfoField(
                  'Téléphone',
                  _adminData!['telephone'] ?? 'Non défini',
                  Icons.phone_outlined,
                  controller: _telephoneController,
                ),
                const SizedBox(height: 16),
                _buildInfoField(
                  'Email',
                  _adminData!['email'] ?? 'Non défini',
                  Icons.email_outlined,
                  controller: _emailController,
                  copyable: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🏢 Carte des informations de compagnie
  Widget _buildCompanyInfoCard() {
    final companyData = _adminData!['companyData'] as Map<String, dynamic>?;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100.withOpacity(0.3)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Compagnie Assignée',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoField(
                  'Nom de la compagnie',
                  companyData?['nom'] ?? _adminData!['compagnieNom'] ?? 'Non défini',
                  Icons.business_center_rounded,
                ),
                if (companyData?['code'] != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoField(
                    'Code',
                    companyData!['code'],
                    Icons.qr_code_rounded,
                  ),
                ],
                if (companyData?['type'] != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoField(
                    'Type',
                    companyData!['type'],
                    Icons.category_rounded,
                  ),
                ],
                if (companyData?['adresse'] != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoField(
                    'Adresse',
                    companyData!['adresse'],
                    Icons.location_on_outlined,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔐 Carte des informations de compte
  Widget _buildAccountInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.purple.shade100.withOpacity(0.3)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Informations de Compte',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusBadge(
                        'Statut',
                        _adminData!['status'] ?? 'actif',
                        _adminData!['isActive'] == true ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusBadge(
                        'Connexions',
                        '${_adminData!['loginCount'] ?? 0}',
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusBadge(
                        '2FA',
                        _adminData!['twoFactorEnabled'] == true ? 'Activé' : 'Désactivé',
                        _adminData!['twoFactorEnabled'] == true ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusBadge(
                        'Mot de passe',
                        _adminData!['requirePasswordChange'] == true ? 'À changer' : 'OK',
                        _adminData!['requirePasswordChange'] == true ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔑 Carte des permissions
  Widget _buildPermissionsCard() {
    final permissions = List<String>.from(_adminData!['permissions'] ?? []);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade50, Colors.indigo.shade100.withOpacity(0.3)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Permissions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${permissions.length} permission(s)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.indigo.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: permissions.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune permission définie',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: permissions.map((permission) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo.shade100, Colors.indigo.shade50],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigo.shade200),
                        ),
                        child: Text(
                          permission.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    String value,
    IconData icon, {
    TextEditingController? controller,
    bool copyable = false,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.grey.shade600, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              _isEditing && controller != null
                  ? TextFormField(
                      controller: controller,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
            ],
          ),
        ),
        if (copyable && !_isEditing)
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📋 Copié!')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            tooltip: 'Copier',
          ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    try {
      final success = await AdminCompagnieCrudService.updateAdminCompagnie(
        adminId: widget.adminId,
        prenom: _prenomController.text.trim(),
        nom: _nomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (success) {
        setState(() => _isEditing = false);
        await _loadAdminData();
        _showSuccessSnackBar('✅ Modifications sauvegardées');
      } else {
        _showErrorSnackBar('❌ Erreur lors de la sauvegarde');
      }
    } catch (e) {
      _showErrorSnackBar('❌ Erreur: $e');
    }
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'deactivate':
        await _toggleActivation();
        break;
      case 'delete':
        await _confirmDelete();
        break;
    }
  }

  Future<void> _toggleActivation() async {
    final isActive = _adminData!['isActive'] == true;
    final success = isActive
        ? await AdminCompagnieCrudService.deactivateAdminCompagnie(widget.adminId)
        : await AdminCompagnieCrudService.reactivateAdminCompagnie(widget.adminId);

    if (success) {
      await _loadAdminData();
      _showSuccessSnackBar(
        isActive ? '🔒 Compte désactivé' : '🔓 Compte réactivé',
      );
    } else {
      _showErrorSnackBar('❌ Erreur lors de la modification du statut');
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer définitivement le compte de ${widget.adminName} ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AdminCompagnieCrudService.deleteAdminCompagnie(widget.adminId);
      if (success) {
        Navigator.pop(context, true); // Retourner à la liste
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Admin supprimé avec succès')),
        );
      } else {
        _showErrorSnackBar('❌ Erreur lors de la suppression');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

