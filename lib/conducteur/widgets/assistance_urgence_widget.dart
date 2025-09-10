import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

/// 🚑 Widget d'assistance d'urgence pour accidents avec blessés
class AssistanceUrgenceWidget extends StatefulWidget {
  final Function(bool) onBlessesChanged;
  final bool blessesInitial;

  const AssistanceUrgenceWidget({
    super.key,
    required this.onBlessesChanged,
    this.blessesInitial = false,
  });

  @override
  State<AssistanceUrgenceWidget> createState() => _AssistanceUrgenceWidgetState();
}

class _AssistanceUrgenceWidgetState extends State<AssistanceUrgenceWidget> {
  bool _blesses = false;
  Position? _position;
  bool _localisationEnCours = false;

  @override
  void initState() {
    super.initState();
    _blesses = widget.blessesInitial;
    if (_blesses) {
      _obtenirLocalisation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _blesses ? Colors.red[300]! : Colors.grey[300]!,
          width: _blesses ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question principale
            Row(
              children: [
                Icon(
                  Icons.local_hospital,
                  color: _blesses ? Colors.red[600] : Colors.grey[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Y a-t-il des blessés ?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Options Oui/Non
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    label: 'NON',
                    isSelected: !_blesses,
                    color: Colors.green,
                    onTap: () => _changerStatutBlesses(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOptionButton(
                    label: 'OUI',
                    isSelected: _blesses,
                    color: Colors.red,
                    onTap: () => _changerStatutBlesses(true),
                  ),
                ),
              ],
            ),
            
            // Interface d'urgence si blessés
            if (_blesses) ...[
              const SizedBox(height: 20),
              _buildInterfaceUrgence(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterfaceUrgence() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alerte principale
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red[600], size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'URGENCE DÉTECTÉE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            'Des blessés sont signalés. Contactez immédiatement les secours :',
            style: TextStyle(fontSize: 14),
          ),
          
          const SizedBox(height: 16),
          
          // Boutons d'appel d'urgence
          Row(
            children: [
              Expanded(
                child: _buildBoutonUrgence(
                  label: 'Police',
                  numero: '197',
                  icon: Icons.local_police,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBoutonUrgence(
                  label: 'SAMU',
                  numero: '190',
                  icon: Icons.local_hospital,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildBoutonUrgence(
                  label: 'Pompiers',
                  numero: '198',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBoutonUrgence(
                  label: 'Protection Civile',
                  numero: '71',
                  icon: Icons.shield,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Localisation
          _buildSectionLocalisation(),
          
          const SizedBox(height: 16),
          
          // Instructions d'urgence
          _buildInstructionsUrgence(),
        ],
      ),
    );
  }

  Widget _buildBoutonUrgence({
    required String label,
    required String numero,
    required IconData icon,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: () => _appelerNumeroUrgence(numero, label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: Icon(icon, size: 20),
      label: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            numero,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLocalisation() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue[600], size: 16),
              const SizedBox(width: 8),
              const Text(
                'Localisation pour les secours',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (_localisationEnCours)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Localisation en cours...', style: TextStyle(fontSize: 12)),
              ],
            )
          else if (_position != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latitude: ${_position!.latitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                Text(
                  'Longitude: ${_position!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _partagerLocalisation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  icon: const Icon(Icons.share_location, size: 16),
                  label: const Text('Partager position', style: TextStyle(fontSize: 12)),
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: _obtenirLocalisation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              icon: const Icon(Icons.my_location, size: 16),
              label: const Text('Obtenir position', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionsUrgence() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.orange[600], size: 16),
              const SizedBox(width: 8),
              const Text(
                'Instructions importantes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Ne déplacez pas les blessés sauf danger immédiat\n'
            '• Sécurisez la zone avec les feux de détresse\n'
            '• Restez calme et donnez des informations précises\n'
            '• Attendez les secours avant de remplir le constat',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _changerStatutBlesses(bool blesses) {
    if (mounted) setState(() {
      _blesses = blesses;
    });
    
    widget.onBlessesChanged(blesses);
    
    if (blesses) {
      _obtenirLocalisation();
      _afficherDialogueUrgence();
    }
  }

  void _afficherDialogueUrgence() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('URGENCE'),
          ],
        ),
        content: const Text(
          'Des blessés ont été signalés. Il est recommandé d\'appeler immédiatement les secours avant de continuer le constat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('J\'ai compris'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _appelerNumeroUrgence('190', 'SAMU');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Appeler SAMU'),
          ),
        ],
      ),
    );
  }

  Future<void> _appelerNumeroUrgence(String numero, String service) async {
    try {
      final uri = Uri(scheme: 'tel', path: numero);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        
        // Logger l'appel d'urgence
        _loggerAppelUrgence(numero, service);
      } else {
        _afficherErreurAppel(numero);
      }
    } catch (e) {
      _afficherErreurAppel(numero);
    }
  }

  void _loggerAppelUrgence(String numero, String service) {
    // TODO: Logger dans Firestore pour audit
    print('Appel d\'urgence: $service ($numero) à ${DateTime.now()}');
  }

  void _afficherErreurAppel(String numero) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Impossible d\'appeler le $numero. Composez manuellement.'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Copier',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Copier le numéro dans le presse-papiers
          },
        ),
      ),
    );
  }

  Future<void> _obtenirLocalisation() async {
    if (mounted) setState(() {
      _localisationEnCours = true;
    });

    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _afficherErreurLocalisation('Permissions de localisation refusées');
        return;
      }

      // Obtenir la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) setState(() {
        _position = position;
      });

    } catch (e) {
      _afficherErreurLocalisation('Erreur de localisation: $e');
    } finally {
      if (mounted) setState(() {
        _localisationEnCours = false;
      });
    }
  }

  void _afficherErreurLocalisation(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _partagerLocalisation() {
    if (_position == null) return;

    final message = 'Position d\'urgence:\n'
        'Latitude: ${_position!.latitude}\n'
        'Longitude: ${_position!.longitude}\n'
        'https://maps.google.com/?q=${_position!.latitude},${_position!.longitude}';

    // TODO: Implémenter le partage
    print('Partage localisation: $message');
  }
}

