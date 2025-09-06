import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/accident_session.dart';
import '../../models/vehicule_model.dart';
import '../../common/widgets/custom_app_bar.dart';
import 'accident_invitations_screen.dart';

/// 📋 Écran de constat officiel conforme au formulaire tunisien
class ConstatOfficielScreen extends StatefulWidget {
  final VehiculeModel vehiculeSelectionne;

  const ConstatOfficielScreen({
    super.key,
    required this.vehiculeSelectionne,
  });

  @override
  State<ConstatOfficielScreen> createState() => _ConstatOfficielScreenState();
}

class _ConstatOfficielScreenState extends State<ConstatOfficielScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Cases 1-2: Date, heure, lieu
  DateTime _dateAccident = DateTime.now();
  TimeOfDay _heureAccident = TimeOfDay.now();
  final _lieuController = TextEditingController();
  String? _lieuGps;

  // Case 3-4: Blessés et dégâts
  bool? _blesses;
  bool? _degatsAutres;

  // Case 5: Témoins
  List<Temoin> _temoins = [];

  // Données par véhicule (A et B)
  final Map<String, IdentiteVehicule> _identitesVehicules = {};
  final Map<String, PointChocInitial?> _pointsChocInitial = {};
  final Map<String, DegatsApparents> _degatsApparents = {};
  final Map<String, CirconstancesAccident> _circonstances = {};
  final Map<String, String> _observationsVehicules = {};
  final Map<String, SignatureConducteur> _signatures = {};

  // Observations générales
  final _observationsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initialiserDonnees();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lieuController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  void _initialiserDonnees() {
    // Initialiser les données pour le véhicule A (créateur)
    _identitesVehicules['A'] = IdentiteVehicule(
      marque: widget.vehiculeSelectionne.marque,
      type: widget.vehiculeSelectionne.modele,
      numeroImmatriculation: widget.vehiculeSelectionne.numeroImmatriculation,
      senssuivi: '',
      venantDe: '',
      allantA: '',
    );

    _degatsApparents['A'] = DegatsApparents(
      description: '',
      zones: [],
    );

    _circonstances['A'] = CirconstancesAccident(
      casesSelectionnees: [],
      nombreCasesMarquees: 0,
    );

    _observationsVehicules['A'] = '';
    _signatures['A'] = SignatureConducteur(accepteResponsabilite: false);

    // Initialiser les données vides pour le véhicule B
    _identitesVehicules['B'] = IdentiteVehicule(
      marque: '',
      type: '',
      numeroImmatriculation: '',
      senssuivi: '',
      venantDe: '',
      allantA: '',
    );

    _degatsApparents['B'] = DegatsApparents(
      description: '',
      zones: [],
    );

    _circonstances['B'] = CirconstancesAccident(
      casesSelectionnees: [],
      nombreCasesMarquees: 0,
    );

    _observationsVehicules['B'] = '';
    _signatures['B'] = SignatureConducteur(accepteResponsabilite: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Constat Officiel',
        subtitle: 'Formulaire conforme',
      ),
      body: Column(
        children: [
          // Indicateur de progression
          _buildProgressIndicator(),
          
          // Onglets
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Infos Générales'),
              Tab(text: 'Véhicule A'),
              Tab(text: 'Véhicule B'),
              Tab(text: 'Finalisation'),
            ],
          ),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfosGenerales(),
                _buildVehiculeForm('A'),
                _buildVehiculeForm('B'),
                _buildFinalisation(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.description, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                'Constat d\'Accident Automobile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_tabController.index + 1) / 4,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildInfosGenerales() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Cases 1-2: Date, Heure et Lieu'),
            _buildDateHeureLieu(),
            
            const SizedBox(height: 24),
            
            _buildSectionTitle('Cases 3-4: Blessés et Dégâts'),
            _buildBlessesEtDegats(),
            
            const SizedBox(height: 24),
            
            _buildSectionTitle('Case 5: Témoins'),
            _buildTemoins(),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiculeForm(String role) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Véhicule $role'),
          
          const SizedBox(height: 16),
          
          _buildSectionTitle('Case 9: Identité du Véhicule'),
          _buildIdentiteVehicule(role),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Case 10: Point de Choc Initial'),
          _buildPointChocInitial(role),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Case 11: Dégâts Apparents'),
          _buildDegatsApparents(role),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Case 12: Circonstances'),
          _buildCirconstances(role),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Case 14: Observations'),
          _buildObservationsVehicule(role),
        ],
      ),
    );
  }

  Widget _buildFinalisation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Case 15: Signatures'),
          _buildSignatures(),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Observations Générales'),
          _buildObservationsGenerales(),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Photos'),
          _buildPhotos(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildDateHeureLieu() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date et heure
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    subtitle: Text(
                      '${_dateAccident.day}/${_dateAccident.month}/${_dateAccident.year}',
                    ),
                    onTap: _selectionnerDate,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Heure'),
                    subtitle: Text(
                      '${_heureAccident.hour.toString().padLeft(2, '0')}:${_heureAccident.minute.toString().padLeft(2, '0')}',
                    ),
                    onTap: _selectionnerHeure,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Lieu
            TextFormField(
              controller: _lieuController,
              decoration: const InputDecoration(
                labelText: 'Lieu de l\'accident',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez indiquer le lieu de l\'accident';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlessesEtDegats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Blessés
            const Text(
              'Y a-t-il des blessés ?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Oui'),
                    value: true,
                    groupValue: _blesses,
                    onChanged: (value) => setState(() => _blesses = value),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Non'),
                    value: false,
                    groupValue: _blesses,
                    onChanged: (value) => setState(() => _blesses = value),
                  ),
                ),
              ],
            ),
            
            const Divider(),
            
            // Dégâts matériels autres
            const Text(
              'Y a-t-il des dégâts matériels autres que les véhicules ?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Oui'),
                    value: true,
                    groupValue: _degatsAutres,
                    onChanged: (value) => setState(() => _degatsAutres = value),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Non'),
                    value: false,
                    groupValue: _degatsAutres,
                    onChanged: (value) => setState(() => _degatsAutres = value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemoins() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Témoins',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                TextButton.icon(
                  onPressed: _ajouterTemoin,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),

            if (_temoins.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Aucun témoin ajouté',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...(_temoins.asMap().entries.map((entry) =>
                _buildTemoinCard(entry.key, entry.value))),
          ],
        ),
      ),
    );
  }

  Widget _buildTemoinCard(int index, Temoin temoin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${index + 1}'),
        ),
        title: Text('${temoin.nom} ${temoin.prenom}'),
        subtitle: Text(temoin.telephone),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              _temoins.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  Widget _buildIdentiteVehicule(String role) {
    final identite = _identitesVehicules[role]!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: identite.marque,
                    decoration: const InputDecoration(
                      labelText: 'Marque',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _identitesVehicules[role] = IdentiteVehicule(
                        marque: value,
                        type: identite.type,
                        numeroImmatriculation: identite.numeroImmatriculation,
                        senssuivi: identite.senssuivi,
                        venantDe: identite.venantDe,
                        allantA: identite.allantA,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: identite.type,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _identitesVehicules[role] = IdentiteVehicule(
                        marque: identite.marque,
                        type: value,
                        numeroImmatriculation: identite.numeroImmatriculation,
                        senssuivi: identite.senssuivi,
                        venantDe: identite.venantDe,
                        allantA: identite.allantA,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextFormField(
              initialValue: identite.numeroImmatriculation,
              decoration: const InputDecoration(
                labelText: 'N° d\'immatriculation',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _identitesVehicules[role] = IdentiteVehicule(
                  marque: identite.marque,
                  type: identite.type,
                  numeroImmatriculation: value,
                  senssuivi: identite.senssuivi,
                  venantDe: identite.venantDe,
                  allantA: identite.allantA,
                );
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              initialValue: identite.senssuivi,
              decoration: const InputDecoration(
                labelText: 'Sens suivi',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _identitesVehicules[role] = IdentiteVehicule(
                  marque: identite.marque,
                  type: identite.type,
                  numeroImmatriculation: identite.numeroImmatriculation,
                  senssuivi: value,
                  venantDe: identite.venantDe,
                  allantA: identite.allantA,
                );
              },
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: identite.venantDe,
                    decoration: const InputDecoration(
                      labelText: 'Venant de',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _identitesVehicules[role] = IdentiteVehicule(
                        marque: identite.marque,
                        type: identite.type,
                        numeroImmatriculation: identite.numeroImmatriculation,
                        senssuivi: identite.senssuivi,
                        venantDe: value,
                        allantA: identite.allantA,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: identite.allantA,
                    decoration: const InputDecoration(
                      labelText: 'Allant à',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _identitesVehicules[role] = IdentiteVehicule(
                        marque: identite.marque,
                        type: identite.type,
                        numeroImmatriculation: identite.numeroImmatriculation,
                        senssuivi: identite.senssuivi,
                        venantDe: identite.venantDe,
                        allantA: value,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointChocInitial(String role) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Indiquer par une flèche le point de choc initial',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),

            // Schéma de véhicule interactif
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: GestureDetector(
                onTapDown: (details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(details.globalPosition);

                  setState(() {
                    _pointsChocInitial[role] = PointChocInitial(
                      x: localPosition.dx / 300, // Largeur approximative
                      y: localPosition.dy / 200, // Hauteur du container
                      description: 'Point de choc véhicule $role',
                    );
                  });
                },
                child: Stack(
                  children: [
                    // Schéma de véhicule
                    Center(
                      child: Container(
                        width: 120,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Text(
                            'Véhicule $role',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Point de choc
                    if (_pointsChocInitial[role] != null)
                      Positioned(
                        left: _pointsChocInitial[role]!.x * 280,
                        top: _pointsChocInitial[role]!.y * 180,
                        child: const Icon(
                          Icons.arrow_downward,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Touchez le schéma pour indiquer le point de choc',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),

            if (_pointsChocInitial[role] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Point de choc défini',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _pointsChocInitial[role] = null;
                        });
                      },
                      child: const Text('Effacer'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDegatsApparents(String role) {
    final degats = _degatsApparents[role]!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dégâts apparents',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),

            TextFormField(
              initialValue: degats.description,
              decoration: const InputDecoration(
                labelText: 'Description des dégâts',
                border: OutlineInputBorder(),
                hintText: 'Décrivez les dégâts visibles...',
              ),
              maxLines: 3,
              onChanged: (value) {
                _degatsApparents[role] = DegatsApparents(
                  description: value,
                  zones: degats.zones,
                  croquisData: degats.croquisData,
                );
              },
            ),

            const SizedBox(height: 16),

            const Text(
              'Zones endommagées:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: [
                'Avant',
                'Arrière',
                'Côté gauche',
                'Côté droit',
                'Toit',
                'Pare-brise',
                'Phares',
                'Feux',
              ].map((zone) => FilterChip(
                label: Text(zone),
                selected: degats.zones.contains(zone),
                onSelected: (selected) {
                  setState(() {
                    final newZones = List<String>.from(degats.zones);
                    if (selected) {
                      newZones.add(zone);
                    } else {
                      newZones.remove(zone);
                    }
                    _degatsApparents[role] = DegatsApparents(
                      description: degats.description,
                      zones: newZones,
                      croquisData: degats.croquisData,
                    );
                  });
                },
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCirconstances(String role) {
    final circonstances = _circonstances[role]!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Circonstances de l\'accident',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cochez les cases correspondant aux circonstances:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            ...CirconstancesAccident.circonstancesOfficielle.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final description = entry.value;
              final isSelected = circonstances.casesSelectionnees.contains(index);

              return CheckboxListTile(
                dense: true,
                title: Text(
                  '$index. $description',
                  style: const TextStyle(fontSize: 13),
                ),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    final newCases = List<int>.from(circonstances.casesSelectionnees);
                    if (value == true) {
                      newCases.add(index);
                    } else {
                      newCases.remove(index);
                    }
                    _circonstances[role] = CirconstancesAccident(
                      casesSelectionnees: newCases,
                      nombreCasesMarquees: newCases.length,
                    );
                  });
                },
              );
            }).toList(),

            const Divider(),

            Text(
              'Nombre de cases marquées: ${circonstances.nombreCasesMarquees}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationsVehicule(String role) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Observations - Véhicule $role',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),

            TextFormField(
              initialValue: _observationsVehicules[role],
              decoration: const InputDecoration(
                labelText: 'Observations particulières',
                border: OutlineInputBorder(),
                hintText: 'Ajoutez vos observations...',
              ),
              maxLines: 4,
              onChanged: (value) {
                setState(() {
                  _observationsVehicules[role] = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatures() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Signatures des conducteurs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Signature véhicule A
            _buildSignatureSection('A'),

            const SizedBox(height: 16),

            // Signature véhicule B
            _buildSignatureSection('B'),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureSection(String role) {
    final signature = _signatures[role]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conducteur $role',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          CheckboxListTile(
            dense: true,
            title: const Text(
              'J\'accepte la responsabilité de cet accident',
              style: TextStyle(fontSize: 13),
            ),
            value: signature.accepteResponsabilite,
            onChanged: (value) {
              setState(() {
                _signatures[role] = SignatureConducteur(
                  signatureData: signature.signatureData,
                  dateSignature: signature.dateSignature,
                  accepteResponsabilite: value ?? false,
                );
              });
            },
          ),

          const SizedBox(height: 12),

          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[50],
            ),
            child: signature.signatureData != null
                ? const Center(
                    child: Text(
                      'Signature enregistrée',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const Center(
                    child: Text(
                      'Zone de signature\n(Fonctionnalité à implémenter)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (signature.dateSignature != null)
                Text(
                  'Signé le ${signature.dateSignature!.day}/${signature.dateSignature!.month}/${signature.dateSignature!.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              TextButton(
                onPressed: () {
                  // TODO: Implémenter la signature
                  setState(() {
                    _signatures[role] = SignatureConducteur(
                      signatureData: 'signature_data_placeholder',
                      dateSignature: DateTime.now(),
                      accepteResponsabilite: signature.accepteResponsabilite,
                    );
                  });
                },
                child: Text(signature.signatureData != null ? 'Modifier' : 'Signer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObservationsGenerales() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Observations générales',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _observationsController,
              decoration: const InputDecoration(
                labelText: 'Observations sur l\'accident',
                border: OutlineInputBorder(),
                hintText: 'Décrivez les circonstances générales...',
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotos() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Photos de l\'accident',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implémenter la prise de photo
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Ajouter'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            const Text(
              'Minimum 4 photos recommandées: vue générale, dégâts, plaques d\'immatriculation',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Text(
                  'Aucune photo ajoutée',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_tabController.index > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _tabController.animateTo(_tabController.index - 1);
                },
                child: const Text('Précédent'),
              ),
            ),

          if (_tabController.index > 0) const SizedBox(width: 16),

          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _tabController.index < 3 ? _continuerEtape : _finaliserConstat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _tabController.index < 3 ? 'Suivant' : 'Finaliser le constat',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes d'action
  Future<void> _selectionnerDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateAccident,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );

    if (date != null) {
      setState(() {
        _dateAccident = date;
      });
    }
  }

  Future<void> _selectionnerHeure() async {
    final heure = await showTimePicker(
      context: context,
      initialTime: _heureAccident,
    );

    if (heure != null) {
      setState(() {
        _heureAccident = heure;
      });
    }
  }

  void _ajouterTemoin() {
    showDialog(
      context: context,
      builder: (context) => _TemoinDialog(
        onTemoinAjoute: (temoin) {
          setState(() {
            _temoins.add(temoin);
          });
        },
      ),
    );
  }

  void _continuerEtape() {
    if (_tabController.index < 3) {
      _tabController.animateTo(_tabController.index + 1);
    }
  }

  void _finaliserConstat() {
    if (!_formKey.currentState!.validate()) return;

    if (_blesses == null || _degatsAutres == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez compléter toutes les informations obligatoires'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Créer la session d'accident
    final session = AccidentSession(
      id: '',
      codePublic: _genererCodePublic(),
      createurUserId: widget.vehiculeSelectionne.conducteurId,
      createurVehiculeId: widget.vehiculeSelectionne.id,
      statut: AccidentSession.STATUT_BROUILLON,
      dateOuverture: DateTime.now(),
      dateAccident: _dateAccident,
      heureAccident: _heureAccident,
      localisation: {
        'adresse': _lieuController.text.trim(),
        'lat': _lieuGps?.split(',')[0],
        'lng': _lieuGps?.split(',')[1],
        'ville': '',
        'codePostal': '',
      },
      blesses: _blesses ?? false,
      degatsAutres: _degatsAutres ?? false,
      temoins: _temoins,
      identitesVehicules: _identitesVehicules,
      pointsChocInitial: _pointsChocInitial,
      degatsApparents: _degatsApparents,
      circonstances: _circonstances,
      observationsVehicules: _observationsVehicules,
      signatures: _signatures,
      croquisFileId: null,
      croquisData: null,
      observations: _observationsController.text.trim(),
      photos: [],
      nombreParticipants: 2,
      rolesDisponibles: ['A', 'B'],
      deadlineDeclaration: _dateAccident.add(const Duration(days: 5)),
      declarationUnilaterale: false,
      dateCreation: DateTime.now(),
      dateModification: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccidentInvitationsScreen(
          session: session,
          vehiculeCreateur: widget.vehiculeSelectionne,
        ),
      ),
    );
  }

  String _genererCodePublic() {
    final now = DateTime.now();
    final year = now.year;
    final timestamp = now.millisecondsSinceEpoch.toString().substring(8);
    return 'ACC-$year-$timestamp';
  }
}

/// 👥 Dialog pour ajouter un témoin
class _TemoinDialog extends StatefulWidget {
  final Function(Temoin) onTemoinAjoute;

  const _TemoinDialog({required this.onTemoinAjoute});

  @override
  State<_TemoinDialog> createState() => _TemoinDialogState();
}

class _TemoinDialogState extends State<_TemoinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un témoin'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez saisir le nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _prenomController,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez saisir le prénom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telephoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez saisir le téléphone';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
            if (_formKey.currentState!.validate()) {
              final temoin = Temoin(
                nom: _nomController.text.trim(),
                prenom: _prenomController.text.trim(),
                telephone: _telephoneController.text.trim(),
                adresse: _adresseController.text.trim(),
              );
              widget.onTemoinAjoute(temoin);
              Navigator.pop(context);
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
