import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import '../../../common/widgets/custom_app_bar.dart';
import '../../../common/widgets/gradient_background.dart';
import '../../../models/accident_session.dart';
import '../services/accident_session_service.dart';
import 'invitations_screen.dart';

/// Écran des informations communes d'accident (Cases 1-5, 13, 14)
class InfosCommunesScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> vehiculeData;

  const InfosCommunesScreen({
    Key? key,
    required this.sessionId,
    required this.vehiculeData,
  }) : super(key: key);

  @override
  State<InfosCommunesScreen> createState() => _InfosCommunesScreenState();
}

class _InfosCommunesScreenState extends State<InfosCommunesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Contrôleurs de formulaire
  final _dateController = TextEditingController();
  final _heureController = TextEditingController();
  final _adresseController = TextEditingController();
  final _observationsController = TextEditingController();

  // Données du formulaire
  DateTime _dateAccident = DateTime.now();
  TimeOfDay _heureAccident = TimeOfDay.now();
  Map<String, dynamic> _localisation = {};
  bool _blesses = false;
  bool _degatsAutres = false;
  List<Map<String, dynamic>> _temoins = [];
  List<String> _photos = [];

  // Services
  final AccidentSessionService _sessionService = AccidentSessionService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _dateController.text = DateFormat('dd/MM/yyyy').format(_dateAccident);
    // On initialisera l'heure dans didChangeDependencies ou build
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Maintenant on peut utiliser context
    if (_heureController.text.isEmpty) {
      _heureController.text = _heureAccident.format(context);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _heureController.dispose();
    _adresseController.dispose();
    _observationsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Informations de l\'Accident',
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildDateHeurePage(),
                    _buildLieuPage(),
                    _buildCirconstancesPage(),
                    _buildTemoinsPage(),
                    _buildObservationsPage(),
                  ],
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index <= _currentPage;
          final isCompleted = index < _currentPage;
          
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : isActive
                        ? Colors.blue
                        : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDateHeurePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.schedule,
            title: 'Date et Heure',
            subtitle: 'Quand l\'accident a-t-il eu lieu ?',
          ),
          const SizedBox(height: 32),
          _buildFormCard([
            _buildDateField(),
            const SizedBox(height: 16),
            _buildTimeField(),
          ]),
          const SizedBox(height: 24),
          _buildInfoCard(
            'Précision importante',
            'Indiquez l\'heure exacte de l\'accident. Cette information est cruciale pour l\'enquête.',
            Icons.info_outline,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildLieuPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.location_on,
            title: 'Lieu de l\'Accident',
            subtitle: 'Où l\'accident s\'est-il produit ?',
          ),
          const SizedBox(height: 32),
          _buildFormCard([
            _buildAddressField(),
            const SizedBox(height: 16),
            _buildLocationButton(),
          ]),
          const SizedBox(height: 24),
          if (_localisation.isNotEmpty) _buildLocationInfo(),
        ],
      ),
    );
  }

  Widget _buildCirconstancesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.warning,
            title: 'Circonstances',
            subtitle: 'Y a-t-il eu des blessés ou des dégâts ?',
          ),
          const SizedBox(height: 32),
          _buildFormCard([
            _buildBlessesField(),
            const SizedBox(height: 16),
            _buildDegatsAutresField(),
          ]),
          const SizedBox(height: 24),
          if (_blesses) _buildUrgenceCard(),
        ],
      ),
    );
  }

  Widget _buildTemoinsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.people,
            title: 'Témoins',
            subtitle: 'Y a-t-il eu des témoins de l\'accident ?',
          ),
          const SizedBox(height: 32),
          _buildTemoinsSection(),
        ],
      ),
    );
  }

  Widget _buildObservationsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.note_add,
            title: 'Observations',
            subtitle: 'Ajoutez des détails et des photos',
          ),
          const SizedBox(height: 32),
          _buildFormCard([
            _buildObservationsField(),
          ]),
          const SizedBox(height: 24),
          _buildPhotosSection(),
        ],
      ),
    );
  }

  Widget _buildPageHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
          Icon(icon, size: 48, color: Colors.blue[600]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
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

  Widget _buildFormCard(List<Widget> children) {
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
        children: children,
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
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

  Widget _buildDateField() {
    return TextFormField(
      controller: _dateController,
      decoration: InputDecoration(
        labelText: 'Date de l\'accident',
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.edit_calendar),
          onPressed: _selectDate,
        ),
      ),
      readOnly: true,
      validator: (value) => value?.isEmpty == true ? 'Date requise' : null,
    );
  }

  Widget _buildTimeField() {
    return TextFormField(
      controller: _heureController,
      decoration: InputDecoration(
        labelText: 'Heure de l\'accident',
        prefixIcon: const Icon(Icons.access_time),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.schedule),
          onPressed: _selectTime,
        ),
      ),
      readOnly: true,
      validator: (value) => value?.isEmpty == true ? 'Heure requise' : null,
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _adresseController,
      decoration: InputDecoration(
        labelText: 'Adresse du lieu',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        hintText: 'Rue, ville, code postal...',
      ),
      maxLines: 2,
      validator: (value) => value?.trim().isEmpty == true ? 'Adresse requise' : null,
    );
  }

  Widget _buildLocationButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _getCurrentLocation,
        icon: const Icon(Icons.my_location),
        label: const Text('Utiliser ma position actuelle'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return _buildInfoCard(
      'Position enregistrée',
      'Latitude: ${_localisation['lat']?.toStringAsFixed(6)}\n'
      'Longitude: ${_localisation['lng']?.toStringAsFixed(6)}',
      Icons.gps_fixed,
      Colors.green,
    );
  }

  Widget _buildBlessesField() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Y a-t-il eu des blessés (même légers) ?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(
          value: _blesses,
          onChanged: (value) => setState(() => _blesses = value),
          activeColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildDegatsAutresField() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Y a-t-il des dégâts matériels autres qu\'aux véhicules ?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(
          value: _degatsAutres,
          onChanged: (value) => setState(() => _degatsAutres = value),
        ),
      ],
    );
  }

  Widget _buildUrgenceCard() {
    return _buildInfoCard(
      '🚨 Urgence - Blessés signalés',
      'En cas de blessures graves, appelez immédiatement les secours (190). '
      'Vous pouvez continuer la déclaration après avoir pris soin des blessés.',
      Icons.emergency,
      Colors.red,
    );
  }

  Widget _buildTemoinsSection() {
    return Column(
      children: [
        ..._temoins.asMap().entries.map((entry) => _buildTemoinCard(entry.key, entry.value)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _ajouterTemoin,
            icon: const Icon(Icons.person_add),
            label: const Text('Ajouter un témoin'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemoinCard(int index, Map<String, dynamic> temoin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Témoin ${index + 1}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _supprimerTemoin(index),
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Nom: ${temoin['nom'] ?? 'Non renseigné'}'),
          Text('Téléphone: ${temoin['tel'] ?? 'Non renseigné'}'),
          Text('Adresse: ${temoin['adresse'] ?? 'Non renseigné'}'),
        ],
      ),
    );
  }

  Widget _buildObservationsField() {
    return TextFormField(
      controller: _observationsController,
      decoration: InputDecoration(
        labelText: 'Observations et commentaires',
        prefixIcon: const Icon(Icons.note),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        hintText: 'Décrivez les circonstances, les conditions météo, etc.',
        alignLabelWithHint: true,
      ),
      maxLines: 4,
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos de l\'accident',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_photos.isEmpty)
          _buildAddPhotoCard()
        else
          _buildPhotosGrid(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _ajouterPhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Ajouter une photo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoCard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 32, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              'Aucune photo ajoutée',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) => _buildPhotoItem(index),
    );
  }

  Widget _buildPhotoItem(int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[200],
              child: const Icon(Icons.image, size: 32),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _supprimerPhoto(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Précédent'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage < 4 ? _nextPage : _saveAndContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(_currentPage < 4 ? 'Suivant' : 'Continuer'),
            ),
          ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_validateCurrentPage()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0: // Date et heure
        return _dateController.text.isNotEmpty && _heureController.text.isNotEmpty;
      case 1: // Lieu
        return _adresseController.text.trim().isNotEmpty;
      case 2: // Circonstances
        return true; // Pas de validation spécifique
      case 3: // Témoins
        return true; // Optionnel
      case 4: // Observations
        return true; // Optionnel
      default:
        return true;
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateAccident,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      if (mounted) setState(() {
        _dateAccident = date;
        _dateController.text = DateFormat('dd/MM/yyyy').format(date);
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _heureAccident,
    );
    if (time != null) {
      if (mounted) setState(() {
        _heureAccident = time;
        _heureController.text = time.format(context);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);
      
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée');
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final adresse = '${placemark.street}, ${placemark.locality}, ${placemark.country}';
        
        setState(() {
          _localisation = {
            'lat': position.latitude,
            'lng': position.longitude,
            'adresse': adresse,
            'ville': placemark.locality,
            'codePostal': placemark.postalCode,
          };
          _adresseController.text = adresse;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de localisation: $e')),
      );
    }
  }

  void _ajouterTemoin() {
    showDialog(
      context: context,
      builder: (context) => _TemoinDialog(
        onSave: (temoin) {
          setState(() => _temoins.add(temoin));
        },
      ),
    );
  }

  void _supprimerTemoin(int index) {
    setState(() => _temoins.removeAt(index));
  }

  Future<void> _ajouterPhoto() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() => _photos.add(image.path));
      }
    }
  }

  void _supprimerPhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _saveAndContinue() async {
    if (!_validateCurrentPage()) return;

    setState(() => _isLoading = true);

    try {
      // Combiner date et heure
      final dateHeure = DateTime(
        _dateAccident.year,
        _dateAccident.month,
        _dateAccident.day,
        _heureAccident.hour,
        _heureAccident.minute,
      );

      // Mettre à jour la session avec les informations communes
      await _sessionService.updateSession(widget.sessionId, {
        'dateOuverture': dateHeure,
        'localisation': _localisation.isNotEmpty ? _localisation : {
          'adresse': _adresseController.text.trim(),
        },
        'blesses': _blesses,
        'degatsAutres': _degatsAutres,
        'temoins': _temoins,
        'observations': _observationsController.text.trim(),
        'photos': _photos,
        'statut': AccidentSession.STATUT_EN_ATTENTE_INVITES,
      });

      // Naviguer vers l'écran d'invitations
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InvitationsScreen(
            sessionId: widget.sessionId,
            vehiculeData: widget.vehiculeData,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}

/// Dialog pour ajouter un témoin
class _TemoinDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const _TemoinDialog({required this.onSave});

  @override
  State<_TemoinDialog> createState() => _TemoinDialogState();
}

class _TemoinDialogState extends State<_TemoinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _telController = TextEditingController();
  final _adresseController = TextEditingController();

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
                labelText: 'Nom et prénom',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) => value?.trim().isEmpty == true ? 'Nom requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                prefixIcon: Icon(Icons.location_on),
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
              widget.onSave({
                'nom': _nomController.text.trim(),
                'tel': _telController.text.trim(),
                'adresse': _adresseController.text.trim(),
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

