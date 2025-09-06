import 'package:flutter/material.dart';

/// 🎨 Interface moderne de sélection du nombre de véhicules
class ModernVehicleCountScreen extends StatefulWidget {
  final Map<String, dynamic> typeAccident;

  const ModernVehicleCountScreen({
    super.key,
    required this.typeAccident,
  });

  @override
  State<ModernVehicleCountScreen> createState() => _ModernVehicleCountScreenState();
}

class _ModernVehicleCountScreenState extends State<ModernVehicleCountScreen>
    with TickerProviderStateMixin {
  int _nombreVehicules = 3;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.typeAccident['couleur'].withOpacity(0.8),
              widget.typeAccident['couleur'],
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header avec retour
              _buildHeader(),
              
              // Contenu principal
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      
                      // Titre dynamique
                      _buildTitreDynamique(),
                      
                      const SizedBox(height: 40),
                      
                      // Slider moderne
                      _buildSliderModerne(),
                      
                      const SizedBox(height: 40),
                      
                      // Visualisation dynamique
                      _buildVisualisationVehicules(),
                      
                      const Spacer(),
                      
                      // Bouton suivant
                      _buildBoutonSuivant(),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Bouton retour
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Type d'accident sélectionné
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.typeAccident['titre'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Configuration du nombre de véhicules',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          
          // Icône du type
          Text(
            widget.typeAccident['icon'],
            style: const TextStyle(fontSize: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildTitreDynamique() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            'Combien de véhicules sont impliqués dans l\'accident ?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.typeAccident['couleur'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _nombreVehicules > 5 
                  ? 'Plus de 5 véhicules'
                  : '$_nombreVehicules véhicule${_nombreVehicules > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.typeAccident['couleur'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderModerne() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: widget.typeAccident['couleur'],
              inactiveTrackColor: widget.typeAccident['couleur'].withOpacity(0.3),
              thumbColor: widget.typeAccident['couleur'],
              overlayColor: widget.typeAccident['couleur'].withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 25),
              trackHeight: 6,
            ),
            child: Slider(
              value: _nombreVehicules.toDouble(),
              min: 3,
              max: 8,
              divisions: 5,
              onChanged: (value) {
                setState(() {
                  _nombreVehicules = value.round();
                });
                _animationController.forward().then((_) {
                  _animationController.reverse();
                });
              },
            ),
          ),
          
          // Graduations
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 3; i <= 8; i++)
                Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _nombreVehicules >= i
                            ? widget.typeAccident['couleur']
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      i == 8 ? '5+' : '$i',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _nombreVehicules >= i
                            ? widget.typeAccident['couleur']
                            : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisualisationVehicules() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: widget.typeAccident['couleur'].withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.typeAccident['couleur'].withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Visualisation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.typeAccident['couleur'],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Icônes de véhicules
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (int i = 0; i < (_nombreVehicules > 5 ? 6 : _nombreVehicules); i++)
                      AnimatedContainer(
                        duration: Duration(milliseconds: 200 + (i * 50)),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.typeAccident['couleur'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.typeAccident['couleur'].withOpacity(0.3),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '🚗',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    
                    // Indicateur "plus" si plus de 5
                    if (_nombreVehicules > 5)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.typeAccident['couleur'].withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.typeAccident['couleur'],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '+${_nombreVehicules - 5}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: widget.typeAccident['couleur'],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  _nombreVehicules > 5 
                      ? 'Accident complexe avec ${_nombreVehicules} véhicules'
                      : 'Accident impliquant ${_nombreVehicules} véhicules',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoutonSuivant() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _continuer,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.typeAccident['couleur'],
            foregroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Suivant',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ),
    );
  }

  void _continuer() {
    // TODO: Naviguer vers l'écran de sélection de véhicule
    // avec le type d'accident et le nombre de véhicules
    print('Navigation vers sélection véhicule: ${widget.typeAccident['titre']} - $_nombreVehicules véhicules');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.typeAccident['titre']} - $_nombreVehicules véhicules configurés',
        ),
        backgroundColor: widget.typeAccident['couleur'],
      ),
    );
  }
}
