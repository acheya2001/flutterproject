import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_agence_management_service.dart';

/// 🔗 Écran d'affectation d'un admin existant à une agence
class AssignAdminAgenceScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> agenceData;

  const AssignAdminAgenceScreen({
    Key? key,
    required this.userData,
    required this.agenceData,
  }) : super(key: key);

  @override
  State<AssignAdminAgenceScreen> createState() => _AssignAdminAgenceScreenState();
}

class _AssignAdminAgenceScreenState extends State<AssignAdminAgenceScreen> {
  List<Map<String, dynamic>> _availableAdmins = [];
  Map<String, dynamic>? _selectedAdmin;
  bool _isLoading = true;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableAdmins();
  }

  /// 📊 Charger les admins disponibles
  Future<void> _loadAvailableAdmins() async {
    setState(() => _isLoading = true);
    
    try {
      final admins = await AdminAgenceManagementService.getAvailableAdminsAgence(
        compagnieId: widget.userData['compagnieId'],
      );
      
      setState(() {
        _availableAdmins = admins;
      });
    } catch (e) {
      debugPrint('Erreur chargement admins: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// 🎨 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Affecter un Admin',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontSize: 18,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _loadAvailableAdmins,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  /// ⏳ État de chargement
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
          ),
          SizedBox(height: 16),
          Text('Chargement des admins disponibles...'),
        ],
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
          // Informations de l'agence
          _buildAgenceInfoCard(),
          const SizedBox(height: 24),
          
          // Liste des admins disponibles
          _buildAdminsListCard(),
        ],
      ),
    );
  }

  /// 🏢 Carte informations agence
  Widget _buildAgenceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.agenceData['nom'] ?? 'Nom non défini',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Code: ${widget.agenceData['code'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  widget.agenceData['adresse'] ?? 'Adresse non définie',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'LIBRE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 👥 Carte liste des admins
  Widget _buildAdminsListCard() {
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
                  Icons.people_rounded,
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
                      'Admins Agence Disponibles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      '${_availableAdmins.length} admin(s) disponible(s)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_availableAdmins.isEmpty) ...[
            _buildEmptyState(),
          ] else ...[
            ...(_availableAdmins.map((admin) => _buildAdminCard(admin))),
          ],
        ],
      ),
    );
  }

  /// 📭 État vide
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_off_rounded,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun admin disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tous les admins agence de votre compagnie sont déjà affectés à des agences.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Naviguer vers la création d'admin
            },
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Créer un nouvel admin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 Carte admin
  Widget _buildAdminCard(Map<String, dynamic> admin) {
    final isSelected = _selectedAdmin?['id'] == admin['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF667EEA).withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isSelected 
              ? const Color(0xFF667EEA) 
              : Colors.blue.withOpacity(0.1),
          child: Text(
            '${admin['prenom']?[0] ?? ''}${admin['nom']?[0] ?? ''}',
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          '${admin['prenom']} ${admin['nom']}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isSelected ? const Color(0xFF667EEA) : const Color(0xFF1F2937),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              admin['email'] ?? 'Email non défini',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  admin['isActive'] == true ? Icons.check_circle : Icons.cancel,
                  color: admin['isActive'] == true ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  admin['isActive'] == true ? 'Actif' : 'Inactif',
                  style: TextStyle(
                    color: admin['isActive'] == true ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                if (admin['telephone'] != null) ...[
                  Icon(Icons.phone, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    admin['telephone'],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: isSelected 
            ? const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF667EEA),
                size: 28,
              )
            : const Icon(
                Icons.radio_button_unchecked_rounded,
                color: Colors.grey,
                size: 28,
              ),
        onTap: () {
          setState(() {
            _selectedAdmin = isSelected ? null : admin;
          });
        },
      ),
    );
  }

  /// 📱 Barre du bas
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isAssigning ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Annuler'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: const BorderSide(color: Colors.grey),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: (_selectedAdmin != null && !_isAssigning) ? _assignAdmin : null,
              icon: _isAssigning 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.person_add_rounded),
              label: Text(_isAssigning ? 'Affectation...' : 'Affecter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔗 Affecter l'admin sélectionné
  Future<void> _assignAdmin() async {
    if (_selectedAdmin == null) return;

    setState(() => _isAssigning = true);

    try {
      final result = await AdminAgenceManagementService.assignAdminToAgence(
        adminId: _selectedAdmin!['id'],
        agenceId: widget.agenceData['id'],
        agenceNom: widget.agenceData['nom'],
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, {'success': true, 'message': result['message']});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isAssigning = false);
    }
  }
}
