import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../common/widgets/custom_app_bar.dart';
import '../../../common/widgets/gradient_background.dart';
import '../../../models/accident_session.dart';
import '../services/accident_session_service.dart';
import 'infos_communes_screen.dart';

/// Écran de création d'une session de constat (Écran 1)
class CreationSessionScreen extends StatefulWidget {
  const CreationSessionScreen({Key? key}) : super(key: key);

  @override
  State<CreationSessionScreen> createState() => _CreationSessionScreenState();
}

class _CreationSessionScreenState extends State<CreationSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Données du véhicule sélectionné
  Map<String, dynamic>? _selectedVehicule;
  List<Map<String, dynamic>> _vehicules = [];
  
  // Services
  final AccidentSessionService _sessionService = AccidentSessionService();

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadUserVehicules();
    });
  }

  Future<void> _loadUserVehicules() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('🔄 Chargement véhicules pour déclaration sinistre - utilisateur: ${user.uid}');

      // 1. D'abord, chercher dans vehicules_assures (priorité)
      var snapshot = await FirebaseFirestore.instance
          .collection('vehicules_assures')
          .where('conducteurId', isEqualTo: user.uid)
          .where('statut', isEqualTo: 'actif')
          .get();

      print('🚗 ${snapshot.docs.length} véhicules trouvés dans vehicules_assures');

      final vehicules = <Map<String, dynamic>>[];

      // Traiter les véhicules de vehicules_assures
      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Vérifier que le contrat n'est pas expiré
        final contratData = data['contrat'] as Map<String, dynamic>?;
        final dateFinTimestamp = contratData?['date_fin'] as Timestamp?;

        if (dateFinTimestamp == null || dateFinTimestamp.toDate().isAfter(DateTime.now())) {
          final vehiculeData = data['vehicule'] as Map<String, dynamic>? ?? {};
          vehicules.add({
            'id': doc.id,
            'marque': vehiculeData['marque'] ?? data['marque'] ?? '',
            'modele': vehiculeData['modele'] ?? data['modele'] ?? '',
            'immatriculation': vehiculeData['immatriculation'] ?? data['immatriculation'] ?? '',
            'numeroContrat': data['numero_contrat'] ?? '',
            'compagnieNom': data['assureur_id'] ?? '',
            'agenceNom': '',
            'dateExpiration': dateFinTimestamp?.toDate(),
            'source': 'vehicule_assure',
            'data': data,
          });
        }
      }

      // 2. Si aucun véhicule trouvé, chercher dans demandes_contrats
      if (vehicules.isEmpty) {
        print('🔍 Recherche dans demandes_contrats...');

        var contratsSnapshot = await FirebaseFirestore.instance
            .collection('demandes_contrats')
            .where('conducteurId', isEqualTo: user.uid)
            .where('statut', whereIn: ['contrat_actif', 'documents_completes', 'frequence_choisie'])
            .get();

        // Si aucun contrat trouvé avec conducteurId, essayer avec l'email
        if (contratsSnapshot.docs.isEmpty && user.email != null) {
          contratsSnapshot = await FirebaseFirestore.instance
              .collection('demandes_contrats')
              .where('email', isEqualTo: user.email)
              .where('statut', whereIn: ['contrat_actif', 'documents_completes', 'frequence_choisie'])
              .get();
        }

        print('📄 ${contratsSnapshot.docs.length} contrats actifs trouvés');

        for (final doc in contratsSnapshot.docs) {
          final data = doc.data();

          // Vérifier que le contrat n'est pas expiré
          final dateExpiration = data['dateExpiration'] as Timestamp?;
          if (dateExpiration == null || dateExpiration.toDate().isAfter(DateTime.now())) {
            vehicules.add({
              'id': doc.id,
              'marque': data['marque'] ?? '',
              'modele': data['modele'] ?? '',
              'immatriculation': data['immatriculation'] ?? '',
              'numeroContrat': data['numeroContrat'] ?? '',
              'compagnieNom': data['compagnieNom'] ?? '',
              'agenceNom': data['agenceNom'] ?? '',
              'dateExpiration': dateExpiration?.toDate(),
              'source': 'contrat',
              'data': data,
            });
          }
        }
      }

      if (mounted) setState(() {
        _vehicules = vehicules;
        _isLoading = false;
      });

      print('✅ ${_vehicules.length} véhicules avec contrats actifs chargés');

      if (_vehicules.isEmpty) {
        _showNoActiveContractDialog();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Erreur chargement véhicules: $e');
      _showErrorDialog('Erreur lors du chargement des véhicules: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Créer une Déclaration',
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildVehicleSelection(),
            const SizedBox(height: 32),
            if (_selectedVehicule != null) ...[
              _buildContractInfo(),
              const SizedBox(height: 32),
              _buildLegalDeadlineWarning(),
              const SizedBox(height: 32),
              _buildContinueButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_car,
            size: 48,
            color: Colors.blue[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Sélectionnez votre véhicule',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez le véhicule impliqué dans l\'accident parmi vos contrats actifs',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelection() {
    if (_vehicules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.warning_amber,
              size: 48,
              color: Colors.orange[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun contrat actif',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez aucun véhicule avec un contrat d\'assurance actif. '
              'Veuillez d\'abord souscrire une assurance.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.orange[700],
                height: 1.4,
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
          'Mes véhicules assurés',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ..._vehicules.map((vehicule) => _buildVehicleCard(vehicule)),
      ],
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicule) {
    final isSelected = _selectedVehicule?['id'] == vehicule['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedVehicule = vehicule),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: isSelected ? Colors.blue : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicule['marque']} ${vehicule['modele']}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicule['immatriculation'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contrat: ${vehicule['numeroContrat']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContractInfo() {
    final vehicule = _selectedVehicule!;
    final dateExpiration = vehicule['dateExpiration'] as DateTime?;

    // Calculer les jours restants si la date d'expiration existe
    String validiteText = 'Non spécifiée';
    Color validiteColor = Colors.grey;

    if (dateExpiration != null) {
      final joursRestants = dateExpiration.difference(DateTime.now()).inDays;
      if (joursRestants > 0) {
        validiteText = 'Expire dans $joursRestants jours';
        validiteColor = joursRestants < 30 ? Colors.orange : Colors.green;
      } else {
        validiteText = 'Expiré';
        validiteColor = Colors.red;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Informations du contrat',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Assureur', vehicule['compagnieNom'] ?? 'Non spécifié'),
          _buildInfoRow('Agence', vehicule['agenceNom'] ?? 'Non spécifiée'),
          _buildInfoRow('N° Police', vehicule['numeroContrat'] ?? 'Non spécifié'),
          _buildInfoRow(
            'Validité',
            validiteText,
            color: validiteColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color ?? Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalDeadlineWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.red[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Délai légal de déclaration',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vous avez 5 jours ouvrés pour déclarer votre sinistre à partir de la date de l\'accident.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red[700],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _createSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_forward),
            const SizedBox(width: 8),
            Text(
              'Continuer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSession() async {
    if (_selectedVehicule == null) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      // Créer la session d'accident
      final session = AccidentSession(
        id: '',
        codePublic: AccidentSession.generateCodePublic(),
        createurUserId: user.uid,
        createurVehiculeId: _selectedVehicule!['id'] ?? '',
        statut: AccidentSession.STATUT_BROUILLON,
        dateOuverture: DateTime.now(),
        dateAccident: null,
        heureAccident: null,
        localisation: {}, // Sera rempli dans l'écran suivant
        blesses: false,
        degatsAutres: false,
        temoins: [],
        identitesVehicules: {},
        pointsChocInitial: {},
        degatsApparents: {},
        circonstances: {},
        observationsVehicules: {},
        signatures: {},
        croquisFileId: null,
        croquisData: null,
        observations: '',
        photos: [],
        nombreParticipants: 2,
        rolesDisponibles: ['A', 'B'],
        deadlineDeclaration: DateTime.now().add(const Duration(days: 5)),
        declarationUnilaterale: false,
        dateCreation: DateTime.now(),
        dateModification: DateTime.now(),
      );

      final sessionId = await _sessionService.createSession(session);

      // Naviguer vers l'écran des infos communes
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InfosCommunesScreen(
            sessionId: sessionId,
            vehiculeData: _selectedVehicule!,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Erreur lors de la création de la session: $e');
    }
  }

  void _showNoActiveContractDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[600], size: 28),
            const SizedBox(width: 12),
            const Text('Aucun contrat actif'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vous n\'avez aucun véhicule avec un contrat d\'assurance actif.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pour déclarer un sinistre, vous devez :',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Avoir un contrat d\'assurance actif'),
                  const Text('• Vérifier que votre contrat n\'est pas expiré'),
                  const Text('• Contacter votre agent si nécessaire'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

