import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'demande_contrat_screen.dart';

/// 🏠 Dashboard Complet pour Conducteur
/// Toutes les fonctionnalités d'un conducteur
class ConducteurDashboardSimple extends StatefulWidget {
  const ConducteurDashboardSimple({super.key});

  @override
  State<ConducteurDashboardSimple> createState() => _ConducteurDashboardSimpleState();
}

class _ConducteurDashboardSimpleState extends State<ConducteurDashboardSimple> {
  final User? user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;

  // Données du conducteur
  Map<String, dynamic>? _conducteurData;
  List<Map<String, dynamic>> _mesVehicules = [];
  List<Map<String, dynamic>> _mesSinistres = [];
  List<Map<String, dynamic>> _mesContrats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConducteurData();
  }

  Future<void> _loadConducteurData() async {
    if (user == null) return;

    try {
      // Charger les données du conducteur
      final conducteurDoc = await FirebaseFirestore.instance
          .collection('conducteurs')
          .doc(user!.uid)
          .get();

      if (conducteurDoc.exists) {
        _conducteurData = conducteurDoc.data();
      }

      // Charger les véhicules
      final vehiculesSnapshot = await FirebaseFirestore.instance
          .collection('vehicules')
          .where('conducteurId', isEqualTo: user!.uid)
          .get();

      _mesVehicules = vehiculesSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      // Charger les sinistres
      final sinistresSnapshot = await FirebaseFirestore.instance
          .collection('sinistres')
          .where('conducteurId', isEqualTo: user!.uid)
          .orderBy('dateCreation', descending: true)
          .get();

      _mesSinistres = sinistresSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      // Charger les contrats
      final contratsSnapshot = await FirebaseFirestore.instance
          .collection('contrats')
          .where('conducteurId', isEqualTo: user!.uid)
          .get();

      _mesContrats = contratsSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Mon Espace Conducteur'),
          backgroundColor: Colors.blue[700],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _getPageTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () => _showNotifications(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Véhicules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Contrats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Sinistres',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0: return 'Mon Espace Conducteur';
      case 1: return 'Mes Véhicules';
      case 2: return 'Mes Contrats';
      case 3: return 'Mes Sinistres';
      case 4: return 'Mon Profil';
      default: return 'Mon Espace Conducteur';
    }
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0: return _buildAccueilPage();
      case 1: return _buildVehiculesPage();
      case 2: return _buildContratsPage();
      case 3: return _buildSinistresPage();
      case 4: return _buildProfilPage();
      default: return _buildAccueilPage();
    }
  }

  Widget _buildAccueilPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // 👋 Bienvenue
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '👋 Bienvenue !',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? 'Conducteur',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🚗 Actions Rapides
            const Text(
              '🚗 Actions Rapides',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Grid des actions
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  icon: Icons.add_circle,
                  title: 'Nouvelle Demande',
                  subtitle: 'Demande d\'assurance',
                  color: Colors.green,
                  onTap: () => _nouvelleDemandeAssurance(),
                ),
                _buildActionCard(
                  icon: Icons.warning,
                  title: 'Déclarer Sinistre',
                  subtitle: 'Nouveau constat',
                  color: Colors.orange,
                  onTap: () => _declarerSinistre(),
                ),
                _buildActionCard(
                  icon: Icons.directions_car,
                  title: 'Mes Véhicules',
                  subtitle: '${_mesVehicules.length} véhicule(s)',
                  color: Colors.blue,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _buildActionCard(
                  icon: Icons.description,
                  title: 'Mes Contrats',
                  subtitle: '${_mesContrats.length} contrat(s)',
                  color: Colors.purple,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 📊 Résumé
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Mon Résumé',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow('Véhicules assurés', '${_mesVehicules.length}', Icons.directions_car),
                  _buildStatRow('Contrats actifs', '${_mesContrats.length}', Icons.description),
                  _buildStatRow('Sinistres en cours', '${_mesSinistres.where((s) => s['statut'] == 'en_cours').length}', Icons.pending),
                  _buildStatRow('Sinistres réglés', '${_mesSinistres.where((s) => s['statut'] == 'regle').length}', Icons.check_circle),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 📞 Contact
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.support_agent, size: 40, color: Colors.amber[700]),
                  const SizedBox(height: 12),
                  const Text(
                    'Besoin d\'aide ?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Contactez votre agent ou notre support',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showContact(),
                    icon: const Icon(Icons.phone),
                    label: const Text('Contacter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showContrats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚗 Mes Contrats'),
        content: const Text(
          'Ici vous verrez la liste de vos véhicules assurés.\n\n'
          '• Peugeot 208 - Contrat #12345\n'
          '• Renault Clio - Contrat #67890\n\n'
          'Fonctionnalité en cours de développement.',
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

  void _showDeclarationSinistre() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Déclarer un Sinistre'),
        content: const Text(
          'Ici vous pourrez déclarer un accident ou sinistre.\n\n'
          'Le formulaire de constat sera simple et guidé.\n\n'
          'Fonctionnalité en cours de développement.',
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

  void _showHistoriqueSinistres() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📋 Mes Sinistres'),
        content: const Text(
          'Historique de vos déclarations de sinistres.\n\n'
          '• Sinistre #001 - Réglé (15/08/2025)\n'
          '• Aucun sinistre en cours\n\n'
          'Fonctionnalité en cours de développement.',
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

  void _showProfil() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('👤 Mon Profil'),
        content: Text(
          'Informations personnelles :\n\n'
          'Email: ${user?.email ?? "Non défini"}\n'
          'Nom: À compléter\n'
          'Téléphone: À compléter\n\n'
          'Fonctionnalité en cours de développement.',
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

  void _showContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📞 Contact'),
        content: const Text(
          'Support Constat Tunisie :\n\n'
          '📧 Email: support@constat-tunisie.tn\n'
          '📱 Téléphone: +216 XX XXX XXX\n'
          '🕒 Horaires: 8h-18h (Lun-Ven)\n\n'
          'Votre agent vous contactera si nécessaire.',
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

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔔 Notifications'),
        content: const Text(
          'Aucune nouvelle notification.\n\n'
          'Vous serez notifié pour :\n'
          '• Validation de contrats\n'
          '• Mise à jour de sinistres\n'
          '• Messages de votre agent',
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

  void _nouvelleDemandeAssurance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DemandeContratScreen(),
      ),
    );
  }

  void _declarerSinistre() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Déclarer un Sinistre'),
        content: const Text(
          'Voulez-vous déclarer un nouveau sinistre ?\n\n'
          'Vous serez guidé étape par étape pour :\n'
          '• Décrire l\'accident\n'
          '• Prendre des photos\n'
          '• Remplir le constat',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Naviguer vers le formulaire de déclaration
            },
            child: const Text('Déclarer'),
          ),
        ],
      ),
    );
  }

  void _ajouterVehicule() {
    Navigator.pushNamed(context, '/conducteur/add-vehicle');
  }

  void _modifierProfil() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✏️ Modifier le Profil'),
        content: const Text(
          'Fonctionnalité en cours de développement.\n\n'
          'Vous pourrez bientôt modifier :\n'
          '• Vos informations personnelles\n'
          '• Votre photo de profil\n'
          '• Vos préférences',
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

  Widget _buildVehiculeCard(Map<String, dynamic> vehicule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.directions_car, color: Colors.blue[700]),
        ),
        title: Text('${vehicule['marque']} ${vehicule['modele']}'),
        subtitle: Text('Immatriculation: ${vehicule['immatriculation']}'),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
        onTap: () => _voirDetailsVehicule(vehicule),
      ),
    );
  }

  Widget _buildContratCard(Map<String, dynamic> contrat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(Icons.description, color: Colors.green[700]),
        ),
        title: Text('Contrat #${contrat['numero']}'),
        subtitle: Text('Compagnie: ${contrat['compagnie']}'),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
        onTap: () => _voirDetailsContrat(contrat),
      ),
    );
  }

  Widget _buildSinistreCard(Map<String, dynamic> sinistre) {
    Color statusColor = sinistre['statut'] == 'regle' ? Colors.green : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(Icons.warning, color: statusColor),
        ),
        title: Text('Sinistre #${sinistre['numero']}'),
        subtitle: Text('Date: ${sinistre['date']} - ${sinistre['statut']}'),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
        onTap: () => _voirDetailsSinistre(sinistre),
      ),
    );
  }

  Widget _buildProfilRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _voirDetailsVehicule(Map<String, dynamic> vehicule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🚗 ${vehicule['marque']} ${vehicule['modele']}'),
        content: Text(
          'Détails du véhicule :\n\n'
          'Immatriculation: ${vehicule['immatriculation']}\n'
          'Année: ${vehicule['annee']}\n'
          'Type: ${vehicule['type']}\n'
          'Carburant: ${vehicule['carburant']}',
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

  void _voirDetailsContrat(Map<String, dynamic> contrat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📄 Contrat #${contrat['numero']}'),
        content: Text(
          'Détails du contrat :\n\n'
          'Compagnie: ${contrat['compagnie']}\n'
          'Agence: ${contrat['agence']}\n'
          'Date début: ${contrat['dateDebut']}\n'
          'Date fin: ${contrat['dateFin']}',
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

  void _voirDetailsSinistre(Map<String, dynamic> sinistre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ Sinistre #${sinistre['numero']}'),
        content: Text(
          'Détails du sinistre :\n\n'
          'Date: ${sinistre['date']}\n'
          'Lieu: ${sinistre['lieu']}\n'
          'Statut: ${sinistre['statut']}\n'
          'Description: ${sinistre['description']}',
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
