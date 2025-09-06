import 'package:flutter/material.dart';
import '../../models/sinistre_model.dart';
import '../../services/sinistre_service.dart';
import '../../services/accident_session_complete_service.dart';
import '../../models/accident_session_complete.dart';
import '../../widgets/simple_sketch_widget.dart';

/// 🚨 Écran de détails d'un sinistre
class SinistreDetailsScreen extends StatefulWidget {
  final SinistreModel sinistre;

  const SinistreDetailsScreen({
    super.key,
    required this.sinistre,
  });

  @override
  State<SinistreDetailsScreen> createState() => _SinistreDetailsScreenState();
}

class _SinistreDetailsScreenState extends State<SinistreDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AccidentSessionComplete? _session;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSessionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 📋 Charger les données de la session
  Future<void> _loadSessionData() async {
    try {
      _session = await AccidentSessionCompleteService.obtenirSession(widget.sinistre.sessionId);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.sinistre.numeroSinistre),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Infos'),
            Tab(icon: Icon(Icons.people), text: 'Participants'),
            Tab(icon: Icon(Icons.draw), text: 'Croquis'),
            Tab(icon: Icon(Icons.timeline), text: 'Statut'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInfosTab(),
                _buildParticipantsTab(),
                _buildCroquisTab(),
                _buildStatutTab(),
              ],
            ),
    );
  }

  /// 📋 Onglet informations
  Widget _buildInfosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte principale
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment, color: Colors.blue[600], size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.sinistre.numeroSinistre,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.sinistre.typeAccident,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatutBadge(widget.sinistre.statut),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Informations de l'accident
                  _buildInfoSection('Accident', [
                    _buildInfoRow(Icons.calendar_today, 'Date', 
                        '${widget.sinistre.dateAccident.day}/${widget.sinistre.dateAccident.month}/${widget.sinistre.dateAccident.year}'),
                    _buildInfoRow(Icons.access_time, 'Heure', widget.sinistre.heureAccident),
                    _buildInfoRow(Icons.location_on, 'Lieu', widget.sinistre.lieuAccident),
                  ]),
                  
                  const SizedBox(height: 16),
                  
                  // Informations du sinistre
                  _buildInfoSection('Sinistre', [
                    _buildInfoRow(Icons.directions_car, 'Véhicules impliqués', '${widget.sinistre.nombreVehicules}'),
                    _buildInfoRow(Icons.local_hospital, 'Blessés', widget.sinistre.blesses ? 'Oui' : 'Non'),
                    _buildInfoRow(Icons.build, 'Dégâts matériels', widget.sinistre.degatsMateriels ? 'Oui' : 'Non'),
                  ]),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Session de constat
          if (_session != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.group_work, color: Colors.green[600], size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Session de constat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildInfoRow(Icons.vpn_key, 'Code session', widget.sinistre.codeSession),
                    _buildInfoRow(Icons.timeline, 'Statut session', widget.sinistre.statutSession.label),
                    _buildInfoRow(Icons.people, 'Participants', '${_session!.conducteurs.length}/${_session!.nombreVehicules}'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 👥 Onglet participants
  Widget _buildParticipantsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conducteurs impliqués',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 16),
          
          ...widget.sinistre.conducteurs.map((conducteur) => _buildConducteurCard(conducteur)),
        ],
      ),
    );
  }

  /// 🎨 Onglet croquis
  Widget _buildCroquisTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Croquis de l\'accident',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              if (widget.sinistre.statutSession == StatutSession.enCoursRemplissage)
                ElevatedButton.icon(
                  onPressed: _modifierCroquis,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Croquis en lecture seule
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SimpleSketchWidget(
                  width: double.infinity,
                  height: double.infinity,
                  isReadOnly: true,
                  initialElements: _convertCroquisToElements(),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Actions sur le croquis
          if (widget.sinistre.statutSession == StatutSession.enAttenteValidation)
            _buildCroquisActions(),
        ],
      ),
    );
  }

  /// 📊 Onglet statut
  Widget _buildStatutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progression
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progression du constat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildProgressStep('Participants', 
                      widget.sinistre.conducteurs.length == widget.sinistre.nombreVehicules),
                  _buildProgressStep('Informations', 
                      widget.sinistre.lieuAccident.isNotEmpty),
                  _buildProgressStep('Croquis', 
                      widget.sinistre.croquisData.isNotEmpty),
                  _buildProgressStep('Validation', 
                      widget.sinistre.statutSession == StatutSession.termine),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Actions selon le statut
          _buildActionsCard(),
        ],
      ),
    );
  }

  /// 🎯 Construire le badge de statut
  Widget _buildStatutBadge(SinistreStatut statut) {
    Color color;
    switch (statut) {
      case SinistreStatut.enAttente:
        color = Colors.orange;
        break;
      case SinistreStatut.enCours:
        color = Colors.blue;
        break;
      case SinistreStatut.enExpertise:
        color = Colors.purple;
        break;
      case SinistreStatut.termine:
        color = Colors.green;
        break;
      case SinistreStatut.rejete:
        color = Colors.red;
        break;
      case SinistreStatut.clos:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        statut.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// 📋 Section d'informations
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  /// 📋 Ligne d'information
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 Carte de conducteur
  Widget _buildConducteurCard(Map<String, dynamic> conducteur) {
    final estCreateur = conducteur['estCreateur'] == true;
    final aRejoint = conducteur['aRejoint'] == true;
    final estInscrit = conducteur['estInscrit'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: estCreateur ? Colors.blue[100] : Colors.grey[100],
                  child: Icon(
                    estCreateur ? Icons.star : Icons.person,
                    color: estCreateur ? Colors.blue[600] : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${conducteur['prenom']} ${conducteur['nom']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        conducteur['roleVehicule'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (estCreateur)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Créateur',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: estInscrit ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        estInscrit ? 'Inscrit' : 'Invité',
                        style: TextStyle(
                          fontSize: 10,
                          color: estInscrit ? Colors.green[600] : Colors.orange[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(conducteur['email'] ?? ''),
                const SizedBox(width: 16),
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(conducteur['telephone'] ?? ''),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(
                  aRejoint ? Icons.check_circle : Icons.schedule,
                  size: 16,
                  color: aRejoint ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  aRejoint ? 'A rejoint la session' : 'En attente',
                  style: TextStyle(
                    fontSize: 12,
                    color: aRejoint ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📈 Étape de progression
  Widget _buildProgressStep(String title, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: completed ? Colors.green : Colors.grey[600],
              fontWeight: completed ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Actions sur le croquis
  Widget _buildCroquisActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Validation du croquis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Êtes-vous d\'accord avec ce croquis de l\'accident ?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _validerCroquis(true),
                    icon: const Icon(Icons.check),
                    label: const Text('J\'accepte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _validerCroquis(false),
                    icon: const Icon(Icons.close),
                    label: const Text('Je refuse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🎯 Carte d'actions
  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions disponibles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (widget.sinistre.statutSession == StatutSession.enCoursRemplissage) ...[
              _buildActionButton(
                'Continuer le constat',
                Icons.edit,
                Colors.blue,
                _continuerConstat,
              ),
            ],
            
            if (widget.sinistre.statutSession == StatutSession.enAttenteValidation) ...[
              _buildActionButton(
                'Valider le constat',
                Icons.check_circle,
                Colors.green,
                _validerConstat,
              ),
            ],
            
            _buildActionButton(
              'Télécharger le PDF',
              Icons.download,
              Colors.purple,
              _telechargerPDF,
            ),
            
            _buildActionButton(
              'Partager',
              Icons.share,
              Colors.orange,
              _partager,
            ),
          ],
        ),
      ),
    );
  }

  /// 🎯 Bouton d'action
  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  /// 🎨 Convertir le croquis en éléments
  List<SketchElement> _convertCroquisToElements() {
    // TODO: Implémenter la conversion des données de croquis
    return [];
  }

  /// ✏️ Modifier le croquis
  void _modifierCroquis() {
    // TODO: Naviguer vers l'éditeur de croquis
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modification du croquis'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// ✅ Valider le croquis
  void _validerCroquis(bool accepte) {
    // TODO: Enregistrer la validation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(accepte ? 'Croquis accepté' : 'Croquis refusé'),
        backgroundColor: accepte ? Colors.green : Colors.red,
      ),
    );
  }

  /// ✏️ Continuer le constat
  void _continuerConstat() {
    // TODO: Naviguer vers le formulaire de constat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Continuer le constat'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// ✅ Valider le constat
  void _validerConstat() {
    // TODO: Valider le constat complet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Constat validé'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 📄 Télécharger le PDF
  void _telechargerPDF() {
    // TODO: Générer et télécharger le PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Téléchargement du PDF'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  /// 📤 Partager
  void _partager() {
    // TODO: Partager le sinistre
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partage du sinistre'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
