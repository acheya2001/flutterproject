import 'package:flutter/material.dart';
import '../../../common/widgets/gradient_background.dart';
import '../../../common/widgets/custom_app_bar.dart';
import 'accident_type_selection_screen.dart';
import '../../../conducteur/screens/vehicle_selection_enhanced_screen.dart';
import '../../../conducteur/screens/constat_complet_screen.dart';

/// 🚗 Écran de sélection du nombre de véhicules - Design moderne
class VehicleCountSelectionScreen extends StatefulWidget {
  final AccidentType accidentType;
  final String? sinistreId;
  final Map<String, dynamic>? vehiculeSelectionne;

  const VehicleCountSelectionScreen({
    Key? key,
    required this.accidentType,
    this.sinistreId,
    this.vehiculeSelectionne,
  }) : super(key: key);

  @override
  State<VehicleCountSelectionScreen> createState() => _VehicleCountSelectionScreenState();
}

class _VehicleCountSelectionScreenState extends State<VehicleCountSelectionScreen>
    with TickerProviderStateMixin {
  late int _vehicleCount;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialiser avec la valeur par défaut selon le type d'accident
    _vehicleCount = widget.accidentType.defaultVehicleCount;
    
    // Si c'est un objet fixe ou sortie de route, bloquer à 1
    if (widget.accidentType.id == 'collision_objet_fixe' || 
        widget.accidentType.id == 'sortie_route' ||
        widget.accidentType.id == 'accident_pieton_cycliste') {
      _vehicleCount = 1;
    }
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _isFixedVehicleCount {
    return widget.accidentType.id == 'collision_objet_fixe' || 
           widget.accidentType.id == 'sortie_route' ||
           widget.accidentType.id == 'accident_pieton_cycliste';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: [
          const Color(0xFF667eea),
          const Color(0xFF764ba2),
          const Color(0xFFf093fb),
        ],
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Nombre de véhicules',
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 40),
                      _buildVehicleCountSelector(),
                      const SizedBox(height: 40),
                      _buildVehicleVisualization(),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Type d'accident sélectionné
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.accidentType.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.accidentType.color.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.accidentType.icon,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.accidentType.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.accidentType.color,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Question principale
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
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
                const Text(
                  'Combien de véhicules sont impliqués ?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_isFixedVehicleCount) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Pour ce type d\'accident, un seul véhicule est impliqué',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCountSelector() {
    if (_isFixedVehicleCount) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              '1 véhicule (fixe)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
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
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: widget.accidentType.color,
              inactiveTrackColor: widget.accidentType.color.withOpacity(0.3),
              thumbColor: widget.accidentType.color,
              overlayColor: widget.accidentType.color.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              trackHeight: 6,
            ),
            child: Slider(
              value: _vehicleCount.toDouble(),
              min: widget.accidentType.id == 'carambolage' ? 3.0 : 2.0,
              max: 6.0,
              divisions: widget.accidentType.id == 'carambolage' ? 3 : 4,
              onChanged: (value) {
                setState(() {
                  _vehicleCount = value.round();
                });
                _animateVehicleChange();
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Affichage du nombre
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.accidentType.color.withOpacity(0.8),
                  widget.accidentType.color,
                ],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              _vehicleCount >= 6 ? 'Plus de 5 véhicules' : '$_vehicleCount véhicules',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleVisualization() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
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
          Text(
            'Visualisation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          
          // Icônes de véhicules
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(
              _vehicleCount >= 6 ? 5 : _vehicleCount,
              (index) => AnimatedContainer(
                duration: Duration(milliseconds: 200 + (index * 50)),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.accidentType.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.accidentType.color.withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Color(0xFF1F2937),
                  size: 24,
                ),
              ),
            ),
          ),
          
          if (_vehicleCount >= 6) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.accidentType.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${_vehicleCount - 5} autres',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.accidentType.color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.accidentType.color.withOpacity(0.8),
              widget.accidentType.color,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.accidentType.color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _continueToVehicleSelection,
            borderRadius: BorderRadius.circular(16),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Suivant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _animateVehicleChange() {
    _animationController.reset();
    _animationController.forward();
  }

  void _continueToVehicleSelection() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ConstatCompletScreen(
          sinistreId: widget.sinistreId,
          vehiculeSelectionne: widget.vehiculeSelectionne,
          isCollaborative: false,
          sessionData: null, // Pas de session collaborative
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }
}
