import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/notification_service.dart';

/// 🔧 Écran de gestion des permissions
class PermissionsManagementScreen extends ConsumerStatefulWidget {
  const PermissionsManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PermissionsManagementScreen> createState() => _PermissionsManagementScreenState();
}

class _PermissionsManagementScreenState extends ConsumerState<PermissionsManagementScreen> {
  String _selectedUserType = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Permissions disponibles par rôle
  final Map<String, List<Permission>> _availablePermissions = {
    'assureur': [
      Permission('view_contracts', 'Voir les contrats', 'Accès en lecture aux contrats d\'assurance'),
      Permission('create_contracts', 'Créer des contrats', 'Créer de nouveaux contrats d\'assurance'),
      Permission('edit_contracts', 'Modifier les contrats', 'Modifier les contrats existants'),
      Permission('delete_contracts', 'Supprimer les contrats', 'Supprimer des contrats'),
      Permission('view_claims', 'Voir les sinistres', 'Accès aux déclarations de sinistres'),
      Permission('process_claims', 'Traiter les sinistres', 'Traiter et valider les sinistres'),
      Permission('view_reports', 'Voir les rapports', 'Accès aux rapports et statistiques'),
      Permission('manage_clients', 'Gérer les clients', 'Gérer le portefeuille clients'),
    ],
    'expert': [
      Permission('view_expertises', 'Voir les expertises', 'Accès aux dossiers d\'expertise'),
      Permission('create_expertises', 'Créer des expertises', 'Créer de nouveaux rapports d\'expertise'),
      Permission('edit_expertises', 'Modifier les expertises', 'Modifier les rapports existants'),
      Permission('validate_claims', 'Valider les sinistres', 'Valider les déclarations de sinistres'),
      Permission('access_photos', 'Accès aux photos', 'Voir et analyser les photos d\'accidents'),
      Permission('generate_reports', 'Générer des rapports', 'Créer des rapports d\'expertise'),
      Permission('view_statistics', 'Voir les statistiques', 'Accès aux statistiques d\'expertise'),
    ],
    'admin': [
      Permission('manage_users', 'Gérer les utilisateurs', 'Créer, modifier, supprimer des utilisateurs'),
      Permission('manage_permissions', 'Gérer les permissions', 'Attribuer et modifier les permissions'),
      Permission('view_all_data', 'Voir toutes les données', 'Accès complet à toutes les données'),
      Permission('system_config', 'Configuration système', 'Modifier la configuration du système'),
      Permission('backup_restore', 'Sauvegarde/Restauration', 'Gérer les sauvegardes du système'),
      Permission('audit_logs', 'Journaux d\'audit', 'Voir les logs d\'activité du système'),
    ],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Gestion des Permissions',
      ),
      body: Column(
        children: [
          // Filtres et recherche
          _buildFiltersAndSearch(),
          
          // Liste des utilisateurs
          Expanded(
            child: _buildUsersList(),
          ),
        ],
      ),
    );
  }

  /// 🔍 Filtres et barre de recherche
  Widget _buildFiltersAndSearch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filtres par type d'utilisateur
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Tous', Colors.grey),
                const SizedBox(width: 8),
                _buildFilterChip('assureur', 'Assureurs', Colors.blue),
                const SizedBox(width: 8),
                _buildFilterChip('expert', 'Experts', Colors.orange),
                const SizedBox(width: 8),
                _buildFilterChip('admin', 'Admins', Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = _selectedUserType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedUserType = value;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// 👥 Liste des utilisateurs
  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data?.docs ?? [];
        final filteredUsers = _filterUsers(users);

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucun utilisateur trouvé',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final userDoc = filteredUsers[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            return _buildUserCard(userDoc.id, userData);
          },
        );
      },
    );
  }

  /// 🃏 Carte utilisateur
  Widget _buildUserCard(String userId, Map<String, dynamic> userData) {
    final userType = userData['userType'] ?? '';
    final nom = userData['nom'] ?? '';
    final prenom = userData['prenom'] ?? '';
    final email = userData['email'] ?? '';
    final permissions = List<String>.from(userData['permissions'] ?? []);
    final accountStatus = _getAccountStatusFromString(userData['accountStatus'] ?? 'active');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getUserTypeColor(userType),
          child: Icon(
            _getUserTypeIcon(userType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          '$prenom $nom',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusBadge(accountStatus),
                const SizedBox(width: 8),
                Text(
                  '${permissions.length} permission(s)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          _buildPermissionsSection(userId, userType, permissions),
        ],
      ),
    );
  }

  /// 🔧 Section des permissions
  Widget _buildPermissionsSection(String userId, String userType, List<String> currentPermissions) {
    final availablePerms = _availablePermissions[userType] ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Permissions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showPermissionEditor(userId, userType, currentPermissions),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Modifier'),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (currentPermissions.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[600], size: 20),
                  const SizedBox(width: 8),
                  const Text('Aucune permission attribuée'),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: currentPermissions.map((permId) {
                final permission = availablePerms.firstWhere(
                  (p) => p.id == permId,
                  orElse: () => Permission(permId, permId, 'Permission inconnue'),
                );
                return Chip(
                  label: Text(permission.name),
                  backgroundColor: Colors.green[50],
                  side: BorderSide(color: Colors.green[200]!),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// ✏️ Éditeur de permissions
  void _showPermissionEditor(String userId, String userType, List<String> currentPermissions) {
    final availablePerms = _availablePermissions[userType] ?? [];
    final selectedPermissions = Set<String>.from(currentPermissions);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Modifier les permissions - $userType'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Text(
                  'Sélectionnez les permissions à attribuer:',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: availablePerms.length,
                    itemBuilder: (context, index) {
                      final permission = availablePerms[index];
                      final isSelected = selectedPermissions.contains(permission.id);

                      return CheckboxListTile(
                        title: Text(permission.name),
                        subtitle: Text(
                          permission.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        value: isSelected,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedPermissions.add(permission.id);
                            } else {
                              selectedPermissions.remove(permission.id);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateUserPermissions(userId, selectedPermissions.toList());
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  /// 💾 Mettre à jour les permissions d'un utilisateur
  Future<void> _updateUserPermissions(String userId, List<String> newPermissions) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'permissions': newPermissions});

      // Notifier l'utilisateur du changement
      await NotificationService.notifyPermissionChanged(
        userId: userId,
        changedBy: 'admin', // TODO: Récupérer l'ID de l'admin connecté
        newPermissions: newPermissions,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions mises à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 📊 Stream des utilisateurs
  Stream<QuerySnapshot> _getUsersStream() {
    Query query = FirebaseFirestore.instance.collection('users');

    if (_selectedUserType != 'all') {
      query = query.where('userType', isEqualTo: _selectedUserType);
    }

    return query.snapshots();
  }

  /// 🔍 Filtrer les utilisateurs
  List<QueryDocumentSnapshot> _filterUsers(List<QueryDocumentSnapshot> users) {
    if (_searchQuery.isEmpty) {
      return users;
    }

    return users.where((user) {
      final userData = user.data() as Map<String, dynamic>;
      final nom = (userData['nom'] ?? '').toString().toLowerCase();
      final prenom = (userData['prenom'] ?? '').toString().toLowerCase();
      final email = (userData['email'] ?? '').toString().toLowerCase();

      return nom.contains(_searchQuery) ||
             prenom.contains(_searchQuery) ||
             email.contains(_searchQuery);
    }).toList();
  }

  /// 🎨 Couleur par type d'utilisateur
  Color _getUserTypeColor(String userType) {
    switch (userType) {
      case 'assureur':
        return Colors.blue;
      case 'expert':
        return Colors.orange;
      case 'admin':
        return Colors.red;
      case 'conducteur':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// 🔧 Icône par type d'utilisateur
  IconData _getUserTypeIcon(String userType) {
    switch (userType) {
      case 'assureur':
        return Icons.business;
      case 'expert':
        return Icons.assignment_ind;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'conducteur':
        return Icons.drive_eta;
      default:
        return Icons.person;
    }
  }

  /// 📊 Badge de statut
  Widget _buildStatusBadge(AccountStatus status) {
    Color color;
    String text;

    switch (status) {
      case AccountStatus.active:
        color = Colors.green;
        text = 'Actif';
        break;
      case AccountStatus.pending:
        color = Colors.orange;
        text = 'En attente';
        break;
      case AccountStatus.suspended:
        color = Colors.red;
        text = 'Suspendu';
        break;
      case AccountStatus.rejected:
        color = Colors.red;
        text = 'Rejeté';
        break;
      default:
        color = Colors.grey;
        text = 'Inconnu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 📊 Convertir string en AccountStatus
  AccountStatus _getAccountStatusFromString(String status) {
    switch (status) {
      case 'active':
        return AccountStatus.active;
      case 'pending':
        return AccountStatus.pending;
      case 'suspended':
        return AccountStatus.suspended;
      case 'rejected':
        return AccountStatus.rejected;
      default:
        return AccountStatus.active;
    }
  }
}

/// 🔧 Modèle de permission
class Permission {
  final String id;
  final String name;
  final String description;

  const Permission(this.id, this.name, this.description);
}
